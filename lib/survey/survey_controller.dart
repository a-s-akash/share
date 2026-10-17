import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_internet_signal/flutter_internet_signal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as appsettings;
import 'package:schnell_luminator/pole_install.dart/pole_installtion_history.dart';
import 'package:schnell_luminator/survey/background_sync_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:carrier_info/carrier_info.dart';
import 'package:permission_handler/permission_handler.dart';
import '../device_page/device_controller.dart';
import '../location_selection/location_service.dart';
import '../login_page/login_controller.dart';
import '../s3_bucket/s3_config.dart';
import '../utils/constants.dart';
import '../utils/dialog_box.dart';
import '../utils/dropdown_options.dart';
import '../utils/image_compression_util.dart';
import '../utils/utility.dart';
import 'background_connectivity_monitoring.dart';
import 'connectivity_sync_service.dart';
import 'models/pole_survey_model.dart';
import 'models/sp_survey_model.dart';
import 'models/survey_image_model.dart';
import 'models/transformer_model.dart';
import 'survey_service.dart';
import 'package:http/http.dart' as http;

final surveyController =
    ChangeNotifierProvider<SurveyProvider>((ref) => SurveyProvider());

final hiveSyncProvider = StateProvider<int>((ref) => 0);

class SurveyProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  late PoleSurveyModel _surveyDetails;
  late SpSurveyModel _spSurveyDetails;
  late TransformerSurveyModel _transSurveyDetails;
  late MultiCapturedImageModel _imageDetails;
  bool _isButtonEnabled = true;
  String _wardNumberForPolePrefix = '';
  final TextEditingController _clampTypeLengthController =
      TextEditingController();
  final TextEditingController _clampTypeWidthController =
      TextEditingController();
  final TextEditingController _goodArmTextController =
      TextEditingController(text: '0');
  final TextEditingController _badArmTextController =
      TextEditingController(text: '0');
  final TextEditingController _missingArmTextController =
      TextEditingController(text: '1');
  final TextEditingController _workingTextController =
      TextEditingController(text: '0');
  final TextEditingController _notWorkingTextController =
      TextEditingController(text: '0');
  final TextEditingController _missingTextController =
      TextEditingController(text: '1');
  final TextEditingController _poleNumberController = TextEditingController();
  final TextEditingController _exCorpPoleNoController = TextEditingController();
  final TextEditingController _ebPoleNoController = TextEditingController();
  final TextEditingController _switchPointController = TextEditingController();
  final TextEditingController _switchPointNumberController =
      TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _surveyManualLocationEntry =
      TextEditingController();

  final TextEditingController _rrNumberController = TextEditingController();
  final TextEditingController _spMeterNoController = TextEditingController();
  final TextEditingController _spMakeController =
      TextEditingController(text: 'L&T');
  final TextEditingController _spConnectedLoadController =
      TextEditingController();
  final TextEditingController _switchPointIdController =
      TextEditingController();

  final TextEditingController _transNoController = TextEditingController();
  final TextEditingController _transCapacityController =
      TextEditingController();

  bool _isSurveyLocationFetched = false;
  String _clickEventIsFor = '';
  bool _isResurvey = false;
  String _fetchedLat = '';
  String _fetchedLong = '';
  String _fetchedAcc = '';
  String _fetchedAltitude = '';
  String _fetchedLandMark = '';
  String _selectedTrafficDensity = 'High';
  String _selectedTrafficSpeed = 'Slow Moving';
  String _selectedPoleNumber = '';
  String _selectedSwitchPointNo = '';
  bool _isSwitchPointFromDropdown = false;
  List<String> _customSwitchPointNo =
      []; // for switch point association with panel
  List<String> _multiSwitchPointNo =
      []; // for switch point association with panel
  bool _isSpEarthingAvailable = true; // for switch point association screen
  String _spEarthingReason = ''; // for switch point association screen
  String _selectedEscomPoleNumber = '';
  String _selectedRoadType = 'Main Road';
  String _selectedAssetType = 'Switch Point';
  String _selectedPoleType = 'RCC';
  String _selectedPoleHeight = '7 m';
  String _selectedPoleSpan = '';
  String _selectedPoleCondition = 'Good';
  String _selectedConnectionType = 'Connection Type';
  String _selectedArmCount = '1';
  String _selectedArmCondition = 'Good';
  String _selectedArmLength = 'Normal';
  // bool _isClampRequired = true;
  bool _isEarthingRequired = true;
  bool _isBracketRequired = true;
  bool _isControlWireStatus = true;
  String _selectedManualSwitchCtrl = 'Exists - Good Condition';
  String _selectedWorkingCount = '0';
  String _selectedNotWorkingCount = '0';
  String _selectedMissingCount = '1';
  String _selectedGoodArmCount = '0';
  String _selectedBadArmCount = '0';
  String _selectedMissingArmCount = '1';
  String _selectedLampType = 'Tube light';
  String _selectedLampWatts = '40 W';
  List<Map<String, String>> _selectedLamps = [
    {'type': 'Tube light', 'watts': '40 W'}
  ];
  String _selectedComments = '';
  String _selectedManualEnteredLocation = '';
  String _selectedRoadCategory = 'A1';
  String _selectedRoadWidth = 'above 9m';
  String _selectedVehicleAccess = 'Long Truck';
  String _selectedIncomingTransLine = 'Under Ground';
  String _selectedIncomingTransType = 'Dedicated for Streetlight';
  String _selectedBracketMountingHeight = '6 m';
  String _selectedCustomBracketHeight = '';
  String _selectedClampType = '6 x 3 inch';
  String _selectedClampLength = '';
  String _selectedClampWidth = '';
  String _selectedClampUnits = 'inch';
  String _selectedPoleRatingUnits = 'hp';
  String _selectedPoleWinchCondition = 'Good';
  String _selectedPoleRopeCondition = 'Working';
  String _selectedPoleMotorCondition = 'Good';
  final TextEditingController _poleMotorMakeController =
      TextEditingController();
  final TextEditingController _poleMotorModelController =
      TextEditingController();
  final TextEditingController _poleMotorRatingController =
      TextEditingController();
  final TextEditingController _poleTransformerNoController =
      TextEditingController();
  final TextEditingController _spTransformerNoController =
      TextEditingController();
  String _selectedSwitchPointType = 'Feeder Pillar';
  String _selectedSPMeter = 'Working';
  String _selectedSpEarthingCondition = 'Good';
  String _selectedSpCondition = 'Working';
  String _selectedSpMeterType = 'Digital';
  String _selectedSpMake = 'L&T';
  String _selectedSpPhase = '1';
  String _selectedSpNumber = '';
  String _selectedSpRrNo = '';
  String _selectedSpId = '';
  String _selectedSpConnectedLoad = '';
  String _selectedSpMeterNo = '';
  String _carrierName = '';
  int _signalStrengthLevel = 0;
  bool _hasInternet = false;
  String _surveyPolePrefix = '';
  final SurveyService surveyService = SurveyService();
  bool _isBracketMountingEditable = true;
  List<XFile?> _fetchedCapturedImages = [];
  List<String> _fetchedAuditImagesNames = [];

  // String _wardNumberForPolePrefix = '';

  updateSurveyFieldValues(
    context,
    ref,
    dynamic onchangedValue,
    String? fieldName,
  ) {
    if (fieldName == null) return;

    switch (fieldName) {
      case 'connectionType':
        _selectedConnectionType = onchangedValue;
        break;
      case 'Bracket Required':
        _isBracketRequired = onchangedValue;
        break;
      case 'Earthing':
        _isEarthingRequired = onchangedValue;
        break;
      case 'Control Wire Status':
        _isControlWireStatus = onchangedValue;
        break;
      case 'lampType':
        _selectedLampType = onchangedValue;
        break;
      case 'lampWatts':
        _selectedLampWatts = onchangedValue;
        break;
      case 'comments':
        _selectedComments = onchangedValue;
        break;
      case 'manualEnteredLocation':
        _selectedManualEnteredLocation = onchangedValue;
        break;
    }

    notifyListeners();
  }

  updateBaseSurveyFieldValues(
    context,
    ref,
    dynamic onchangedValue,
    String? fieldName,
  ) {
    if (fieldName == null) return;

    switch (fieldName) {
      case 'trafficDensity':
        _selectedTrafficDensity = onchangedValue;
        break;
      case 'trafficSpeed':
        _selectedTrafficSpeed = onchangedValue;
        break;
      case 'assetType':
        _selectedAssetType = onchangedValue;
        break;
    }
    notifyListeners();
  }

  updateSwitchPointSurveyFieldValues(
    context,
    ref,
    dynamic onchangedValue,
    String? fieldName,
  ) {
    if (fieldName == null) return;

    switch (fieldName) {
      case 'switchPointNumber':
        _selectedSpNumber = onchangedValue;
        _switchPointNumberController.text = onchangedValue;
        break;
      case 'spType':
        _selectedSwitchPointType = onchangedValue;
        break;
      case 'rrNumber':
        _selectedSpRrNo = onchangedValue;
        break;
      case 'spTransFormerNo':
        _spTransformerNoController.text = onchangedValue;
        break;
      case 'spId':
        _switchPointIdController.text = onchangedValue;
        _selectedSpId = onchangedValue;
        break;
      case 'spMeter':
        _selectedSPMeter = onchangedValue;
        break;
      case 'spConnectedLoad':
        _spConnectedLoadController.text = onchangedValue;
        _selectedSpConnectedLoad = onchangedValue;
        break;
      case 'spMeterNo':
        _spMeterNoController.text = onchangedValue;
        _selectedSpMeterNo = onchangedValue;
        break;
      case 'spMeterType':
        _selectedSpMeterType = onchangedValue;
        break;
      case 'spMake':
        _selectedSpMake = onchangedValue;
        break;
      case 'spPhase':
        _selectedSpPhase = onchangedValue;
        break;
      case 'spCondition':
        _selectedSpCondition = onchangedValue;
        break;
      case 'spEarthingCondition':
        _selectedSpEarthingCondition = onchangedValue;
        break;
      // for switch point association with panel
      case 'customSwitchPointNo':
        _customSwitchPointNo = onchangedValue;
        break;
      case 'multiSwitchPointNo':
        _multiSwitchPointNo = onchangedValue;
        break;
      case 'spEarthingAvailable':
        _isSpEarthingAvailable = onchangedValue;
        break;
      case 'spEarthingReason':
        _spEarthingReason = onchangedValue;
        break;
    }
    notifyListeners();
  }

  updateTransformerSurveyFieldValues(
    context,
    ref,
    dynamic onchangedValue,
    String? fieldName,
  ) {
    if (fieldName == null) return;

    switch (fieldName) {
      case 'transNo':
        _transNoController.text = onchangedValue;
        break;
      case 'transCapacity':
        _transCapacityController.text = onchangedValue;
        break;
    }

    notifyListeners();
  }

  updatePoleSurveyFieldValues(
    context,
    ref,
    dynamic onchangedValue,
    String? fieldName,
  ) {
    if (fieldName == null) return;

    switch (fieldName) {
      case 'poleNumber':
        _selectedPoleNumber = onchangedValue;
        _poleNumberController.text = onchangedValue;
        break;
      case 'escomPoleNumber':
        _selectedEscomPoleNumber = onchangedValue;
        break;
      case 'exCorpPoleNo':
        _exCorpPoleNoController.text = onchangedValue;
        break;
      case 'poleTransFormerNo':
        _poleTransformerNoController.text = onchangedValue;
        break;
      case 'switchPointNo':
        _selectedSwitchPointNo = onchangedValue;
        // _switchPointController.text = onchangedValue;
        break;
    }
    notifyListeners();
  }

  Future<void> fetchSurveyDetails(WidgetRef ref, assetName) async {
    final hasInternet = ref.read(internetStatusProvider);
    if (!hasInternet) {
      log('No internet connection');
      ref.read(surveyController).updatePoleHeightCascade(selectedRoadType);
      return;
    }
    var data = await surveyService.getSurveyDetailService(assetName);
    _isSurveyLocationFetched = true;
    if (data == 404) {
      ref.read(surveyController).updatePoleHeightCascade(selectedRoadType);
    } else if (data.containsKey('deviceDetails')) {
      if (data['deviceDetails'][0].containsKey("pole")) {
        await loadPoleData(data['deviceDetails'][0]['pole']);
      } else if (data['deviceDetails'][0].containsKey("switchPoint")) {
        await loadSpData(data['deviceDetails'][0]['switchPoint']);
      } else if (data['deviceDetails'][0].containsKey("transformer")) {
        await loadTransData(data['deviceDetails'][0]['transformer']);
      }
    }
  }

  Future<void> loadPoleData(data) async {
    try {
      String entirePoleNumber = (data['name'] ?? '').toString();
      final poleMatch = RegExp(r'P(\d+)').firstMatch(entirePoleNumber);
      final spMatch = RegExp(r'SP(\d+)').firstMatch(entirePoleNumber);

      if (poleMatch != null) {
        _poleNumberController.text = poleMatch.group(1)!;
      }

      if (spMatch != null) {
        _switchPointController.text = spMatch.group(1)!;
      }
      String entireTransNumber = (data['transformerNo'] ?? '').toString();
      final transMatch = RegExp(r'TFR(.+)$').firstMatch(entireTransNumber);
      if (transMatch != null) {
        _poleTransformerNoController.text = transMatch.group(1)!;
      }
      _exCorpPoleNoController.text = (data['exCorpPoleNo'] ?? '').toString();
      _ebPoleNoController.text = (data['ebPoleNo'] ?? '').toString();
      _selectedEscomPoleNumber = (data['ebPoleNo'] ?? '').toString();
      _commentsController.text = (data['remarks'] ?? '').toString();
      _selectedComments = (data['remarks'] ?? '').toString();

      // Selected simple fields
      _selectedPoleType = (data['pole_type'] ?? _selectedPoleType).toString();
      _selectedPoleHeight = (data['height'] ?? _selectedPoleHeight).toString();
      _selectedPoleSpan = (data['span'] ?? _selectedPoleSpan).toString();
      _selectedPoleCondition =
          (data['condition'] ?? _selectedPoleCondition).toString();

      // Arm and lamp counts
      var armDetails = data['armDetails'] ?? '';
      if (armDetails.isNotEmpty) {
        _selectedArmCount =
            (armDetails['count'] ?? _selectedArmCount).toString();
        _selectedArmLength =
            (armDetails['length'] ?? _selectedArmLength).toString();
        _selectedGoodArmCount = armDetails['condition'][0]['count'].toString();
        _selectedBadArmCount = armDetails['condition'][1]['count'].toString();
        _selectedMissingArmCount =
            armDetails['condition'][2]['count'].toString();
      }
      var lightDetails = data['lightDetails'] ?? '';
      if (lightDetails.isNotEmpty) {
        _selectedWorkingCount = lightDetails[0]['count'].toString();
        _selectedNotWorkingCount = lightDetails[1]['count'].toString();
        _selectedMissingCount = lightDetails[2]['count'].toString();
      }

      // Update controllers for numeric/text counts
      goodArmTextController.text = _selectedGoodArmCount;
      badArmTextController.text = _selectedBadArmCount;
      missingArmTextController.text = _selectedMissingArmCount;
      workingTextController.text = _selectedWorkingCount;
      notWorkingTextController.text = _selectedNotWorkingCount;
      missingTextController.text = _selectedMissingCount;

      // Clamp / bracket / earthing
      var clampDimension = data['clampDimension'] ?? '';
      if (clampDimension.isNotEmpty) {
        _selectedClampLength = (clampDimension['length']).toString();

        _selectedClampWidth = (clampDimension['width']).toString();

        _selectedClampUnits = (clampDimension['unit']).toString();

        String formatted =
            ('$_selectedClampLength x $_selectedClampWidth $_selectedClampUnits')
                .toString();
        if (clampTypeOptions.contains(formatted)) {
          _selectedClampType = formatted;
        } else {
          _selectedClampType = 'Others';
          _clampTypeLengthController.text = _selectedClampLength;
          _clampTypeWidthController.text = _selectedClampWidth;
        }
      }

      _selectedBracketMountingHeight =
          (data['bracketMountingHeight'] ?? _selectedBracketMountingHeight)
              .toString();
      _isEarthingRequired =
          (data['earthingRequired'] ?? _isEarthingRequired) as bool? ??
              _isEarthingRequired;

      _selectedManualSwitchCtrl =
          (data['manualSwitchControl'] ?? _selectedManualSwitchCtrl).toString();

      // Incoming transformer / motor / winch / rope
      _selectedIncomingTransLine =
          (data['incomingTransmissionLine'] ?? _selectedIncomingTransLine)
              .toString();
      _selectedIncomingTransType =
          (data['incomingTransmissionType'] ?? _selectedIncomingTransType)
              .toString();

      var motorDetails = data['motorDetails'] ?? '';
      if (motorDetails.isNotEmpty) {
        final ratingRawValue = motorDetails['rating'] ?? ''.toString();
        final match = RegExp(r'^\s*([\d.]+)\s*([a-zA-Z]+)\s*$')
            .firstMatch(ratingRawValue);

        if (match != null) {
          _poleMotorRatingController.text = match.group(1)!;
          _selectedPoleRatingUnits = match.group(2)!;
        }
        _poleMotorMakeController.text = motorDetails['make'] ?? ''.toString();
        _poleMotorModelController.text = motorDetails['model'] ?? ''.toString();
      }
      _selectedPoleMotorCondition =
          (data['motorCondition'] ?? _selectedPoleMotorCondition).toString();
      _selectedPoleWinchCondition =
          (data['winchCondition'] ?? _selectedPoleWinchCondition).toString();
      _selectedPoleRopeCondition =
          (data['ropeCondition'] ?? _selectedPoleRopeCondition).toString();

      final lampProfiles = data['lampProfiles'];
      updateLamp(lampProfiles);
      _fetchedAuditImagesNames = data['auditImg'] is String
          ? List<String>.from(jsonDecode(data['auditImg']))
          : List<String>.from(data['auditImg'] ?? []);
      await updateImages();

      _fetchedLandMark = (data['location'] ?? '').toString();
      _fetchedLat = (data['latitude'] ?? '').toString();
      _fetchedLong = (data['longitude'] ?? '').toString();
      _fetchedAltitude = (data['altitude'] ?? '').toString();
      _selectedRoadCategory =
          (data['existingRoadCategory'] ?? _selectedRoadCategory).toString();
      _selectedRoadType = (data['roadType'] ?? _selectedRoadType).toString();
      _selectedRoadWidth = (data['roadWidth'] ?? _selectedRoadWidth).toString();
      _selectedVehicleAccess =
          (data['vehicleAccess'] ?? _selectedVehicleAccess).toString();
      _selectedTrafficDensity =
          (data['trafficDensity'] ?? _selectedTrafficDensity).toString();
      _selectedTrafficSpeed =
          (data['trafficSpeed'] ?? _selectedTrafficSpeed).toString();

      notifyListeners();
    } catch (e) {
      EasyLoading.dismiss();
      log('Error loading pole survey map into provider: $e');
    }
  }

  Future<void> loadSpData(data) async {
    try {
      String entireSpNumber = (data['name'] ?? '').toString();
      final spMatch = RegExp(r'SP(\d+)').firstMatch(entireSpNumber);

      if (spMatch != null) {
        _switchPointNumberController.text = spMatch.group(1)!;
      }
      _selectedSwitchPointType =
          (data['switchPointType'] ?? _selectedSwitchPointType).toString();
      _rrNumberController.text = (data['rrNumber'] ?? '').toString();
      _selectedSpRrNo = (data['rrNumber'] ?? '').toString();
      String entireTransNumber = (data['transformerNo'] ?? '').toString();
      final transMatch = RegExp(r'TFR(.+)$').firstMatch(entireTransNumber);
      if (transMatch != null) {
        _spTransformerNoController.text = transMatch.group(1)!;
      }
      switchPointIdController.text = (data['panelId'] ?? '').toString();
      _selectedSpId = (data['panelId'] ?? '').toString();
      _commentsController.text = (data['remarks'] ?? '').toString();
      _selectedComments = (data['remarks'] ?? '').toString();

      var meterDetails = data['meterDetails'] ?? '';
      if (meterDetails.isNotEmpty) {
        _selectedSPMeter =
            (meterDetails['status'] ?? _selectedSPMeter).toString();
        _selectedSpMeterNo =
            (meterDetails['no'] ?? _selectedSpMeterNo).toString();
        _spMeterNoController.text =
            (meterDetails['no'] ?? _selectedSpMeterNo).toString();
        _selectedSpMeterType =
            (meterDetails['type'] ?? _selectedSpMeterType).toString();
        _selectedSpMake = (meterDetails['make'] ?? _selectedSpMake).toString();
        _selectedSpPhase =
            (meterDetails['phase'] ?? _selectedSpPhase).toString();
      }

      _selectedSpCondition =
          (data['condition'] ?? _selectedSpCondition).toString();
      _selectedSpEarthingCondition =
          (data['earthingCondition'] ?? _selectedSpEarthingCondition)
              .toString();

      final connectedLoad = data['connectedLoad'] ?? ''.toString();
      // final match = RegExp(r'^\s*([\d.]+)\s*([a-zA-Z]+)\s*$')
      //     .firstMatch(connectedLoadRawValue);

      _spConnectedLoadController.text = connectedLoad;
      _selectedSpConnectedLoad = connectedLoad;

      _fetchedLandMark = (data['location'] ?? '').toString();
      _fetchedLat = (data['latitude'] ?? '').toString();
      _fetchedLong = (data['longitude'] ?? '').toString();
      _fetchedAltitude = (data['altitude'] ?? '').toString();
      _selectedRoadCategory =
          (data['existingRoadCategory'] ?? _selectedRoadCategory).toString();
      _selectedRoadType = (data['roadType'] ?? _selectedRoadType).toString();
      _selectedRoadWidth = (data['roadWidth'] ?? _selectedRoadWidth).toString();
      _selectedVehicleAccess =
          (data['vehicleAccess'] ?? _selectedVehicleAccess).toString();
      _selectedTrafficDensity =
          (data['trafficDensity'] ?? _selectedTrafficDensity).toString();
      _selectedTrafficSpeed =
          (data['trafficSpeed'] ?? _selectedTrafficSpeed).toString();
      _fetchedAuditImagesNames = data['auditImg'] is String
          ? List<String>.from(jsonDecode(data['auditImg']))
          : List<String>.from(data['auditImg'] ?? []);
      await updateImages();
      notifyListeners();
    } catch (e) {
      EasyLoading.dismiss();
      log('Error loading pole survey map into provider: $e');
    }
  }

  Future<void> loadTransData(data) async {
    try {
      String entireTransNumber = (data['name'] ?? '').toString();

      final transMatch = RegExp(r'TFR(.+)$').firstMatch(entireTransNumber);

      if (transMatch != null) {
        _transNoController.text = transMatch.group(1)!;
      }

      final transCapacityRawValue = data['capacity'] ?? ''.toString();
      final match = RegExp(r'^\s*([\d.]+)\s*([a-zA-Z]+)\s*$')
          .firstMatch(transCapacityRawValue);
      if (match != null) {
        _transCapacityController.text = match.group(1)!;
      }
      _fetchedLandMark = (data['location'] ?? '').toString();
      _fetchedLat = (data['latitude'] ?? '').toString();
      _fetchedLong = (data['longitude'] ?? '').toString();
      _fetchedAltitude = (data['altitude'] ?? '').toString();
      _commentsController.text = (data['remarks'] ?? '').toString();
      _selectedComments = (data['remarks'] ?? '').toString();
      _selectedRoadCategory =
          (data['existingRoadCategory'] ?? _selectedRoadCategory).toString();
      _selectedRoadType = (data['roadType'] ?? _selectedRoadType).toString();
      _selectedRoadWidth = (data['roadWidth'] ?? _selectedRoadWidth).toString();
      _selectedVehicleAccess =
          (data['vehicleAccess'] ?? _selectedVehicleAccess).toString();
      _selectedTrafficDensity =
          (data['trafficDensity'] ?? _selectedTrafficDensity).toString();
      _selectedTrafficSpeed =
          (data['trafficSpeed'] ?? _selectedTrafficSpeed).toString();
      _fetchedAuditImagesNames = data['auditImg'] is String
          ? List<String>.from(jsonDecode(data['auditImg']))
          : List<String>.from(data['auditImg'] ?? []);

      await updateImages();
      notifyListeners();
    } catch (e) {
      EasyLoading.dismiss();
      log('Error loading pole survey map into provider: $e');
    }
  }

  poleFormValidation(context, ref, request, poleType) {
    if (poleType == null || request == null) return;
    switch (request) {
      case 'init':
        switch (poleType) {
          case 'RCC':
            poleFormValidation(context, ref, 'Earthing', poleType);
            poleFormValidation(
                context, ref, 'incomingTransmissionLine', poleType);
            poleFormValidation(context, ref, 'bracketMountingHeight', poleType);
          // break;
        }
      case 'Earthing':
        switch (poleType) {
          case 'RCC':
            updateSurveyFieldValues(context, ref, true, 'Earthing');
            break;
          case 'Tubular':
            updateSurveyFieldValues(context, ref, false, 'Earthing');
            break;
          // default:
          //   updateSurveyFieldValues(context, ref, true, 'Earthing');
          //   break;
        }
      case 'incomingTransmissionLine':
        switch (poleType) {
          case 'RCC':
            incomingTransLineOptions = ['Overhead', 'ABC'];
            _selectedIncomingTransLine = 'Overhead';
            break;
          default:
            incomingTransLineOptions = [
              'Under Ground',
              'Conductor',
              'Overhead',
              'Missing',
              'ABC'
            ];
            _selectedIncomingTransLine = 'Under Ground';
            break;
        }
      case 'bracketMountingHeight':
        switch (poleType) {
          case 'RCC':
            _isBracketMountingEditable = true;
            if (_selectedPoleHeight != 'Others') {
              if (_selectedRoadType == 'Park Road') {
                _isBracketMountingEditable = false;
                _selectedBracketMountingHeight = _selectedPoleHeight;
              } else {
                _isBracketMountingEditable = false;
                _selectedBracketMountingHeight =
                    '${int.parse(_selectedPoleHeight.replaceAll(RegExp(r'\D'), '')) - 1} m';
              }
            }
            break;
          case 'Tubular':
            _isBracketMountingEditable = true;
            if (_selectedPoleHeight != 'Others') {
              _isBracketMountingEditable = false;
              _selectedBracketMountingHeight = _selectedPoleHeight;
            }
            break;
          default:
            _isBracketMountingEditable = true;
            if (_selectedRoadType == 'Park Road') {
              _selectedBracketMountingHeight = 'Others';
            }
            break;
        }
    }
    notifyListeners();
  }

  updatePoleSurveyFieldPoleValues(
    context,
    ref,
    dynamic onchangedValue,
    String? fieldName,
  ) {
    if (fieldName == null) return;

    switch (fieldName) {
      case 'poleCondition':
        _selectedPoleCondition = onchangedValue;
        break;
      case 'poleType':
        _selectedPoleType = onchangedValue;
        updatePoleTypeCascade(_selectedPoleType);
        if (_selectedPoleType == 'RCC') {
          updatePoleHeightCascade(selectedRoadType);
        }
        poleFormValidation(context, ref, 'Earthing', onchangedValue);
        poleFormValidation(
            context, ref, 'incomingTransmissionLine', onchangedValue);
        poleFormValidation(
            context, ref, 'bracketMountingHeight', onchangedValue);
        break;
      case 'poleHeight':
        _selectedPoleHeight = onchangedValue;
        poleFormValidation(
            context, ref, 'bracketMountingHeight', _selectedPoleType);
        break;
      case 'poleSpan':
        _selectedPoleSpan = onchangedValue;
        break;
      case 'incomingTransLine':
        _selectedIncomingTransLine = onchangedValue;
        break;
      case 'incomingTransType':
        _selectedIncomingTransType = onchangedValue;
        break;
      case 'clampType':
        _selectedClampType = onchangedValue;
        break;
      case 'customInputLength':
        _selectedClampLength = onchangedValue;
        break;
      case 'customInputWidth':
        _selectedClampWidth = onchangedValue;
        break;
      case 'customInputUnits':
        _selectedClampUnits = onchangedValue;
        break;
      case 'bracketMountingHeight':
        _selectedBracketMountingHeight = onchangedValue;
        break;
      case 'customBracketHeight':
        _selectedCustomBracketHeight = onchangedValue;
        break;
    }

    notifyListeners();
  }

  updatePoleSurveyFieldMotorValues(
    context,
    ref,
    dynamic onchangedValue,
    String? fieldName,
  ) {
    if (fieldName == null) return;

    switch (fieldName) {
      case 'motorCondition':
        _selectedPoleMotorCondition = onchangedValue;
        break;
      case 'motorRating':
        _poleMotorRatingController.text = onchangedValue;
        break;
      case 'ratingUnits':
        _selectedPoleRatingUnits = onchangedValue;
        break;
      case 'motorMake':
        _poleMotorMakeController.text = onchangedValue;
        break;
      case 'motorModel':
        _poleMotorModelController.text = onchangedValue;
        break;
      case 'winchCondition':
        _selectedPoleWinchCondition = onchangedValue;
        break;
      case 'ropeCondition':
        _selectedPoleRopeCondition = onchangedValue;
        break;
    }
    notifyListeners();
  }

  updatePoleSurveyFieldArmValues(
    context,
    ref,
    dynamic onchangedValue,
    String? fieldName,
  ) {
    if (fieldName == null) return;

    switch (fieldName) {
      case 'armCount':
        _selectedArmCount = onchangedValue;
        _resetArmAndLampCounts(int.tryParse(_selectedArmCount) ?? 0);
        break;
      case 'armLength':
        _selectedArmLength = onchangedValue;
        break;
      case 'armCondition':
        _selectedArmCondition = onchangedValue;
        break;
      case 'Good':
      case 'Bad':
        _updateArmConditionCounts(fieldName, onchangedValue);
        break;
    }
    notifyListeners();
  }

  updatePoleSurveyFieldLightValues(
    context,
    ref,
    dynamic onchangedValue,
    String? fieldName,
  ) {
    if (fieldName == null) return;

    switch (fieldName) {
      case 'Working':
      case 'Not Working':
        _updateLampStatusCounts(fieldName, onchangedValue);
        break;
      case 'manualSwitchCtrl':
        _selectedManualSwitchCtrl = onchangedValue;
        break;
    }
    notifyListeners();
  }

  void updateRoadCategoryCascade(
      BuildContext context, WidgetRef ref, String newCategory) {
    _selectedRoadCategory = newCategory;

    // Set Road Type
    final roadTypeList = roadTypeOptions[newCategory] ?? [];
    _selectedRoadType = (roadTypeList.isNotEmpty ? roadTypeList.first : null)!;

    // Set Road Width
    final widthList = roadWidthOptions[_selectedRoadType] ?? [];
    _selectedRoadWidth = (widthList.isNotEmpty ? widthList.first : null)!;

    // Set Vehicle Access
    final accessList = vehicleAccessOptions[_selectedRoadWidth] ?? [];
    _selectedVehicleAccess = (accessList.isNotEmpty ? accessList.first : null)!;

    notifyListeners();
  }

  void updateRoadTypeCascade(
      BuildContext context, WidgetRef ref, String newType) {
    _selectedRoadType = newType;

    final widthList = roadWidthOptions[newType] ?? [];
    _selectedRoadWidth = (widthList.isNotEmpty ? widthList.first : null)!;

    final accessList = vehicleAccessOptions[_selectedRoadWidth] ?? [];
    _selectedVehicleAccess = (accessList.isNotEmpty ? accessList.first : null)!;

    notifyListeners();
  }

  void updateRoadWidthCascade(
      BuildContext context, WidgetRef ref, String newWidth) {
    _selectedRoadWidth = newWidth;

    // Update vehicle access list based on new width
    final accessList = vehicleAccessOptions[newWidth] ?? [];
    _selectedVehicleAccess = (accessList.isNotEmpty ? accessList.first : null)!;

    notifyListeners();
  }

  void updateVehicleAccess(String newAccess) {
    _selectedVehicleAccess = newAccess;
    notifyListeners();
  }

  void updatePoleHeightCascade(String roadType) {
    if (roadType == 'Park Road') {
      poleHeightOptions = ['3 m', '5 m'];
      _selectedPoleHeight = '3 m';
      bracketMountingHeightOptions = ['Others'];
      _selectedBracketMountingHeight = 'Others';
    }
  }

  void updatePoleTypeCascade(String type) {
    if (type == 'High Mast(HM)') {
      armCountOptions = [
        '6',
        '7',
        '8',
        '9',
        '10',
        '11',
        '12',
        '13',
        '14',
        '15',
        '16',
        '17',
        '18',
        '19',
        '20'
      ];
      _selectedArmCount = '6';
      poleHeightOptions = ['20 m', 'Others'];
      _selectedPoleHeight = '20 m';
      lampWattageOptions.clear();
      lampWattageOptions = {
        'SVL': ['250 W', '400 W'],
        'MH': ['250 W', '400 W'],
        'FL LED': ['125 W', '150 W', '200 W'],
      };
      _selectedLampType = 'SVL';
      _selectedLampWatts = '250 W';
    } else if (type == 'Mini Mast(MM)') {
      armCountOptions = [
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '10',
        '11',
        '12',
        '13',
        '14',
        '15',
        '16',
        '17',
        '18',
        '19',
        '20'
      ];
      poleHeightOptions = ['10 m', '12 m', '16 m', '20 m', 'Others'];
      _selectedArmCount = '4';
      _selectedPoleHeight = '10 m';
      lampWattageOptions.clear();
      lampWattageOptions = {
        'Tube light': ['40 W'],
        'SVL': ['250 W', '400 W'],
        'CFL': ['25 W', '36 W', '65 W', '72 W', '85 W'],
        'LED': [
          '20 W',
          '40 W',
          '60 W',
          '70 W',
          '90 W',
          '120 W',
          '150 W',
          '200 W'
        ],
        'T5': ['96 W', '120 W', '220 W'],
        'BULB': ['10 W'],
        'MH': ['250 W', '400 W']
      };
      _selectedLampType = 'Tube light';
      _selectedLampWatts = '40 W';
    } else {
      armCountOptions = [
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '10',
        '11',
        '12',
        '13',
        '14',
        '15',
        '16',
        '17',
        '18',
        '19',
        '20'
      ];
      _selectedArmCount = '1';
      poleHeightOptions = [
        '7 m',
        '8 m',
        '9 m',
        '10 m',
        '12 m',
        '16 m',
        '20 m',
        'Others'
      ];
      _selectedPoleHeight = '7 m';
      lampWattageOptions.clear();
      lampWattageOptions = {
        'Tube light': ['40 W'],
        'SVL': ['150 W', '250 W', '400 W'],
        'CFL': ['25 W', '36 W', '65 W', '72 W', '85 W'],
        'LED': [
          '20 W',
          '40 W',
          '60 W',
          '70 W',
          '90 W',
          '120 W',
          '150 W',
          '200 W'
        ],
        'T5': ['96 W', '120 W', '220 W'],
        'BULB': ['10 W'],
        'MH': ['150 W', '250 W', '400 W']
      };
      _selectedLampType = 'Tube light';
      _selectedLampWatts = '40 W';
    }
    _resetArmAndLampCounts(int.tryParse(_selectedArmCount) ?? 0);
  }

  void _resetArmAndLampCounts(int armCount) {
    _selectedGoodArmCount = '0';
    _selectedBadArmCount = '0';
    _selectedMissingArmCount = armCount.toString();
    _selectedWorkingCount = '0';
    _selectedNotWorkingCount = '0';
    _selectedMissingCount = armCount.toString();

    goodArmTextController.text = '0';
    badArmTextController.text = '0';
    missingArmTextController.text = armCount.toString();

    workingTextController.text = '0';
    notWorkingTextController.text = '0';
    missingTextController.text = armCount.toString();

    // Reset lamp list to have only one entry
    _selectedLamps = [
      {'type': _selectedLampType, 'watts': _selectedLampWatts}
    ];
  }

  Future<void> updateImages() async {
    final auditImages = _fetchedAuditImagesNames;

    _fetchedCapturedImages = [];

    if (auditImages.isEmpty) {
      _fetchedCapturedImages = List<XFile?>.filled(3, null);
      notifyListeners();
      return;
    }

    for (int i = 0; i < auditImages.length && i < 3; i++) {
      final imageUrl =
          '${S3Config.s3Endpoint}/${S3Config.luminatorFolder}/${auditImages[i]}';

      try {
        final res = await http.get(Uri.parse(imageUrl));
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${auditImages[i]}');
        await file.writeAsBytes(res.bodyBytes);
        _fetchedCapturedImages.add(XFile(file.path));
      } catch (e) {
        log('Failed to download image: $imageUrl, error: $e');
        _fetchedCapturedImages.add(null);
      }
    }

    while (_fetchedCapturedImages.length < 3) {
      _fetchedCapturedImages.add(null);
    }
    notifyListeners();
  }

  void updateLamp(lampProfiles) {
    _selectedLamps = [];

    for (int i = 0; i < lampProfiles.length; i++) {
      addLamp(
          type: lampProfiles[i]['type'],
          watts: '${lampProfiles[i]['watts']} W');
    }
    // _workingTextController.text = lampProfiles.length.toString();
    // _updateLampStatusCounts('Working', _workingTextController.text);
    notifyListeners();
  }

  void addLamp({String? type, String? watts}) {
    if (_selectedLamps.length < int.parse(_selectedArmCount)) {
      _selectedLamps.add({
        'type': type ?? _selectedLampType,
        'watts': watts ?? _selectedLampWatts,
      });
      log('lamp profiles :$_selectedLamps');
      notifyListeners();
    }
  }

  void updateLampType(int index, String type) {
    if (index < _selectedLamps.length) {
      final wattsList = lampWattageOptions[type] ?? [];
      final watts = wattsList.isNotEmpty ? wattsList.first : '40 W';
      _selectedLamps = List.from(_selectedLamps);
      _selectedLamps[index] = {
        'type': type,
        'watts': watts,
      };
      log('lamp profiles :$_selectedLamps');
      notifyListeners();
    }
  }

  void updateLampWatts(int index, String watts) {
    if (index < _selectedLamps.length) {
      _selectedLamps = List.from(_selectedLamps);
      _selectedLamps[index] = Map.from(_selectedLamps[index])
        ..['watts'] = watts;
      log('lamp profiles :$_selectedLamps');
      notifyListeners();
    }
  }

  void _updateArmConditionCounts(String field, String value) {
    if (field == 'Good') {
      _selectedGoodArmCount = value;
    } else if (field == 'Bad') {
      _selectedBadArmCount = value;
    }

    int armCount = int.tryParse(_selectedArmCount) ?? 0;
    int good = int.tryParse(_selectedGoodArmCount) ?? 0;
    int bad = int.tryParse(_selectedBadArmCount) ?? 0;

    if (good + bad > armCount) {
      if (field == 'Good') {
        good = armCount - bad;
        _selectedGoodArmCount = good.toString();
        goodArmTextController.text = _selectedGoodArmCount;
      } else {
        bad = armCount - good;
        _selectedBadArmCount = bad.toString();
        badArmTextController.text = _selectedBadArmCount;
      }
    }

    int missing = armCount - good - bad;
    _selectedMissingArmCount = missing.toString();
    missingArmTextController.text = _selectedMissingArmCount;
  }

  void _updateLampStatusCounts(String field, String value) {
    if (field == 'Working') {
      _selectedWorkingCount = value;
    } else if (field == 'Not Working') {
      _selectedNotWorkingCount = value;
    }

    int armCount = int.tryParse(_selectedArmCount) ?? 0;
    int working = int.tryParse(_selectedWorkingCount) ?? 0;
    int notWorking = int.tryParse(_selectedNotWorkingCount) ?? 0;

    if (working + notWorking > armCount) {
      if (field == 'Working') {
        working = armCount - notWorking;
        _selectedWorkingCount = working.toString();
        workingTextController.text = _selectedWorkingCount;
      } else {
        notWorking = armCount - working;
        _selectedNotWorkingCount = notWorking.toString();
        notWorkingTextController.text = _selectedNotWorkingCount;
      }
    }

    int missing = armCount - working - notWorking;
    _selectedMissingCount = missing.toString();
    missingTextController.text = _selectedMissingCount;
  }

  clearAllUpdatedSelectedFields() {
    //pole details
    _selectedEscomPoleNumber = '';
    _selectedPoleNumber = '';
    poleNumberController.clear();
    ebPoleNoController.clear();
    workingTextController.text = '0';
    notWorkingTextController.text = '0';
    missingTextController.text = '1';
    goodArmTextController.text = '0';
    badArmTextController.text = '0';
    missingArmTextController.text = '1';
    commentsController.clear();
    _selectedComments = '';
    _surveyManualLocationEntry.clear();
    _fetchedLandMark = '';
    _fetchedLat = '';
    _fetchedLong = '';
    _fetchedAltitude = '';
    _selectedPoleSpan = '';
    _selectedPoleType = 'RCC';
    _selectedPoleCondition = 'Good';
    _selectedPoleHeight = '7 m';
    _selectedConnectionType = 'Connection Type';
    _selectedArmCount = '1';
    _selectedArmCondition = 'Good';
    _selectedArmLength = 'Normal';
    _selectedRoadCategory = 'A1';
    _selectedRoadWidth = 'above 9m';
    _selectedVehicleAccess = 'Long Truck';
    _selectedIncomingTransLine = 'Under Ground';
    _selectedIncomingTransType = 'Dedicated for Streetlight';
    _selectedClampType = '6 x 3 inch';
    _selectedClampLength = '';
    _selectedClampWidth = '';
    _selectedClampUnits = '';
    _isEarthingRequired = false;
    _isBracketRequired = false;
    _isControlWireStatus = false;
    _selectedManualSwitchCtrl = 'Exists - Good Condition';
    _selectedWorkingCount = '0';
    _selectedNotWorkingCount = '0';
    _selectedMissingCount = '1';
    _selectedMissingArmCount = '1';
    _selectedGoodArmCount = '0';
    _selectedBadArmCount = '0';
    _selectedManualEnteredLocation = '';
    _selectedBracketMountingHeight = '6 m';
    bracketMountingHeightOptions = [
      'Not Required',
      '6 m',
      '7 m',
      '8 m',
      '9 m',
      '12 m',
      '16 m',
      'Others'
    ];
    _selectedLampType = 'Tube light';
    _selectedLampWatts = '40 W';
    _selectedLamps = [
      {'type': 'Tube light', 'watts': '40 W'}
    ];
    _exCorpPoleNoController.clear();
    _selectedPoleMotorCondition = 'Good';
    _poleMotorMakeController.clear();
    _poleMotorModelController.clear();
    _poleMotorRatingController.clear();
    _selectedPoleRatingUnits = 'hp';
    _selectedPoleWinchCondition = 'Good';
    _selectedPoleRopeCondition = 'Working';
    lampWattageOptions = {
      'Tube light': ['40 W'],
      'SVL': ['150 W', '250 W', '400 W'],
      'CFL': ['25 W', '36 W', '65 W', '72 W', '85 W'],
      'LED': [
        '20 W',
        '40 W',
        '60 W',
        '70 W',
        '90 W',
        '120 W',
        '150 W',
        '200 W'
      ],
      'T5': ['96 W', '120 W', '220 W'],
      'BULB': ['10 W'],
      'MH': ['150 W', '250 W', '400 W']
    };
    armCountOptions = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
      '13',
      '14',
      '15',
      '16',
      '17',
      '18',
      '19',
      '20'
    ];
    poleHeightOptions = [
      '7 m',
      '8 m',
      '9 m',
      '10 m',
      '12 m',
      '16 m',
      '20 m',
      'Others'
    ];
    _selectedTrafficDensity = 'High';
    _selectedTrafficSpeed = 'Slow Moving';
    _poleTransformerNoController.clear();

// switch point details
    _switchPointNumberController.clear();
    _selectedSpNumber = '';
    _selectedSpRrNo = '';
    _rrNumberController.clear();
    _selectedSwitchPointType = 'Feeder Pillar';
    _switchPointIdController.clear();
    _selectedSpId = '';
    _spConnectedLoadController.clear();
    _selectedSpConnectedLoad = '';
    _spMeterNoController.clear();
    _selectedSpMeterNo = '';
    _selectedSpMake = 'L&T';
    _spMakeController.text = 'L&T';
    _selectedSPMeter = 'Working';
    _selectedSpMeterType = 'Digital';
    _selectedSpPhase = '1';
    _selectedSpCondition = 'Working';
    _selectedSpEarthingCondition = 'Good';
    _isSpEarthingAvailable = true;
    _spEarthingReason = '';
    _spTransformerNoController.clear();

//transformer details
    _transNoController.clear();
    _transCapacityController.clear();
// base survey details
    _selectedRoadType = 'Main Road';
    _selectedRoadCategory = 'A1';
    _selectedRoadWidth = 'above 9m';
    _selectedVehicleAccess = 'Long Truck';
    _selectedAssetType = 'Switch Point';
    _isSwitchPointFromDropdown = false;
    _fetchedAuditImagesNames = [];
    _fetchedCapturedImages = [];
    notifyListeners();
  }

  resetSpNumber() {
    // only in switch point selection screen [Associating sp to panels]
    _selectedSwitchPointNo = '';
    _isSwitchPointFromDropdown = false;
    notifyListeners();
  }

  bool isValidSwitchPointNo(String spNumber) {
    final trimmed = spNumber.trim();

    final regex = RegExp(r'^\d{1,4}$', caseSensitive: true);

    return regex.hasMatch(trimmed);
  }

  dynamic getUniqueLampTypes(selectedLampType) {
    final List<Map<String, dynamic>> inputList = selectedLampType;

    final List<Map<String, dynamic>> outputList = [];

    for (final item in inputList) {
      final lampType = item['type'] as String;
      final wattageStr = item['watts'] as String;
      final wattage = int.tryParse(wattageStr.replaceAll(RegExp(r'\D'), ''));

      if (wattage != null) {
        final hasDuplicate = outputList
            .any((map) => map['type'] == lampType && map['watts'] == wattage);

        if (!hasDuplicate) {
          final map = {
            'type': lampType,
            'watts': wattage,
          };
          outputList.add(map);
        }
      }
    }
    return outputList;
  }

  Future<void> insertPoleSurveyDetails(context, WidgetRef ref) async {
    String usermail = ref.watch(loginController).userMail;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedWard = ref.watch(deviceController).selectedWard;
    String wardId = ref.watch(deviceController).userSelectedWardid;
    String selectedCustomerId = ref.watch(deviceController).selectedCustomerId;
    String selectedZone = ref.watch(deviceController).selectedZone;
    List<Map<String, dynamic>> lampProfiles = [];

    int intClampTypeLength = 0;
    int intClampTypeWidth = 0;
    // int intCustomBracketHeight = 0;
    if (_selectedClampType != 'Clamp Type Not Required') {
      if (_selectedClampType == 'Others') {
        intClampTypeLength = int.parse(_selectedClampLength);
        intClampTypeWidth = int.parse(_selectedClampWidth);
      } else {
        List<String> splittedClampType = _selectedClampType.split(' ');
        intClampTypeLength = int.parse(splittedClampType[0]);
        intClampTypeWidth = int.parse(splittedClampType[2]);
        _selectedClampUnits = splittedClampType[3];
      }
    }

    if (_selectedBracketMountingHeight != 'Not Required') {
      if (_selectedBracketMountingHeight == 'Others') {
        _selectedBracketMountingHeight = '$_selectedCustomBracketHeight m';
      }
    }

    if (_selectedPoleType == 'High Mast(HM)' ||
        _selectedPoleType == 'Mini Mast(MM)') {
      // _selectedPoleSpan = '';
      _selectedCustomBracketHeight = '';
      _selectedBracketMountingHeight = '';
      _selectedClampType = '';
      intClampTypeLength = 0;
      intClampTypeWidth = 0;
      _selectedClampUnits = '';
    }

    if ((_selectedWorkingCount == '0' || _selectedWorkingCount == '') &&
        (_selectedNotWorkingCount == '0' || _selectedNotWorkingCount == '')) {
      _selectedLamps = [];
    }

    if (_selectedPoleCondition == 'Missing') {
      _selectedPoleType = '';
      _selectedPoleSpan = '';
      _selectedPoleHeight = '';
      _selectedIncomingTransLine = '';
      _selectedIncomingTransType = '';
      _selectedClampType = '';
      _selectedClampUnits = '';
      intClampTypeLength = 0;
      intClampTypeWidth = 0;
      _selectedClampUnits = '';
      _selectedBracketMountingHeight = '';
      _isEarthingRequired = false;
      _selectedArmCount = '';
      _selectedArmLength = '';
      _selectedGoodArmCount = '';
      _selectedBadArmCount = '';
      _selectedMissingArmCount = '';
      _selectedWorkingCount = '';
      _selectedNotWorkingCount = '';
      _selectedMissingCount = '';
      _selectedManualSwitchCtrl = '';
      _selectedLamps = [];
      _selectedPoleMotorCondition = '';
      poleMotorRatingController.text = '';
      poleMotorMakeController.text = '';
      poleMotorModelController.text = '';
      _selectedPoleWinchCondition = '';
      _selectedPoleRopeCondition = '';
    }
    if (_selectedLamps.isNotEmpty) {
      lampProfiles = getUniqueLampTypes(_selectedLamps);
      log('lamp profiles :$lampProfiles');
    }
    if (Hive.isBoxOpen('surveyBox')) {
      await Hive.box('surveyBox').close();
    }
    final box = await Hive.openBox('surveyBox');

    _surveyDetails = PoleSurveyModel(
        roadType: _selectedRoadType,
        trafficDensity: _selectedTrafficDensity,
        trafficSpeed: _selectedTrafficSpeed,
        assetType: _selectedAssetType,
        latitude: double.parse(_fetchedLat == '' ? '0' : _fetchedLat),
        longitude: double.parse(_fetchedLong == '' ? '0' : _fetchedLong),
        accuracy: _fetchedAcc,
        altitude: double.parse(_fetchedAltitude == '' ? '0' : _fetchedAltitude),
        landmark: fetchedLandMark,
        poleType: _selectedPoleType,
        poleHeight: _selectedPoleHeight,
        poleSpan: _selectedPoleSpan,
        poleCondition: _selectedPoleCondition,
        goodArmCount: _selectedGoodArmCount,
        badArmCount: _selectedBadArmCount,
        missingArmCount: _selectedMissingArmCount,
        armCount: _selectedArmCount,
        armLength: _selectedArmCount == '0' ? '' : _selectedArmLength,
        bracketRequired: _isBracketRequired,
        earthingRequired: _isEarthingRequired,
        controlWireStatus: _isControlWireStatus,
        manualSwitchControl: _selectedManualSwitchCtrl,
        workingCount: _selectedWorkingCount,
        notWorkingCount: _selectedNotWorkingCount,
        missingCount: _selectedMissingCount,
        poleNumber: _selectedPoleNumber,
        switchPointNo: _selectedSwitchPointNo,
        poleTransformerNo: poleTransformerNoController.text,
        exCorpPoleNo: _exCorpPoleNoController.text,
        escomPoleNumber: _selectedEscomPoleNumber,
        // lampType: _selectedLampType,
        // lampWatts: _selectedLampWatts,
        selectedLamps: lampProfiles,
        comments: _selectedComments,
        uuidFileName1: _imageDetails.fileName1,
        uuidFileName2: _imageDetails.fileName2,
        uuidFileName3: _imageDetails.fileName3,
        installedOn: DateTime.now().millisecondsSinceEpoch.toString(),
        installedBy: usermail,
        region: selectedRegion,
        zone: selectedZone,
        ward: selectedWard,
        wardId: wardId,
        customerId: selectedCustomerId,
        manualEnteredLocation: _selectedManualEnteredLocation,
        roadCategory: _selectedRoadCategory,
        roadWidth: _selectedRoadWidth,
        vehicleAccess: _selectedVehicleAccess,
        incomingTransLine: _selectedIncomingTransLine,
        incomingTransType: _selectedIncomingTransType,
        clampType: _selectedClampType,
        clampTypeLength: intClampTypeLength,
        clampTypeWidth: intClampTypeWidth,
        clampTypeUnits: _selectedClampUnits,
        bracketMountingHeight: _selectedBracketMountingHeight,
        carrierName: _carrierName,
        signalStrengthLevel: _signalStrengthLevel,
        motorCondition: _selectedPoleMotorCondition,
        motorRating: poleMotorRatingController.text,
        motorMake: poleMotorMakeController.text,
        motorModel: poleMotorModelController.text,
        winchCondition: _selectedPoleWinchCondition,
        ropeCondition: _selectedPoleRopeCondition);
// Save the model as a Map
    await box.add(_surveyDetails.toMap());
    log('survey details ${_surveyDetails.toMap()}');

    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);
    await SimpleSyncService.enqueueTelemetry({"activityMode": storedMode});

    final hasInternet = ref.watch(internetStatusProvider);
    String userMail = ref.read(loginController).userMail;

    if (!hasInternet) {
      await incrementAssetCount('pole', wardId, userMail);
    }
    clearAllUpdatedSelectedFields();
    await alertPopUp(
        context, 'Data Captured Successfully', 'assets/animation/tick.json');
    enableButton();
    BackgroundSyncWorkManager.triggerImmediateSync();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const PoleInstalltionHistoryInfo()),
        (route) => false);
  }

  Future<void> insertSpSurveyDetails(context, WidgetRef ref) async {
    String userMail = ref.watch(loginController).userMail;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedWard = ref.watch(deviceController).selectedWard;
    String wardId = ref.watch(deviceController).userSelectedWardid;
    String selectedCustomerId = ref.watch(deviceController).selectedCustomerId;
    String selectedZone = ref.watch(deviceController).selectedZone;
    if (_selectedSPMeter == 'Missing') {
      _selectedSpMake = '';
      _selectedSpPhase = '';
      _selectedSpMeterType = '';
      _selectedSpMeterNo = '';
    }
    if (Hive.isBoxOpen('surveyBox')) {
      await Hive.box('surveyBox').close();
    }
    final box = await Hive.openBox('surveyBox');
    _spSurveyDetails = SpSurveyModel(
        roadType: _selectedRoadType,
        trafficDensity: _selectedTrafficDensity,
        trafficSpeed: _selectedTrafficSpeed,
        assetType: _selectedAssetType,
        latitude: double.parse(_fetchedLat == '' ? '0' : _fetchedLat),
        longitude: double.parse(_fetchedLong == '' ? '0' : _fetchedLong),
        accuracy: _fetchedAcc,
        altitude: double.parse(_fetchedAltitude == '' ? '0' : _fetchedAltitude),
        landmark: fetchedLandMark,
        spNo: _selectedSpNumber,
        spType: _selectedSwitchPointType,
        rrNo: _selectedSpRrNo,
        spTransformerNo: spTransformerNoController.text,
        spId: _selectedSpId,
        spMeter: _selectedSPMeter,
        spconnectedLoad: _selectedSpConnectedLoad,
        spMeterMake: _selectedSpMake,
        spMeterPhase: _selectedSpPhase,
        spMeterType: _selectedSpMeterType,
        spMeterNo: _selectedSpMeterNo,
        spCondition: _selectedSpCondition,
        spEarthingCondition: _selectedSpEarthingCondition,
        uuidFileName1: _imageDetails.fileName1,
        uuidFileName2: _imageDetails.fileName2,
        uuidFileName3: _imageDetails.fileName3,
        installedOn: DateTime.now().millisecondsSinceEpoch.toString(),
        installedBy: userMail,
        region: selectedRegion,
        zone: selectedZone,
        ward: selectedWard,
        wardId: wardId,
        customerId: selectedCustomerId,
        manualEnteredLocation: _selectedManualEnteredLocation,
        roadCategory: _selectedRoadCategory,
        roadWidth: _selectedRoadWidth,
        vehicleAccess: _selectedVehicleAccess,
        comments: _selectedComments,
        carrierName: _carrierName,
        signalStrengthLevel: _signalStrengthLevel);
    await box.add(_spSurveyDetails.toMap());
    log('survey details ${_spSurveyDetails.toMap()}');

    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);
    await SimpleSyncService.enqueueTelemetry({"activityMode": storedMode});

    final hasInternet = ref.watch(internetStatusProvider);

    if (!hasInternet) {
      await incrementAssetCount('switchPoint', wardId, userMail);
    }
    clearAllUpdatedSelectedFields();
    await alertPopUp(
        context, 'Data Captured Successfully', 'assets/animation/tick.json');
    enableButton();
    BackgroundSyncWorkManager.triggerImmediateSync();

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const PoleInstalltionHistoryInfo()),
        (route) => false);
  }

  Future<void> insertCustomSpSurveyDetailsSync(
      context, WidgetRef ref, data) async {
    String userMail = ref.watch(loginController).userMail;
    String wardId = ref.watch(deviceController).userSelectedWardid;
    if (_selectedSPMeter == 'Missing') {
      _selectedSpMake = '';
      _selectedSpPhase = '';
      _selectedSpMeterType = '';
      _selectedSpMeterNo = '';
    }
    if (Hive.isBoxOpen('surveyBox')) {
      await Hive.box('surveyBox').close();
    }
    final box = await Hive.openBox('surveyBox');
    _spSurveyDetails = SpSurveyModel(
        roadType: _selectedRoadType,
        trafficDensity: _selectedTrafficDensity,
        trafficSpeed: _selectedTrafficSpeed,
        assetType: "Switch Point",
        latitude: double.parse(data['slatitude']),
        longitude: double.parse(data['slongitude']),
        accuracy: data['accuracy'],
        altitude: 0,
        landmark: data['location'],
        spNo: _selectedSpNumber,
        spType: _selectedSwitchPointType,
        rrNo: _selectedSpRrNo,
        spTransformerNo: spTransformerNoController.text,
        spId: _selectedSpId,
        spMeter: _selectedSPMeter,
        spconnectedLoad: _selectedSpConnectedLoad,
        spMeterMake: _selectedSpMake,
        spMeterPhase: _selectedSpPhase,
        spMeterType: _selectedSpMeterType,
        spMeterNo: _selectedSpMeterNo,
        spCondition: _selectedSpCondition,
        spEarthingCondition: _selectedSpEarthingCondition,
        uuidFileName1: '',
        uuidFileName2: '',
        uuidFileName3: '',
        installedOn: DateTime.now().millisecondsSinceEpoch.toString(),
        installedBy: data['installedBy'],
        region: data['region'],
        zone: data['zoneName'],
        ward: data['wardName'],
        wardId: data['wardId'],
        customerId: data['customerId'],
        manualEnteredLocation: '',
        roadCategory: _selectedRoadCategory,
        roadWidth: _selectedRoadWidth,
        vehicleAccess: _selectedVehicleAccess,
        comments: "Captured while associating with panel",
        carrierName: _carrierName,
        signalStrengthLevel: _signalStrengthLevel);
    await box.add(_spSurveyDetails.toMap());
    log('custom survey details ${_spSurveyDetails.toMap()}');
    final hasInternet = ref.watch(internetStatusProvider);

    if (!hasInternet) {
      await incrementAssetCount('switchPoint', wardId, userMail);
    }
    clearAllUpdatedSelectedFields();
    BackgroundSyncWorkManager.triggerImmediateSync();
  }

  Future<void> insertTransSurveyDetails(context, WidgetRef ref) async {
    String userMail = ref.watch(loginController).userMail;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedWard = ref.watch(deviceController).selectedWard;
    String wardId = ref.watch(deviceController).userSelectedWardid;
    String selectedCustomerId = ref.watch(deviceController).selectedCustomerId;
    String selectedZone = ref.watch(deviceController).selectedZone;
    if (Hive.isBoxOpen('surveyBox')) {
      await Hive.box('surveyBox').close();
    }
    final box = await Hive.openBox('surveyBox');
    _transSurveyDetails = TransformerSurveyModel(
        roadType: _selectedRoadType,
        trafficDensity: _selectedTrafficDensity,
        trafficSpeed: _selectedTrafficSpeed,
        assetType: _selectedAssetType,
        latitude: double.parse(_fetchedLat == '' ? '0' : _fetchedLat),
        longitude: double.parse(_fetchedLong == '' ? '0' : _fetchedLong),
        accuracy: _fetchedAcc,
        altitude: double.parse(_fetchedAltitude == '' ? '0' : _fetchedAltitude),
        landmark: fetchedLandMark,
        uuidFileName1: _imageDetails.fileName1,
        uuidFileName2: _imageDetails.fileName2,
        uuidFileName3: _imageDetails.fileName3,
        installedOn: DateTime.now().millisecondsSinceEpoch.toString(),
        installedBy: userMail,
        region: selectedRegion,
        zone: selectedZone,
        ward: selectedWard,
        wardId: wardId,
        customerId: selectedCustomerId,
        manualEnteredLocation: _selectedManualEnteredLocation,
        roadCategory: _selectedRoadCategory,
        roadWidth: _selectedRoadWidth,
        vehicleAccess: _selectedVehicleAccess,
        comments: _selectedComments,
        carrierName: _carrierName,
        signalStrengthLevel: _signalStrengthLevel,
        transformerNo: _transNoController.text,
        transCapacity: _transCapacityController.text);
    await box.add(_transSurveyDetails.toMap());
    log('survey details ${_transSurveyDetails.toMap()}');

    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);
    await SimpleSyncService.enqueueTelemetry({"activityMode": storedMode});

    final hasInternet = ref.watch(internetStatusProvider);

    if (!hasInternet) {
      await incrementAssetCount('transformer', wardId, userMail);
    }
    clearAllUpdatedSelectedFields();
    await alertPopUp(
        context, 'Data Captured Successfully', 'assets/animation/tick.json');
    enableButton();
    BackgroundSyncWorkManager.triggerImmediateSync();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const PoleInstalltionHistoryInfo()),
        (route) => false);
  }

  Future<void> insertCapturedImages(BuildContext context, WidgetRef ref,
      List<XFile?> capturedImages, capturedIndexes) async {
    if (Hive.isBoxOpen('imagesBox')) {
      await Hive.box('imagesBox').close();
    }
    final box = await Hive.openBox('imagesBox');
    var uuid = const Uuid();
    try {
      String? filePath1 = '', filePath2 = '', filePath3 = '';
      String? fileName1 = '', fileName2 = '', fileName3 = '';

      if (capturedImages[0] != null) {
        final fileName = uuid.v1();
        fileName1 = capturedIndexes.contains(0)
            ? '$fileName.jpg'
            : _fetchedAuditImagesNames[0];
        filePath1 = await ImageCompressionUtil.compressAndSaveImage(
          originalImagePath: capturedImages[0]!.path,
          fileName: fileName1,
        );
        log('Image 1 compressed and saved to: $filePath1');
      }

      if (capturedImages[1] != null) {
        final fileName = uuid.v1();
        // fileName2 = '$fileName.jpg';
        fileName2 = capturedIndexes.contains(1)
            ? '$fileName.jpg'
            : _fetchedAuditImagesNames[1];
        filePath2 = await ImageCompressionUtil.compressAndSaveImage(
          originalImagePath: capturedImages[1]!.path,
          fileName: fileName2,
        );
        log('Image 2 compressed and saved to: $filePath2');
      }

      if (capturedImages[2] != null) {
        final fileName = uuid.v1();
        // fileName3 = '$fileName.jpg';
        fileName3 = capturedIndexes.contains(2)
            ? '$fileName.jpg'
            : _fetchedAuditImagesNames[2];
        filePath3 = await ImageCompressionUtil.compressAndSaveImage(
          originalImagePath: capturedImages[2]!.path,
          fileName: fileName3,
        );
        log('Image 3 compressed and saved to: $filePath3');
      }

      _imageDetails = MultiCapturedImageModel(
        fileName1: fileName1,
        filePath1: filePath1,
        isUploaded1: !capturedIndexes.contains(0),
        fileName2: fileName2,
        filePath2: filePath2,
        isUploaded2: !capturedIndexes.contains(1),
        fileName3: fileName3,
        filePath3: filePath3,
        isUploaded3: !capturedIndexes.contains(2),
      );

      await box.add(_imageDetails.toMap());
      log("Stored image filenames: ${_imageDetails.fileName1}, ${_imageDetails.fileName2}, ${_imageDetails.fileName3}");
      log("Stored image file paths: ${_imageDetails.filePath1}, ${_imageDetails.filePath2}, ${_imageDetails.filePath3}");
    } catch (e) {
      log('Error while saving images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving images.')),
      );
    }
  }

  onClickEventIsFor(val) {
    _clickEventIsFor = val;
    notifyListeners();
  }

  setIsResurvey(bool val) {
    _isResurvey = val;
    notifyListeners();
  }

  checkPermission() async {
    bool serviceEnabled;
    LocationPermission serviceEnb;
    serviceEnb = await Geolocator.checkPermission();
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    switch (serviceEnb) {
      case LocationPermission.denied:
        serviceEnb = await Geolocator.requestPermission();
        break;
      case LocationPermission.deniedForever:
        await appsettings.openAppSettings();
        break;
      case LocationPermission.whileInUse:
        null;
        break;
      case LocationPermission.always:
        null;
        break;
      case LocationPermission.unableToDetermine:
        null;
        break;
    }

    if (serviceEnb == LocationPermission.whileInUse ||
        serviceEnb == LocationPermission.always) {
      if (serviceEnabled) {
        fetchLocationForSurvey(); //modified
      }
    }
  }

  Future<String> getUserLocation(double? lat, double? long) async {
    if (lat == null || long == null) {
      log("Latitude or Longitude not provided.");
      return '';
    }

    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      try {
        var res = await _locationService.getGeocodingLocation(lat, long);
        log("Attempt $attempt response: $res");

        if (res['status'] == 200) {
          String formattedAddress = res['data']['formatted_address'] ?? '';
          log('Formatted Address: $formattedAddress');
          return formattedAddress;
        } else if (res == 401) {
          log('Session expired.');
          return '';
        } else {
          log('Invalid response: $res');
        }
      } catch (e) {
        log("Attempt $attempt failed with error: $e");
      }

      // Wait 2 seconds before retrying
      if (attempt < maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    log("All $maxRetries attempts failed. Returning empty address.");
    return '';
  }

  fetchLocationForSurvey() async {
    Position locationData;
    LocationPermission serviceEnb = await Geolocator.checkPermission();
    if (serviceEnb == LocationPermission.denied ||
        serviceEnb == LocationPermission.deniedForever) {
      checkPermission();
    }

    locationData = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
    );
    _fetchedAltitude = locationData.altitude.toStringAsFixed(4);
    _fetchedAcc = locationData.accuracy.toStringAsFixed(4);
    _fetchedLat = locationData.latitude.toString();
    _fetchedLong = locationData.longitude.toString();
    await Utility.isConnected().then((value) async {
      if (value) {
        _fetchedLandMark = await getUserLocation(
            double.parse(_fetchedLat), double.parse(_fetchedLong));
      } else {
        null;
      }
    });
    _isSurveyLocationFetched = true;
    notifyListeners();
    log("OUTPUT , fetchedAcc:${_fetchedAcc.toString()}, fetchedLat:${_fetchedLat.toString()}, fetchedLong:${_fetchedLong.toString()}");
    return [
      _fetchedAcc.toString(),
      _fetchedLat.toString(),
      _fetchedLong.toString(),
      _fetchedAltitude.toString(),
    ];
  }

  Future<void> fetchNetworkDetails() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    await Permission.locationWhenInUse.status;
    await ensurePermission(Permission.phone);

    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      _carrierName = 'wifi/Others';
      int? signalStrength =
          await FlutterInternetSignal().getWifiSignalStrength();
      _signalStrengthLevel = mapDbmToLevel(signalStrength ?? 0);

      log("Connected to Wifi");
      log("Carrier: $_carrierName");
      log("Mobile Signal Strength: $_signalStrengthLevel / 5");
    } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
      final carrierInfo = await CarrierInfo.getAndroidInfo();
      TelephonyInfo? activeSim;
      if (carrierInfo?.telephonyInfo != null) {
        try {
          activeSim = carrierInfo!.telephonyInfo.firstWhere(
            (sim) => sim.simState == 'SIM_STATE_READY',
          );
          _carrierName = activeSim.carrierName;
          log('carrierName : $_carrierName');
        } catch (e) {
          activeSim = null; // if no ready SIM
          _carrierName = activeSim?.carrierName ?? 'Unknown';
        }
      }

      int? signalStrength =
          await FlutterInternetSignal().getMobileSignalStrength();
      _signalStrengthLevel = mapDbmToLevel(signalStrength ?? 0);

      log("Connected to Mobile Data");
      log('telephony details : $carrierInfo');
      log("Mobile Signal Strength: $_signalStrengthLevel / 5");
    } else {
      log("No Internet Connection");
      _carrierName = 'offline';
      _signalStrengthLevel = 0;
    }
    notifyListeners();
  }

  int mapDbmToLevel(int dbm) {
    if (dbm >= -85) return 5;
    if (dbm >= -95) return 4;
    if (dbm >= -105) return 3;
    if (dbm >= -115) return 2;
    if (dbm >= -125) return 1;
    return 0;
  }

  Future<void> ensurePermission(Permission permission) async {
    while (true) {
      final status = await Permission.phone.request();

      if (status.isGranted) {
        break;
      } else if (status.isPermanentlyDenied) {
        log('${permission.toString()} permanently denied');
        await openAppSettings();
        break;
      } else {
        log('${permission.toString()} denied, asking again...');
      }
    }
  }

  Future<void> loadInternetStatus() async {
    final prefs = await SharedPreferences.getInstance();

    _hasInternet = prefs.getBool('hasInternet') ?? false;
    log('hasInternet loaded from prefs: $hasInternet');
    notifyListeners();
  }

  String generatePoleName({
    required String template,
    required String wardNo,
    required String poleNo,
    required String switchPointNo,
  }) {
    String result = template;
    // BBMP-SNL-<wardNo>-<poleNo>-<switchPoint/PanelNo>
    // Replace switchPoint first, and remove hyphen if it's empty
    if (switchPointNo.isEmpty) {
      result = result.replaceAll(RegExp(r'-?<switchPoint/PanelNo>'), '');
    } else {
      result = result.replaceAll('<switchPoint/PanelNo>', switchPointNo);
    }
    result =
        result.replaceAll('<wardNo>', wardNo).replaceAll('<poleNo>', poleNo);

    return result;
  }

  String extractPolePrefix(String template, String wardNumber) {
    final match = RegExp(r'^(.*?<wardNo>)').firstMatch(template);
    if (match != null) {
      final prefixTemplate = match.group(1)!; // e.g. BBMP-SNL-<wardNo>
      return '${prefixTemplate.replaceAll('<wardNo>', wardNumber)}-P';
    }
    return '';
  }

  void generatePolePrefixForSurvey(WidgetRef ref) {
    final poleNoTemplate = ref.watch(deviceController).selectedRegionPoleSchema;

    final match = RegExp(r'^(.*?<wardNo>)').firstMatch(poleNoTemplate);
    if (match != null) {
      final prefixTemplate = match.group(1)!; // e.g. BBMP-SNL-<wardNo>
      _surveyPolePrefix =
          '${prefixTemplate.replaceAll('<wardNo>', _wardNumberForPolePrefix)}-P';
    } else {
      _surveyPolePrefix = '';
    }
  }

  void disableButton() {
    _isButtonEnabled = false;
    notifyListeners();
  }

  void enableButton() {
    _isButtonEnabled = true;
    notifyListeners();
  }

  void extractWardValue(String wardString) {
    final parts = wardString.split('-');
    _wardNumberForPolePrefix = parts.isNotEmpty ? parts.last : '';
  }

  String padNumber(String input, int length) {
    if (input.isEmpty) return ''; // return empty if user didn't enter anything
    final number = int.tryParse(input) ?? 0;
    return number.toString().padLeft(length, '0');
  }

  Future<void> getWardAssetsName(String wardId) async {
    final response = await surveyService.fetchAssetsDetailsForWard(wardId);
    final box = await Utility.openHiveBox(assetNameBox);

    final switchPointNames = (response['switchPoint'] as List? ?? [])
        .map<String>((e) => (e as Map<String, dynamic>)['name'].toString())
        .toList();

    final transformerNames = (response['transformer'] as List? ?? [])
        .map<String>((e) => (e as Map<String, dynamic>)['name'].toString())
        .toList();

    await box.put('ward_$wardId', {
      'switchPoints': switchPointNames,
      'transformers': transformerNames,
    });

    // final wardData = box.get('ward_$wardId');
    // log('Hive data for ward_$wardId: $wardData');
  }

  /// Perform manual sync when user taps sync button
  Future<void> performManualSync() async {
    try {
      EasyLoading.show(status: 'Syncing data...');
      // await _syncManager.startBackgroundSync();
      EasyLoading.show(
          indicator:
              const Icon(Icons.upload_sharp, color: Colors.white, size: 45),
          status: 'Sync Initiated successfully!',
          maskType: EasyLoadingMaskType.clear,
          dismissOnTap: true);
      BackgroundSyncWorkManager.triggerImmediateSync();
      await Future.delayed(const Duration(seconds: 2));
      EasyLoading.dismiss();
      log('Manual sync completed successfully');
    } catch (e) {
      log('Manual sync failed: $e');
      EasyLoading.showError('Sync failed: ${e.toString()}');
    }
  }

  String get clickEventIsFor => _clickEventIsFor;
  bool get isButtonEnabled => _isButtonEnabled;
  String get wardNumberForPolePrefix => _wardNumberForPolePrefix;
  String get selectedRoadType => _selectedRoadType;
  String get selectedAssetType => _selectedAssetType;
  String get selectedPoleType => _selectedPoleType;
  String get selectedPoleHeight => _selectedPoleHeight;
  String get selectedPoleSpan => _selectedPoleSpan;
  String get selectedPoleCondition => _selectedPoleCondition;
  String get selectedConnectionType => _selectedConnectionType;
  String get selectedArmCondition => _selectedArmCondition;
  String get selectedArmCount => _selectedArmCount;
  String get selectedArmLength => _selectedArmLength;
  String get selectedRoadCategory => _selectedRoadCategory;
  String get selectedRoadWidth => _selectedRoadWidth;
  String get selectedVehicleAccess => _selectedVehicleAccess;
  String get selectedIncomingTransType => _selectedIncomingTransType;
  String get selectedIncomingTransLine => _selectedIncomingTransLine;
  String get selectedLampType => _selectedLampType;
  String get selectedLampWatts => _selectedLampWatts;
  List<Map<String, String>> get selectedLamps => _selectedLamps;
  // bool get isClampRequired => _isClampRequired;
  bool get isBracketRequired => _isBracketRequired;
  bool get isEarthingRequired => _isEarthingRequired;
  bool get isControlWireStatus => _isControlWireStatus;
  String get selectedManualSwitchCtrl => _selectedManualSwitchCtrl;
  String get fetchedAcc => _fetchedAcc;
  String get fetchedAltitude => _fetchedAltitude;
  String get fetchedLandMark => _fetchedLandMark;
  String get fetchedLat => _fetchedLat;
  String get fetchedLong => _fetchedLong;
  String get selectedTrafficSpeed => _selectedTrafficSpeed;
  String get selectedTrafficDensity => _selectedTrafficDensity;
  String get selectedPoleNumber => _selectedPoleNumber;
  String get selectedSwitchPointNo => _selectedSwitchPointNo;

  bool get isSwitchPointFromDropdown => _isSwitchPointFromDropdown;

  set isSwitchPointFromDropdown(bool value) {
    _isSwitchPointFromDropdown = value;
  }

  List get customSwitchPointNo => _customSwitchPointNo;
  List<String> get multiSwitchPointNo => _multiSwitchPointNo;
  bool get isSpEarthingAvailable => _isSpEarthingAvailable;
  String get spEarthingReason => _spEarthingReason;
  String get selectedBracketMountingHeight => _selectedBracketMountingHeight;
  String get selectedCustomBracketHeight => _selectedCustomBracketHeight;
  String get selectedClampType => _selectedClampType;
  String get selectedClampLength => _selectedClampLength;
  String get selectedClampWidth => _selectedClampWidth;
  String get selectedClampUnits => _selectedClampUnits;
  TextEditingController get poleMotorMakeController => _poleMotorMakeController;
  TextEditingController get spTransformerNoController =>
      _spTransformerNoController;
  TextEditingController get poleTransformerNoController =>
      _poleTransformerNoController;
  TextEditingController get poleMotorRatingController =>
      _poleMotorRatingController;
  TextEditingController get poleMotorModelController =>
      _poleMotorModelController;
  String get selectedPoleMotorCondition => _selectedPoleMotorCondition;
  String get selectedPoleWinchCondition => _selectedPoleWinchCondition;
  String get selectedPoleRopeCondition => _selectedPoleRopeCondition;
  String get selectedPoleRatingUnits => _selectedPoleRatingUnits;
  bool get isSurveyLocationFetched => _isSurveyLocationFetched;
  TextEditingController get workingTextController => _workingTextController;
  TextEditingController get goodArmTextController => _goodArmTextController;
  TextEditingController get badArmTextController => _badArmTextController;
  TextEditingController get missingArmTextController =>
      _missingArmTextController;
  TextEditingController get clampTypeLengthController =>
      _clampTypeLengthController;
  TextEditingController get clampTypeWidthController =>
      _clampTypeWidthController;

  TextEditingController get notWorkingTextController =>
      _notWorkingTextController;
  TextEditingController get missingTextController => _missingTextController;
  TextEditingController get poleNumberController => _poleNumberController;
  TextEditingController get exCorpPoleNoController => _exCorpPoleNoController;
  TextEditingController get ebPoleNoController => _ebPoleNoController;
  TextEditingController get switchPointController => _switchPointController;
  TextEditingController get commentsController => _commentsController;
  int get signalStrengthLevel => _signalStrengthLevel;
  bool get hasInternet => _hasInternet;
  String get carrierName => _carrierName;
  TextEditingController get surveyManualLocationEntry =>
      _surveyManualLocationEntry;

  String get selectedSwitchPointType => _selectedSwitchPointType;
  String get selectedSPMeter => _selectedSPMeter;
  String get selectedSpEarthingCondition => _selectedSpEarthingCondition;
  String get selectedSpCondition => _selectedSpCondition;
  String get selectedSpMeterType => _selectedSpMeterType;
  String get selectedSpPhase => _selectedSpPhase;
  String get selectedSpMake => _selectedSpMake;
  TextEditingController get switchPointNumberController =>
      _switchPointNumberController;
  TextEditingController get rrNumberController => _rrNumberController;
  TextEditingController get spMeterNoController => _spMeterNoController;
  TextEditingController get spMakeController => _spMakeController;
  TextEditingController get spConnectedLoadController =>
      _spConnectedLoadController;
  TextEditingController get switchPointIdController => _switchPointIdController;

  TextEditingController get transNoController => _transNoController;
  TextEditingController get transCapacityController => _transCapacityController;
  String get surveyPolePrefix => _surveyPolePrefix;
  bool get isBracketMountingEditable => _isBracketMountingEditable;
  bool get isResurvey => _isResurvey;
  List<XFile?> get fetchedCapturedImages => _fetchedCapturedImages;
  List<String> get fetchedAuditImagesNames => _fetchedAuditImagesNames;

  @override
  void dispose() {
    // Dispose all TextEditingControllers managed by this provider
    try {
      _clampTypeLengthController.dispose();
    } catch (_) {}
    try {
      _clampTypeWidthController.dispose();
    } catch (_) {}
    try {
      _goodArmTextController.dispose();
    } catch (_) {}
    try {
      _badArmTextController.dispose();
    } catch (_) {}
    try {
      _missingArmTextController.dispose();
    } catch (_) {}
    try {
      _workingTextController.dispose();
    } catch (_) {}
    try {
      _notWorkingTextController.dispose();
    } catch (_) {}
    try {
      _missingTextController.dispose();
    } catch (_) {}
    try {
      _poleNumberController.dispose();
    } catch (_) {}
    try {
      _exCorpPoleNoController.dispose();
    } catch (_) {}
    try {
      _switchPointController.dispose();
    } catch (_) {}
    try {
      _switchPointNumberController.dispose();
    } catch (_) {}
    try {
      _commentsController.dispose();
    } catch (_) {}
    try {
      _surveyManualLocationEntry.dispose();
    } catch (_) {}
    try {
      _rrNumberController.dispose();
    } catch (_) {}
    try {
      _spMeterNoController.dispose();
    } catch (_) {}
    try {
      _spMakeController.dispose();
    } catch (_) {}
    try {
      _spConnectedLoadController.dispose();
    } catch (_) {}
    try {
      _switchPointIdController.dispose();
    } catch (_) {}
    try {
      _transNoController.dispose();
    } catch (_) {}
    try {
      _transCapacityController.dispose();
    } catch (_) {}
    try {
      _poleMotorMakeController.dispose();
    } catch (_) {}
    try {
      _poleMotorModelController.dispose();
    } catch (_) {}
    try {
      _poleMotorRatingController.dispose();
    } catch (_) {}

    super.dispose();
  }
}
