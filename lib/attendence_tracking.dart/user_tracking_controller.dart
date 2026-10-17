import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:schnell_luminator/attendence_tracking.dart/ppe_queue_item.dart';
import 'package:schnell_luminator/attendence_tracking.dart/user_tracking_service.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/login_page/login_controller.dart';
import 'package:schnell_luminator/utils/constants.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:schnell_luminator/utils/session.dart';
import 'package:schnell_luminator/utils/utility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../location_selection/customer_list.dart';
import '../location_selection/location_controller.dart';
import '../s3_bucket/s3_upload_service.dart';
import '../utils/secure_storage.dart';
import 'gps_details_model.dart';

final userTrackingController = ChangeNotifierProvider<UserTrackingProvider>(
    (ref) => UserTrackingProvider());

class UserTrackingProvider extends ChangeNotifier {
  final UserTrackingService _userTrackingService = UserTrackingService();
  final S3UploadService _s3UploadService = S3UploadService();

  // String _deviceMake = '';
  // String _deviceModel = '';
  // String _imei = '';
  // String _carrierName = '';
  // int _signalStrengthLevel = 0;

  Future<void> activityLocationTracking(WidgetRef ref, activityName, entityName,
      {bool isTicket = false, entityType = ''}) async {
    try {
      double latitude = 0.0;
      double longitude = 0.0;
      String clickeventIsFor = ref.read(deviceController).clickeventIsFor;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      if ((activityName == 'ILM Installation' &&
              clickeventIsFor != "addILM" &&
              clickeventIsFor != "addILMViaPole") ||
          activityName == 'GW Installation') {
        // For ILM and GW installations, the latitude and longitude have already been
        // determined using 20 iterations in advance, so we directly use the fetched values here.
        latitude = double.parse(ref.read(deviceController).fetchedLat);
        longitude = double.parse(ref.read(deviceController).fetchedLong);
      } else {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
        );
        latitude = position.latitude;
        longitude = position.longitude;
        dev.log(
            "Location Tracking during activity: $latitude, $longitude at $timestamp");
      }
      final networkDetails =
          await _userTrackingService.fetchNetworkDetails(fetchBattery: false);
      dev.log('Network Details: ${networkDetails['batteryLevel']}');
      await storeLocationLocally(timestamp,
          lat: latitude,
          long: longitude,
          locationEnabled: true,
          activityName: activityName ?? '',
          entityName: entityName ?? '',
          entityType: entityType ?? '',
          carrierName: networkDetails['carrierName'],
          signalStrengthLevel: networkDetails['signalStrengthLevel'],
          deviceMake: networkDetails['deviceMake'],
          deviceModel: networkDetails['deviceModel'],
          imei: networkDetails['imei'],
          isTicket: isTicket);
      await Utility.isConnected().then((value) async {
        if (value) {
          //if internet available else location details just stored locally
          await _userTrackingService.pushLocationToUserTelemetry();
        }
      });
    } catch (e) {
      dev.log("Location error: $e");
    }
  }

  Future<void> ppeImageUpload(WidgetRef ref, context, imagePath) async {
    final secureStorage = SecureStorageService();
    String userId = await secureStorage.getUserId() ?? '';
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
    final fileName = '${userId}_$formattedDate.jpg';
    final filePath = await Utility.activityCompressImage(imagePath, fileName);
    String userMail = ref.watch(loginController).userMail;

    // Always queue the PPE item locally so sync can retry if upload fails/skipped
    final meta = await secureStorage.getOfflineSessionMeta();
    final sessionId = meta?['sessionId'] ?? userId;
    final ppeBox = await Utility.openPpeQueueBox();
    final queueEntry = PpeQueueItem(
      sessionId: sessionId,
      imagePath: filePath,
      timestamp: timestamp,
      uploaded: false,
    );
    final queueKey = await ppeBox.add(queueEntry);

    final isOnline = await Utility.isConnected();

    if (!isOnline) {
      // Offline — image queued, proceed to app without upload
      EasyLoading.dismiss();
      if (context.mounted) {
        await successTick(context, 'PPE image saved. Will upload when online.');
        EasyLoading.show(status: 'loading...');
        await ref.read(locationController).getStoredContext(userMail);
        EasyLoading.dismiss();
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerList()),
          );
        }
      }
      return;
    }

    var res = await _s3UploadService
        .updateSurveyImageServiceS3(filePath, fileName, isPPE: true);
    if (res == '200') {
      // Mark as uploaded in the queue
      queueEntry.uploaded = true;
      await ppeBox.put(queueKey, queueEntry);

      EasyLoading.dismiss();
      await successTick(context, 'Image Uploaded Successfully');
      EasyLoading.show(status: 'loading...');
      ref.read(locationController).refreshFromServer(userMail);
      await ref.read(locationController).getStoredContext(userMail);
      EasyLoading.dismiss();

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerList()),
        );
      }
    } else if (res == '500' || res == '503') {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  Future<bool> autoLogout(BuildContext context, WidgetRef ref) async {
    final secureStorage = SecureStorageService();
    var data = await secureStorage.getUserDetails();

    // if already logged in
    if (data != '' || data != null) {
      //auto logout after 24 hrs
      final prefs = await SharedPreferences.getInstance();
      final loginTimestamp = prefs.getInt('loginTimestamp');
      if (loginTimestamp == null) return false;
      final loginTime = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
      final now = DateTime.now();
      final difference = now.difference(loginTime);

      if (difference.inHours >= 24) {
        await ref.read(loginController).onUserLogout(context, ref);
        return true;
      }
    }
    return false;
  }

  Future<double> calculateSessionDistance() async {
    if (Hive.isBoxOpen(locationTrackingBox)) {
      await Hive.box<TravelLocationEntity>(locationTrackingBox).close();
    }
    final box = await Hive.openBox<TravelLocationEntity>(locationTrackingBox);
    dev.log(
        'Box data after login: ${box.length} items → ${box.values.map((e) => '(${e.lat}, ${e.long}, ${e.timestamp})').toList()}');

    if (box.length < 1) return 0.0;

    double totalKm = 0;

    for (int i = 0; i < box.length - 1; i++) {
      totalKm += calculateDistanceKm(
        box.getAt(i)!.lat,
        box.getAt(i)!.long,
        box.getAt(i + 1)!.lat,
        box.getAt(i + 1)!.long,
      );
    }

    return totalKm;
  }

  double _toRad(double deg) => deg * pi / 180;

  double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // km

    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Lower bound for the location tracking period so a misconfigured or
  /// missing server value never causes tracking to run more frequently
  /// than once every 5 minutes.
  static const int _minLocationTrackingIntervalMs = 5 * 60 * 1000;

  Future<void> initForegroundTask(int interval) async {
    final effectiveInterval = interval < _minLocationTrackingIntervalMs
        ? _minLocationTrackingIntervalMs
        : interval;
    FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'location_tracking',
            channelName: 'Location Tracking',
            channelDescription:
                'This notification appears when background location is running',
            channelImportance: NotificationChannelImportance.MAX,
            priority: NotificationPriority.MAX,
            visibility: NotificationVisibility.VISIBILITY_PUBLIC,
            playSound: true,
            onlyAlertOnce: false,
            enableVibration: true,
            showWhen: true),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
          // eventAction: ForegroundTaskEventAction.repeat(3600000),// 1 hr
          eventAction: ForegroundTaskEventAction.repeat(
              effectiveInterval), //in millisecs
          autoRunOnBoot: true,
          autoRunOnMyPackageReplaced: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ));
  }
}
