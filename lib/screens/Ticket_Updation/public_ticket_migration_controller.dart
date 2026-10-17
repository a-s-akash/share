import 'dart:developer';
import 'package:citizen_complaints_list_web/s3_bucket/s3_controller.dart';
import 'package:citizen_complaints_list_web/firestore_controller.dart';
import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart' as uuid;

final publicTicketMigrationController =
    ChangeNotifierProvider<PublicTicketMigrationProvider>(
  (ref) => PublicTicketMigrationProvider(),
);

class PublicTicketMigrationProvider extends ChangeNotifier {
  final TextEditingController _commentsController = TextEditingController();
  Uint8List? _pickedImageBytes;

  String _ticketId = '';
  String _docId = '';

  // Original Reference Data
  String _originalRegion = '';
  String _originalDeviceId = '';
  String _originalLocation = '';
  String _originalProblemType = '';
  String _originalPhone = '';

  // Target Migration Data
  String _targetCustomer = '';
  String _targetCustomerId = '';
  String _targetRegion = '';
  String _targetRegionId = '';
  String _targetZone = '';
  String _targetZoneId = '';
  String _targetWard = '';
  String _targetWardId = '';

  Map<String, dynamic>? _userContextCache;
  Map<String, dynamic>? _targetRegionData;
  Map<String, dynamic>? _targetZoneData;

  // Getters for UI
  String get ticketId => _ticketId;
  String get originalRegion => _originalRegion;
  String get originalDeviceId => _originalDeviceId;
  String get originalLocation => _originalLocation;
  String get originalProblemType => _originalProblemType;
  String get originalPhone => _originalPhone;

  String get targetCustomer => _targetCustomer;
  String get targetRegion => _targetRegion;
  String get targetZone => _targetZone;
  String get targetWard => _targetWard;

  Uint8List? get pickedImageBytes => _pickedImageBytes;
  TextEditingController get commentsController => _commentsController;

  Future<void> initialize(Map<String, dynamic> data, String docId) async {
    _docId = docId;
    _ticketId = data['ticket_id'] ?? '';
    _originalRegion = data['region'] ?? '';
    _originalDeviceId = data['entity_name'] ?? '';
    _originalLocation = data['location'] ?? '';
    _originalProblemType = data['problem_type'] ?? '';
    _originalPhone = data['complainee_contact_no'] ?? '';

    // Reset target context
    _targetCustomer = '';
    _targetCustomerId = '';
    _targetRegion = '';
    _targetRegionId = '';
    _targetZone = '';
    _targetZoneId = '';
    _targetWard = '';
    _targetWardId = '';
    _targetRegionData = null;
    _targetZoneData = null;

    // Reset Comments and Image
    _commentsController.clear();
    _pickedImageBytes = null;

    // Load Project Context for Migration
    final box = await Hive.openBox('project_context');
    if (box.containsKey(userEmail)) {
      final cacheData = box.get(userEmail);
      if (cacheData is Map) {
        _userContextCache = Map<String, dynamic>.from(cacheData);
      }
    }

    notifyListeners();
  }

  List<String> get customerList {
    if (_userContextCache != null) {
      return _userContextCache!.keys
          .where((k) => k != 'Public')
          .cast<String>()
          .toList()
        ..sort();
    }
    return [];
  }

  List<String> get targetRegionList {
    if (_targetCustomer.isNotEmpty &&
        _userContextCache != null &&
        _userContextCache![_targetCustomer] != null) {
      final regions = _userContextCache![_targetCustomer]['regions'] as Map?;
      if (regions != null) {
        return regions.keys.cast<String>().toList()..sort();
      }
    }
    return [];
  }

  List<String> get targetZoneList {
    if (_targetRegionData != null && _targetRegionData!['zones'] != null) {
      return (_targetRegionData!['zones'] as Map).keys.cast<String>().toList()
        ..sort();
    }
    return [];
  }

  List<String> get targetWardList {
    if (_targetZoneData != null && _targetZoneData!['wards'] != null) {
      return (_targetZoneData!['wards'] as Map).keys.cast<String>().toList()
        ..sort();
    }
    return [];
  }

  void targetValueUpdate(String which, String value) {
    if (which == 'customer') {
      if (value != _targetCustomer) {
        _targetCustomer = value;
        _targetCustomerId = _userContextCache?[value]?['customer_id'] ?? '';
        _targetRegion = '';
        _targetRegionId = '';
        _targetZone = '';
        _targetZoneId = '';
        _targetWard = '';
        _targetWardId = '';
        _targetRegionData = null;
        _targetZoneData = null;
      }
    } else if (which == 'region') {
      if (value != _targetRegion) {
        _targetRegion = value;
        _targetRegionData =
            _userContextCache?[_targetCustomer]?['regions']?[value];
        _targetRegionId = _targetRegionData?['region_id'] ?? '';
        _targetZone = '';
        _targetZoneId = '';
        _targetWard = '';
        _targetWardId = '';
        _targetZoneData = null;
      }
    } else if (which == 'zone') {
      if (value != _targetZone) {
        _targetZone = value;
        _targetZoneData = _targetRegionData?['zones']?[value];
        _targetZoneId = _targetZoneData?['zone_id'] ?? '';
        _targetWard = '';
        _targetWardId = '';
      }
    } else if (which == 'ward') {
      if (value != _targetWard) {
        _targetWard = value;
        final wardData = _targetZoneData?['wards']?[value];
        _targetWardId = wardData?['ward_id'] ?? '';
      }
    }
    notifyListeners();
  }

  Future<void> imagePicker() async {
    final ImagePicker picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      EasyLoading.show(maskType: EasyLoadingMaskType.black);
      final bytes = await img.readAsBytes();
      _pickedImageBytes = bytes;
      notifyListeners();
      EasyLoading.dismiss();
    }
  }

  void removeImage() {
    _pickedImageBytes = null;
    notifyListeners();
  }

  bool get canMigrate {
    return _targetCustomer.isNotEmpty &&
        _targetRegion.isNotEmpty &&
        _commentsController.text.isNotEmpty;
  }

  Future<void> migrateTicket(BuildContext context) async {
    if (_docId.isEmpty || !canMigrate) return;

    var fileName = "";
    if (_pickedImageBytes != null) {
      fileName = const uuid.Uuid().v1();
      final compressedBytes = await activityCompressImage(_pickedImageBytes!);
      final res = await s3Upload(compressedBytes, fileName);
      if (res != '200') {
        EasyLoading.showError("Image upload failed");
        return;
      }
    }

    String datetime = getCurrentFormattedDateTime();

    Map<String, dynamic> updateData = {
      'customer': _targetCustomer,
      'customer_id': _targetCustomerId,
      'region': _targetRegion,
      'region_id': _targetRegionId,
      'zone': _targetZone,
      'zone_id': _targetZoneId,
      'ward': _targetWard,
      'ward_id': _targetWardId,
      'comments': _commentsController.text,
    };
    final parts = [
      _targetCustomer,
      _targetRegion,
      _targetZone,
      _targetWard,
    ].where((e) => e.toString().isNotEmpty).toList();

    final action = 'Moved from Public to Project Context: ${parts.join(' > ')}';
    Map<String, dynamic> auditEntry = {
      "actions": [action],
      "by": user,
      "mail_id": userEmail,
      "user_id": userId,
      "on": datetime,
      "comment": _commentsController.text,
      "attachment": _pickedImageBytes != null ? fileName : "",
    };
    updateData["audit_trail"] = auditEntry;

    try {
      int res = await updateTicketInFirestore(_docId, updateData);
      if (res == 1) {
        // --- NEW: Local Cleanup for Immediate Feedback ---
        final ticketsBox = Hive.box('tickets_box');
        final publicTickets = ticketsBox.get(publicCustomerId);
        if (publicTickets != null && publicTickets is Map) {
          final updatedPublic = Map<String, dynamic>.from(publicTickets);
          if (updatedPublic.containsKey(_docId)) {
            updatedPublic.remove(_docId);
            await ticketsBox.put(publicCustomerId, updatedPublic);
          }
        }
        // --------------------------------------------------

        EasyLoading.showSuccess("Ticket Migrated Successfully");
        Navigator.pop(context);
      } else {
        EasyLoading.showError("Migration Failed");
      }
    } catch (e) {
      log("Error migrating ticket: $e");
      EasyLoading.showError("Migration Error");
    }
  }

  void clearData() {
    _ticketId = '';
    _docId = '';
    _targetCustomer = '';
    _targetRegion = '';
    _targetZone = '';
    _targetWard = '';
    _commentsController.clear();
    _pickedImageBytes = null;
    notifyListeners();
  }
}
