import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:schnell_luminator/attendence_tracking.dart/attendance_service.dart';
import 'package:schnell_luminator/location_selection/location_service.dart';
import 'package:schnell_luminator/survey/background_sync_manager.dart';
import 'package:schnell_luminator/survey/survey_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../device_page/telemetry_service.dart';
import '../pole_install.dart/pole_history_model.dart';
import '../s3_bucket/s3_config.dart';
import '../s3_bucket/s3_upload_service.dart';
import '../ticket_notification/offline/ticket_queue_item.dart';
import '../ticket_notification/ticket_model.dart';
import '../ticket_notification/offline/ticket_update_queue_item.dart';
import '../ticket_notification/ticket_service.dart';
import '../utils/constants.dart';
import '../utils/image_compression_util.dart';
import '../utils/utility.dart';
import 'models/survey_image_model.dart';
import 'survey_service.dart';

const int _ticketSyncBatchSize = 5;

class SimpleSyncService {
  static Future<bool> performSurveyDataSync() async {
    try {
      log('Starting background survey sync...');
      final box = await Hive.openBox('surveyBox');
      final keys = box.keys.toList();
      final pendingKeys = keys.where((k) {
        final data = box.get(k);
        log('Checking survey k=$k| isUploaded=${data['isUploaded']} for ${data['poleNumber']}');

        return data != null && data['isUploaded'] != true;
      }).toList();

      if (pendingKeys.isEmpty) return true;

      int syncedCount = 0;

      for (final key in pendingKeys) {
        final surveyData = box.get(key);
        log('Checking survey key=$key | isUploaded=${surveyData['isUploaded']}');
        if (surveyData == null) continue;

        final response = await _syncSurveyInIsolate(surveyData);
        if (response) {
          surveyData['isUploaded'] = true;
          await box.put(key, surveyData); // update in place
          syncedCount++;

          // update ward asset list
          final wardId = surveyData['wardId'];
          final assetType = surveyData['assetType'];

          if (assetType == 'Switch Point' && surveyData['spNo'] != null) {
            await addSurveyedAssetToHive(
              wardId: wardId,
              assetType: 'switchPoints',
              assetName: surveyData['spNo'],
            );
            await box.flush();
          }

          if (assetType == 'Transformer' &&
              surveyData['transformerNo'] != null) {
            await addSurveyedAssetToHive(
              wardId: wardId,
              assetType: 'transformers',
              assetName: surveyData['transformerNo'],
            );
            await box.flush();
          }
        }
      }

      log('Survey sync completed: $syncedCount/${pendingKeys.length} synced');
      return true;
    } catch (e) {
      log('Survey sync failed: $e');
      return false;
    }
  }

  static Future<bool> performImageSync() async {
    try {
      log('Starting background image sync...');

      final box = await Hive.openBox('imagesBox');
      final s3Service = S3UploadService();

      final keys = box.keys.toList();
      final pendingKeys = keys.where((k) {
        final data = box.get(k);
        if (data == null) return false;
        final model = MultiCapturedImageModel.fromMap(data);
        return !model.isUploaded1 || !model.isUploaded2 || !model.isUploaded3;
      }).toList();

      if (pendingKeys.isEmpty) return true;

      int syncedCount = 0;

      for (final key in pendingKeys) {
        final data = box.get(key);
        if (data == null) continue;

        final model = MultiCapturedImageModel.fromMap(data);

        if (!model.isUploaded1 && model.fileName1.isNotEmpty) {
          if (await _uploadImage(s3Service, model.filePath1, model.fileName1)) {
            log("Entered into image uploading part in background sync");
            model.isUploaded1 = true;
            syncedCount++;
          }
        }

        if (!model.isUploaded2 && model.fileName2.isNotEmpty) {
          if (await _uploadImage(s3Service, model.filePath2, model.fileName2)) {
            model.isUploaded2 = true;
            syncedCount++;
          }
        }

        if (!model.isUploaded3 && model.fileName3.isNotEmpty) {
          if (await _uploadImage(s3Service, model.filePath3, model.fileName3)) {
            model.isUploaded3 = true;
            syncedCount++;
          }
        }

        // Update record at same key
        await box.put(key, model.toMap());
      }

      log('Image sync completed: $syncedCount images uploaded');
      return true;
    } catch (e) {
      log('Image sync failed: $e');
      return false;
    }
  }

  static Future<bool> performSync() async {
    log('monitoring immediate connectivity for sync...');
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();

    bool hasInternet = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
    final prefs = await SharedPreferences.getInstance();
    if (hasInternet) {
      await prefs.setBool('hasInternet', true);
      log('Background: Internet available, triggering data sync...');
      final surveyResult = await performSurveyDataSync();
      log('triggered image sync');
      final imageResult = await performImageSync();
      await performAttendanceSync();
      await performPpeSync();
      await performTelemetrySync(prefs);
      await performTicketImageSync();
      await performTicketSync();
      await performTicketUpdateSync();
      log('surveyResult: $surveyResult, imageResult: $imageResult');
      return surveyResult && imageResult;
    } else {
      await prefs.setBool('hasInternet', false);
      log('Background: No internet connection');
      return true;
    }
  }

  static Future<void> performAttendanceSync() async {
    try {
      log('Background: syncing pending attendance records...');
      await AttendanceService.syncPending();
      log('Background: attendance sync complete');
    } catch (e) {
      log('Background: attendance sync error: $e');
    }
  }

  static Future<void> performPpeSync() async {
    try {
      log('Background: syncing pending PPE uploads...');
      final box = await Utility.openPpeQueueBox();
      final pending = box.values.where((item) => !item.uploaded).toList();
      if (pending.isEmpty) return;

      final s3Service = S3UploadService();
      int synced = 0;

      for (final item in pending) {
        final file = File(item.imagePath);
        if (!await file.exists()) {
          // Image deleted from device — mark uploaded to avoid repeated retries
          item.uploaded = true;
          await item.save();
          log('PPE sync: image missing, skipping ${item.imagePath}');
          continue;
        }
        final fileName = item.imagePath.split('/').last;
        final result = await s3Service
            .updateSurveyImageServiceS3(item.imagePath, fileName, isPPE: true);
        if (result == '200') {
          item.uploaded = true;
          await item.save();
          synced++;
          log('PPE sync: uploaded $fileName');
        }
      }
      log('Background: PPE sync complete — $synced/${pending.length} uploaded');
    } catch (e) {
      log('Background: PPE sync error: $e');
    }
  }

  static bool _isTicketImageSyncing = false;

  static Future<void> performTicketImageSync() async {
    if (_isTicketImageSyncing) return;
    _isTicketImageSyncing = true;
    try {
      log('Background: syncing pending ticket images...');
      final box = await Utility.openHiveBox(ticketImagesQueueBox);
      final keys = box.keys.toList();
      final pendingKeys = keys.where((k) {
        final data = box.get(k);
        if (data == null) return false;
        return data['uploaded'] != true;
      }).toList();

      if (pendingKeys.isEmpty) {
        log('Background: no pending ticket images to sync');
        return;
      }

      int synced = 0;
      for (final key in pendingKeys) {
        final data = Map<String, dynamic>.from(box.get(key) as Map);
        final filePath = data['filePath']?.toString() ?? '';
        final fileName = data['fileName']?.toString() ?? '';
        final folder = data['folder']?.toString() ?? S3Config.grievanceFolder;

        final file = File(filePath);
        if (!await file.exists()) {
          log('Ticket image sync: missing file at $filePath, removing key');
          await box.delete(key);
          continue;
        }

        final result = await S3UploadService.uploadImageFileToS3(
          filePath: filePath,
          fileName: fileName,
          folder: folder,
          contentType: 'image/jpeg',
        );

        if (result != null && result.isNotEmpty) {
          log('Ticket image sync: successfully uploaded $fileName to $folder');
          await ImageCompressionUtil.deleteCompressedImage(filePath);
          await box.delete(key);
          synced++;
        }
      }
      log('Background: ticket image sync complete — $synced/${pendingKeys.length} uploaded');
    } catch (e) {
      log('Background: ticket image sync error: $e');
    } finally {
      _isTicketImageSyncing = false;
    }
  }

  /// Syncs locally-queued offline tickets, small batch at a time.
  ///
  /// Mirrors [performPpeSync]/[performAttendanceSync] exactly: open the box,
  /// filter to `!uploaded`, try each one, flip the flag on success. No
  /// separate "syncing"/"failed" states — an item that fails just stays
  /// `uploaded = false` and gets picked up again on the next run, same as
  /// every other offline queue in this app.
  static Future<void> performTicketSync() async {
    try {
      log('[TicketSync] starting ticket sync...');
      final box = await Hive.openBox<TicketQueueItem>(ticketQueueBox);

      final pending = box.values.where((item) => !item.uploaded).toList()
        ..sort((a, b) => a.createdAtEpochMs.compareTo(b.createdAtEpochMs));

      if (pending.isEmpty) {
        log('[TicketSync] nothing to sync');
        return;
      }

      final batch = pending.take(_ticketSyncBatchSize);
      int syncedCount = 0;
      for (final item in batch) {
        try {
          final postData = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          // Reuses the same createTicketServiceFB the online path calls —
          // context/ref aren't touched inside it, so this is a safe
          // background-isolate call.
          if (item.latitude == 0.0 || item.longitude == 0.0) {
            postData['latitude'] = item.tlatitude;
            postData['longitude'] = item.tlongitude;
          }

          if (item.tlatitude != 0.0 && item.tlongitude != 0.0) {
            final LocationService _locationService = LocationService();

            final locResponse = await _locationService.getGeocodingLocation(
                item.tlatitude, item.tlongitude);

            if (locResponse['status'] == 200) {
              postData['location'] = locResponse['data']['formatted_address'];
            }
          }

          // The queue key is the Firestore doc id the ticket will be created
          // under — any offline updates to it are queued under the same id.
          postData['alarm_id'] = item.alarmId;
          final res = await TicketService().createTicketServiceFB(postData);

          item.lastAttemptEpochMs = DateTime.now().millisecondsSinceEpoch;
          if (res != null && res['status'] == 'success') {
            item.uploaded = true;
            item.remoteTicketId = res['ticketId']?.toString();
            item.lastError = null;
            syncedCount++;
            log('[TicketSync] synced localId=${item.alarmId} -> ticketId=${item.remoteTicketId}');
            await _reconcileListBoxEntry(item, postData);
          } else {
            item.attemptCount += 1;
            item.lastError = 'server rejected create';
            log('[TicketSync] sync rejected alarmId=${item.alarmId}, attempt ${item.attemptCount}');
          }
          await item.save();
        } catch (e) {
          item.attemptCount += 1;
          item.lastAttemptEpochMs = DateTime.now().millisecondsSinceEpoch;
          item.lastError = e.toString();
          await item.save();
          log('[TicketSync] sync error alarmId=${item.alarmId}: $e');
        }
      }
      if (syncedCount > 0) {
        // Runs in the background isolate — the main isolate's already-open
        // ticketListBox instance won't see these writes until it's told to
        // reopen the box (see HiveSyncManager.setupSyncPort in main.dart).
        HiveSyncManager.notifySync();
      }
      log('[TicketSync] batch complete: $syncedCount/${batch.length} synced, ${pending.length - batch.length} remaining for next run');
    } catch (e) {
      log('[TicketSync] performTicketSync failed: $e');
    }
  }

  /// Moves a just-synced ticket's ticketListBox entry from its localId key
  /// to the server ticketId, and flips synced to true — the same record,
  /// same badge logic MyTicketsView already reads, now just showing as
  /// synced instead of disappearing and being re-created on next login.
  static Future<void> _reconcileListBoxEntry(
      TicketQueueItem item, Map<String, dynamic> postData) async {
    final ticketId = item.remoteTicketId;
    if (ticketId == null || ticketId.isEmpty) return;
    try {
      final box = await Hive.openBox(ticketListBox);
      final existing = box.get(item.alarmId);
      final ticket = existing != null
          ? Ticket.fromJson(Map<String, dynamic>.from(existing))
          : Ticket(
              alarmId: item.alarmId,
              deviceType: item.deviceType,
              problemType: item.problemType,
              comment: item.comments,
              location: item.locationText,
              // Same "yyyy-MM-dd HH:mm:ss" format getDurationFB expects —
              // not ISO8601, which throws a FormatException when the card
              // tries to parse it.
              createdTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.fromMillisecondsSinceEpoch(item.createdAtEpochMs)),
              ward: postData['ward']?.toString() ?? '',
              zone: postData['zone']?.toString() ?? '',
              region: postData['region']?.toString() ?? '',
              customer: postData['customer']?.toString() ?? '',
            );
      // alarm_id is the ticket's permanent identity (the value the update
      // endpoint looks it up by) and never changes — only ticketId (the
      // human-readable display number) and sync state do. The box entry
      // therefore stays at the same key it's always been at; there is no
      // re-keying step here anymore.
      ticket.ticketId = ticketId;
      ticket.localId = null;
      ticket.synced = true;
      await box.put(item.alarmId, ticket.toJson());
    } catch (e) {
      log('[TicketSync] failed to reconcile ticketListBox for alarmId=${item.alarmId}: $e');
    }
  }

  /// Syncs locally-queued offline ticket updates, same pattern as
  /// [performTicketSync].
  ///
  /// The queue holds one merged entry per ticket (keyed by alarm id), so
  /// each entry carries that ticket's latest pending state.
  ///
  /// An update to a ticket that was itself created offline is held back
  /// until that ticket's create has synced — the alarm id only exists as a
  /// Firestore doc once the create lands. Runs after [performTicketSync] in
  /// [performSync], so both usually go out in the same cycle.
  static Future<void> performTicketUpdateSync() async {
    try {
      log('[TicketUpdateSync] starting ticket update sync...');
      final box =
          await Hive.openBox<TicketUpdateQueueItem>(ticketUpdateQueueBox);
      final createBox = await Hive.openBox<TicketQueueItem>(ticketQueueBox);

      bool isCreatePending(String alarmId) {
        final create = createBox.get(alarmId);
        return create != null && !create.uploaded;
      }

      final pending = box.values
          .where((item) => !item.uploaded && !isCreatePending(item.alarmId))
          .toList()
        ..sort((a, b) => a.updatedAtEpochMs.compareTo(b.updatedAtEpochMs));

      if (pending.isEmpty) {
        log('[TicketUpdateSync] nothing to sync');
        return;
      }

      final batch = pending.take(_ticketSyncBatchSize);
      int syncedCount = 0;
      for (final item in batch) {
        // Queued against a ticket created offline — pick up the ticket
        // number the server assigned now that the create has synced.
        if (item.ticketId.isEmpty) {
          item.ticketId = createBox.get(item.alarmId)?.remoteTicketId ?? '';
        }
        try {
          final postData = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          log('DEBUG sync item.alarmId=${item.alarmId} item.ticketId=${item.ticketId} item.remoteTicketId=${createBox.get(item.alarmId)?.remoteTicketId}');

          final res = await TicketService()
              .updateTicketServiceFB(null, null, item.alarmId, postData);

          item.lastAttemptEpochMs = DateTime.now().millisecondsSinceEpoch;
          if (res == 1) {
            item.uploaded = true;
            item.lastError = null;
            syncedCount++;
            log('[TicketUpdateSync] synced ticket=${item.ticketId} (alarmId=${item.alarmId})');
            await _clearPendingUpdateFlag(item);
          } else {
            item.attemptCount += 1;
            item.lastError = 'server rejected update';
            log('[TicketUpdateSync] sync rejected ticket=${item.ticketId}, attempt ${item.attemptCount}');
          }
          await item.save();
        } catch (e) {
          item.attemptCount += 1;
          item.lastAttemptEpochMs = DateTime.now().millisecondsSinceEpoch;
          item.lastError = e.toString();
          await item.save();
          log('[TicketUpdateSync] sync error ticket=${item.ticketId}: $e');
        }
      }
      if (syncedCount > 0) {
        HiveSyncManager.notifySync();
      }
      log('[TicketUpdateSync] batch complete: $syncedCount/${batch.length} synced, ${pending.length - syncedCount} remaining for next run');
    } catch (e) {
      log('[TicketUpdateSync] performTicketUpdateSync failed: $e');
    }
  }

  /// Clears the "Update Pending" flag on the ticket's ticketListBox entry
  /// once its update has synced.
  static Future<void> _clearPendingUpdateFlag(
      TicketUpdateQueueItem item) async {
    try {
      final box = await Hive.openBox(ticketListBox);
      // alarm_id is the permanent box key — ticketListBox entries are never
      // re-keyed once created, so there's no ambiguity about which key to
      // look this ticket up under.
      final raw = box.get(item.alarmId);
      if (raw == null) return;
      final ticket = Ticket.fromJson(Map<String, dynamic>.from(raw));
      if (!ticket.hasPendingUpdate) return;
      ticket.hasPendingUpdate = false;
      await box.put(item.alarmId, ticket.toJson());
    } catch (e) {
      log('[TicketUpdateSync] failed to clear pending-update flag for alarmId=${item.alarmId}: $e');
    }
  }

  /// Adds any telemetry payload to the offline queue.
  static Future<void> enqueueTelemetry(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('pending_telemetry_queue') ?? [];
    queue.add(jsonEncode(data));
    await prefs.setStringList('pending_telemetry_queue', queue);
    log('Telemetry queued offline: $data');
  }

  /// Flushes every queued telemetry payload in order.
  /// Items that fail remain in the queue for the next sync cycle.
  static Future<void> performTelemetrySync(SharedPreferences prefs) async {
    final queue = prefs.getStringList('pending_telemetry_queue') ?? [];
    if (queue.isEmpty) return;

    log('Background: flushing ${queue.length} pending telemetry item(s)');
    final telemetry = TelemetryService();
    final remaining = <String>[];

    for (final item in queue) {
      try {
        final data = jsonDecode(item) as Map<String, dynamic>;
        final result = await telemetry.pushValuesToUserTelemetry(data);
        if (result == '200') {
          log('Background: telemetry synced — $data');
        } else {
          remaining.add(item);
        }
      } catch (e) {
        remaining.add(item);
        log('Background: telemetry sync failed — $e');
      }
    }

    await prefs.setStringList('pending_telemetry_queue', remaining);
  }

  static Future<bool> _uploadImage(
      S3UploadService service, String? filePath, String filename) async {
    if (filePath == null || filePath.isEmpty) return true;

    try {
      final result =
          await service.updateSurveyImageServiceS3(filePath, filename);
      return result == "200";
    } catch (e) {
      log('Image upload failed for $filename: $e');
      return false;
    }
  }

  static Future<bool> performInternetCheck() async {
    try {
      log('monitoring immediate connectivity for sync...');

      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();

      bool hasInternet = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasInternet', hasInternet);
      log('Background: Internet status updated = $hasInternet');

      return true;
    } catch (e) {
      log('Internet check failed: $e');
      return false;
    }
  }
}

Future<bool> _syncSurveyInIsolate(dynamic data) async {
  final SurveyService surveyService = SurveyService();
  log('data inside BG thread: $data');
  var landMark = data['landmark'];
  log('locationCheck inside BG thread: $landMark');
  var manualEnteredLocation = data['manualEnteredLocation'];

  if (landMark == null || landMark.isEmpty) {
    log('inside getUser location');
    landMark = await SurveyProvider()
        .getUserLocation(data['latitude'], data['longitude']);
  }

  String? concatenatedLocation = '$manualEnteredLocation,$landMark';
  String? filteredLandMark;
  filteredLandMark = concatenatedLocation
      .replaceAll(RegExp(r',\s*'), ',')
      .replaceAll(RegExp(r'^,\s*'), '')
      .trim();

  final isPole = data['assetType'] == 'Pole';
  final isSwitchPoint = data['assetType'] == 'Switch Point';
  final isTransformer = data['assetType'] == 'Transformer';
  final installedOn = int.tryParse(data['installedOn'] ?? '0') ?? 0;
  final armCount = int.tryParse(data['armCount'] ?? '0') ?? 0;

  final prefs = await SharedPreferences.getInstance();
  final storedMode = prefs.getString(selectedModePrefsKey);

  final Map<String, dynamic> postData = {
    "roadType": data['roadType'],
    "trafficDensity": data['trafficDensity'],
    "trafficSpeed": data['trafficSpeed'],
    "assetType": data['assetType'],
    "customerId": data['customerId'],
    "wardId": data['wardId'],
    if (data['comments'] != '') "remarks": data['comments'],
    "region": data['region'],
    "zoneName": data['zone'],
    "wardName": data['ward'],
    "installedBy": data['installedBy'],
    "installedOn": installedOn,
    "state": 'INSTALLED',
    "latitude": data['latitude'],
    "longitude": data['longitude'],
    "location": filteredLandMark,
    "accuracy": double.parse(data['accuracy'] == '' ? '0' : data['accuracy']),
    "altitude": data['altitude'],
    "existingRoadCategory": data['roadCategory'],
    "roadWidth": data['roadWidth'],
    "vehicleAccess": data['vehicleAccess'],
    "signalStrength": {
      data["carrierName"]: data['signalStrengthLevel'],
    },
    "auditImg": [
      if (data['uuidFileName1'] != '') data['uuidFileName1'],
      if (data['uuidFileName2'] != '') data['uuidFileName2'],
      if (data['uuidFileName3'] != '') data['uuidFileName3'],
    ],
    "activityMode": storedMode,
  };

  if (isPole) {
    postData.addAll({
      "name": data['poleNumber'],
      "condition": data['poleCondition'],
    });

    if (data['switchPointNo'] != '') {
      postData["switchPointNo"] = data['switchPointNo'];
    }
    if (data['escomPoleNumber'] != '') {
      postData["ebPoleNo"] = data['escomPoleNumber'];
    }
    if (data['exCorpPoleNo'] != '') {
      postData["exCorpPoleNo"] = data['exCorpPoleNo'];
    }
    if (data['poleTransformerNo'] != '') {
      postData["transformerNo"] = data['poleTransformerNo'];
    }
    if (data['poleCondition'] != 'Missing') {
      postData.addAll({
        "type": data['poleType'],
        "height": data['poleHeight'],
        "earthingRequired": data['earthingRequired'],
        "manualSwitchControl": data['manualSwitchControl'],
        "incomingTransmissionLine": data['incomingTransLine'],
        "incomingTransmissionType": data['incomingTransType'],
        "armCount": armCount,
        "armDetails": {
          "count": armCount,
          "length": data['armLength'],
          "condition": [
            {"condition": "Good", "count": data['goodArmCount']},
            {"condition": "Bad", "count": data['badArmCount']},
            {"condition": "Missing", "count": data['missingArmCount']},
          ]
        },
      });
      if (armCount > 0) {
        if (data['selectedLamps'].length > 0) {
          postData['lampProfiles'] = data['selectedLamps'];
        }
        postData['lightDetails'] = [
          {
            "condition": "Working",
            "count": data['workingCount'],
          },
          {
            "condition": "Not Working",
            "count": data['notWorkingCount'],
          },
          {
            "condition": "Missing",
            "count": data['missingCount'],
          },
        ];
      }

      if (data['poleType'] == 'High Mast(HM)') {
        postData['motorCondition'] = data['motorCondition'];
        if (data['motorCondition'] != 'Missing') {
          postData["motorDetails"] = {
            'rating': data['motorRating'],
            'make': data['motorMake'],
            'model': data['motorModel']
          };
          postData['winchCondition'] = data['winchCondition'];
          postData['ropeCondition'] = data['ropeCondition'];
        }
      }
      if (data['poleType'] != 'High Mast(HM)' &&
          data['poleType'] != 'Mini Mast(MM)') {
        postData["span"] = data['poleSpan'];
        postData["bracketMountingHeight"] = data['bracketMountingHeight'];
        if (data['clampType'] != 'Clamp Type Not Required') {
          postData["clampDimension"] = {
            "length": data['clampTypeLength'],
            "width": data['clampTypeWidth'],
            "unit": data['clampTypeUnits'],
          };
        }
      }
    }
  }

  if (isSwitchPoint) {
    postData.addAll({
      "switchPointNumber": data['spNo'],
      "switchPointType": data['spType'],
      "connectedLoad": (data['spconnectedLoad']?.isNotEmpty ?? false)
          ? (double.tryParse(data['spconnectedLoad']) ?? 0)
          : 0,
      "condition": data['spCondition'],
      "earthingCondition": data['spEarthingCondition'],
    });

    if (data['rrNo'] != '') postData["rrNumber"] = data['rrNo'];
    if (data['spId'] != '') postData["panelId"] = data['spId'];
    if (data['spTransformerNo'] != '') {
      postData["transformerNo"] = data['spTransformerNo'];
    }

    if (data['spMeter'] == 'Missing') {
      postData["meterDetails"] = {"status": data['spMeter']};
    } else {
      postData["meterDetails"] = {
        "no": data['spMeterNo'],
        "type": data['spMeterType'],
        "make": data['spMeterMake'],
        "phase": data['spMeterPhase'],
        "status": data['spMeter'],
      };
    }
  }

  if (isTransformer) {
    postData.addAll({
      "transformerNumber": data['transformerNo'],
      "capacity": (data['transCapacity'].isNotEmpty ?? false)
          ? '${data['transCapacity']} kW'
          : '0 kW',
    });
  }

  var result = await surveyService.updateSurveyDetailService(postData);
  log('Survey details $postData uploaded successfully in isolate');
  if (result == "200" || result == "400") {
    return true;
  }
  return false;
}

Future<void> incrementAssetCount(
  String assetType, // "pole" | "switchPoint" | "transformer"
  String wardId,
  String usermail,
) async {
  final box = await Utility.openInstallationHistoryBox();

  final todaysDate = '${DateTime.now().day.toString().padLeft(2, '0')}-'
      '${DateTime.now().month.toString().padLeft(2, '0')}-'
      '${DateTime.now().year}';

  final key = '${wardId}_${usermail}_$todaysDate';

  InstallationHistory? history = box.get(key);

  // If today's record already exists --> increment count
  if (history != null) {
    switch (assetType) {
      case 'pole':
        history.pole += 1;
        break;
      case 'switchPoint':
        history.switchPoint += 1;
        break;
      case 'transformer':
        history.transformer += 1;
        break;
    }
    await box.put(key, history);
  }

  // If today's record does NOT exist --> create it
  else {
    history = InstallationHistory(
      date: todaysDate,
      pole: assetType == 'pole' ? 1 : 0,
      switchPoint: assetType == 'switchPoint' ? 1 : 0,
      transformer: assetType == 'transformer' ? 1 : 0,
      wardId: wardId,
      usermail: usermail,
    );

    await box.put(key, history);
  }
}

Future<void> addSurveyedAssetToHive({
  required String wardId,
  required String assetType, // 'switchPoints' or 'transformers'
  required String assetName,
}) async {
  try {
    final box = await Utility.openHiveBox(assetNameBox);

    final key = 'ward_$wardId';

    final wardData = Map<String, dynamic>.from(box.get(key) ?? {});

    final List<String> existingList =
        List<String>.from(wardData[assetType] ?? []);

    // Avoid duplicates
    if (!existingList.contains(assetName)) {
      existingList.add(assetName);
    }

    wardData[assetType] = existingList;

    await box.put(key, wardData);

    log('Updated Hive [$key][$assetType]: $existingList');

    // Notify main isolate to refresh Hive boxes
    HiveSyncManager.notifySync();
  } catch (e) {
    log('Error updating Hive for surveyed asset: $e');
  }
}
