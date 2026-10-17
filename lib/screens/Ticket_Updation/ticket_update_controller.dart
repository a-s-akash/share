import 'dart:developer';

import 'package:citizen_complaints_list_web/s3_bucket/s3_controller.dart';
import 'package:citizen_complaints_list_web/screens/Ticket_Creation/new_ticket_service.dart';
import 'package:citizen_complaints_list_web/firestore_controller.dart';
import 'package:citizen_complaints_list_web/screens/Tickets_List/tickets_list_controller.dart';
import 'package:citizen_complaints_list_web/screens/api/api_services.dart';
import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:uuid/uuid.dart' as uuid;
import 'package:citizen_complaints_list_web/screens/Ticket_Updation/duplicate_search_dialog.dart';

import '../../firebase_setup/firbase_config.dart';
import '../../firebase_setup/firebase_services.dart';

final ticketUpdateController = ChangeNotifierProvider<TicketUpdateProvider>(
  (ref) => TicketUpdateProvider(),
);

class TicketUpdateProvider extends ChangeNotifier {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _replacedEntityNameController =
      TextEditingController();
  Uint8List? _pickedImageBytes;

  List<String> priorityList = [
    'Critical',
    'Major',
    'Minor',
    'Warning',
    // 'Indeterminate',
  ];
  List<Map<String, String>> _assigneesData = [];
  List<String> get assigneeList {
    final Set<String> options = _assigneesData.map((e) => e['name']!).toSet();
    if (_selectedAssignee.isNotEmpty && _selectedAssignee != 'Unassigned') {
      options.add(_selectedAssignee);
    }
    return ['Unassigned', ...options];
  }

  String _ticketId = '';
  String _selectedCustomer = '';
  String _selectedCustomerId = '';
  String _selectedRegion = '';
  String _selectedRegionId = '';
  String _selectedZone = '';
  String _selectedZoneId = '';
  String _selectedWard = '';
  String _selectedWardId = '';
  String _selectedDeviceType = '';
  String _selectedDevice = '';
  String _previousDeviceType = '';
  String _selectedDeviceId = '';
  String _previousDeviceId = '';
  String _selectedPriority = '';
  String _selectedProblemType = '';
  String _selectedStatus = '';
  String _selectedAssignee = '';
  String _previousReplacedEntityName = '';
  String _previousLocation = '';
  String _previousDuplicatedTo = '';

  // String _selectedComplainee = '';
  bool _selectedComponentChanged = false;
  String _selectedIssueIdentified = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _panelId = '';
  String _meterSerialNo = '';
  String _spNo = '';
  String _deviceAssetId = '';
  String _complaineePhoneNumber = '';
  String _previousComplaineePhoneNumber = '';
  String _comments = '';
  String _existingAttachment = '';
  final List<String> _statusList = [
    'Open',
    'Assigned',
    'Visited-Closed',
    'Visited-Not Closed',
    'Verified-Opened',
    'Verified-Closed',
    'Closed',
    'Verified-Duplicate',
    'Waiting-For-Support'
  ];
  String _entityType = '';

  String _previousZone = '';
  String _previousWard = '';
  String _previousStatus = '';
  String _previousComplainee = '';
  String _previousAssignee = '';
  String _previousPriority = '';
  bool? _previousComponentChanged;
  String _previousIssueIdentified = '';
  Map<String, String> _duplicateOf = {};

  String _previousTicketOpenedOn = '';

  String _docId = '';
  bool _isMinimised = false;

  Future<void> initialize(Map<String, dynamic> data, String docId) async {
    log(data.toString());
    if (!Hive.isBoxOpen('assignee_cache')) {
      await Hive.openBox('assignee_cache');
    }

    _docId = docId;
    _ticketId = data['ticket_id'];
    _selectedCustomer = data['customer'];
    _selectedCustomerId = data['customer_id'] ?? '';
    _selectedRegion = data['region'];
    _selectedRegionId = data['region_id'];
    _selectedZone = data['zone'] ?? '';
    _previousZone = _selectedZone;
    _selectedZoneId = data['zone_id'] ?? '';
    _selectedWard = data['ward'] ?? '';
    _previousWard = _selectedWard;
    _selectedWardId = data['ward_id'] ?? '';
    _selectedDeviceType = data['entity_type'] ?? '';
    _previousDeviceType = _selectedDeviceType;
    _previousDuplicatedTo = data['duplicated_to'] ?? '';

    if (_selectedDeviceType.isNotEmpty &&
        entityList.containsKey(_selectedDeviceType)) {
      _selectedDeviceTypes =
          List<String>.from(entityList[_selectedDeviceType]!['device']!);
      _entityType = entityList[_selectedDeviceType]!['type']!;
    }

    _selectedDeviceId = data['entity_id'] ?? '';
    _previousDeviceId = _selectedDeviceId;
    _selectedDevice = data['entity_name'] ?? '';
    _previousPriority = data['priority'];
    _selectedPriority = _previousPriority;
    _selectedProblemType = data['problem_type'];
    _previousStatus = data['status'];
    _selectedStatus = _previousStatus;
    _previousAssignee = data['assignee'] ?? '';
    _selectedAssignee = _previousAssignee;
    _previousComplainee = data['complainee'];
    _previousTicketOpenedOn = data['ticket_opened_on'];
    // _selectedComplainee = _previousComplainee;

    _previousComponentChanged = data['components_changed'];
    _selectedComponentChanged = _previousComponentChanged ?? false;
    _previousIssueIdentified = data['issue_identified'] ?? '';
    _selectedIssueIdentified = _previousIssueIdentified;

    if (!isComponentChangeEnabled) {
      _selectedComponentChanged = false;
    }

    _locationController.text = data['location'] ?? '';
    _previousLocation = data['location'] ?? '';
    _latitude = double.tryParse(data['latitude']?.toString() ?? '0.0') ?? 0.0;
    _longitude = double.tryParse(data['longitude']?.toString() ?? '0.0') ?? 0.0;
    _panelId = data['panel_id'] ?? '';
    _meterSerialNo = data['meter_serial_no'] ?? '';
    _spNo = data['sp_no'] ?? '';
    _previousComplaineePhoneNumber = data['complainee_contact_no'] ?? '';
    _phoneController.text = _previousComplaineePhoneNumber;
    _commentsController.text = '';

    _previousReplacedEntityName = data['replaced_entity_name'] ?? '';
    _replacedEntityNameController.text = _previousReplacedEntityName;

    _pickedImageBytes = null;
    _assigneesData = [];

    // _statusList = switch (_selectedStatus) {
    //   'Open' => [
    //       'Open',
    //       'Assigned',
    //       'Closed',
    //       'Verified-Duplicate',
    //       'Waiting-For-Support'
    //     ],
    //   'Assigned' => [
    //       'Assigned',
    //       'Closed',
    //       'Visited-Closed',
    //       'Visited-Not Closed',
    //       'Verified-Duplicate',
    //       'Waiting-For-Support'
    //     ],
    //   'Closed' => [
    //       'Closed',
    //       'Verified-Opened',
    //       'Verified-Closed',
    //       'Verified-Duplicate',
    //     ],
    //   'Visited-Closed' => [
    //       'Visited-Closed',
    //       'Verified-Opened',
    //       'Verified-Closed',
    //       'Assigned',
    //       'Verified-Duplicate'
    //     ],
    //   'Visited-Not Closed' => [
    //       'Visited-Not Closed',
    //       'Assigned',
    //       'Visited-Closed',
    //       'Verified-Opened',
    //       'Verified-Closed',
    //       'Verified-Duplicate',
    //       'Waiting-For-Support'
    //     ],
    //   'Verified-Opened' => [
    //       'Verified-Opened',
    //       'Assigned',
    //       'Verified-Duplicate',
    //       'Waiting-For-Support'
    //     ],
    //   'Verified-Closed' => ['Verified-Closed'],
    //   'Verified-Duplicate' => ['Verified-Duplicate'],
    //   'Waiting-For-Support' => [
    //       'Waiting-For-Support',
    //       'Closed',
    //       'Visited-Closed',
    //       'Verified-Closed',
    //       'Verified-Duplicate'
    //     ],
    //   _ => [],
    // };

    _isRegionEditable = false;
    _isZoneEditable = _selectedZone.isEmpty || _selectedDeviceId.isEmpty;
    _isWardEditable = _selectedWard.isEmpty || _selectedDeviceId.isEmpty;

    if (_isZoneEditable || _isWardEditable) {
      final box = await Hive.openBox('project_context');
      if (box.containsKey(userEmail)) {
        final data = box.get(userEmail);
        if (data is Map) {
          _userContextCache = Map<String, dynamic>.from(data);
          if (_userContextCache != null &&
              _userContextCache![_selectedCustomer] != null) {
            _regionData = _userContextCache![_selectedCustomer]['regions']
                ?[_selectedRegion];
            if (_selectedZone.isNotEmpty) {
              _zoneData = _regionData?['zones']?[_selectedZone];
            }
          }
        }
      }
    }

    _isDeviceEditable = _selectedDeviceId.isEmpty;
    _isDeviceTypeEditable = _selectedDeviceType.isEmpty;

    notifyListeners();
  }

  bool _isRegionEditable = false;
  bool _isZoneEditable = false;
  bool _isWardEditable = false;
  bool _isDeviceEditable = false;
  bool _isDeviceTypeEditable = false;
  Map<String, dynamic>? _userContextCache;
  Map<String, dynamic>? _regionData;
  Map<String, dynamic>? _zoneData;

  bool get isRegionEditable => _isRegionEditable;
  bool get isZoneEditable => _isZoneEditable;
  bool get isTicketEditable {
    return !['Verified-Closed', 'Verified-Duplicate']
            .contains(_previousStatus) ||
        (['Verified-Closed', 'Verified-Duplicate'].contains(_previousStatus) &&
            _selectedStatus != _previousStatus);
  }

  bool get isWardEditable => _isWardEditable;
  bool get isDeviceEditable => _isDeviceEditable;
  bool get isDeviceTypeEditable => _isDeviceTypeEditable;

  List<String> get zoneList {
    if (_regionData != null && _regionData!['zones'] != null) {
      return (_regionData!['zones'] as Map).keys.cast<String>().toList()
        ..sort();
    }
    return [];
  }

  List<String> get wardList {
    if (_zoneData != null && _zoneData!['wards'] != null) {
      return (_zoneData!['wards'] as Map).keys.cast<String>().toList()..sort();
    }
    return [];
  }

  List<String> get devicesList {
    if (_selectedDeviceType.isEmpty) return [];

    var devices = _deviceOptions.map((e) => e['value']!).toList()..sort();
    return devices;
  }

  List<String> get problemTypeList {
    final probIssueBox = Hive.box('problemTypesAndIssuesIdentified');

    if (_selectedDeviceType.isEmpty) {
      return probIssueBox.get('problem_types')['general'] as List<String>;
      // return generalProblemTypes;
    }

    return List<String>.from(
      probIssueBox.get('problem_types')[_selectedDeviceType] ?? [],
    );
  }

  List<Map<String, String>> _deviceOptions = [];
  String _deviceSearchQuery = '';
  bool _isLoadingDevices = false;
  bool get isLoadingDevices => _isLoadingDevices;
  int _fetchDevicesVersion = 0;

  Future<void> fetchDevices([String? query]) async {
    if (query != null) {
      _deviceSearchQuery = query;
    }

    String contextId = _selectedWardId.isNotEmpty
        ? _selectedWardId
        : _selectedZoneId.isNotEmpty
            ? _selectedZoneId
            : _selectedRegionId;

    if (contextId.isEmpty || _selectedDeviceType.isEmpty) {
      _deviceOptions = [];
      notifyListeners();
      return;
    }

    _fetchDevicesVersion++;
    final int myVersion = _fetchDevicesVersion;
    _isLoadingDevices = true;
    notifyListeners();

    List<Map<String, String>> results;
    try {
      if (_entityType != 'others') {
        results = await searchAssetsService(
          contextId,
          _selectedDeviceTypes,
          _entityType,
          _deviceSearchQuery,
        );
      } else {
        results = [];
      }
    } catch (e) {
      log('Error fetching devices: $e');
      results = [];
    }

    // A newer call was made while we were waiting — discard stale results.
    if (myVersion != _fetchDevicesVersion) return;

    _deviceOptions = results;
    _isLoadingDevices = false;
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

  List<String> _selectedDeviceTypes = [];

  Future<void> valueUpdate(String which, value, [context]) async {
    // Mark as async
    if (which == 'priority') {
      _selectedPriority = value;
    } else if (which == 'status') {
      if (value == 'Open') {
        _selectedAssignee = "Unassigned";
      } else if (value == "Verified-Duplicate" &&
          _previousStatus != "Verified-Duplicate") {
        final statusBeforeDuplicate = _selectedStatus;
        showDialog(
          context: context,
          builder: (context) {
            return DuplicateSearchScreen(
                region: _selectedRegion,
                currentTicketId: _ticketId,
                currentTicketOpenedOn: _previousTicketOpenedOn);
          },
        ).then((selectedValue) {
          if (selectedValue != null) {
            log("Selected Duplicate: $selectedValue");
            _duplicateOf = selectedValue;
            notifyListeners();
          } else {
            log("No Duplicate Selected");
            _selectedStatus = statusBeforeDuplicate;
            _duplicateOf = {};
            notifyListeners();
          }
        });
      } else {
        _duplicateOf = {};
        notifyListeners();
      }
      _selectedStatus = value;
    } else if (which == 'deviceType') {
      if (value != _selectedDeviceType) {
        _selectedDeviceType = value;
        _selectedDeviceTypes = entityList[_selectedDeviceType]!['device']!;
        _entityType = entityList[_selectedDeviceType]!['type']!;
        if (_selectedDeviceId != '') {
          _locationController.clear();
        }
        _selectedDevice = '';
        _selectedDeviceId = '';
        _latitude = 0.0;
        _longitude = 0.0;
        _panelId = '';
        _meterSerialNo = '';
        _spNo = '';
        _selectedIssueIdentified = '';
        _selectedComponentChanged = false;
        _deviceSearchQuery = '';
        fetchDevices();
      }
    } else if (which == 'device') {
      if (value != _selectedDevice) {
        _selectedDevice = value;
        final selectedOption = _deviceOptions.firstWhere(
          (element) => element['value'] == value,
          orElse: () => {'id': '', 'value': ''},
        );
        try {
          final deviceName = _selectedDevice;
          final details = await getDeviceDetailsService(
            _selectedDevice,
            _selectedDeviceTypes,
          );
          if (details != null && details is Map) {
            valueUpdate('region', details['region']);
            valueUpdate('zone', details['zone']);
            valueUpdate('ward', details['ward']);
            _selectedDeviceId = selectedOption['id'] ?? '';
            _selectedDevice = deviceName;
            _latitude = details['latitude'] ?? 0.0;
            _longitude = details['longitude'] ?? 0.0;
            _panelId = details['panel_id'] ?? '';
            _meterSerialNo = details['meter_serial_no'] ?? '';
            _spNo = details['sp_no'] ?? '';
            final loc = details['location'];
            if (loc != null && loc.toString().isNotEmpty) {
              _locationController.text = loc.toString();
            }
          }
        } catch (e) {
          log('Error getting device details: $e');
        }
      }
    } else if (which == 'zone') {
      if (value != _selectedZone) {
        _selectedZone = value;
        _selectedWard = '';
        _selectedWardId = '';
        _zoneData = null;
        if (_selectedDeviceId != '') {
          _locationController.clear();
        }
        _selectedDevice = '';
        _selectedDeviceId = '';
        _latitude = 0.0;
        _longitude = 0.0;
        _panelId = '';
        _meterSerialNo = '';
        _spNo = '';

        if (_regionData != null) {
          _zoneData = _regionData!['zones']?[value];
          _selectedZoneId = _zoneData?['zone_id'] ?? '';
        }

        if (_selectedDeviceType.isNotEmpty) {
          fetchDevices();
        }
      }
    } else if (which == 'ward') {
      if (value != _selectedWard) {
        _selectedWard = value;
        if (_selectedDeviceId != '') {
          _locationController.clear();
        }
        _selectedDevice = '';
        _selectedDeviceId = '';
        _latitude = 0.0;
        _longitude = 0.0;
        _panelId = '';
        _meterSerialNo = '';
        _spNo = '';

        if (_zoneData != null) {
          final wardData = _zoneData!['wards']?[value];
          _selectedWardId = wardData?['ward_id'] ?? '';
        }

        if (_selectedDeviceType.isNotEmpty) {
          fetchDevices();
        }
      }
    } else if (which == 'assignee') {
      if (value != "Unassigned") {
        if (_selectedStatus == 'Open') {
          _selectedStatus = "Assigned";
        }
      } else {
        if (_selectedStatus == 'Assigned') {
          _selectedStatus = "Open";
        }
      }
      _selectedAssignee = value;
    } else if (which == 'componentChanged') {
      _selectedComponentChanged = value;
    } else if (which == 'issueIdentified') {
      _selectedIssueIdentified = value;
      if (!isComponentChangeEnabled) {
        _selectedComponentChanged = false;
      }
    } else if (which == 'comments') {
      _comments = value;
    }
    // else if (which == 'complainee') {
    //   _selectedComplainee = value;
    // }
    else if (which == 'phone') {
      _complaineePhoneNumber = value;
    } else if (which == 'minimize') {
      _isMinimised = value;
    }
    notifyListeners();
  }

  bool get canUpdate {
    return _comments.isNotEmpty &&
        (_phoneController.text.length == 10 || _phoneController.text.isEmpty) &&
        (_selectedStatus != 'Assigned' || _selectedAssignee != 'Unassigned');
  }

  Future<void> updateTicket(BuildContext context) async {
    if (_ticketId.isEmpty) {
      EasyLoading.showError("Invalid Ticket ID");
      return;
    }

    // Capture state to prevent issues when dialog is minimized during async upload/compress
    final localDocId = _docId;
    final localExistingAttachment = _existingAttachment;
    final localPickedImageBytes = _pickedImageBytes;
    final localSelectedStatus = _selectedStatus;
    final localPreviousStatus = _previousStatus;
    final localIsDeviceTypeEditable = isDeviceTypeEditable;
    final localSelectedDeviceType = _selectedDeviceType;
    final localPreviousDeviceType = _previousDeviceType;
    final localIsDeviceEditable = _isDeviceEditable;
    final localSelectedDeviceId = _selectedDeviceId;
    final localPreviousDeviceId = _previousDeviceId;
    final localSelectedDevice = _selectedDevice;
    final localLatitude = _latitude;
    final localLongitude = _longitude;
    final localPanelId = _panelId;
    final localMeterSerialNo = _meterSerialNo;
    final localSpNo = _spNo;
    final localDeviceSearchQuery = _deviceSearchQuery;
    final localLocationText = _locationController.text;
    final localIsZoneEditable = _isZoneEditable;
    final localSelectedZone = _selectedZone;
    final localSelectedZoneId = _selectedZoneId;
    final localPreviousZone = _previousZone;
    final localIsWardEditable = _isWardEditable;
    final localSelectedWard = _selectedWard;
    final localSelectedWardId = _selectedWardId;
    final localPreviousWard = _previousWard;
    final localSelectedAssignee = _selectedAssignee;
    final localPreviousAssignee = _previousAssignee;
    final localSelectedPriority = _selectedPriority;
    final localPreviousPriority = _previousPriority;
    final localPreviousComponentChanged = _previousComponentChanged;
    final localSelectedComponentChanged = _selectedComponentChanged;
    final localSelectedIssueIdentified = _selectedIssueIdentified;
    final localPreviousIssueIdentified = _previousIssueIdentified;
    final localPhoneText = _phoneController.text;
    final localPreviousComplaineePhoneNumber = _previousComplaineePhoneNumber;
    final localPreviousLocation = _previousLocation;
    final localAssigneesData = List<Map<String, String>>.from(_assigneesData);
    final localDuplicateOf = Map<String, String>.from(_duplicateOf);
    final localCommentsText = _commentsController.text;

    var fileName = localExistingAttachment;
    if (localPickedImageBytes != null) {
      fileName = const uuid.Uuid().v1();
      final compressedBytes =
          await activityCompressImage(localPickedImageBytes);

      final res = await s3Upload(compressedBytes, fileName);

      if (res != '200') {
        EasyLoading.showError("Image upload failed");
        return;
      }
    }

    // String datetime = getCurrentFormattedDateTime();

    bool isClosed = localSelectedStatus == 'Closed' ||
        localSelectedStatus == 'Verified-Closed' ||
        localSelectedStatus == 'Visited-Closed';

    Map<String, dynamic> updateData = {};
    if (localSelectedStatus != localPreviousStatus) {
      updateData['status'] = localSelectedStatus;
    }

    if (localIsDeviceTypeEditable &&
        localSelectedDeviceType != localPreviousDeviceType) {
      updateData['entity_type'] = localSelectedDeviceType;
    }
    if (localIsDeviceEditable) {
      if (localSelectedDeviceId.isNotEmpty) {
        updateData['entity_id'] = localSelectedDeviceId;
        updateData['entity_name'] = localSelectedDevice;
        if (localLatitude != 0.0) {
          updateData['latitude'] = localLatitude;
          updateData['user_latitude'] = localLatitude;
        }
        if (localLongitude != 0.0) {
          updateData['longitude'] = localLongitude;
          updateData['user_longitude'] = localLongitude;
        }
        if (localPanelId.isNotEmpty) updateData['panel_id'] = localPanelId;
        if (localMeterSerialNo.isNotEmpty) {
          updateData['meter_serial_no'] = localMeterSerialNo;
        }
        if (localSpNo.isNotEmpty) updateData['sp_no'] = localSpNo;
      } else {
        updateData['entity_name'] = localDeviceSearchQuery;
      }
    }

    if (localLocationText.isNotEmpty) {
      updateData['location'] = localLocationText;
      updateData['user_location'] = localLocationText;
    }

    if (localIsZoneEditable && localSelectedZone.isNotEmpty) {
      updateData['zone'] = localSelectedZone;
      if (localSelectedZoneId.isNotEmpty) {
        updateData['zone_id'] = localSelectedZoneId;
      }
    }
    if (localIsWardEditable && localSelectedWard.isNotEmpty) {
      updateData['ward'] = localSelectedWard;
      if (localSelectedWardId.isNotEmpty) {
        updateData['ward_id'] = localSelectedWardId;
      }
    }
    if (localSelectedAssignee != localPreviousAssignee) {
      updateData['assignee'] = localSelectedAssignee;
    }
    // if (_selectedComplainee != _previousComplainee) {
    //   updateData['complainee'] = _selectedComplainee;
    // }
    if (localSelectedPriority != localPreviousPriority) {
      updateData['priority'] = localSelectedPriority;
    }

    if (localPreviousComponentChanged == null &&
        localSelectedComponentChanged) {
      updateData['components_changed'] = true;
    } else if (localPreviousComponentChanged != null &&
        localSelectedComponentChanged != localPreviousComponentChanged) {
      updateData['components_changed'] = localSelectedComponentChanged;
    }
    if (localSelectedIssueIdentified != localPreviousIssueIdentified) {
      updateData['issue_identified'] = localSelectedIssueIdentified;
    }
    if (isClosed) {
      if (_previousComplainee == "Auto") {
        closeAutoTicketsService(_docId);
      }
      if (!['Closed', 'Verified-Closed', 'Visited-Closed']
          .contains(localPreviousStatus)) {
        // updateData['ticket_closed_on'] = datetime;
        updateData['ticket_closed_by'] = user;
        updateData['ticket_closed_by_mail_id'] = userEmail;
        updateData['ticket_closed_by_user_id'] = userId;
      }
    } else {
      // updateData['ticket_closed_on'] = "";
      updateData['ticket_closed_by'] = "";
      updateData['ticket_closed_by_mail_id'] = "";
      updateData['ticket_closed_by_user_id'] = "";
    }

    List<String> actionsPerformed = [];
    if (localSelectedZone != localPreviousZone) {
      actionsPerformed.add(
        localPreviousZone.isEmpty
            ? "Zone added : $localSelectedZone"
            : "Zone updated from $localPreviousZone to $localSelectedZone",
      );
    }
    if (localSelectedWard != localPreviousWard) {
      actionsPerformed.add(
        localPreviousWard.isEmpty
            ? 'Ward added : $localSelectedWard'
            : "Ward updated from $localPreviousWard to $localSelectedWard",
      );
    }
    if (localSelectedDeviceType != localPreviousDeviceType) {
      actionsPerformed.add(
        "Device Type updated to ${getEntityLabel(localSelectedDeviceType)}",
      );
    }
    if (localSelectedDeviceId != localPreviousDeviceId) {
      actionsPerformed.add(
        "Device updated to $localSelectedDevice",
      );
    } else {
      if (localDeviceSearchQuery != '' && localSelectedDeviceId.isEmpty) {
        actionsPerformed.add(
          "Device name updated to $localDeviceSearchQuery",
        );
      }
    }
    if (localPreviousLocation != localLocationText &&
        localSelectedDeviceId.isEmpty) {
      actionsPerformed.add(
        "Location updated to $localLocationText",
      );
    }

    if (localSelectedStatus != localPreviousStatus) {
      actionsPerformed.add(
        "Status changed from $localPreviousStatus to $localSelectedStatus",
      );
    }
    // if (_selectedComplainee != _previousComplainee) {
    //   actionsPerformed.add(
    //     "Complainee Updated : $_selectedComplainee",
    //   );
    // }
    if (localSelectedAssignee != localPreviousAssignee) {
      if (localPreviousAssignee == 'Unassigned') {
        actionsPerformed.add("Assigned to: $localSelectedAssignee");
      } else {
        actionsPerformed.add(
          "Assignee changed from $localPreviousAssignee to $localSelectedAssignee",
        );
      }

      if (localSelectedAssignee != "Unassigned") {
        final selectedMap = localAssigneesData.firstWhere(
          (e) => e['name'] == localSelectedAssignee,
          orElse: () => {},
        );
        if (selectedMap.isNotEmpty) {
          updateData["assignee"] = selectedMap['name'] ?? localSelectedAssignee;
          updateData["assignee_id"] = selectedMap['id'] ?? '';
          updateData["assignee_mail_id"] = selectedMap['email'] ?? '';
        }
      } else {
        updateData["assignee_id"] = "";
        updateData["assignee_mail_id"] = "";
      }
    }
    if (localSelectedPriority != localPreviousPriority) {
      actionsPerformed.add(
        "Priority changed from $localPreviousPriority to $localSelectedPriority",
      );
    }
    if (localPreviousComponentChanged == null &&
        localSelectedComponentChanged) {
      actionsPerformed.add(
        "Components Changed: Yes",
      );
    } else if (localPreviousComponentChanged != null &&
        localSelectedComponentChanged != localPreviousComponentChanged) {
      actionsPerformed.add(
        "Components Changed Toggled: ${localPreviousComponentChanged ? 'Yes' : 'No'} -> ${localSelectedComponentChanged ? 'Yes' : 'No'}",
      );
    }
    if (localSelectedIssueIdentified != localPreviousIssueIdentified) {
      if (localPreviousIssueIdentified == '') {
        actionsPerformed
            .add("Issues Identified: $localSelectedIssueIdentified");
      } else {
        actionsPerformed.add(
          "Issues identified changed from $localPreviousIssueIdentified to $localSelectedIssueIdentified",
        );
      }
    }
    if (localPhoneText != localPreviousComplaineePhoneNumber) {
      updateData["complainee_contact_no"] = localPhoneText;
      actionsPerformed.add("Complainer Contact Number updated");
    }

    // if (_selectedComponentChanged &&
    //     ['Gateway', 'ILM', 'Lamp', 'Meter']
    //         .contains(_selectedIssueIdentified)) {
    //   if (_replacedEntityNameController.text != _previousReplacedEntityName) {
    //     updateData['replaced_entity_name'] = _replacedEntityNameController.text;
    //     if (_previousReplacedEntityName.isEmpty) {
    //       actionsPerformed.add(
    //         "Replaced $_selectedIssueIdentified Name updated to ${_replacedEntityNameController.text}",
    //       );
    //     } else if (_replacedEntityNameController.text.isEmpty) {
    //       actionsPerformed.add(
    //         "Replaced $_selectedIssueIdentified Name cleared",
    //       );
    //     } else {
    //       actionsPerformed.add(
    //         "Replaced $_selectedIssueIdentified Name updated from $_previousReplacedEntityName to ${_replacedEntityNameController.text}",
    //       );
    //     }
    //   }
    // } else {
    //   if (_previousReplacedEntityName.isNotEmpty) {
    //     updateData['replaced_entity_name'] = '';
    //     actionsPerformed.add(
    //       "Replaced Entity Name cleared (Criteria not met)",
    //     );
    //   }
    // }
    if (actionsPerformed.isEmpty && localPickedImageBytes != null) {
      actionsPerformed.add("Attachment added");
    }
    var targetDuplicateOf = Map<String, String>.from(localDuplicateOf);
    if (localSelectedStatus == "Verified-Duplicate" &&
        targetDuplicateOf.isNotEmpty) {
      DocumentSnapshot<Map<String, dynamic>> selectedParentTicket =
          await FirebaseServices.ticketsFirestore
              .collection(ticketCollectionName)
              .doc(targetDuplicateOf['doc_id'])
              .get();

      if (selectedParentTicket.exists && selectedParentTicket.data() != null) {
        Map<String, dynamic> selectedParentData = selectedParentTicket.data()!;

        if (selectedParentData["duplicated_to"] != null &&
            selectedParentData["duplicated_to_id"] != null) {
          targetDuplicateOf['ticket_id'] = selectedParentData["duplicated_to"];
          targetDuplicateOf['doc_id'] = selectedParentData["duplicated_to_id"];
        }
      }

      actionsPerformed.add("Duplicated to: ${targetDuplicateOf['ticket_id']}");

      updateData['duplicated_to'] = targetDuplicateOf['ticket_id'];
      updateData['duplicated_to_id'] = targetDuplicateOf['doc_id'];
    } else {
      targetDuplicateOf = {};
    }

    updateData['comments'] = localCommentsText;

    Map<String, dynamic> auditEntry = {
      "actions": actionsPerformed,
      "by": user,
      "mail_id": userEmail,
      "user_id": userId,
      // "on": datetime,
      "comment": localCommentsText,
      "attachment": localPickedImageBytes != null ? fileName : "",
    };
    // updateData["audit_trail"] = FieldValue.arrayUnion([auditEntry]);
    updateData["audit_trail"] = auditEntry;

    try {
      int res = await updateTicketInFirestore(localDocId, updateData);
      if (res != 1) {
        EasyLoading.showError("Failed to update ticket");
      }

      if (!_isMinimised && context.mounted) {
        if (res == 1) {
          clearData();
          EasyLoading.showSuccess("Ticket Updated");
          Navigator.pop(context);
        }
      }
    } catch (e) {
      log("Error updating ticket: $e");
      EasyLoading.showError("Failed to update ticket");
    }
  }

  void clearData() {
    _ticketId = '';
    _selectedCustomer = '';
    _selectedCustomerId = '';
    _selectedRegion = '';
    _selectedRegionId = '';
    _selectedZone = '';
    _selectedZoneId = '';
    _selectedWard = '';
    _selectedWardId = '';
    _selectedDeviceType = '';
    _selectedDevice = '';
    _selectedDeviceId = '';
    _selectedPriority = '';
    _selectedProblemType = '';
    _selectedStatus = '';
    _selectedAssignee = '';
    // _selectedComplainee = '';
    _selectedComponentChanged = false;
    _selectedIssueIdentified = '';
    _deviceAssetId = '';
    _complaineePhoneNumber = '';
    _comments = '';
    _entityType = '';
    _existingAttachment = '';
    _latitude = 0.0;
    _longitude = 0.0;
    _panelId = '';
    _meterSerialNo = '';
    _spNo = '';

    _locationController.clear();
    _phoneController.clear();
    _commentsController.clear();
    _replacedEntityNameController.clear();
    _deviceSearchQuery = '';

    _previousComplaineePhoneNumber = '';
    _previousReplacedEntityName = '';

    _previousTicketOpenedOn = '';

    _pickedImageBytes = null;
    _duplicateOf = {};
    _isMinimised = false;
    notifyListeners();
  }

  List<String> get issueIdentifiedList {
    final probIssueBox = Hive.box('problemTypesAndIssuesIdentified');

    return List<String>.from(
      probIssueBox.get('issues_identified')[_selectedDeviceType] ?? [],
    );
  }

  bool get isComponentChangeEnabled {
    if (_selectedIssueIdentified.isEmpty) return false;

    final probIssueBox = Hive.box('problemTypesAndIssuesIdentified');
    final List nonComponents =
        probIssueBox.get('issues_identified')['non_components'] ?? [];

    return !nonComponents.contains(_selectedIssueIdentified);
  }

  // List<String> get issueIdentifiedList {
  //   switch (_selectedDeviceType) {
  //     case 'slc':
  //       return [
  //         "SMPS",
  //         "Gateway",
  //         "Meter",
  //         "Wire",
  //         "Energy Meter",
  //         "AC Timer",
  //         "MCB",
  //         "MCB Resetter",
  //         "3-Way switch",
  //         "Load break switch",
  //         "Connector",
  //         "Door Magnet",
  //         "SIM",
  //         "Antenna",
  //         "Input Power Issue",
  //         "Circuit or Jumper Fault",
  //         "Device Reset",
  //         "Cable Damaged",
  //         "Input Fuse",
  //         "SPD ",
  //         "Line filter ",
  //         "Contactor ",
  //         "No Issue",
  //         "I dont know",
  //       ];
  //     case 'lamp':
  //       return [
  //         'Lamp',
  //         'Wire',
  //         'SPD',
  //         'Input Power Issue',
  //         'Circuit or Jumper Fault',
  //         'Cable Damaged',
  //         'No Issue',
  //       ];
  //     case 'gw':
  //       return [
  //         "Gateway",
  //         "SIM",
  //         "Antenna",
  //         "Wire",
  //         "Device Reset",
  //         "Input Power Issue",
  //         "Circuit or Jumper Fault",
  //         "No Issue",
  //         "I dont know",
  //       ];
  //     case 'ilm':
  //       return [
  //         'ILM',
  //         'Wire',
  //         'Device Reset',
  //         'Input Power Issue',
  //         'Circuit or Jumper Fault',
  //         'No Issue',
  //         'I dont know',
  //       ];
  //     case 'pole':
  //       return ['Pole', 'No Issue', 'I dont know'];
  //     case 'others':
  //       return ['Others'];
  //     default:
  //       return [];
  //   }
  // }

  Future<void> fetchAssignees() async {
    if (_selectedRegionId.isEmpty && _selectedCustomerId.isEmpty) {
      _assigneesData = [];
      notifyListeners();
      return;
    }

    final cacheKey = _selectedRegionId.isNotEmpty
        ? 'region_$_selectedRegionId'
        : 'customer_$_selectedCustomerId';

    final assigneeBox = Hive.box('assignee_cache');

    if (assigneeBox.containsKey(cacheKey)) {
      final cachedData = assigneeBox.get(cacheKey);
      if (cachedData is List) {
        _assigneesData = List<Map<String, String>>.from(
          cachedData.map((e) => Map<String, String>.from(e)),
        );
        notifyListeners();
      }
      _isLoadingAssignees = false;
    } else {
      _isLoadingAssignees = true;
      notifyListeners();
    }

    try {
      final freshData = await fetchAssigneesByRegionService(_selectedRegionId);

      if (freshData.isNotEmpty) {
        await assigneeBox.put(cacheKey, freshData);
        _assigneesData = freshData;
        notifyListeners();
      }
    } catch (e) {
      log('Error fetching assignees: $e');
      if (_assigneesData.isEmpty) {
        _assigneesData = [];
      }
    }
    _isLoadingAssignees = false;
    notifyListeners();
  }

  String get ticketId => _docId;
  String get selectedCustomer => _selectedCustomer;
  String get selectedCustomerId => _selectedCustomerId;
  String get selectedRegion => _selectedRegion;
  String get selectedRegionId => _selectedRegionId;
  String get selectedZone => _selectedZone;
  String get selectedZoneId => _selectedZoneId;
  String get selectedWard => _selectedWard;
  String get selectedWardId => _selectedWardId;
  String get selectedDeviceType => _selectedDeviceType;
  String get selectedDevice => _selectedDevice;
  String get selectedDeviceId => _selectedDeviceId;
  String get selectedPriority => _selectedPriority;
  String get selectedProblemType => _selectedProblemType;
  String get selectedStatus => _selectedStatus;
  String get selectedAssignee => _selectedAssignee;
  String get previousDuplicatedTo => _previousDuplicatedTo;
  String get duplicateOf => _duplicateOf['ticket_id'] ?? '';
  // String get selectedComplainee => _selectedComplainee;
  String get previousComplainee => _previousComplainee;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get panelId => _panelId;
  String get meterSerialNo => _meterSerialNo;
  String get spNo => _spNo;
  bool get selectedComponentChanged => _selectedComponentChanged;
  String get selectedIssueIdentified => _selectedIssueIdentified;
  String get deviceAssetId => _deviceAssetId;
  String get complaineePhoneNumber => _complaineePhoneNumber;
  String get previousComplaineePhoneNumber => _previousComplaineePhoneNumber;
  String get previousLocation => _previousLocation;
  String get comments => _comments;
  TextEditingController get phoneController => _phoneController;
  TextEditingController get locationController => _locationController;
  TextEditingController get commentsController => _commentsController;
  TextEditingController get replacedEntityNameController =>
      _replacedEntityNameController;
  Uint8List? get pickedImageBytes => _pickedImageBytes;
  List<String> get statusList => _statusList;

  bool _isLoadingAssignees = false;
  bool get isLoadingAssignees => _isLoadingAssignees;
  bool get isMinimised => _isMinimised;

  // bool get shouldShowReplacedNameField =>
  //     _selectedComponentChanged &&
  //     ['Gateway', 'ILM', 'Lamp', 'Meter'].contains(_selectedIssueIdentified);
}
