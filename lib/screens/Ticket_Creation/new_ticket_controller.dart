import 'dart:developer';

import 'package:citizen_complaints_list_web/s3_bucket/s3_controller.dart';
import 'package:citizen_complaints_list_web/screens/Ticket_Creation/new_ticket_service.dart';

import 'package:citizen_complaints_list_web/firestore_controller.dart';
import 'package:citizen_complaints_list_web/screens/Tickets_List/tickets_list_controller.dart';
import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart' as uuid;
import 'package:citizen_complaints_list_web/screens/Tickets_List/project_context_controller.dart';

final newTicketController = ChangeNotifierProvider<NewTicketProvider>((ref) {
  final userContext = ref.watch(userContextController);
  return NewTicketProvider(
      customer: userContext.selectedCustomer,
      customerId: userContext.selectedCustomerId);
});

class NewTicketProvider extends ChangeNotifier {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  Uint8List? _pickedImageBytes;

  final String customer;
  final String customerId;
  late String _customer;
  late String _customerId;

  NewTicketProvider({required this.customer, required this.customerId}) {
    _customer = customer;
    _customerId = customerId;
  }

  Map<String, dynamic>? _userContextCache;
  bool _isInit = false;
  bool _isMinimised = false;

  Future<void> init() async {
    if (_isInit) return;
    _isInit = true;
    final box = await Hive.openBox('project_context');
    if (!Hive.isBoxOpen('assignee_cache')) {
      await Hive.openBox('assignee_cache');
    }
    if (box.containsKey(userEmail)) {
      final data = box.get(userEmail);
      if (data is Map) {
        _userContextCache = Map<String, dynamic>.from(data);
      }
    }
  }

  List<String> priorityList = [
    'Critical',
    'Major',
    'Minor',
    'Warning',
    // 'Indeterminate',
  ];

  List<String> statusList = ['Open', 'Assigned'];

  List<Map<String, String>> _assigneesData = [];
  List<String> get assigneeList {
    if (_assigneesData.isEmpty) return ['Unassigned'];
    final options = _assigneesData.map((e) {
      return e['name']!;
    }).toList();
    return ['Unassigned', ...options];
  }

  List<Map<String, String>> _deviceOptions = [];

  String _selectedRegion = '';
  String _selectedRegionId = '';
  String _selectedZone = '';
  String _selectedZoneId = '';
  String _selectedWard = '';
  String _selectedWardId = '';
  String _selectedLatestContextId = '';
  String _selectedDeviceType = '';
  List<String> _selectedDeviceTypes = [];
  String _entityType = '';
  String _selectedDevice = '';
  String _selectedDeviceId = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _panelId = '';
  String _meterSerialNo = '';
  String _spNo = '';
  String _selectedPriority = 'Minor';
  String _selectedProblemType = '';
  String _selectedStatus = 'Open';
  String _selectedAssignee = 'Unassigned';
  String _selectedComplainee = 'O&M (CMS)';
  String _complaineePhoneNumber = '';
  String _comments = '';

  bool _isLoadingAssignees = false;
  bool _isLoadingDevices = false;

  bool get isLoadingAssignees => _isLoadingAssignees;
  bool get isLoadingDevices => _isLoadingDevices;

  dynamic _latestContextData;

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

  void createTicket(BuildContext context) async {
    final localPickedImageBytes = _pickedImageBytes;
    final localCustomer = _customer;
    final localCustomerId = _customerId;
    final localSelectedRegion = _selectedRegion;
    final localSelectedRegionId = _selectedRegionId;
    final localSelectedZone = _selectedZone;
    final localSelectedZoneId = _selectedZoneId;
    final localSelectedWard = _selectedWard;
    final localSelectedWardId = _selectedWardId;
    final localSelectedDeviceType = _selectedDeviceType;
    final localSelectedDevice = _selectedDevice;
    final localSelectedDeviceId = _selectedDeviceId;
    final localDeviceSearchQuery = _deviceSearchQuery;
    final localLocationText = _locationController.text;
    final localLatitude = _latitude;
    final localLongitude = _longitude;
    final localPanelId = _panelId;
    final localMeterSerialNo = _meterSerialNo;
    final localSpNo = _spNo;
    final localSelectedProblemType = _selectedProblemType;
    final localSelectedComplainee = _selectedComplainee;
    final localPhoneText = _phoneController.text;
    final localCommentsText = _commentsController.text;
    final localSelectedAssignee = _selectedAssignee;
    final localSelectedPriority = _selectedPriority;
    final localAssigneesData = List<Map<String, String>>.from(_assigneesData);

    var localSelectedStatus = _selectedStatus;

    var fileName = "";
    if (localPickedImageBytes != null) {
      fileName = const uuid.Uuid().v1();
      final compressedBytes =
          await activityCompressImage(localPickedImageBytes);

      log(fileName);

      final res = await s3Upload(compressedBytes, fileName);

      if (res != '200') {
        fileName = "";
        EasyLoading.showError("Image upload failed");
        return;
      }
    }

    // String datetime = getCurrentFormattedDateTime();

    List<String> actionsPerformed = ['Opened'];
    if (localSelectedAssignee != "Unassigned") {
      actionsPerformed.add("Assigned to $localSelectedAssignee");
    } else {
      localSelectedStatus = "Open";
    }

    String assigneeId = '';
    String assigneeEmail = '';
    String assigneeName = localSelectedAssignee;

    if (localSelectedAssignee != "Unassigned") {
      final selectedMap = localAssigneesData.firstWhere(
        (e) => e['name'] == localSelectedAssignee,
        orElse: () => {},
      );
      if (selectedMap.isNotEmpty) {
        assigneeId = selectedMap['id'] ?? '';
        assigneeEmail = selectedMap['email'] ?? '';
        assigneeName = selectedMap['name'] ?? localSelectedAssignee;
      }
    }

    var entityName = localSelectedDevice;
    var entityId = localSelectedDeviceId;
    var loc = localLocationText;
    var lat = localLatitude;
    var lng = localLongitude;
    var panelId = localPanelId;
    var meterSerialNo = localMeterSerialNo;
    var spNo = localSpNo;
    if (localSelectedDevice != localDeviceSearchQuery &&
        localDeviceSearchQuery.isNotEmpty) {
      entityName = localDeviceSearchQuery;
      entityId = "";
      loc = "";
      lat = 0.0;
      lng = 0.0;
      panelId = '';
      meterSerialNo = '';
      spNo = '';
    }

    Map<String, dynamic> ticketData = {
      "customer_id": localCustomerId,
      "customer": localCustomer,
      "region": localSelectedRegion,
      "user_region": localSelectedRegion,
      "region_id": localSelectedRegionId,
      "zone": localSelectedZone,
      "zone_id": localSelectedZoneId,
      "ward": localSelectedWard,
      "ward_id": localSelectedWardId,
      "entity_type": localSelectedDeviceType,
      "entity_name": entityName,
      "entity_id": entityId,
      "meter_serial_no": meterSerialNo,
      "panel_id": panelId,
      "sp_no": spNo,
      "location": loc,
      "user_location": loc,
      "latitude": lat,
      "user_latitude": lat,
      "longitude": lng,
      "user_longitude": lng,
      "problem_type": localSelectedProblemType,
      "complainee": localSelectedComplainee,
      "complainee_contact_no": localPhoneText,
      "comments": localCommentsText,
      // "ticket_opened_on": datetime,
      "ticket_opened_by": user,
      "ticket_opened_by_mail_id": userEmail,
      "ticket_opened_by_user_id": userId,
      "assignee": assigneeName,
      "assignee_id": assigneeId,
      "assignee_mail_id": assigneeEmail,
      "status": localSelectedStatus,
      "priority": localSelectedPriority,
      "audit_trail": [
        {
          "actions": actionsPerformed,
          "by": user,
          "mail_id": userEmail,
          "user_id": userId,
          // "on": datetime,
          "comment": localCommentsText,
          "attachment": fileName,
        },
      ],
    };

    log(ticketData.toString());

    // var res = await addTicketToFireStore(ticketData, _selectedRegion);

    var res = await addTicketToFireStore(ticketData);
    // final status = res['status'];
    if (res['status'] == "failed") {
      EasyLoading.showError("Failed to create ticket");
      return;
    }
    // var msgData = {};
    // if (_phoneController.text.length == 10) {
    //   msgData = {
    //     "contact_number": "91${_phoneController.text}",
    //     "latitude": _latitude,
    //     "longitude": _longitude,
    //     "location":
    //         _locationController.text.isEmpty ? "N/A" : _locationController.text,
    //     "status": "Opened",
    //     "time": datetime,
    //     "problem_type": _selectedProblemType,
    //     "device": _selectedDevice.isEmpty ? "N/A" : _selectedDevice,
    //     "ward": _selectedWard.isEmpty ? "N/A" : _selectedWard,
    //     "customer": _customer
    //   };
    // }

    if (!_isMinimised && context.mounted) {
      clearData();
      Navigator.pop(context);

      EasyLoading.dismiss();
      final ticketId = res['ticketId'];

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              backgroundColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.all(0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    width: double.infinity,
                    child: Lottie.asset(
                      'assets/animation/tick.json',
                      height: 150,
                      width: 150,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Success',
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Ticket Created Successfully!\nTicket ID : $ticketId",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "OK",
                        style: TextStyle(color: Theme.of(context).cardColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    // if (msgData.isNotEmpty) {
    //   sendConfirmationWhatsAppMsg(data: msgData, ticketId: ticketId);
    // }
  }

  Future<void> valueUpdate(String which, value) async {
    if (_userContextCache == null) {
      await init();
    }
    final box = Hive.box('project_context');
    final userContext = _userContextCache ?? box.get(userEmail);
    if (userContext == null || userContext[_customer] == null) return;
    final data = userContext[_customer];

    if (which == 'region') {
      if (value != _selectedRegion) {
        _selectedRegion = value;
        _latestContextData = data['regions'][value];
        _selectedRegionId = _latestContextData['region_id'] ?? '';
        _selectedLatestContextId = _selectedRegionId;
      }
      if (_selectedDeviceId != '') {
        _locationController.clear();
      }
      _selectedZone = '';
      _selectedZoneId = '';
      _selectedWard = '';
      _selectedWardId = '';
      _selectedDevice = '';
      _selectedDeviceId = '';
      _latitude = 0.0;
      _longitude = 0.0;
      _panelId = '';
      _meterSerialNo = '';
      _spNo = '';
      _deviceSearchQuery = '';
      if (_selectedDeviceType.isNotEmpty) {
        fetchDevices();
      }
    } else if (which == 'zone') {
      if (value != _selectedZone) {
        _latestContextData =
            data['regions']?[_selectedRegion]?['zones']?[value];
        _selectedZone = value;
        _selectedZoneId = _latestContextData?['zone_id'] ?? '';
        _selectedLatestContextId = _selectedZoneId.isNotEmpty
            ? _selectedZoneId
            : _selectedRegionId; // Fallback? Or keep empty?
        if (_selectedDeviceId != '') {
          _locationController.clear();
        }
        _selectedWard = '';
        _selectedWardId = '';
        _selectedDevice = '';
        _selectedDeviceId = '';
        _latitude = 0.0;
        _longitude = 0.0;
        _panelId = '';
        _meterSerialNo = '';
        _spNo = '';
        _deviceSearchQuery = '';

        if (!deviceTypeList.contains(_selectedDeviceType)) {
          _selectedDeviceType = '';
          _selectedDeviceTypes = [];
          _entityType = '';
          _selectedProblemType = '';
        }
        if (_selectedDeviceType.isNotEmpty) {
          fetchDevices();
        }
      }
      _selectedWard = '';
      _selectedWardId = '';
    } else if (which == 'ward') {
      if (value != _selectedWard) {
        _selectedWard = value;
        _latestContextData = data['regions']?[_selectedRegion]?['zones']
            ?[_selectedZone]?['wards']?[value];
        _selectedWardId = _latestContextData?['ward_id'] ?? '';
        _selectedLatestContextId =
            _selectedWardId.isNotEmpty ? _selectedWardId : _selectedZoneId;
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
        _deviceSearchQuery = '';

        if (!deviceTypeList.contains(_selectedDeviceType)) {
          _selectedDeviceType = '';
          _selectedDeviceTypes = [];
          _entityType = '';
          _selectedProblemType = '';
        }
        if (_selectedDeviceType.isNotEmpty) {
          fetchDevices();
        }
      }
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
        _deviceSearchQuery = '';
        if (!problemTypeList.contains(_selectedProblemType)) {
          _selectedProblemType = '';
        }
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
          log("${details}logg");
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
    } else if (which == 'priority') {
      if (value != _selectedPriority) {
        _selectedPriority = value;
      }
    } else if (which == 'problemType') {
      if (value != _selectedProblemType) {
        _selectedProblemType = value;
      }
    } else if (which == 'status') {
      if (value != _selectedStatus) {
        if (value == 'Open') {
          _selectedAssignee = "Unassigned";
        }
        _selectedStatus = value;
      }
    } else if (which == 'assignee') {
      if (value != _selectedAssignee) {
        if (value != "Unassigned") {
          _selectedStatus = "Assigned";
        } else {
          _selectedStatus = "Open";
        }
        _selectedAssignee = value;
      }
    } else if (which == 'complainee') {
      if (value != _selectedComplainee) {
        _selectedComplainee = value;
      }
    } else if (which == 'phone') {
      if (value != _complaineePhoneNumber) {
        _complaineePhoneNumber = value;
      }
    } else if (which == 'comments') {
      if (value != _comments) {
        _comments = value;
      }
    } else if (which == 'minimize') {
      _isMinimised = value;
    }

    notifyListeners();
  }

  Future<void> prePopulateContext({
    required String region,
    required String zone,
    required String ward,
  }) async {
    if (region.isNotEmpty) {
      await valueUpdate('region', region);
      if (zone.isNotEmpty) {
        await valueUpdate('zone', zone);
        if (ward.isNotEmpty) {
          await valueUpdate('ward', ward);
        }
      }
    }
  }

  bool get canCreateTicket {
    return _selectedRegion.isNotEmpty &&
        _selectedProblemType.isNotEmpty &&
        (_selectedProblemType != 'Others' || _comments.isNotEmpty) &&
        (_selectedStatus != 'Assigned' || _selectedAssignee != 'Unassigned') &&
        (_phoneController.text.isEmpty || _phoneController.text.length == 10);
  }

  void clearData() {
    _selectedRegion = '';
    _selectedRegionId = '';
    _selectedZone = '';
    _selectedZoneId = '';
    _selectedWard = '';
    _selectedWardId = '';
    _selectedLatestContextId = '';
    _selectedDeviceType = '';
    _selectedDeviceTypes = [];
    _entityType = '';
    _selectedDevice = '';
    _selectedDeviceId = '';
    _selectedPriority = 'Minor';
    _selectedStatus = 'Open';
    _selectedAssignee = 'Unassigned';
    _selectedProblemType = '';
    _selectedComplainee = 'O&M (CMS)';
    _complaineePhoneNumber = '';
    _latitude = 0.0;
    _longitude = 0.0;
    _panelId = '';
    _meterSerialNo = '';
    _spNo = '';
    _locationController.clear();
    _comments = '';
    _pickedImageBytes = null;
    _phoneController.clear();
    _commentsController.clear();

    _assigneesData = [];
    _latestContextData = null;
    _isMinimised = false;
    notifyListeners();
  }

  List<String> get regionList {
    try {
      final box = Hive.box('project_context');
      final userContext = _userContextCache ?? box.get(userEmail);
      final data = userContext?[_customer];
      if (data != null && data['regions'] != null) {
        return (data['regions'] as Map).keys.cast<String>().toList()..sort();
      }
    } catch (e) {
      log('Error getting region list: $e');
    }
    return [];
  }

  List<String> get zoneList {
    if (_selectedRegion.isEmpty) return [];
    try {
      final box = Hive.box('project_context');
      final userContext = _userContextCache ?? box.get(userEmail);
      final data = userContext?[_customer];
      if (data != null &&
          data['regions'] != null &&
          data['regions'][_selectedRegion] != null &&
          data['regions'][_selectedRegion]['zones'] != null) {
        return (data['regions'][_selectedRegion]['zones'] as Map)
            .keys
            .cast<String>()
            .toList()
          ..sort();
      }
    } catch (e) {
      log('Error getting zone list: $e');
    }
    return [];
  }

  List<String> get wardList {
    if (_selectedRegion.isEmpty || _selectedZone.isEmpty) return [];
    try {
      final box = Hive.box('project_context');
      final userContext = _userContextCache ?? box.get(userEmail);
      final data = userContext?[_customer];
      if (data != null &&
          data['regions'] != null &&
          data['regions'][_selectedRegion] != null &&
          data['regions'][_selectedRegion]['zones'] != null &&
          data['regions'][_selectedRegion]['zones'][_selectedZone] != null &&
          data['regions'][_selectedRegion]['zones'][_selectedZone]['wards'] !=
              null) {
        return (data['regions'][_selectedRegion]['zones'][_selectedZone]
                ['wards'] as Map)
            .keys
            .cast<String>()
            .toList()
          ..sort();
      }
    } catch (e) {
      log('Error getting ward list: $e');
    }
    return [];
  }

  List<String> get problemTypeList {
    final probIssueBox = Hive.box('problemTypesAndIssuesIdentified');

    if (_selectedDeviceType.isEmpty) {
      List<String> generalProblemTypes = List<String>.from(
        probIssueBox.get('problem_types')['general'] ?? [],
      );

      // log(probIssueBox.get('problem_types')['general'].toString() + "dsdsfdsf");

      return generalProblemTypes;
      // return generalProblemTypes;
    }
    // var entry = entityList[_selectedDeviceType];
    return List<String>.from(
      probIssueBox.get('problem_types')[_selectedDeviceType] ?? [],
    );
  }

  List<String> get devicesList {
    if (_selectedDeviceType.isEmpty) return [];

    var devices = _deviceOptions.map((e) => e['value']!).toList()..sort();
    // if (devices.isEmpty) {
    //   _latitude = 0.0;
    //   _longitude = 0.0;
    //   _locationController.clear();
    //   notifyListeners();
    // }
    return devices;
  }

  String _deviceSearchQuery = '';
  int _fetchDevicesVersion = 0;

  Future<void> fetchDevices([String? query]) async {
    if (query != null) {
      _deviceSearchQuery = query;
    }

    // Derive context from most specific available ID.
    // _selectedLatestContextId can become stale after device selection updates
    // region/zone/ward via non-awaited calls with wrong _latestContextData.
    final String contextId = _selectedWardId.isNotEmpty
        ? _selectedWardId
        : _selectedZoneId.isNotEmpty
            ? _selectedZoneId
            : _selectedRegionId.isNotEmpty
                ? _selectedRegionId
                : _selectedLatestContextId;

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

  Future<void> fetchAssignees() async {
    final cacheKey = _selectedRegionId.isNotEmpty
        ? 'region_$_selectedRegionId'
        : 'customer_$_customerId';

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

  String get selectedRegion => _selectedRegion;
  String get selectedRegionId => _selectedRegionId;
  String get selectedZone => _selectedZone;
  String get selectedZoneId => _selectedZoneId;
  String get selectedWard => _selectedWard;
  String get selectedWardId => _selectedWardId;
  String get selectedDeviceType => _selectedDeviceType;
  String get selectedDevice => _selectedDevice;
  String get selectedDeviceId => _selectedDeviceId;
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get panelId => _panelId;
  String get meterSerialNo => _meterSerialNo;
  String get spNo => _spNo;
  String get selectedPriority => _selectedPriority;
  String get selectedProblemType => _selectedProblemType;
  String get selectedStatus => _selectedStatus;
  String get selectedAssignee => _selectedAssignee;
  String get selectedComplainee => _selectedComplainee;
  String get complaineePhoneNumber => _complaineePhoneNumber;
  String get comments => _comments;
  TextEditingController get phoneController => _phoneController;
  TextEditingController get locationController => _locationController;
  TextEditingController get commentsController => _commentsController;
  Uint8List? get pickedImageBytes => _pickedImageBytes;
  bool get isMinimised => _isMinimised;
}
