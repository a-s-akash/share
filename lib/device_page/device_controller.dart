import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:schnell_luminator/attendence_tracking.dart/user_tracking_controller.dart';
import 'package:schnell_luminator/device_page/gw/panel_actions_controller.dart';
import 'package:schnell_luminator/device_page/lamp/lamp_controller.dart';
import 'package:schnell_luminator/device_page/lamp/lamp_details_page.dart';
import 'package:schnell_luminator/device_page/lamp/lamp_scan_page.dart';
import 'package:schnell_luminator/device_page/pole/pole_page.dart';
import 'package:schnell_luminator/home_page/map_controller.dart';
import 'package:schnell_luminator/location_selection/location_controller.dart';
import 'package:schnell_luminator/qr_scan_online.dart';
import 'package:schnell_luminator/survey/survey_controller.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:schnell_luminator/utils/session.dart';
import 'package:schnell_luminator/utils/utility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:schnell_luminator/device_page/gw/gw_maintenance1.dart';
import 'package:schnell_luminator/device_page/ilm/maintenance1.dart';
import 'package:schnell_luminator/home_page/dashboard.dart';
import 'package:schnell_luminator/utils/constants.dart';
import '../location_selection/ward_list.dart';
import '../login_page/login_controller.dart';
import '../pole_install.dart/pole_controller.dart';
import '../s3_bucket/s3_upload_service.dart';
import '../ticket_notification/ticket_controller.dart';
import '../ticket_notification/ticket_list_page.dart';
import '../utils/asset_folder.dart';
import '../utils/dialog_box.dart';
import '../utils/secure_storage.dart';
import 'device_service.dart';
import 'ilm/scantest.dart';
import 'switchPoint_selection_screen.dart';
import 'take_photo.dart';
import 'telemetry_service.dart';

final deviceController =
    ChangeNotifierProvider<DeviceProvider>((ref) => DeviceProvider());

final isSecondTime = StateProvider<bool>((ref) => false);

class DeviceProvider extends ChangeNotifier {
  final DeviceService _service = DeviceService();
  final S3UploadService _s3Service = S3UploadService();
  final TelemetryService _telemetryService = TelemetryService();

  List _deviceSearchList = [];
  List _poleSearchList = [];
  List _spSearchList = [];
  List _transSearchList = [];
  int _firstOrSecondDevice = 0;
  String _clickEventIsFor = "1";
  // String _commStatusForPanel = '';
  // String _relayStatusForPanel = '';
  // bool _isMcbTripPanel = false;
  String _lampOrILMScanForReplace = "lamp";
  bool isJson = false;
  String _selectedWard = '';
  String _selectedWardId = '';
  String _selectedZone = '';
  String _selectedZoneId = '';
  String _selectedRegion = '';
  String _selectedRegionId = '';
  String _selectedRegionPoleSchema = '';
  String _selectedCustomer = '';
  String _userSelectedWardid = '';
  String _deviceOrAssetWardId = '';
  String _selectedContextId = '';

  String _selectedCustomerId = '';
  String _deviceType = '';
  String _manualEnteredLocation = '';
  String _newMeterReadingValue = '';
  String _oldMeterReadingValue = '';
  bool _isButtonEnabled = true;
  String _userSelectedDeviceOrAssetName = "";
  String _fetchedLat = '';
  String _fetchedLong = '';
  String _fetchedAcc = '';
  final String _devicePath = "";
  String _hubId = "";
  String _ccmsInstallBy = "";
  String _hubInstallBy = "";

  List _firstDevice = [];
  String _firstDeviceName = '';
  String _firstDevicecurrentState = '';
  String _lightpointState = '';
  String _lpType = '';

  String _firstDeviceCurrentCondition = '';
  String _firstDeviceType = '';
  String _firstDeviceWardName = '';
  final String _firstDeviceWardId = '';
  String _firstDeviceZoneName = '';
  String _firstDeviceRegionName = '';
  String _lpregion = '';
  String _lpward = '';
  String _lpzone = '';
  final int _lplastCommunicatedStatus = 0;

  bool _isFirstDeviceGotRelation = false;
  String _firstDeviceId = '';
  String _fisrDevicelandmark = '';
  String _ccmsLandmark = '';
  String _lpLandmark = '';
  String _ccmsregion = '';
  String _ccmsward = '';
  String _ccmszone = '';
  String _ccmsAcc = '';
  String _ccmsLat = '';
  String _ccmsLong = '';
  String _lpInstallBy = '';
  String _lpLat = '';
  String _lpLong = '';
  String _lpAccuracy = '';
  String _lampInstallBy = '';
  String _firstDeviceInstallBy = '';
  final int _ccmslastCommunicatedStatus = 0;
  final int _hublastCommunicatedStatus = 0;

  String _ccmsState = '';
  String _ebMeterNo = '';
  String _newEbMeterNo = '';
  String _ebMeterPhase = '';
  String _ebMeterReadingOffset = '';
  int _ebMeterReplacedOn = 0;
  String _ebMeterReplacedBy = '';
  int _ccmsInstalledOn = 0;
  final String _gwAssetName = '';
  final int _gplastCommunicatedStatus = 0;
  final int _gwInstalledOn = 0;
  final String _gwState = '';

  int _firstDevicelastCommunicatedStatus = 0;
  String _firstDeviceLampWatts = '';
  String _firstDeviceAccuracy = '';
  String _firstDeviceCustomerId = '';
  final String _createdTime = '';
  String _lampAssets = '';
  String _lampWard = '';

  String _lampName = '';
  String _lampId = '';
  String _lampManufacturer = '';
  String _lampDimmable = '';
  String _lampTypeSignify = '';
  String _lampYear = '';
  String _lampState = '';
  String _lampAssetType = '';
  String _lampAssetsId = '';
  String _hubName = '';
  String _assetType = "";
  String _hubLandmark = '';
  String _hubState = '';
  String _hubregion = '';
  String _hubward = '';
  String _hubzone = '';
  String _hubAcc = '';
  String _hubLat = '';
  String _hubLong = '';
  int _hubInstalledOn = 0;
  String _ccmsAssetsId = '';
  String _ccmsAssetName = '';
  String _firstDeviceTypewithChr = '';

  int _lmpInstalledOn = 0;
  String _lampWatts = "";
  int _deviceInstalledOn = 0;
  int _lightpointInstalledOn = 0;
  bool _isTestBench = false;

  String _newLmpName = '';
  String _finalNewLmpName = '';
  String _newLmpYear = '';
  String _newManufacturer = '';
  String _newDimmable = '';
  String _newLmpWattage = '';
  String _newLmpType = '';
  int _newLampCount = 0;
  List _lampHistoryData = [];
  int _lampSpecificUserCount = 0;
  List<dynamic> _recommendedWattage = [];
  String _poleSpNo = '';
  bool _isValidSp = false;
  String _poleTransformerNo = '';
  String _newRoadCategory = '';
  String _poleRoadType = '';
  String _incomingTransmissionLine = '';

  String _poleName = '';
  String _poleId = '';
  String _poleType = '';
  String _poleLocation = '';
  List<dynamic> _lampProfiles = [];
  String _poleLat = '';
  String _poleLong = '';
  String _poleWardName = '';
  String _poleZoneName = '';
  String _poleRegion = '';
  String _poleState = '';
  int _poleInstalledOn = 0;
  String _poleInstalledBy = '';
  String _poleAccuracy = '';
  final String _poleClampDimension = '';
  String _lampConnection = '';
  int _armCount = 0;
  String _poleSubtype = '';
  List _lampNamesInRelation = [];
  List _lampLightPointIdInRelation = [];
  String _lampLightPointId = '';

  // bool _toggleButton = true;
  List _ilmNamesInRelation = [];

  // String _lampLabel = '';
  // String _ilmLabel = '';

  List _secondDevice = [];
  String _secondDeviceName = '';
  String _secondDeviceCurrentState = '';
  String _secondDeviceCurrentCondition = '';
  String _secondDeviceType = '';
  String _secondDeviceWardName = '';
  bool _isSecondDeviceGotRelation = false;
  bool _isSecondLampGotRelation = false;
  bool _isLocationFetched = false;
  String _secondLampName = '';
  String _finalSecondLampName = '';
  String _secondLampWard = '';
  String _secondLampId = '';
  String _secondLampAssetType = '';
  String _secondLampWatts = '';
  String _secondLampManufacturer = '';
  String _secondLampTypeSignify = '';
  String _secondLampYear = '';
  String _secondLampDimmable = '';
  String _auditImg = '';
  String deviceNameForImgAppend = '';
  late File mapIconPath;
  String _selectedRegionDesc = '';
  String _selectedZoneDesc = '';
  String _selectedWardDesc = '';

  String _smslcAssetId = '';
  String _smslcAssetName = '';
  String _smslcLandmark = '';
  String _smslcInstallBy = '';
  String _smslcregion = '';
  String _smslcward = '';
  String _smslczone = '';
  String _smslcAcc = '';
  String _smslcLong = '';
  String _smslcLat = '';

  String _smslcState = '';
  int _smslcInstalledOn = 0;

  int _deviceSearchPage = 0;
  bool _hasMoreDeviceSearch = true;
  bool _isDeviceSearchLoadingMore = false;
  String _lastSearchQuery = '';

  int get deviceSearchPage => _deviceSearchPage;
  bool get hasMoreDeviceSearch => _hasMoreDeviceSearch;
  bool get isDeviceSearchLoadingMore => _isDeviceSearchLoadingMore;
  String get lastSearchQuery => _lastSearchQuery;

  void toggleDeviceSearchLoadingMore(bool val) {
    _isDeviceSearchLoadingMore = val;
    notifyListeners();
  }

  // void addWattage(recommendedWattage) {
  //   _recommendedWattage = recommendedWattage;
  //   notifyListeners();
  // }

  void addFirstDevice(device, clickEventIsFor) async {
    _firstDevice = [];
    _clickEventIsFor = clickEventIsFor;

    if (clickeventIsFor != 'addILM' &&
        clickEventIsFor != 'addLampInMaintenance') {
      _deviceOrAssetWardId = '';
    }

    if (clickEventIsFor != "scanLampViaILM" &&
        clickEventIsFor != 'addLampInMaintenance') {
      _firstDeviceName = "";
      _firstDeviceId = "";
      _firstDeviceAccuracy = "";
      _firstDevicecurrentState = "";
      _firstDeviceCurrentCondition = "";
      _firstDeviceWardName = "";
      _firstDeviceZoneName = "";
      _firstDeviceRegionName = "";
      _firstDeviceCustomerId = "";
      _firstDeviceType = "";
      _isFirstDeviceGotRelation = false;
    }
    _deviceType = "";

    _isTestBench = false;

    if (clickEventIsFor != "scanLampViaILM" &&
        clickEventIsFor != "addILM" &&
        clickEventIsFor != 'addLamp' &&
        clickEventIsFor != "addILMViaPole" &&
        clickEventIsFor != 'addLampInMaintenance') {
      _poleName = '';
      _poleId = '';
      _poleType = '';
      _poleAccuracy = '';
      _poleLat = '';
      _poleLong = '';
      _poleLocation = '';
      _lampProfiles = [];
      _poleWardName = '';
      _poleZoneName = '';
      _poleRegion = '';
      _poleState = '';
      _lampConnection = '';
      _poleSubtype = '';
    }

    if (clickEventIsFor != "addILM" && clickEventIsFor != "addILMViaPole") {
      if (clickEventIsFor != 'addLampInMaintenance') {
        _lampAssetsId = "";
        _lampAssets = "";
        _lightpointState = "";
        _lpregion = "";
        _lpward = "";
        _lpzone = "";
        _lpLat = "";
        _lpLong = "";
        _lpLandmark = '';
        _lpType = '';
      }

      _lampName = "";
      _lampId = "";
      _lampAssetType = "";
      _lampWatts = "";
      _lampManufacturer = "";
      _lampTypeSignify = "";
      _lampYear = "";
      _lampDimmable = "";
      _lampWard = "";

      _ccmsAssetsId = "";
      _ccmsAssetName = "";
      _ccmsregion = "";
      _ebMeterNo = "";
      _ebMeterPhase = "";
      _ebMeterReadingOffset = "";
      _ebMeterReplacedOn = 0;
      _ebMeterReplacedBy = '';
      _ccmsInstalledOn = 0;
      _ccmsward = "";
      _ccmszone = "";
      _ccmsLandmark = "";
      _ccmsAcc = '';
      _ccmsLat = '';
      _ccmsLong = '';
      _ccmsState = "";
      _ccmsInstallBy = "";

      _assetType = "";
      _hubInstallBy = "";
      _hubInstalledOn = 0;
      _hubId = "";
      _hubState = "";

      _smslcAssetId = "";
      _smslcAssetName = "";
      _smslcLandmark = "";
      _smslcInstallBy = "";
      _smslcregion = "";
      _smslcward = "";
      _smslczone = "";
      _smslcAcc = "";
      _smslcLong = "";
      _smslcLat = "";
      _smslcState = '';
      _smslcInstalledOn = 0;
    }
    var devicePath;

    _firstDevice.add(device);

    checkDeviceGotRelation();

    if (_firstDevice[0]['deviceDetails'][0].containsKey("ilm")) {
      devicePath = _firstDevice[0]['deviceDetails'][0]['ilm'];
      _deviceType = "luminar";
    } else if (_firstDevice[0]['deviceDetails'][0].containsKey("gw")) {
      devicePath = _firstDevice[0]['deviceDetails'][0]['gw'];
      _deviceType = "gateway";
    } else if (_firstDevice[0]['deviceDetails'][0].containsKey("pole")) {
      devicePath = _firstDevice[0]['deviceDetails'][0]['pole'];
    } else if (_firstDevice[0]['deviceDetails'][0].containsKey("semc")) {
      devicePath = _firstDevice[0]['deviceDetails'][0]['semc'];
    }
//ilm
    if (devicePath == _firstDevice[0]['deviceDetails'][0]['ilm']) {
      if (_firstDevice[0]['deviceDetails'][0]['ilm'].isNotEmpty &&
          clickEventIsFor != "scanLampViaILM" &&
          clickEventIsFor != 'addLampInMaintenance') {
        _firstDeviceTypewithChr = devicePath['type'] ?? "";
        _firstDeviceType = _firstDeviceTypewithChr.isNotEmpty
            ? _firstDeviceTypewithChr.toString().toUpperCase()
            : "";
      }
      if (_firstDeviceType.isNotEmpty) {
        if (_firstDeviceType == 'ILM' ||
            _firstDeviceType == 'LUMINODE' ||
            _firstDeviceType == 'ILM-4G') {
          _firstDeviceType = 'ILM';
        } else if (_firstDeviceType == 'GW' || _firstDeviceType == 'CCMS') {
          _firstDeviceType = 'GW';
        }
      }
      if (_firstDeviceType == 'ILM') {
        _fisrDevicelandmark = devicePath['landmark'] ?? "";
      } else if (_firstDeviceType == 'GW') {
        _fisrDevicelandmark = devicePath['location'] ?? "";
      }

      if (_firstDevice[0]['deviceDetails'][0]['ilm'].isNotEmpty &&
          clickEventIsFor != "scanLampViaILM") {
        //clickEventIsFor != 6 is considered in the scenario ilm installation with scan a lamp, if the lamp is already installed or removed, the ilm, pole, lp details must not be added and caches must not be cleared, only lamp details have to be added.
        _firstDeviceName = devicePath['name'] ?? "";

        _firstDeviceId = devicePath['id'] ?? "";
        String deviceCommTime = devicePath['lastActivityTime'].toString();
        _firstDevicelastCommunicatedStatus =
            deviceCommTime == '' ? 0 : int.parse(deviceCommTime);
        _firstDeviceLampWatts = devicePath['lampWatts'] ?? "";
        _firstDeviceAccuracy = devicePath['accuracy'] ?? "";
        _firstDevicecurrentState = devicePath['state'].toString().isNotEmpty
            ? devicePath['state'].toString().toUpperCase()
            : "";
        _firstDeviceCurrentCondition =
            devicePath['condition'].toString().isNotEmpty
                ? devicePath['condition'].toString().toUpperCase()
                : "";
        _firstDeviceWardName = devicePath['wardName'] ?? "";

        _firstDeviceZoneName = devicePath['zoneName'] ?? "";
        _firstDeviceRegionName = devicePath['region'] ?? "";
        _firstDeviceInstallBy = devicePath['installedBy'] ?? "";

        String deviceinstalledTime = devicePath['installedOn'] ?? "".toString();
        _deviceInstalledOn =
            deviceinstalledTime == "" ? 0 : int.parse(deviceinstalledTime);
      }

      _firstDeviceCustomerId = _firstDevice[0]['customer']['id'] ?? "";

      //lightpoint
      if (_firstDevice[0]['deviceDetails'][0]['lightPoint'].isNotEmpty &&
          !_isTestBench) {
        if (clickEventIsFor != "addILM" &&
            clickEventIsFor != "addILMViaPole" &&
            clickEventIsFor != 'addLampInMaintenance') {
          _lampAssetsId =
              _firstDevice[0]['deviceDetails'][0]['lightPoint']['id'] ?? "";
        }
        _lampAssets =
            _firstDevice[0]['deviceDetails'][0]['lightPoint']['name'] ?? "";
        _lightpointState =
            _firstDevice[0]['deviceDetails'][0]['lightPoint']['state'] ?? "";
        _lpType =
            _firstDevice[0]['deviceDetails'][0]['lightPoint']['type'] ?? "";
        String lpinstalledTime = _firstDevice[0]['deviceDetails'][0]
                ['lightPoint']['installedOn']
            .toString();

        _lightpointInstalledOn =
            lpinstalledTime == '' ? 0 : int.parse(lpinstalledTime);
        if (clickEventIsFor != "addILM") {
          _lpLat = _firstDevice[0]['deviceDetails'][0]['lightPoint']
                  ['latitude'] ??
              "";
          _lpLong = _firstDevice[0]['deviceDetails'][0]['lightPoint']
                  ['longitude'] ??
              "";
          _lpAccuracy = _firstDevice[0]['deviceDetails'][0]['lightPoint']
                  ['accuracy'] ??
              "";
          _lpLandmark = _firstDevice[0]['deviceDetails'][0]['lightPoint']
                  ['landmark'] ??
              "";
        }
        _lpregion =
            _firstDevice[0]['deviceDetails'][0]['lightPoint']['region'] ?? "";
        _lpward =
            _firstDevice[0]['deviceDetails'][0]['lightPoint']['wardName'] ?? "";
        _lpzone =
            _firstDevice[0]['deviceDetails'][0]['lightPoint']['zoneName'] ?? "";
        _lpInstallBy = _firstDevice[0]['deviceDetails'][0]['lightPoint']
                ['installedBy'] ??
            "";
      }

      //lamp
      if (_firstDevice[0]['deviceDetails'][0]['lamp'].isNotEmpty &&
          clickEventIsFor != "addILM" &&
          clickEventIsFor != "addILMViaPole") {
        _lampName =
            _firstDevice[0]['deviceDetails'][0]['lamp']['name'].toString();
        _lampId = _firstDevice[0]['deviceDetails'][0]['lamp']['id'].toString();
        _lampAssetType = _firstDevice[0]['deviceDetails'][0]['lamp']['type']
                .toString()
                .isNotEmpty
            ? _firstDevice[0]['deviceDetails'][0]['lamp']['type']
                .toString()
                .toUpperCase()
            : "";
        _lampWatts =
            _firstDevice[0]['deviceDetails'][0]['lamp']['lampWatts'] ?? "";
        _lampManufacturer =
            _firstDevice[0]['deviceDetails'][0]['lamp']['manufacturer'] ?? "";
        _lampTypeSignify =
            _firstDevice[0]['deviceDetails'][0]['lamp']['lampType'] ?? "";
        _lampYear = _firstDevice[0]['deviceDetails'][0]['lamp']['year'] ?? "";
        _lampDimmable =
            _firstDevice[0]['deviceDetails'][0]['lamp']['dimmable'] ?? "";
        _lampState = _firstDevice[0]['deviceDetails'][0]['lamp']['state'] ?? "";

        _lampWard =
            _firstDevice[0]['deviceDetails'][0]['lamp']['wardName'] ?? "";
        String lmpinstalledTime = _firstDevice[0]['deviceDetails'][0]['lamp']
                ['installedOn']
            .toString();
        _lmpInstalledOn =
            lmpinstalledTime == '' ? 0 : int.parse(lmpinstalledTime);
        _lampInstallBy =
            _firstDevice[0]['deviceDetails'][0]['lamp']['installedBy'] ?? "";
      }
    }
//gateway
    if (devicePath == _firstDevice[0]['deviceDetails'][0]['gw'] &&
        clickEventIsFor != "addILM" &&
        clickEventIsFor != "addILMViaPole") {
      //ccms

      if (_firstDevice[0]['deviceDetails'][0].containsKey("ccms")) {
        _ccmsAssetsId = _firstDevice[0]['deviceDetails'][0]['ccms']['id'] ?? "";
        _assetType = _firstDevice[0]['deviceDetails'][0].keys.last;
        _ccmsAssetName =
            _firstDevice[0]['deviceDetails'][0]['ccms']['name'] ?? "";
        _ccmsLandmark =
            _firstDevice[0]['deviceDetails'][0]['ccms']['location'] ?? "";
        _ccmsInstallBy =
            _firstDevice[0]['deviceDetails'][0]['ccms']['installedBy'] ?? "";
        _ccmsregion =
            _firstDevice[0]['deviceDetails'][0]['ccms']['region'] ?? "";
        _ccmsward =
            _firstDevice[0]['deviceDetails'][0]['ccms']['wardName'] ?? "";
        _ccmszone =
            _firstDevice[0]['deviceDetails'][0]['ccms']['zoneName'] ?? "";
        _ccmsAcc =
            _firstDevice[0]['deviceDetails'][0]['ccms']['accuracy'] ?? "";
        _ccmsLong =
            _firstDevice[0]['deviceDetails'][0]['ccms']['slongitude'] ?? "";
        _ccmsLat =
            _firstDevice[0]['deviceDetails'][0]['ccms']['slatitude'] ?? "";
        _ccmsState = _firstDevice[0]['deviceDetails'][0]['ccms']['state']
            .toString()
            .toUpperCase();

        String ccmsinstalledTime = _firstDevice[0]['deviceDetails'][0]['ccms']
                ['installedOn']
            .toString();
        _ccmsInstalledOn =
            ccmsinstalledTime == '' ? 0 : int.parse(ccmsinstalledTime);
        _ebMeterNo = _firstDevice[0]['deviceDetails'][0]['ccms']['ebMeter']
                ['name'] ??
            "";
        _ebMeterPhase =
            _firstDevice[0]['deviceDetails'][0]['ccms']['phase'] ?? "";
        _ebMeterReadingOffset = _firstDevice[0]['deviceDetails'][0]['ccms']
                ['meterReadingOffset'] ??
            "";
        String ebMeterReplacedTime = _firstDevice[0]['deviceDetails'][0]['ccms']
                ['ebMeter']['replacedOn']
            .toString();
        _ebMeterReplacedOn =
            ebMeterReplacedTime == '' ? 0 : int.parse(ebMeterReplacedTime);
        _ebMeterReplacedBy = _firstDevice[0]['deviceDetails'][0]['ccms']
                ['ebMeter']['replacedBy'] ??
            "";
      }
      _firstDeviceCustomerId = _firstDevice[0]['customer']['id'] ?? "";
      //hub
      if (_firstDevice[0]['deviceDetails'][0].containsKey("hub") &&
          clickEventIsFor != "addILM") {
        if (_firstDevice[0]['deviceDetails'][0]['hub'].toString() != "") {
          _hubId = _firstDevice[0]['deviceDetails'][0]['hub']['id'] ?? "";
          _assetType = _firstDevice[0]["deviceDetails"][0].keys.last;
          _hubName = _firstDevice[0]['deviceDetails'][0]['hub']['name'] ?? "";
          _hubLandmark =
              _firstDevice[0]['deviceDetails'][0]['hub']['location'] ?? "";
          _hubState = _firstDevice[0]['deviceDetails'][0]['hub']['state'] ?? "";
          String hubinstalledTime = _firstDevice[0]['deviceDetails'][0]['hub']
                  ['installedOn']
              .toString();
          _hubInstallBy =
              _firstDevice[0]['deviceDetails'][0]['hub']['installedBy'] ?? "";

          _hubInstalledOn =
              hubinstalledTime == '' ? 0 : int.parse(hubinstalledTime);
          _hubregion =
              _firstDevice[0]['deviceDetails'][0]['hub']['region'] ?? "";
          _hubward =
              _firstDevice[0]['deviceDetails'][0]['hub']['wardName'] ?? "";
          _hubzone =
              _firstDevice[0]['deviceDetails'][0]['hub']['zoneName'] ?? "";
          _hubAcc =
              _firstDevice[0]['deviceDetails'][0]['hub']['accuracy'] ?? "";
          _hubLong =
              _firstDevice[0]['deviceDetails'][0]['hub']['slongitude'] ?? "";
          _hubLat =
              _firstDevice[0]['deviceDetails'][0]['hub']['slatitude'] ?? "";
        }
      }
      //gw
      if (_firstDevice[0]['deviceDetails'][0]['gw'].isNotEmpty &&
          clickEventIsFor != "addILM" &&
          clickEventIsFor != 'addLampInMaintenance') {
        if (_firstDevice[0]['deviceDetails'][0]['gw'].toString() != "") {
          _firstDeviceTypewithChr = devicePath['type'];
          _firstDeviceType = devicePath['type'].toString().isNotEmpty
              ? devicePath['type'].toString().toUpperCase()
              : "";
          if (_firstDeviceType.isNotEmpty) {
            if (_firstDeviceType == 'ILM' ||
                _firstDeviceType == 'LUMINODE' ||
                _firstDeviceType == 'ILM-4G') {
              _firstDeviceType = 'ILM';
            } else if (_firstDeviceType == 'GW' || _firstDeviceType == 'CCMS') {
              _firstDeviceType = 'GW';
            }
          }

          _firstDeviceName =
              _firstDevice[0]['deviceDetails'][0]['gw']['name'] ?? "";

          _firstDeviceId = devicePath['id'] ?? "";
          _firstDevicecurrentState =
              _firstDevice[0]['deviceDetails'][0]['gw']['state'] ?? "";
          String gpCommTime = _firstDevice[0]['deviceDetails'][0]['gw']
                  ['lastActivityTime']
              .toString();
          _firstDevicelastCommunicatedStatus =
              gpCommTime == '' ? 0 : int.parse(gpCommTime);
          _firstDeviceWardName = devicePath['wardName'] ?? "";
          _firstDeviceRegionName = devicePath['region'] ?? "";

          _firstDeviceZoneName = devicePath['zoneName'] ?? "";
          _firstDeviceInstallBy = devicePath['installedBy'] ?? "";
          _firstDeviceCurrentCondition =
              devicePath['condition'].toString().isNotEmpty
                  ? devicePath['condition'].toString().toUpperCase()
                  : "";
          String gwinstalledTime = _firstDevice[0]['deviceDetails'][0]['gw']
                  ['installedOn']
              .toString();
          _deviceInstalledOn =
              gwinstalledTime == '' ? 0 : int.parse(gwinstalledTime);
        }
      }
    }

//SEMC
    if (devicePath == _firstDevice[0]['deviceDetails'][0]['semc'] &&
        clickEventIsFor != "addILM" &&
        clickEventIsFor != "addILMViaPole") {
      if (_firstDevice[0]['deviceDetails'][0].containsKey("smslc")) {
        _smslcAssetId =
            _firstDevice[0]['deviceDetails'][0]['smslc']['id'] ?? "";
        _assetType = _firstDevice[0]['deviceDetails'][0].keys.last;
        _smslcAssetName =
            _firstDevice[0]['deviceDetails'][0]['smslc']['name'] ?? "";
        _smslcLandmark =
            _firstDevice[0]['deviceDetails'][0]['smslc']['location'] ?? "";
        _smslcInstallBy =
            _firstDevice[0]['deviceDetails'][0]['smslc']['installedBy'] ?? "";
        _smslcregion =
            _firstDevice[0]['deviceDetails'][0]['smslc']['region'] ?? "";
        _smslcward =
            _firstDevice[0]['deviceDetails'][0]['smslc']['wardName'] ?? "";
        _smslczone =
            _firstDevice[0]['deviceDetails'][0]['smslc']['zoneName'] ?? "";
        _smslcAcc =
            _firstDevice[0]['deviceDetails'][0]['smslc']['accuracy'] ?? "";
        _smslcLong =
            _firstDevice[0]['deviceDetails'][0]['smslc']['slongitude'] ?? "";
        _smslcLat =
            _firstDevice[0]['deviceDetails'][0]['smslc']['slatitude'] ?? "";
        _smslcState = _firstDevice[0]['deviceDetails'][0]['smslc']['state']
            .toString()
            .toUpperCase();

        String smslcinstalledTime = _firstDevice[0]['deviceDetails'][0]['smslc']
                ['installedOn']
            .toString();
        _smslcInstalledOn =
            smslcinstalledTime == '' ? 0 : int.parse(smslcinstalledTime);
      }
      _firstDeviceCustomerId = _firstDevice[0]['customer']['id'] ?? "";

      if (_firstDevice[0]['deviceDetails'][0]['semc'].isNotEmpty &&
          clickEventIsFor != "addILM" &&
          clickEventIsFor != 'addLampInMaintenance') {
        if (_firstDevice[0]['deviceDetails'][0]['semc'].toString() != "") {
          _firstDeviceTypewithChr = devicePath['type'];
          _firstDeviceType = devicePath['type'].toString().isNotEmpty
              ? devicePath['type'].toString().toUpperCase()
              : "";
          if (_firstDeviceType.isNotEmpty) {
            if (_firstDeviceType == 'ILM' ||
                _firstDeviceType == 'LUMINODE' ||
                _firstDeviceType == 'ILM-4G') {
              _firstDeviceType = 'ILM';
            } else if (_firstDeviceType == 'GW' || _firstDeviceType == 'CCMS') {
              _firstDeviceType = 'GW';
            } else if (_firstDeviceType == 'SEMC') {
              _firstDeviceType = 'SEMC';
            }
          }

          _firstDeviceName =
              _firstDevice[0]['deviceDetails'][0]['semc']['name'] ?? "";

          _firstDeviceId = devicePath['id'] ?? "";
          _firstDevicecurrentState =
              _firstDevice[0]['deviceDetails'][0]['semc']['state'] ?? "";
          String gpCommTime = _firstDevice[0]['deviceDetails'][0]['semc']
                  ['lastActivityTime']
              .toString();
          _firstDevicelastCommunicatedStatus =
              gpCommTime == '' ? 0 : int.parse(gpCommTime);
          _firstDeviceWardName = devicePath['wardName'] ?? "";
          _firstDeviceRegionName = devicePath['region'] ?? "";

          _firstDeviceZoneName = devicePath['zoneName'] ?? "";
          _firstDeviceInstallBy = devicePath['installedBy'] ?? "";
          _firstDeviceCurrentCondition =
              devicePath['condition'].toString().isNotEmpty
                  ? devicePath['condition'].toString().toUpperCase()
                  : "";
          String gwinstalledTime = _firstDevice[0]['deviceDetails'][0]['semc']
                  ['installedOn']
              .toString();
          _deviceInstalledOn =
              gwinstalledTime == '' ? 0 : int.parse(gwinstalledTime);
        }
      }
    }
//pole
    if (_firstDevice[0]['deviceDetails'][0].containsKey("pole")) {
      if (_firstDevice[0]['deviceDetails'][0]['pole'].isNotEmpty &&
          clickEventIsFor != "addILM" &&
          clickEventIsFor != "addILMViaPole" &&
          clickEventIsFor != "scanLampViaILM" &&
          clickEventIsFor != 'addLamp' &&
          clickEventIsFor != 'addLampInMaintenance') {
        _firstDeviceCustomerId = _firstDevice[0]['customer']['id'] ?? "";

        _poleName = _firstDevice[0]['deviceDetails'][0]['pole']['name'] ?? "";
        _poleId = _firstDevice[0]['deviceDetails'][0]['pole']['id'] ?? "";
        _poleType =
            _firstDevice[0]['deviceDetails'][0]['pole']['asset_type'] ?? "";
        _poleLat =
            _firstDevice[0]['deviceDetails'][0]['pole']['latitude'] ?? "";
        _poleLong =
            _firstDevice[0]['deviceDetails'][0]['pole']['longitude'] ?? "";
        _poleAccuracy =
            _firstDevice[0]['deviceDetails'][0]['pole']['accuracy'] ?? "";
        _poleLocation =
            _firstDevice[0]['deviceDetails'][0]['pole']['location'] ?? "";
        _lampProfiles =
            _firstDevice[0]['deviceDetails'][0]['pole']['lampProfiles'] ?? [];
        _poleWardName =
            _firstDevice[0]['deviceDetails'][0]['pole']['wardName'] ?? "";
        _poleZoneName =
            _firstDevice[0]['deviceDetails'][0]['pole']['zoneName'] ?? "";
        _poleRegion =
            _firstDevice[0]['deviceDetails'][0]['pole']['region'] ?? "";
        _poleState = _firstDevice[0]['deviceDetails'][0]['pole']['state'] ?? "";
        String poleinstalledTime = _firstDevice[0]['deviceDetails'][0]['pole']
                ['installedOn']
            .toString();
        _poleInstalledOn =
            poleinstalledTime == '' ? 0 : int.parse(poleinstalledTime);
        _poleInstalledBy =
            _firstDevice[0]['deviceDetails'][0]['pole']['installedBy'] ?? "";
        _lampConnection =
            _firstDevice[0]['deviceDetails'][0]['pole']['connection'] ?? "";
        _armCount =
            _firstDevice[0]['deviceDetails'][0]['pole']['armCount'] == ''
                ? 0
                : int.parse(
                    _firstDevice[0]['deviceDetails'][0]['pole']['armCount']);
        _poleSubtype =
            _firstDevice[0]['deviceDetails'][0]['pole']['pole_type'] ?? "";
        if (_firstDevice[0]['deviceDetails'][0]['pole']
            .containsKey('relations')) {
          List<dynamic> relationsList =
              _firstDevice[0]['deviceDetails'][0]['pole']['relations'];
          _lampNamesInRelation =
              relationsList.map((relation) => relation['name']).toList();
          _lampLightPointIdInRelation = relationsList
              .map((relation) => relation['lightPointId'])
              .toList();
          _ilmNamesInRelation =
              relationsList.map((relation) => relation['ilm']).toList();
        }
        _recommendedWattage = _firstDevice[0]['deviceDetails'][0]['pole']
                ['recommendedWattage'] ??
            [];
        _poleSpNo =
            _firstDevice[0]['deviceDetails'][0]['pole']['switchPointNo'] ?? "";
        _isValidSp =
            _firstDevice[0]['deviceDetails'][0]['pole']['isValidSwitchPoint'];
        _poleTransformerNo =
            _firstDevice[0]['deviceDetails'][0]['pole']['transformerNo'] ?? "";
        _newRoadCategory = _firstDevice[0]['deviceDetails'][0]['pole']
                ['newRoadCategory'] ??
            "";
        _poleRoadType =
            _firstDevice[0]['deviceDetails'][0]['pole']['roadType'] ?? "";
        _incomingTransmissionLine = _firstDevice[0]['deviceDetails'][0]['pole']
                ['incomingTransmissionLine'] ??
            "";
      }
    }
  }

  void addSecondDevice(device, clickEventIsFor) {
    _secondDevice = [];
    _secondDeviceName = '';
    _secondDeviceCurrentState = '';
    _secondDeviceCurrentCondition = '';
    _secondDeviceType = '';
    _secondDeviceWardName = '';
    _isSecondDeviceGotRelation = false;

    _isTestBench = false;
    if (isJson) {
      _secondLampName = '';
      _secondLampId = '';
      _secondLampAssetType = '';
      _secondLampWard = '';
      _secondLampWatts = '';
      _secondLampManufacturer = '';
      _secondLampTypeSignify = '';
      _secondLampYear = '';
      _secondLampDimmable = '';
      _isSecondLampGotRelation = false;
    }

    _secondDevice = [];
    var devicePath;
    _secondDevice.add(device);
    if (_secondDevice[0]['deviceDetails'][0].containsKey("ilm")) {
      devicePath = _secondDevice[0]['deviceDetails'][0]['ilm'];
    } else if (_secondDevice[0]['deviceDetails'][0].containsKey("gw")) {
      devicePath = _secondDevice[0]['deviceDetails'][0]['gw'];
    } else if (_secondDevice[0]['deviceDetails'][0].containsKey("semc")) {
      devicePath = _secondDevice[0]['deviceDetails'][0]['semc'];
    }
    if ((_secondDevice[0]['deviceDetails'][0].containsKey('ilm') &&
                _secondDevice[0]['deviceDetails'][0]['ilm'].isNotEmpty) &&
            (clickEventIsFor != "lampOnlyReplace") &&
            (!isJson) ||
        (_secondDevice[0]['deviceDetails'][0].containsKey('gw') &&
            _secondDevice[0]['deviceDetails'][0]['gw'].isNotEmpty) ||
        (_secondDevice[0]['deviceDetails'][0].containsKey('semc') &&
            _secondDevice[0]['deviceDetails'][0]['semc'].isNotEmpty)) {
      _secondDeviceName = devicePath['name'];
      _secondDeviceCurrentState = devicePath['state'].toString().toUpperCase();
      _secondDeviceCurrentCondition =
          devicePath['condition'].toString().toUpperCase();
      _secondDeviceType = devicePath['type'].toString().toUpperCase();
      _secondDeviceWardName = devicePath['wardName'];
      checkSecondDeviceGotRelation();
    } else if (_secondDevice[0]['deviceDetails'][0].containsKey('lamp') &&
        _secondDevice[0]['deviceDetails'][0]['lamp'].isNotEmpty &&
        (clickEventIsFor == "lampOnlyReplace" ||
            clickEventIsFor == "lamp+ilmReplace")) {
      _secondLampName =
          _secondDevice[0]['deviceDetails'][0]['lamp']['name'].toString();
      _secondLampId = _secondDevice[0]['deviceDetails'][0]['lamp']['id'];
      _secondLampAssetType = _secondDevice[0]['deviceDetails'][0]['lamp']
                  ['type']
              .toString()
              .isNotEmpty
          ? _secondDevice[0]['deviceDetails'][0]['lamp']['type']
              .toString()
              .toUpperCase()
          : "";
      _secondLampWard =
          _secondDevice[0]['deviceDetails'][0]['lamp']['wardName'].toString();
      _secondLampWatts =
          _secondDevice[0]['deviceDetails'][0]['lamp']['lampWatts'] ?? "";
      _secondLampManufacturer =
          _secondDevice[0]['deviceDetails'][0]['lamp']['manufacturer'] ?? "";
      _secondLampTypeSignify =
          _secondDevice[0]['deviceDetails'][0]['lamp']['lampType'] ?? "";
      _secondLampYear =
          _secondDevice[0]['deviceDetails'][0]['lamp']['year'] ?? "";
      _secondLampDimmable =
          _secondDevice[0]['deviceDetails'][0]['lamp']['dimmable'] ?? "";
      checkSecondLampGotRelation();
    }
    notifyListeners();
  }

  void updateSelectedCustomerid(custId) {
    _selectedCustomerId = custId;
  }

  void addLocationName() {
    List<String> name = _firstDeviceWardName.split('-');
    _firstDeviceRegionName = name[0];
    notifyListeners();
  }

  void checkDeviceGotRelation() {
    // if (firstDeviceType == "ILM") {
    if (_firstDevice[0]['wardDetails'].isNotEmpty) {
      if (_firstDevice[0]['wardDetails'][0].containsKey("type")) {
        if (_firstDevice[0]['wardDetails'][0]["type"] == 'ward') {
          _isFirstDeviceGotRelation = true;
          if (clickeventIsFor != 'addILM') {
            _deviceOrAssetWardId =
                _firstDevice[0]['wardDetails'][0]["id"].toString();
          }
        } else {
          _isTestBench = true;
          _isFirstDeviceGotRelation = false;
        }
      }
    } else {
      _isFirstDeviceGotRelation = false;
    }
  }

  //Output: true

  void checkSecondDeviceGotRelation() {
    if (_secondDevice[0]['wardDetails'].isNotEmpty) {
      if (_secondDevice[0]['wardDetails'][0].containsKey("type")) {
        if (_secondDevice[0]['wardDetails'][0]["type"] == 'ward') {
          _isSecondDeviceGotRelation = true;
        } else {
          _isTestBench = true;
          _isSecondDeviceGotRelation = false;
        }
      }
    } else {
      _isSecondDeviceGotRelation = false;
    }
  }

  void checkSecondLampGotRelation() {
    if (_secondDevice[0]['deviceDetails'][0]['lightPoint'].isNotEmpty) {
      _isSecondLampGotRelation = true;
    } else {
      _isSecondLampGotRelation = false;
    }
  }

  void updateDeviceSearchList(data) async {
    if (_clickEventIsFor == 'poleSurveySearch') {
      _poleSearchList = [];
      await data.forEach((d) => _poleSearchList.add(d));
    } else if (_clickEventIsFor == 'spSurveySearch') {
      _spSearchList = [];
      await data.forEach((d) => _spSearchList.add(d));
    } else if (_clickEventIsFor == 'transSurveySearch') {
      _transSearchList = [];
      await data.forEach((d) => _transSearchList.add(d));
    } else {
      // poleSearch (lamp Summary screen)
      _deviceSearchList = [];
      await data.forEach((d) => _deviceSearchList.add(d));
    }
    notifyListeners();
  }

  void updateDeviceSearchListForPagination(
      Map<String, dynamic> res, page) async {
    List data = res['data'] ?? [];
    int totalPage = res['total_page'] ?? 1;

    if (page == 0) {
      _deviceSearchPage = 0;
      _hasMoreDeviceSearch = true;
    }

    if (page >= totalPage - 1) {
      _hasMoreDeviceSearch = false;
    }

    // allSearch,
    if (page == 0) _deviceSearchList = [];
    for (var d in data) {
      _deviceSearchList.add(d);
    }

    notifyListeners();
  }

  void emptyDeviceSearchList() {
    _deviceSearchList = [];
    _poleSearchList = [];
    _spSearchList = [];
    _transSearchList = [];
    _deviceSearchPage = 0;
    _hasMoreDeviceSearch = true;
    _isDeviceSearchLoadingMore = false;
    notifyListeners();
  }

  updateDevicecount(val) {
    _firstOrSecondDevice = val;
    notifyListeners();
  }

  clickEventIsFor(val) {
    _clickEventIsFor = val;
    notifyListeners();
  }

  lampOrILMScanForReplace(val) {
    _lampOrILMScanForReplace = val;
    notifyListeners();
  }

  Future<void> webViewMaintenance(
      WidgetRef ref, context, selectedviewname, selectedDeviceName) async {
    userSelectedDeviceOrAsset(selectedDeviceName);

    if (selectedviewname == 'pendingTickets' ||
        selectedviewname == 'closedTickets') {
      ref.read(ticketController).updateSearchText('');
      await ref.read(ticketController).isTicketsOfSpecificDeviceOrAsset(false);
      await ref
          .read(ticketController)
          .getTicketsBasedOnStatusFB(context, ref,
              selectedviewname == 'pendingTickets' ? 'Pending' : 'Closed')
          .then((value) {
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TicketListPage()),
        );
      });
    } else {
      var res = await _service.getDeviceDataService(
          ref, context, selectedDeviceName, 1, "1");
      if (res == 1) {
        if (selectedviewname == 'ilm' || selectedviewname == 'lamp') {
          EasyLoading.dismiss();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IlmMaintenance(),
            ),
          );
        } else if (selectedviewname == 'hub' ||
            selectedviewname == 'ccms' ||
            selectedviewname == 'smslc') {
          if (selectedviewname == 'ccms' || selectedviewname == 'smslc') {
            await ref.read(panelController).commRelayStatusCalculation(
                ref, context,
                deviceType: firstDeviceType);
            await ref
                .read(ticketController)
                .isTicketsOfSpecificDeviceOrAsset(true);
            await ref.read(ticketController).getTicketsBasedOnStatusFB(
                context, ref, 'Closed', entityIdForSpecificDeviceTicket: [
              selectedviewname == 'ccms' ? _ccmsAssetsId : _smslcAssetId,
              _firstDeviceId
            ]);
          }
          EasyLoading.dismiss();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GwMaintenance(),
            ),
          );
        } else if (selectedviewname == 'pole') {
          EasyLoading.dismiss();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PoleDetails(),
              settings: const RouteSettings(name: poleDetailsRoute),
            ),
          );
        }
      } else if (res == 401) {
        EasyLoading.dismiss();
        await tokenExpired(context, ref);
      } else if (res.toString() == ErrorMessages.serverTimeOutError) {
        EasyLoading.dismiss();
        showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
      } else {
        EasyLoading.dismiss();
        showSnackBar(ref, context, ErrorMessages.tryAgainError);
      }
    }
  }

  Future<bool> validateEbMeter(
      WidgetRef ref, BuildContext context, String value) async {
    if (_ebMeterPhase == '1' || _ebMeterPhase == 'single') {
      RegExp regExp = RegExp(r'^[A-Za-z]\d{7}$');
      if (!regExp.hasMatch(value)) {
        showSnackBar(ref, context, ErrorMessages.invalidSinglePhaseEbError);
        return false;
      }
    } else {
      RegExp regExp = RegExp(r'^\d{8}$');
      if (!regExp.hasMatch(value)) {
        showSnackBar(ref, context, ErrorMessages.invalidThreePhaseEbError);

        return false;
      }
    }
    return true;
  }

  Future<void> scanDevice(
      WidgetRef ref, context, firstOrSecond, clickEventIsFor,
      {bool isTicket = false,
      bool isFromTicketsList = false,
      String deviceId = '',
      String scannedResponse = ''}) async {
    QRViewController? qrViewController = ref
        .read(ref.watch(isSecondTime) ? qrController2 : qrController)
        .qrViewController;

    await Geolocator.requestPermission();
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _firstOrSecondDevice = firstOrSecond;
    if (clickEventIsFor == "1") {
      setAccuracy();
    }

    if (isTicket) {
      scannedResponse = deviceId;
    }

    Utility.isConnected().then(
      (value) async {
        if (value) {
          if (scannedResponse != "") {
            EasyLoading.show(
              status: '',
              dismissOnTap: false,
            );
            String scannedDeviceOrAssetName;
            dynamic decodedData;

            try {
              decodedData = jsonDecode(scannedResponse);
              // Required keys validation
              final requiredKeys = ['m', 'w', 'l', 'd', 'y', 'i'];

              final isValidQr = requiredKeys.every(
                (key) =>
                    decodedData.containsKey(key) &&
                    decodedData[key] != null &&
                    decodedData[key].toString().trim().isNotEmpty,
              );

              if (!isValidQr) {
                EasyLoading.dismiss();
                showSnackBar(ref, context, ErrorMessages.invalidQRError);
                return;
              }

              isJson = true;
              scannedDeviceOrAssetName =
                  '${decodedData['m']}-${decodedData['w']}-${decodedData['l']}-${decodedData['d']}-${decodedData['y']}-${decodedData['i']}';
            } catch (e) {
              isJson = false;
              scannedDeviceOrAssetName = scannedResponse;
              if ((clickEventIsFor == "lampOnlyReplace" ||
                  (clickEventIsFor == "lamp+ilmReplace" &&
                      lampOrILMscanForReplace == "lamp"))) {
                EasyLoading.dismiss();
                showSnackBar(ref, context, ErrorMessages.invalidQRError);
                return;
              }
            }
            if (clickEventIsFor == 'ebMeterReplace') {
              _newEbMeterNo = scannedDeviceOrAssetName;
              if (_newEbMeterNo == ebMeterNo) {
                EasyLoading.dismiss();

                userAlertWithNoAction(
                    ref,
                    context,
                    ErrorMessages.cantReplaceAssetWarning(
                        firstAssetName: _ebMeterNo,
                        secondAssetName: _newEbMeterNo));
              } else {
                var result = await _service.getDeviceDataService(ref, context,
                    _newEbMeterNo, firstOrSecond, clickEventIsFor);
                EasyLoading.dismiss();
                if (result.containsKey('state')) {
                  if (result['state'] == 'installed') {
                    await userAlertWithNoAction(
                      ref,
                      context,
                      'Eb meter $_newEbMeterNo is already installed',
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TakePictureScreen(
                            camera: firstCamera,
                            clickeventIsFor: clickeventIsFor),
                      ),
                    );
                  }
                }
              }
            } else {
              userSelectedDeviceOrAsset(scannedDeviceOrAssetName);
              var res = await _service.getDeviceDataService(ref, context,
                  scannedDeviceOrAssetName, firstOrSecond, clickEventIsFor);
              if (res == 1 && firstOrSecond == 1) {
                if (_firstDeviceType == 'ILM' ||
                    _firstDeviceType == 'LUMINODE' ||
                    _firstDeviceType == 'ILM-4G') {
                  _firstDeviceType = "ILM";
                } else if (_firstDeviceType == "CCMS") {
                  _firstDeviceType = "GW";
                }
                if (_lpType == '' && _lampAssetType == 'LAMP') {
                  EasyLoading.dismiss();
                  informationAlert(ref, context,
                      ErrorMessages.assetNotInstalledError(lampName: lampName));
                } else if (_poleType == "pole" &&
                    _lampAssetType == '' &&
                    firstDeviceType == '' &&
                    (clickEventIsFor !=
                            "addILMViaPole" || //to avoid navigating to pole screen while scanning the pole in addILM and addILMViaPole
                        clickEventIsFor == "addILM")) {
                  // Pole Validation
                  EasyLoading.dismiss();
                  if (isTicket) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PoleDetails(
                          isFromTickets: true,
                          isFromTicketsList: isFromTicketsList,
                        ),
                        settings: const RouteSettings(name: poleDetailsRoute),
                      ),
                    );
                  } else {
                    //same customer diff ward for pole(take to maintenace, try another device)
                    if ((_selectedCustomerId == _firstDeviceCustomerId) &&
                        (_selectedWard != _poleWardName)) {
                      EasyLoading.dismiss();
                      installationConfirmForPole(
                          context,
                          ref,
                          ErrorMessages
                              .deviceFoundInstalledWantToProceedWarning(
                                  deviceName: _poleName,
                                  region: _poleRegion,
                                  zone: _poleZoneName,
                                  ward: _poleWardName),
                          "isWebview");
                      //diff customer for pole(try another device)
                    } else if (_selectedCustomerId != _firstDeviceCustomerId) {
                      EasyLoading.dismiss();
                      installationConfirmwithDiffCustForPole(
                          context,
                          ref,
                          ErrorMessages
                              .deviceFoundInstalledWantToProceedWarning(
                                  deviceName: _poleName, region: _poleRegion));
                    } else {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PoleDetails(),
                          settings: const RouteSettings(name: poleDetailsRoute),
                        ),
                      );
                    }
                  }
                  // to avoid install gw instead of installing ilm(add ilm scenario)
                } else if ((clickEventIsFor == "addILM" ||
                        clickEventIsFor == "addILMViaPole") &&
                    // _firstDeviceType == "" ||
                    firstDeviceType != 'ILM') {
                  EasyLoading.dismiss();
                  await userAlertWithNoAction(
                      ref, context, "Mismatched Device/Asset type");
                } else {
                  if (clickEventIsFor != "addLamp" &&
                      clickEventIsFor != "ScanAPole") {
                    if (_isFirstDeviceGotRelation && !_isTestBench) {
                      if (_deviceType == "luminar") {
                        // ILM || LAMP
                        //same customer diff ward (lmp - skip, take to maintenance) (ilm - proceed to Install, try another device, take to Maintenance )
                        if ((_selectedCustomerId == _firstDeviceCustomerId) &&
                            (_selectedWard != _lpward) &&
                            !isTicket) {
                          EasyLoading.dismiss();
                          if (_firstDeviceType == "ILM" ||
                              _lampAssetType == "LAMP") {
                            installationConfirm(
                                context,
                                ref,
                                (clickEventIsFor == "addILM" ||
                                        clickEventIsFor == "addILMViaPole")
                                    ? ErrorMessages
                                        .deviceFoundInstalledWantToProceedWarning(
                                            deviceName: _firstDeviceName,
                                            region: _lpregion,
                                            zone: _lpzone,
                                            ward: _lpward)
                                    : ErrorMessages
                                        .deviceFoundInstalledWantToProceedWarning(
                                            deviceName: _firstDeviceName,
                                            lampName: _lampName,
                                            region: _lpregion,
                                            zone: _lpzone,
                                            ward: _lpward),
                                _firstDeviceType,
                                clickEventIsFor);
                          }
                          //diff customer (lmp - skip) (ilm - proceed to Install, try another device)
                        } else if (_selectedCustomerId !=
                                _firstDeviceCustomerId &&
                            !isTicket) {
                          EasyLoading.dismiss();
                          if (_firstDeviceType == "ILM" ||
                              _lampAssetType == "LAMP") {
                            installationConfirmwithDiffCust(
                                context,
                                ref,
                                (clickEventIsFor == "addILM" ||
                                        clickEventIsFor == "addILMViaPole")
                                    ? ErrorMessages
                                        .deviceFoundInstalledWantToProceedWarning(
                                            deviceName: _firstDeviceName,
                                            region: _lpregion)
                                    : ErrorMessages
                                        .deviceFoundInstalledWantToProceedWarning(
                                            deviceName: _firstDeviceName,
                                            lampName: _lampName,
                                            region: _lpregion),
                                clickEventIsFor);
                          }
                        } else {
                          EasyLoading.dismiss();
                          // if (qrViewController != null) {
                          //   qrViewController.resumeCamera();
                          // }
                          if (_firstDeviceType == "ILM" ||
                              _lampAssetType == "LAMP" ||
                              _lpType == 'lightPoint') {
                            if ((clickEventIsFor == "addILM" ||
                                    clickEventIsFor == "addILMViaPole") &&
                                !isTicket) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TakePictureScreen(
                                      camera: firstCamera,
                                      clickeventIsFor: clickeventIsFor),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IlmMaintenance(
                                    isFromTickets: isTicket,
                                    isFromTicketsList: isFromTicketsList,
                                  ),
                                ),
                              );
                            }
                          }
                        }
                        //GW
                      } else {
                        // GW || SEMC
                        if ((_selectedCustomerId == _firstDeviceCustomerId) &&
                            (_selectedWard != _firstDeviceWardName) &&
                            !isTicket) {
                          EasyLoading.dismiss();
                          userAlertWithNoAction(
                              ref,
                              context,
                              ErrorMessages.deviceFoundInstalledWarning(
                                  deviceName: _firstDeviceName,
                                  deviceRegion: _firstDeviceRegionName,
                                  deviceZone: _firstDeviceZoneName,
                                  deviceWard: _firstDeviceWardName));
                        } else if (_selectedCustomerId !=
                                _firstDeviceCustomerId &&
                            !isTicket) {
                          EasyLoading.dismiss();
                          userAlertWithNoAction(
                              ref,
                              context,
                              ErrorMessages.deviceFoundInstalledWithWarning(
                                  deviceName: _firstDeviceName,
                                  deviceRegion: _firstDeviceRegionName));
                        } else {
                          // if (_assetType == 'ccms') {
                          if (_assetType != 'hub') {
                            await ref
                                .read(panelController)
                                .commRelayStatusCalculation(ref, context,
                                    deviceType: firstDeviceType);
                            await ref
                                .read(ticketController)
                                .isTicketsOfSpecificDeviceOrAsset(true);
                            await ref
                                .read(ticketController)
                                .getTicketsBasedOnStatusFB(
                                    context, ref, 'Closed',
                                    entityIdForSpecificDeviceTicket: [
                                  _assetType == 'smslc'
                                      ? _smslcAssetId
                                      : _ccmsAssetsId,
                                  _firstDeviceId
                                ]);
                          }
                          // } else if (_assetType == 'smslc') {
                          //   await ref
                          //       .read(ticketController)
                          //       .isTicketsOfSpecificDeviceOrAsset(true);
                          //   await ref
                          //       .read(ticketController)
                          //       .getTicketsBasedOnStatusFB(
                          //           context, ref, 'Closed',
                          //           entityIdForSpecificDeviceTicket: [
                          //         _smslcAssetId,
                          //         _firstDeviceId
                          //       ]);
                          // }
                          EasyLoading.dismiss();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GwMaintenance(),
                            ),
                          );
                        }
                      }
                    } else {
                      if (_firstDeviceCurrentCondition == "SCRAPPED") {
                        EasyLoading.dismiss();
                        userAlertWithNoAction(
                            ref,
                            context,
                            ErrorMessages.deviceScrappedError(
                                deviceName: _firstDeviceName));
                        // GW || SEMC
                      } else if (_firstDeviceCurrentCondition != "SCRAPPED" &&
                          (((_firstDeviceType == "GW") &&
                                  (_ccmsAssetsId == '' && _hubId == '') ||
                              ((_firstDeviceType == "SEMC") &&
                                  (_smslcAssetId == ''))))) {
                        // handling installable state in case of Gateway & SEMC device Dispatch scenario
                        if (_firstDevicecurrentState == 'INSTALLABLE') {
                          EasyLoading.dismiss();
                          if (selectedWard != '') {
                            userAlertWithNoAction(
                                ref,
                                context,
                                firstDeviceType == "SEMC"
                                    ? ErrorMessages.semcNotDespatchedError(
                                        deviceName: _firstDeviceName)
                                    : ErrorMessages.gwNotDespatchedError(
                                        deviceName: _firstDeviceName));
                          } else {
                            wardRequiredAlert(context, ref,
                                ErrorMessages.wardRequiredAlertMessage);
                          }
                          //handling onboarded state incase of GW || SEMC
                        } else if (_firstDevicecurrentState == "ONBOARDED") {
                          //block the installation
                          EasyLoading.dismiss();
                          userAlertWithNoAction(
                              ref,
                              context,
                              firstDeviceType == "SEMC"
                                  ? ErrorMessages
                                      .deviceNotInstallableTryWithSEMCError(
                                          deviceName: _firstDeviceName)
                                  : ErrorMessages
                                      .deviceNotInstallableTryWithGWError(
                                          deviceName: _firstDeviceName));
                        } else {
                          EasyLoading.dismiss();
                          userAlertWithNoAction(
                              ref,
                              context,
                              firstDeviceType == "SEMC"
                                  ? ErrorMessages.semcNotDespatchedError(
                                      deviceName: _firstDeviceName)
                                  : ErrorMessages.gwNotDespatchedError(
                                      deviceName: _firstDeviceName));
                        }
                      } else if ((_firstDeviceCurrentCondition != "SCRAPPED" &&
                              _isFirstDeviceGotRelation &&
                              !_isTestBench) &&
                          (_firstDeviceWardName != _selectedWard) &&
                          !isTicket) {
                        EasyLoading.dismiss();
                        userAlert(
                            ref,
                            context,
                            ErrorMessages.deviceInstalledSomeWhereWarning,
                            _firstDeviceType,
                            clickEventIsFor);
                      } else if (_firstDeviceCurrentCondition != "SCRAPPED" &&
                          _firstDevicecurrentState != "INSTALLABLE") {
                        EasyLoading.dismiss();
                        if (_firstDeviceType == "ILM") {
                          //handling onboarded state incase of ILM
                          if (_firstDevicecurrentState == "ONBOARDED") {
                            //block the installation
                            userAlertWithNoAction(
                                ref,
                                context,
                                ErrorMessages
                                    .deviceNotInstallableTryWithILMError(
                                        deviceName: _firstDeviceName));
                          } else if (!isTicket) {
                            if (clickEventIsFor != "addILM") {
                              if (selectedWard != '') {
                                userAlert(
                                    ref,
                                    context,
                                    ErrorMessages.deviceNotInstallableWarning(
                                        deviceName: _firstDeviceName),
                                    _firstDeviceType,
                                    clickEventIsFor);
                              } else {
                                wardRequiredAlert(context, ref,
                                    ErrorMessages.wardRequiredAlertMessage);
                              }
                            } else {
                              userAlert(
                                  ref,
                                  context,
                                  ErrorMessages.deviceNotInstallableWarning(
                                      deviceName: _firstDeviceName),
                                  _firstDeviceType,
                                  clickEventIsFor);
                            }
                          } else {
                            EasyLoading.dismiss();
                            userAlertWithNoAction(
                                ref,
                                context,
                                ErrorMessages.deviceRemovedError(
                                    deviceName: _firstDeviceName));
                          }
                          // GW || SEMC [not installable state]
                        } else {
                          userAlertWithNoAction(
                              ref,
                              context,
                              ErrorMessages.deviceNotInstallableError(
                                  deviceName: _firstDeviceName));
                        }
                        // ILM || GW || SEMC [allow installation]
                      } else {
                        EasyLoading.dismiss();
                        if (_firstDeviceType == "ILM" && !isTicket) {
                          if (clickEventIsFor == "addILM" ||
                              clickEventIsFor == "addILMViaPole") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TakePictureScreen(
                                    camera: firstCamera,
                                    clickeventIsFor: clickeventIsFor),
                              ),
                            );
                          } else {
                            // if (qrViewController != null) {
                            //   qrViewController.resumeCamera();
                            // }
                            if (selectedWard != '') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ScanSelectionPage(),
                                ),
                              );
                            } else {
                              wardRequiredAlert(context, ref,
                                  ErrorMessages.wardRequiredAlertMessage);
                            }
                          }
                        } else if ((_firstDeviceType == "GW" ||
                                _firstDeviceType == "CCMS" ||
                                _firstDeviceType == "SEMC") &&
                            !isTicket) {
                          if (selectedWard != '') {
                            if ((_firstDeviceType == 'GW' &&
                                    _assetType == 'ccms') ||
                                (_firstDeviceType == "SEMC")) {
                              // provision only for ccms and smslc
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SwitchPointScreen(
                                      scannedDeviceOrAssetName:
                                          scannedDeviceOrAssetName),
                                ),
                              );
                            } else {
                              // provision only for hub
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TakePictureScreen(
                                      camera: firstCamera,
                                      clickeventIsFor: clickeventIsFor),
                                ),
                              );
                            }
                          } else {
                            wardRequiredAlert(context, ref,
                                ErrorMessages.wardRequiredAlertMessage);
                          }
                        } else if (!isTicket) {
                          userAlertWithNoAction(ref, context,
                              ErrorMessages.invalidScanedDeviceError);
                        } else {
                          EasyLoading.dismiss();
                          userAlertWithNoAction(
                              ref,
                              context,
                              ErrorMessages.deviceRemovedError(
                                  deviceName: _firstDeviceName));
                        }
                      }
                    }
                  } else {
                    EasyLoading.dismiss();
                    showSnackBar(ref, context, ErrorMessages.invalidQRError);
                  }
                }
              } else if (res == 1 && firstOrSecond == 2) {
                if (_secondDeviceType == 'ILM' ||
                    _secondDeviceType == 'LUMINODE' ||
                    _secondDeviceType == 'ILM-4G') {
                  _secondDeviceType = "ILM";
                } else if (_secondDeviceType == "CCMS") {
                  _secondDeviceType = "GW";
                }
                if (clickEventIsFor == "lampOnlyReplace" ||
                    (clickEventIsFor == "lamp+ilmReplace" &&
                        _lampOrILMScanForReplace == 'lamp')) {
                  if (isJson) {
                    _secondLampName = decodedData['i'];
                    _secondLampManufacturer = decodedData['m'];
                    _secondLampYear = decodedData['y'];
                    _secondLampDimmable = decodedData['d'];
                    _secondLampWatts = decodedData['w'];
                    _secondLampTypeSignify = decodedData['l'];
                    _finalSecondLampName =
                        '$_secondLampManufacturer-$_secondLampWatts-$_secondLampTypeSignify-$_secondLampDimmable-$_secondLampYear-$_secondLampName';

                    if (_secondLampName.isEmpty) {
                      EasyLoading.dismiss();
                      showSnackBar(ref, context, ErrorMessages.invalidQRError);
                    } else if (_lampName == _finalSecondLampName) {
                      EasyLoading.dismiss();
                      userAlertWithNoAction(
                          ref,
                          context,
                          ErrorMessages.cantReplaceAssetWarning(
                              firstAssetName: _lampName,
                              secondAssetName: _finalSecondLampName));
                    } else if (_isSecondLampGotRelation) {
                      EasyLoading.dismiss();
                      await userAlertWithNoAction(
                        ref,
                        context,
                        ErrorMessages.lampFoundScanAnotherAlert(
                            lampName: _secondLampName,
                            lampWard: _secondLampWard),
                      );
                    } else if (!_isSecondLampGotRelation) {
                      EasyLoading.dismiss();
                      _secondLampName = decodedData['i'];
                      _secondLampManufacturer = decodedData['m'];
                      _secondLampYear = decodedData['y'];
                      _secondLampDimmable = decodedData['d'];
                      _secondLampWatts = decodedData['w'];
                      _secondLampTypeSignify = decodedData['l'];
                      if (clickEventIsFor == "lampOnlyReplace") {
                        // if (qrViewController != null) {
                        //   qrViewController.resumeCamera();
                        // }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TakePictureScreen(
                                camera: firstCamera,
                                clickeventIsFor: clickeventIsFor),
                          ),
                        );
                      } else {
                        await ref
                            .read(deviceController)
                            .lampOrILMScanForReplace("ilm");
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ScanQRWithCustomScreen(
                              firstOrSecond: 2,
                              clickEventIsFor: clickEventIsFor),
                        ));
                        // await ref
                        //     .read(deviceController)
                        //     .scanDevice(ref, context, 2, clickEventIsFor);
                      }
                    }
                  } else {
                    EasyLoading.dismiss();
                    await userAlertWithNoAction(
                        ref, context, ErrorMessages.deviceMismatchError);
                  }
                } else {
                  if (_firstDeviceName == _secondDeviceName) {
                    EasyLoading.dismiss();
                    userAlertWithNoAction(
                        ref,
                        context,
                        ErrorMessages.cantReplaceDeviceWarning(
                            firstDeviceName: _firstDeviceName,
                            secondDeviceName: _secondDeviceName));
                  } else if (_firstDeviceType != _secondDeviceType) {
                    EasyLoading.dismiss();
                    await userAlertWithNoAction(
                        ref, context, ErrorMessages.deviceMismatchError);
                  } else if (_secondDeviceCurrentCondition == "SCRAPPED") {
                    EasyLoading.dismiss();
                    userAlertWithNoAction(
                        ref,
                        context,
                        ErrorMessages.deviceScrappedError(
                            deviceName: _secondDeviceName));
                  } else if (_secondDeviceCurrentCondition != "SCRAPPED" &&
                      _secondDeviceCurrentState != "INSTALLABLE") {
                    if (_isSecondDeviceGotRelation && !_isTestBench) {
                      EasyLoading.dismiss();
                      repUserAlert(
                          ref,
                          context,
                          ErrorMessages.deviceInstalledAlert(
                              deviceName: _secondDeviceName,
                              deviceWard: _secondDeviceWardName),
                          clickEventIsFor);
                    } else {
                      EasyLoading.dismiss();
                      if (_secondDeviceCurrentState == "ONBOARDED") {
                        if (_secondDeviceType == 'ILM') {
                          userAlertWithNoAction(
                              ref,
                              context,
                              ErrorMessages.deviceNotInstallableTryWithILMError(
                                  deviceName: _secondDeviceName));
                        } else {
                          userAlertWithNoAction(
                              ref,
                              context,
                              ErrorMessages.deviceNotInstallableTryWithGWError(
                                  deviceName: _secondDeviceName));
                        }
                      } else {
                        repUserAlert(
                            ref,
                            context,
                            ErrorMessages.deviceNotInstallableWarning(
                                deviceName: _secondDeviceName),
                            clickEventIsFor);
                      }
                    }
                  } else if ((_secondDeviceCurrentCondition != "SCRAPPED" &&
                          _isSecondDeviceGotRelation &&
                          !_isTestBench) &&
                      _secondDeviceWardName != _firstDeviceWardName) {
                    EasyLoading.dismiss();
                    repUserAlert(
                        ref,
                        context,
                        ErrorMessages.deviceInstalledSomeWhereWarning,
                        clickEventIsFor);
                  } else {
                    EasyLoading.dismiss();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TakePictureScreen(
                            camera: firstCamera,
                            clickeventIsFor: clickeventIsFor),
                      ),
                    );
                  }
                }
              } else if (res == 401) {
                EasyLoading.dismiss();
                await tokenExpired(context, ref);
              } else if (res == 404 || res == 400) {
                EasyLoading.dismiss();
                if (clickEventIsFor == "lampOnlyReplace") {
                  _secondLampName = decodedData['i'];
                  _secondLampManufacturer = decodedData['m'];
                  _secondLampYear = decodedData['y'];
                  _secondLampDimmable = decodedData['d'];
                  _secondLampWatts = decodedData['w'];
                  _secondLampTypeSignify = decodedData['l'];
                  if (_secondLampName.isNotEmpty) {
                    // if (qrViewController != null) {
                    //   qrViewController.resumeCamera();
                    // }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TakePictureScreen(
                            camera: firstCamera,
                            clickeventIsFor: clickeventIsFor),
                      ),
                    );
                  } else {
                    showSnackBar(ref, context, ErrorMessages.invalidQRError);
                  }
                } else if (clickEventIsFor == "lamp+ilmReplace") {
                  if (isJson && _lampOrILMScanForReplace == 'lamp') {
                    // to restrict new lamp(404) device scan in ilm scan screen
                    _secondLampName = decodedData['i'];
                    _secondLampManufacturer = decodedData['m'];
                    _secondLampYear = decodedData['y'];
                    _secondLampDimmable = decodedData['d'];
                    _secondLampWatts = decodedData['w'];
                    _secondLampTypeSignify = decodedData['l'];
                    if (_secondLampName.isNotEmpty) {
                      await ref
                          .read(deviceController)
                          .lampOrILMScanForReplace("ilm");
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ScanQRWithCustomScreen(
                            firstOrSecond: 2, clickEventIsFor: clickEventIsFor),
                      ));
                      // await ref
                      //     .read(deviceController)
                      //     .scanDevice(ref, context, 2, clickEventIsFor);
                    } else {
                      showSnackBar(ref, context, ErrorMessages.invalidQRError);
                    }
                  } else {
                    await userAlertWithNoAction(
                        ref, context, ErrorMessages.mismatchedDeviceError);
                  }
                } else {
                  showSnackBar(ref, context, ErrorMessages.deviceNotFoundError);
                }
              } else if (res.toString() == ErrorMessages.serverTimeOutError) {
                EasyLoading.dismiss();
                showSnackBar(
                    ref, context, ErrorMessages.systemNotResponsiveError);
              } else {
                EasyLoading.dismiss();
                showSnackBar(ref, context, ErrorMessages.tryAgainError);
              }
            }
          } else if (clickEventIsFor == "lampOnlyReplace" ||
              (clickEventIsFor == "lamp+ilmReplace" &&
                  _lampOrILMScanForReplace == "lamp")) {
            _secondLampName = '';
            _secondLampAssetType = '';
            _secondLampId = '';
            _secondLampWatts = '';
            _secondLampManufacturer = '';
            _secondLampTypeSignify = '';
            _secondLampDimmable = '';
            _secondLampYear = '';
            await skipWarning(ref, context, ErrorMessages.lampWithoutQRWarning,
                clickEventIsFor);
          }
        } else {
          await snackBar(context, ErrorMessages.offlineErrorTitle,
              ErrorMessages.offlineErrorMessage);
          if (qrViewController != null) {
            qrViewController.resumeCamera();
          }
        }
      },
    );
  }

  Future<void> showSelectedDevice(
      WidgetRef ref, context, selecteddevice, type, clickEventIsFor) async {
    if (type != 'lamp' && type != 'pole') {
      setAccuracy();
    } else {
      isLocationFetchingComplete(true);
    }
    EasyLoading.show(status: 'loading...', dismissOnTap: false);
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    var device = selecteddevice;
    userSelectedDeviceOrAsset(device);
    var res = await _service.getDeviceDataService(
        ref, context, device, 1, clickEventIsFor);
    if (res == 1) {
      updateDevicecount(1);
      if (_firstDeviceType == 'ILM' ||
          _firstDeviceType == 'LUMINODE' ||
          _firstDeviceType == 'ILM-4G') {
        _firstDeviceType = "ILM";
      } else if (_firstDeviceType == "CCMS") {
        _firstDeviceType = "GW";
      }

      if (_lpType == '' && _lampAssetType == 'LAMP') {
        EasyLoading.dismiss();
        informationAlert(ref, context,
            ErrorMessages.assetNotInstalledError(lampName: lampName));
      } else if (_poleType == "pole" &&
          _lampAssetType == '' &&
          firstDeviceType == '') {
        EasyLoading.dismiss();

        //same customer diff ward for pole(take to maintenace, try another device)
        if ((_selectedCustomerId == _firstDeviceCustomerId) &&
            (_selectedWard != _poleWardName)) {
          EasyLoading.dismiss();
          installationConfirmForPole(
              context,
              ref,
              ErrorMessages.deviceFoundInstalledWantToProceedWarning(
                  deviceName: _poleName,
                  region: _poleRegion,
                  zone: _poleZoneName,
                  ward: _poleWardName),
              "isSearch");
          //diff customer for pole(try another device)
        } else if (_selectedCustomerId != _firstDeviceCustomerId) {
          EasyLoading.dismiss();
          installationConfirmwithDiffCustForPole(
              context,
              ref,
              ErrorMessages.deviceFoundInstalledWantToProceedWarning(
                  deviceName: _poleName, region: _poleRegion));
        } else {
          // Navigator.pushNamed(
          //   context,
          //   poleDetailsRoute,
          //   arguments: ModalRoute.of(context)?.settings.name,
          // );
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PoleDetails(),
              settings: const RouteSettings(name: poleDetailsRoute),
            ),
          );
          // await Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //       builder: (context) => PoleDetails(navigationPath: "isSearch")),
          // );
        }

        //same customer diff ward (lmp - skip, take to maintenance) (ilm - proceed to Install, try another device, take to Maintenance )
      } else if (_isFirstDeviceGotRelation && !_isTestBench) {
        if (_deviceType == 'luminar') {
          if ((_selectedCustomerId == _firstDeviceCustomerId) &&
              (_selectedWard != _lpward)) {
            if (type == 'lamp') {
              EasyLoading.dismiss();
              installationConfirm(
                  context,
                  ref,
                  ErrorMessages.deviceFoundInstalledWantToProceedWarning(
                      deviceName: _firstDeviceName,
                      lampName: _lampName,
                      region: _lpregion,
                      zone: _lpzone,
                      ward: _lpward),
                  type,
                  clickEventIsFor);
            } else {
              EasyLoading.dismiss();
              if (_firstDeviceType == "ILM") {
                installationConfirm(
                    context,
                    ref,
                    ErrorMessages.deviceFoundInstalledWantToProceedWarning(
                        deviceName: _firstDeviceName,
                        lampName: _lampName,
                        region: _lpregion,
                        zone: _lpzone,
                        ward: _lpward),
                    _firstDeviceType,
                    clickEventIsFor);
              }
            }
            //diff customer (lmp - skip) (ilm - proceed to Install, try another device)
          } else if (_selectedCustomerId != _firstDeviceCustomerId) {
            EasyLoading.dismiss();
            if (type == "lamp") {
              // if (_firstDeviceType.isEmpty && _lampAssetType == 'LAMP') {
              installationConfirmwithDiffCust(
                  context,
                  ref,
                  ErrorMessages.deviceInstallWithOtherWarning(
                      deviceName: _firstDeviceName,
                      lampName: _lampName,
                      firstDeviceRegionName: _firstDeviceRegionName,
                      region: _lpregion),
                  clickEventIsFor);
            } else {
              if (_firstDeviceType == "ILM") {
                installationConfirmwithDiffCust(
                    context,
                    ref,
                    ErrorMessages.deviceInstallWithOtherWarning(
                        deviceName: _firstDeviceName,
                        lampName: lampName,
                        firstDeviceRegionName: _firstDeviceRegionName,
                        region: lpregion),
                    clickEventIsFor);
              }
            }
          } else {
            EasyLoading.dismiss();
            if (_firstDeviceType == "ILM" || type == "lamp") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IlmMaintenance(),
                ),
              );
            } else {
              userAlertWithNoAction(
                  ref, context, ErrorMessages.invalidScanedDeviceError);
            }
          }
        } else {
          if ((_selectedCustomerId == _firstDeviceCustomerId) &&
              (_selectedWard != _firstDeviceWardName)) {
            EasyLoading.dismiss();
            userAlertWithNoAction(
                ref,
                context,
                ErrorMessages.deviceFoundInstalledWarning(
                    deviceName: _firstDeviceName,
                    deviceRegion: _firstDeviceRegionName,
                    deviceZone: _firstDeviceZoneName,
                    deviceWard: _firstDeviceWardName));

            //diff customer (lmp - skip) (ilm - proceed to Install, try another device)
          } else if (_selectedCustomerId != _firstDeviceCustomerId) {
            EasyLoading.dismiss();
            userAlertWithNoAction(
                ref,
                context,
                ErrorMessages.deviceFoundInstalledWithWarning(
                    deviceName: _firstDeviceName,
                    deviceRegion: _firstDeviceRegionName));
          } else {
            if (_firstDeviceType == "GW" || _firstDeviceType == "SEMC") {
              if (_assetType == 'ccms' || _assetType == 'smslc') {
                await ref.read(panelController).commRelayStatusCalculation(
                    ref, context,
                    deviceType: firstDeviceType);
                await ref
                    .read(ticketController)
                    .isTicketsOfSpecificDeviceOrAsset(true);
                await ref.read(ticketController).getTicketsBasedOnStatusFB(
                    context, ref, 'Closed', entityIdForSpecificDeviceTicket: [
                  _assetType == 'ccms' ? _ccmsAssetsId : _smslcAssetId,
                  _firstDeviceId
                ]);
              }
              EasyLoading.dismiss();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GwMaintenance(),
                ),
              );
            } else {
              EasyLoading.dismiss();
              userAlertWithNoAction(
                  ref, context, ErrorMessages.invalidScanedDeviceError);
            }
          }
        }
      } else {
        // No Relation or Not Installed
        if (_firstDeviceCurrentCondition == "SCRAPPED") {
          EasyLoading.dismiss();
          userAlertWithNoAction(ref, context,
              ErrorMessages.deviceScrappedError(deviceName: _firstDeviceName));
        } else if (_firstDeviceCurrentCondition != "SCRAPPED" &&
                (_firstDeviceType == "GW") &&
                (_ccmsAssetsId == '' && _hubId == '') ||
            ((_firstDeviceType == "SEMC") && (_smslcAssetId == ''))) {
          // GW || SEMC
          // if not dispatched or related with any of the asset
          if (_firstDevicecurrentState == 'INSTALLABLE') {
            EasyLoading.dismiss();
            userAlertWithNoAction(
                ref,
                context,
                firstDeviceType == "SEMC"
                    ? ErrorMessages.semcNotDespatchedError(
                        deviceName: _firstDeviceName)
                    : ErrorMessages.gwNotDespatchedError(
                        deviceName: _firstDeviceName));
            //handling onboarded state incase of GW
          } else if (_firstDevicecurrentState == "ONBOARDED") {
            EasyLoading.dismiss();
            //block the installation
            userAlertWithNoAction(
                ref,
                context,
                ErrorMessages.deviceNotInstallableTryWithGWError(
                    deviceName: _firstDeviceName));
          } else {
            EasyLoading.dismiss();
            userAlertWithNoAction(
                ref,
                context,
                firstDeviceType == "SEMC"
                    ? ErrorMessages.semcNotDespatchedError(
                        deviceName: _firstDeviceName)
                    : ErrorMessages.gwNotDespatchedError(
                        deviceName: _firstDeviceName));
          }
        } else if ((_firstDeviceCurrentCondition != "SCRAPPED" &&
                _isFirstDeviceGotRelation &&
                !_isTestBench) &&
            _firstDeviceWardName != _selectedWard) {
          // ILM
          EasyLoading.dismiss();
          userAlert(ref, context, ErrorMessages.deviceInstalledSomeWhereWarning,
              _firstDeviceType, clickEventIsFor);
        } else if (_firstDeviceCurrentCondition != "SCRAPPED" &&
            _firstDevicecurrentState != "INSTALLABLE") {
          EasyLoading.dismiss();
          if (_firstDeviceType == "ILM") {
            //handling onboarded state incase of ILM
            if (_firstDevicecurrentState == "ONBOARDED") {
              //block the installation
              userAlertWithNoAction(
                  ref,
                  context,
                  ErrorMessages.deviceNotInstallableTryWithILMError(
                      deviceName: _firstDeviceName));
            } else {
              if (selectedWard != '') {
                userAlert(
                    ref,
                    context,
                    ErrorMessages.deviceNotInstallableWarning(
                        deviceName: _firstDeviceName),
                    _firstDeviceType,
                    clickEventIsFor);
              } else {
                wardRequiredAlert(
                    context, ref, ErrorMessages.wardRequiredAlertMessage);
              }
            }
          } else {
            if (selectedWard != '') {
              userAlertWithNoAction(
                  ref,
                  context,
                  ErrorMessages.deviceNotInstallableError(
                      deviceName: _firstDeviceName));
            } else {
              wardRequiredAlert(
                  context, ref, ErrorMessages.wardRequiredAlertMessage);
            }
          }
        } else {
          EasyLoading.dismiss();
          if (_firstDeviceType == "ILM") {
            if (selectedWard != '') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanSelectionPage(),
                ),
              );
            } else {
              wardRequiredAlert(
                  context, ref, ErrorMessages.wardRequiredAlertMessage);
            }
          } else if (_firstDeviceType == "GW" || _firstDeviceType == "SEMC") {
            if (selectedWard != '') {
              if ((_firstDeviceType == 'GW' && _assetType == 'ccms') ||
                  (_firstDeviceType == "SEMC")) {
                // provision only for ccms and smslc
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SwitchPointScreen(
                        scannedDeviceOrAssetName: selecteddevice),
                  ),
                );
              } else {
                // provision only for hub
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TakePictureScreen(
                        camera: firstCamera, clickeventIsFor: clickeventIsFor),
                  ),
                );
              }
            } else {
              wardRequiredAlert(
                  context, ref, ErrorMessages.wardRequiredAlertMessage);
            }
          } else {
            userAlertWithNoAction(
                ref, context, ErrorMessages.invalidScanedDeviceError);
          }
        }
      }
    } else if (res == 401) {
      EasyLoading.dismiss();
      await tokenExpired(context, ref);
    } else if (res == 404 || res == 400) {
      EasyLoading.dismiss();
      showSnackBar(ref, context, ErrorMessages.invalidQRError);
    } else if (res.toString() == "Server Timeout. Please try Again!") {
      EasyLoading.dismiss();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      EasyLoading.dismiss();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  Future<List<String>> getLatLong() async {
    bool servicestatus = false;
    bool haspermission = false;
    late LocationPermission permission;
    late Position position;
    String long = "", lat = "", acc = '';
    servicestatus = await Geolocator.isLocationServiceEnabled();
    if (servicestatus) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log(ErrorMessages.locationDeniedError);
        } else if (permission == LocationPermission.deniedForever) {
          log(ErrorMessages.locationPermanentlyDeniedError);
        } else {
          haspermission = true;
        }
      } else {
        haspermission = true;
      }

      if (haspermission) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
        );
        long = position.longitude.toString();
        lat = position.latitude.toString();
        acc = position.accuracy.toString();
        LocationSettings locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        );
        StreamSubscription<Position> positionStream =
            Geolocator.getPositionStream(locationSettings: locationSettings)
                .listen((Position position) {
          long = position.longitude.toString();
          lat = position.latitude.toString();
          acc = position.accuracy.toString();
        });
      }
    } else {
      log(ErrorMessages.gpsNotEnabledError);
    }
    return [long, lat, acc];
  }

  isLocationFetchingComplete(val) {
    _isLocationFetched = val;
    notifyListeners();
  }

  setAccuracy() async {
    double minAcc = 1000;
    var lat = '0.0';
    var long = '0.0';
    for (var i = 1; i <= 20; i++) {
      List<String> res = await getLatLong();
      var a = res[2] == "" ? minAcc : res[2];
      log(a.toString());
      String number1 = double.tryParse(a.toString())!.toStringAsFixed(2);
      double accuracy = double.tryParse(number1)!;
      log("setAccuracy I, $i, $accuracy");
      if (accuracy < minAcc) {
        minAcc = accuracy;
        long = res[0];
        lat = res[1];
        if (minAcc <= 3) {
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    log("OUTPUT , ${long.toString()}, ${lat.toString()}, ${minAcc.toString()}");
    _fetchedAcc = minAcc.toString();
    _fetchedLat = lat.toString();
    _fetchedLong = long.toString();
    isLocationFetchingComplete(true);
    notifyListeners();
    log("OUTPUT , fetchedAcc:${_fetchedAcc.toString()}, fetchedLat:${_fetchedLat.toString()}, fetchedLong:${_fetchedLong.toString()}");
    return [long.toString(), lat.toString(), minAcc.toString()];
  }

  Future<void> poleVaultLaunchUrl() async {
    String packageName = 'com.schnelliot.polevault';
    String playStoreUrl =
        'https://play.google.com/store/apps/details?id=$packageName';
    final Uri uri = Uri.parse(playStoreUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        log(ErrorMessages.playStoreLaunchError);
      }
    } catch (e) {
      log(e.toString());
    }
  }

  void openOtherApp(
      WidgetRef ref,
      BuildContext context,
      String packageName,
      String customerId,
      String region,
      String zone,
      String ward,
      String wardId,
      String userName) async {
    EasyLoading.show(
      status: '',
      dismissOnTap: false,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureStorage = SecureStorageService();
      String token = await secureStorage.getAccessToken() ?? '';
      String refreshToken = await secureStorage.getRefreshToken() ?? '';
      String userId = await secureStorage.getUserId() ?? '';

      bool isLocationTrackingRequired =
          prefs.getBool('isLocationTrackingRequired') ?? false;

      List apps = await InstalledApps.getInstalledApps();
      final listedApps = apps
          .where((item) => item.packageName == 'com.schnelliot.polevault')
          .toList();
      log(listedApps.toString());
      EasyLoading.dismiss();
      if (listedApps.isNotEmpty) {
        final indent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: packageName,
          componentName: '$packageName.MainActivity',
          arguments: <String, dynamic>{
            'token': token,
            'customerId': customerId,
            'region': region,
            'zone': zone,
            'ward': ward,
            'wardId': wardId,
            'userName': userName,
            'userId': userId,
            'isLocationTrackingRquired': isLocationTrackingRequired,
            'refreshToken': refreshToken,
            'poleSchema': _selectedRegionPoleSchema // for pole number prefix
          },
        );
        indent.launch();
        log('$token,$region,$customerId,$zone,$ward,$wardId,$userName');
      } else {
        EasyLoading.dismiss();
        if (context.mounted) {
          await poleVaultAlert(
              ref, context, ErrorMessages.installPoleVaultAlert);
        }
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> scanLamp(context, ref, firstOrSecond, clickEventIsFor,
      {String scannedResponse = ''}) async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _firstOrSecondDevice = firstOrSecond;

    if (scannedResponse.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanSelectionPage()),
      );
    } else {
      EasyLoading.show(
        status: '',
        dismissOnTap: false,
      );

      dynamic decodedData;

      try {
        decodedData = jsonDecode(scannedResponse);
        // Required keys validation
        final requiredKeys = ['m', 'w', 'l', 'd', 'y', 'i'];

        final isValidQr = requiredKeys.every(
          (key) =>
              decodedData.containsKey(key) &&
              decodedData[key] != null &&
              decodedData[key].toString().trim().isNotEmpty,
        );

        if (!isValidQr) {
          EasyLoading.dismiss();
          showSnackBar(ref, context, ErrorMessages.invalidQRError);
          return;
        }

        isJson = true;
        _newLmpName = decodedData['i'];
        _newManufacturer = decodedData['m'];
        _newLmpYear = decodedData['y'];
        _newDimmable = decodedData['d'];
        _newLmpWattage = decodedData['w'];
        _newLmpType = decodedData['l'];
        _finalNewLmpName =
            '$_newManufacturer-$_newLmpWattage-$_newLmpType-$_newDimmable-$_newLmpYear-$_newLmpName';
      } catch (e) {
        isJson = false;
        if (clickEventIsFor == "addLampInMaintenance") {
          EasyLoading.dismiss();
          showSnackBar(ref, context, ErrorMessages.invalidQRError);
          return;
        }
      }

      if (_newLmpName.isNotEmpty && isJson) {
        var res = await _service.getDeviceDataService(
            ref, context, _finalNewLmpName, firstOrSecond, clickEventIsFor);
        EasyLoading.dismiss();

        if (res == 1) {
          if (_lampState == 'INSTALLED') {
            _poleLocation = '';
            _lpLandmark = '';
            // if (qrViewController != null) {
            //   qrViewController.resumeCamera();
            // }
            await userAlertWithNoAction(
                ref,
                context,
                ErrorMessages.lampFoundScanAnotherAlert(
                    lampName: _lampName, lampWard: _lampWard));
          } else if (_lampState == 'INSTALLABLE') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TakePictureScreen(
                    camera: firstCamera, clickeventIsFor: clickeventIsFor),
              ),
            );
          }
        } else if (res == 401) {
          await tokenExpired(context, ref);
        } else if (res == 404) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakePictureScreen(
                  camera: firstCamera, clickeventIsFor: clickeventIsFor),
            ),
          );
        } else if (res.toString() == "Server Timeout. Please try Again!") {
          showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
        } else {
          showSnackBar(ref, context, ErrorMessages.tryAgainError);
        }
      } else {
        EasyLoading.dismiss();
        showSnackBar(ref, context, ErrorMessages.invalidQRError);
      }
    }
  }

  void selectedWardUpdate(data, id, desc) {
    _selectedWard = data;
    _selectedWardId = id;
    _userSelectedWardid = id;
    _selectedWardDesc = desc;
    notifyListeners();
  }

  addUserInputValue(ref, context, manualEnteredLocation, newMeterReadingValue,
      oldMeterReadingValue) {
    _manualEnteredLocation = manualEnteredLocation;
    _newMeterReadingValue = newMeterReadingValue;
    _oldMeterReadingValue = oldMeterReadingValue;
    notifyListeners();
  }

  Future<void> deviceInstallation(
      WidgetRef ref, context, data, clickEventIsFor) async {
    var insData = data;
    String usermail = ref.watch(loginController).userMail;
    List<String> multiSwitchPointNo =
        ref.watch(surveyController).multiSwitchPointNo;
    String spEarthingReason = ref.watch(surveyController).spEarthingReason;
    bool isSpEarthingAvailable =
        ref.watch(surveyController).isSpEarthingAvailable;
    var deviceImage = data['deviceImage'];
    String landmarkOrLocation =
        data.containsKey('landmark') ? data['landmark'] : data['location'];

    String concatenatedmanualEnteredLocation =
        "$_manualEnteredLocation,$landmarkOrLocation";

    String filteredmanualEnteredLocation = concatenatedmanualEnteredLocation
        .replaceAll(RegExp(r',\s*'), ',')
        .replaceAll(RegExp(r'^,\s*'), '')
        .trim();
    String deviceWardName = '';
    String deviceZoneName = '';
    String deviceRegionName = '';
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);
    // print(filteredmanualEnteredLocation);
    var postData = {};
    if (_firstDeviceType == "ILM" || _lampAssetType == "LAMP") {
      postData = {
        "ilm": {
          "name": _firstDeviceName,
        },
        "activityMode": storedMode,
        "latitude": _poleLat == ''
            ? _lpLat.isEmpty
                ? _fetchedLat
                : _lpLat
            : _poleLat,
        "longitude": _poleLong == ''
            ? _lpLong.isEmpty
                ? _fetchedLong
                : _lpLong
            : _poleLong,
        "accuracy": _poleAccuracy == ''
            ? _lpAccuracy.isEmpty
                ? _fetchedAcc
                : _lpAccuracy
            : _poleAccuracy,
        "landmark": filteredmanualEnteredLocation,
        "wardName": _poleWardName == ''
            ? _lpward == ''
                ? _selectedWard
                : _lpward
            : _poleWardName,
        "zoneName": _poleZoneName == ''
            ? _lpzone == ''
                ? _selectedZone
                : _lpzone
            : _poleZoneName,
        "region": _poleRegion == ''
            ? _lpregion == ''
                ? _selectedRegion
                : _lpregion
            : _poleRegion,
        "auditImg": _auditImg,
        "installedOn": DateTime.now().millisecondsSinceEpoch.toString(),
        "installedBy": usermail,
        "customerId": _selectedCustomerId,
        "wardId": clickEventIsFor == "addILM"
            ? _deviceOrAssetWardId
            : _userSelectedWardid,
        "lightPointId":
            // clickEventIsFor=="addILM"? clickEventIsFor == 'addILMViaPole'
            //     ? _lampLightPointId
            //     : _lampAssetsId,
            clickEventIsFor == "addILM"
                ? _lampAssetsId
                : clickEventIsFor == "addILMViaPole"
                    ? _lampLightPointId
                    : "",
        "poleId": _poleId
      };
      if (_poleId != "") {
        postData["pole"] = {
          "name": _poleName,
          "armCount": _armCount,
          "type": _poleSubtype,
          "connection": _lampConnection,
          "lampProfiles": lampProfiles,
          if (_poleSpNo != "") "switchPointNo": _poleSpNo,
          if (_poleRoadType != "") "roadType": _poleRoadType,
          if (_newRoadCategory != "") "newRoadCategory": _newRoadCategory,
          if (_incomingTransmissionLine != "")
            "incomingTransmissionLine": _incomingTransmissionLine,
        };
      }

      if (clickeventIsFor == "scanLampViaILM") {
        int intLmpWattage = int.tryParse(_newLmpWattage) ?? 0;
        postData["lamp"] = {
          "name": _newLmpName,
          "type": "lamp",
          "lampWatts": intLmpWattage,
          "manufacturer": _newManufacturer,
          "lampType": _newLmpType,
          "dimmable": _newDimmable,
          "year": _newLmpYear,
        };
      }
    } else {
      if (_firstDeviceType == "GW") {
        deviceWardName = _ccmsward == ''
            ? _hubward == ''
                ? _selectedWard
                : _hubward
            : _ccmsward;
        deviceZoneName = _ccmszone == ''
            ? _hubzone == ''
                ? _selectedZone
                : _hubzone
            : _ccmszone;
        deviceRegionName = _ccmsregion == ''
            ? _hubregion == ''
                ? _selectedRegion
                : _hubregion
            : _ccmsregion;
      } else {
        deviceWardName = _selectedWard;
        deviceZoneName = _selectedZone;
        deviceRegionName = _selectedRegion;
      }

      postData = {
        "name": _firstDeviceName,
        "deviceId": _firstDeviceId,
        "deviceType": _firstDeviceTypewithChr,
        "state": "INSTALLED",
        "accuracy": _fetchedAcc,
        "wardName": deviceWardName,
        "zoneName": deviceZoneName,
        "region": deviceRegionName,
        "wardId": _userSelectedWardid,
        "auditImg": _auditImg,
        "installedOn": DateTime.now().millisecondsSinceEpoch.toString(),
        "installedBy": usermail,
        "customerId": _selectedCustomerId,
        "createdTime": _createdTime,
        "lightPointId": _lampAssetsId,
        "slatitude": _fetchedLat,
        "slongitude": _fetchedLong,
        "location": filteredmanualEnteredLocation,
        if (multiSwitchPointNo.isNotEmpty) "switchPointNo": multiSwitchPointNo,
        "earthingRequired": isSpEarthingAvailable,
        if (spEarthingReason.isNotEmpty) "earthingRemarks": spEarthingReason,
        "activityMode": storedMode,
      };
    }

    if ((_fetchedAcc.isEmpty || double.parse(_fetchedAcc) > 99) &&
        (clickEventIsFor != "addILMViaPole" && clickEventIsFor != "addILM")) {
      //await Future.delayed(const Duration(seconds: 2));
      deviceInstallation(ref, context, insData, clickEventIsFor);
    } else {
      var res = _firstDeviceType == "ILM" ||
              _lampAssetType ==
                  'LAMP' //lamp type is considered in the scenario ilm installation via scan a lamp[already installed lamp without ILM], there will be no ILM details
          ? await _service.ilmInstallService(ref, context, postData)
          : await _service.gwInstallService(
              ref, context, postData, firstDeviceType);
      if (res == 1) {
        await _telemetryService
            .pushValuesToUserTelemetry({"activityMode": storedMode});
        bool isLocationTrackingRequi = await isLocationTrackingRequired();
        if (isLocationTrackingRequi) {
          ref.read(userTrackingController).activityLocationTracking(
              ref,
              _firstDeviceType == "ILM" || _lampAssetType == "LAMP"
                  ? 'ILM Installation'
                  : 'GW Installation',
              _firstDeviceName);
        }

        List customSwitchPointNo =
            ref.watch(surveyController).customSwitchPointNo;
        if (customSwitchPointNo.isNotEmpty) {
          for (String sp in customSwitchPointNo) {
            if (sp.isNotEmpty) {
              ref.read(surveyController).updateSwitchPointSurveyFieldValues(
                  context, ref, sp, 'switchPointNumber');
              await ref
                  .read(surveyController)
                  .insertCustomSpSurveyDetailsSync(context, ref, {
                "slatitude": _fetchedLat,
                "slongitude": _fetchedLong,
                "location": filteredmanualEnteredLocation,
                "accuracy": _fetchedAcc,
                "wardName": deviceWardName,
                "zoneName": deviceZoneName,
                "region": deviceRegionName,
                "wardId": _userSelectedWardid,
                "customerId": _selectedCustomerId,
                "installedBy": usermail
              });
            }
          }
        }

        await EasyLoading.dismiss();
        ref.read(deviceController).enableButton();
        await showDialogFunc(
            context,
            ref,
            postData,
            deviceImage,
            _firstDeviceType == "ILM" ||
                    _firstDeviceType == "LUMINODE" ||
                    _firstDeviceType == 'ILM-4G'
                ? _newLmpName
                : "-",
            clickEventIsFor,
            _poleName);
      } else if (res is Map &&
          res.containsKey('status') &&
          res['status'] != 200 &&
          res['status'] != 500) {
        EasyLoading.dismiss();
        ref.read(deviceController).enableButton();
        if (res['status'] == 404) {
          showSnackBar(ref, context,
              "Lamp/ILM installation requires an active Switchpoint. Please install a Switchpoint first.");
        } else {
          showSnackBar(ref, context, res['message'].toString());
        }
        Navigator.of(context).pushNamedAndRemoveUntil(
            homeRoute, (Route<dynamic> route) => false);
      } else if (res == 401) {
        EasyLoading.dismiss();
        ref.read(deviceController).enableButton();
        await tokenExpired(context, ref);
      } else if (res == '500' ||
          (res is Map && (res["status"] == 500 || res["status"] == 503))) {
        EasyLoading.dismiss();
        ref.read(deviceController).enableButton();
        showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
        Navigator.of(context).pushNamedAndRemoveUntil(
            homeRoute, (Route<dynamic> route) => false);
      } else {
        EasyLoading.dismiss();
        ref.read(deviceController).enableButton();
        showSnackBar(ref, context, ErrorMessages.tryAgainError);
        Navigator.of(context).pushNamedAndRemoveUntil(
            homeRoute, (Route<dynamic> route) => false);
      }
      ref.read(surveyController).resetSpNumber();
    }
  }

  Future<void> lampInstallation(
      WidgetRef ref, context, data, clickEventIsFor) async {
    int intLmpWattage = int.tryParse(newLmpWattage) ?? 0;
    String usermail = ref.watch(loginController).userMail;
    String location = data.containsKey('landmark') ? data['landmark'] : "";
    String concatenatedmanualEnteredLocation =
        "$_manualEnteredLocation,$location";

    String filteredmanualEnteredLocation = concatenatedmanualEnteredLocation
        .replaceAll(RegExp(r',\s*'), ',')
        .replaceAll(RegExp(r'^,\s*'), '')
        .trim();

    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);

    var postData = {
      "lamp": {
        "name": clickEventIsFor == "recordExistingLamp"
            ? _finalNewLmpName
            : _newLmpName,
        "type": "lamp",
        "lampWatts": intLmpWattage,
        "lampType": newLmpType,
        if (clickEventIsFor != "recordExistingLamp")
          "manufacturer": _newManufacturer,
        if (clickEventIsFor != "recordExistingLamp") "dimmable": _newDimmable,
        if (clickEventIsFor != "recordExistingLamp") "year": _newLmpYear,
        "isExistingLamp": clickEventIsFor == "recordExistingLamp" ? true : false
      },
      "activityMode": storedMode,
      "latitude": _poleLat == ''
          ? _lpLat.isEmpty
              ? _fetchedLat
              : _lpLat
          : _poleLat,
      "longitude": _poleLong == ''
          ? _lpLong.isEmpty
              ? _fetchedLong
              : _lpLong
          : _poleLong,
      "accuracy": _poleAccuracy == ''
          ? _lpAccuracy.isEmpty
              ? _fetchedAcc
              : _lpAccuracy
          : _poleAccuracy,
      "landmark": filteredmanualEnteredLocation,
      "wardName": _poleWardName == ''
          ? _lpward == ''
              ? _selectedWard
              : _lpward
          : _poleWardName,
      "zoneName": _poleZoneName == ''
          ? _lpzone == ''
              ? _selectedZone
              : _lpzone
          : _poleZoneName,
      "region": _poleRegion == ''
          ? _lpregion == ''
              ? _selectedRegion
              : _lpregion
          : _poleRegion,
      "auditImg": _auditImg,
      "installedOn": DateTime.now().millisecondsSinceEpoch.toString(),
      "installedBy": usermail,
      "customerId": _selectedCustomerId,
      "wardId": clickEventIsFor == "addLampInMaintenance"
          ? _deviceOrAssetWardId
          : _userSelectedWardid,
      "lightPointId": clickEventIsFor == "addLampInMaintenance"
          ? _lampAssetsId
          : _lampLightPointId,
      "poleId": _poleId,
    };
    if (_poleId != "") {
      postData["pole"] = {
        "name": _poleName,
        "armCount": _armCount,
        "type": _poleSubtype,
        if (_lampConnection != "") "connection": _lampConnection,
        "lampProfiles": lampProfiles,
        if (_poleSpNo != "") "switchPointNo": _poleSpNo,
        if (_poleRoadType != "") "roadType": _poleRoadType,
        if (_newRoadCategory != "") "newRoadCategory": _newRoadCategory,
        if (_incomingTransmissionLine != "")
          "incomingTransmissionLine": _incomingTransmissionLine,
      };
    }
    if (clickEventIsFor != "addLampInMaintenance") {
      postData["pole"] = {
        "name": _poleName,
        "armCount": _armCount,
        "type": _poleSubtype,
        if (_lampConnection != "") "connection": _lampConnection,
        "lampProfiles": lampProfiles,
        if (_poleSpNo != "") "switchPointNo": _poleSpNo,
        if (_poleRoadType != "") "roadType": _poleRoadType,
        if (_newRoadCategory != "") "newRoadCategory": _newRoadCategory,
        if (_incomingTransmissionLine != "")
          "incomingTransmissionLine": _incomingTransmissionLine,
      };
    }

    var res = await _service.lampInstallService(ref, context, postData);
    await ref.read(lampController).saveLampActivityToHive(
          postData,
          _finalNewLmpName,
          res['statusCode'],
          res['uploaded'],
        );
    if (res['statusCode'] == 200) {
      if (clickeventIsFor != "addLampInMaintenance") {
        await _service.lampCountService(
            ref, context, _userSelectedWardid, updateLampCount);
        await _service.lampInstallationHistory(
            ref, context, usermail, userSelectedWardid, lampHistoryData);
      }
      await _telemetryService
          .pushValuesToUserTelemetry({"activityMode": storedMode});
      bool isLocationTrackingRequi = await isLocationTrackingRequired();
      if (isLocationTrackingRequi) {
        ref.read(userTrackingController).activityLocationTracking(
            ref, 'Lamp Installation', _finalNewLmpName);
      }
      await EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      _newLmpType = '';
      _newLmpWattage = '';
      await successTick(
          context,
          ErrorMessages.lampInstalledonPoleAlert(
              lampName: _finalNewLmpName, poleName: _poleName));
      if (clickeventIsFor != "addLampInMaintenance") {
        EasyLoading.show(
          status: '',
          dismissOnTap: false,
        );
        await _service.getDeviceDataService(
            ref, context, _poleName, 1, "scanAPole");
        await EasyLoading.dismiss();
        if (context.mounted) {
          Navigator.popUntil(
              context, (route) => route.settings.name == poleDetailsRoute);
          Navigator.pushReplacementNamed(context, poleDetailsRoute);
        }
      } else {
        ref.read(bottomMenuStateProvider.state).state = 0;
        Navigator.of(context).pushNamedAndRemoveUntil(
            homeRoute, (Route<dynamic> route) => false);
      }
    } else if (res is Map &&
        res.containsKey('statusCode') &&
        res['statusCode'] != 200 &&
        res['statusCode'] != 500) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      ref.read(deviceController).emptyDeviceSearchList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PoleScanPage(),
        ),
      );
      if (res['statusCode'] == 404) {
        showSnackBar(ref, context,
            "Lamp/ILM installation requires an active Switchpoint. Please install a Switchpoint first.");
      } else {
        showSnackBar(ref, context, res['message'].toString());
      }
    } else if (res['statusCode'] == 401) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await tokenExpired(context, ref);
    } else if (res['statusCode'] == '500' ||
        (res is Map &&
            (res["statusCode"] == 500 || res["statusCode"] == 503))) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      // below responseMessage recieves whenever lamp installation exceeds arm count
      // to avoid multiple lightpoints creation
      String responseMessage =
          "Request ignored: Lightpoint count exceeds pole's arm count";
      showSnackBar(
          ref,
          context,
          res["message"] == responseMessage
              ? 'Lamp cannot be installed'
              : ErrorMessages.systemNotResponsiveError);
      if (res["message"] == responseMessage) {
        Navigator.of(context).pushNamedAndRemoveUntil(
            homeRoute, (Route<dynamic> route) => false);
      }
    } else {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
      Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    }
  }

  Future<void> deviceReplace(WidgetRef ref, context, repData) async {
    String usermail = ref.watch(loginController).userMail;
    String landmarkOrLocation = repData.containsKey('landmark')
        ? repData['landmark']
        : repData['location'];
    String concatenatedmanualEnteredLocation =
        "$_manualEnteredLocation,$landmarkOrLocation";

    String filteredmanualEnteredLocation = concatenatedmanualEnteredLocation
        .replaceAll(RegExp(r',\s*'), ',')
        .replaceAll(RegExp(r'^,\s*'), '')
        .trim();

    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);
    // print(filteredmanualEnteredLocation);
    var data = {};
    if (_firstDeviceType == "ILM") {
      data = {
        "ilm": {"name": _secondDeviceName},
        "activityMode": storedMode,
        "latitude": _poleLat == '' ? _lpLat : _poleLat,
        "longitude": _poleLong == '' ? _lpLong : _poleLong,
        "accuracy": _poleAccuracy == '' ? _lpAccuracy : _poleAccuracy,
        "landmark": filteredmanualEnteredLocation,
        "wardName": _lpward,
        "zoneName": _lpzone,
        "region": _lpregion,
        "auditImg": _auditImg,
        "installedOn": DateTime.now().millisecondsSinceEpoch.toString(),
        "installedBy": usermail,
        "customerId": _selectedCustomerId,
        "wardId": _deviceOrAssetWardId,
        "lightPointId": _lampAssetsId,
        "poleId": _poleId,
        "remove": {"ilmId": _firstDeviceId},
      };
      if (_poleId != "") {
        data["pole"] = {
          "name": _poleName,
          "armCount": _armCount,
          "type": _poleSubtype,
          "connection": _lampConnection,
          "lampProfiles": lampProfiles
        };
      }
    } else {
      if (clickeventIsFor == 'ebMeterReplace') {
        data["ebmeterNo"] = _ebMeterNo;
        data['ccmsId'] = _ccmsAssetsId;
        data["activityMode"] = storedMode;
        data['replaceWith'] = {};
        data['replaceWith']["ebmeterNo"] = _newEbMeterNo;
        data['replaceWith']["newMeterReading"] = _newMeterReadingValue;
        data['replaceWith']["oldMeterReading"] = _oldMeterReadingValue;
        data['replaceWith']["customer"] = selectedCustomer;
        data['replaceWith']["auditImg"] = _auditImg;
        data['replaceWith']["region"] = _ccmsregion;
        data['replaceWith']["zoneName"] = _ccmszone;
        data['replaceWith']["wardName"] = _ccmsward;
        data['replaceWith']["location"] = filteredmanualEnteredLocation;
        data['replaceWith']["slatitude"] = _ccmsLat;
        data['replaceWith']['slongitude'] = _ccmsLong;
        data['replaceWith']['installedBy'] = usermail;
        data['replaceWith']['installedOn'] =
            DateTime.now().millisecondsSinceEpoch.toString();
        // log('meterReadingOffset : $_meterReadingValue, ebMeterNumb : $_userSelectedDeviceOrAssetName, lat: $_ccmsLat, long: $_ccmsLong,loc: $filteredmanualEnteredLocation, username: $usermail,timestamp: ${DateTime.now().millisecondsSinceEpoch.toString()}, customerName: $_selectedCustomer, region: $_ccmsregion');
      } else if (_firstDeviceType == "SEMC") {
        data["deviceId"] = _firstDeviceId;
        data['smslcId'] = _smslcAssetId;
        data["activityMode"] = storedMode;
        data['replaceWith'] = {};
        data['replaceWith']["name"] = _secondDeviceName;
        data['replaceWith']["state"] = "INSTALLED";
        data['replaceWith']["condition"] = _secondDeviceCurrentCondition;
        data['replaceWith']["wardName"] = _smslcward;
        data['replaceWith']["zoneName"] = _smslczone;
        data['replaceWith']["region"] = _smslcregion;
        data['replaceWith']["wardId"] = _deviceOrAssetWardId;
        data['replaceWith']["auditImg"] = _auditImg;
        data['replaceWith']['installedOn'] =
            DateTime.now().millisecondsSinceEpoch.toString();
        data['replaceWith']['installedBy'] = usermail;
        data['replaceWith']['customerId'] = _selectedCustomerId;
        data['replaceWith']["accuracy"] = _smslcAcc;
        data['replaceWith']["slatitude"] = _smslcLat == '' ? _hubLat : _ccmsLat;
        data['replaceWith']["slongitude"] = _smslcLong;
        data['replaceWith']["location"] = filteredmanualEnteredLocation;
      } else {
        data["deviceId"] = _firstDeviceId;
        data['ccmsId'] = _ccmsAssetsId == '' ? _hubId : _ccmsAssetsId;
        data["activityMode"] = storedMode;
        data['replaceWith'] = {};
        data['replaceWith']["name"] = _secondDeviceName;
        data['replaceWith']["state"] = "INSTALLED";
        data['replaceWith']["condition"] = _secondDeviceCurrentCondition;
        data['replaceWith']["wardName"] =
            _ccmsward == '' ? _hubward : _ccmsward;
        data['replaceWith']["zoneName"] =
            _ccmszone == '' ? _hubzone : _ccmszone;
        data['replaceWith']["region"] =
            _ccmsregion == '' ? _hubregion : _ccmsregion;
        data['replaceWith']["wardId"] = _deviceOrAssetWardId;
        data['replaceWith']["auditImg"] = _auditImg;
        data['replaceWith']['installedOn'] =
            DateTime.now().millisecondsSinceEpoch.toString();
        data['replaceWith']['installedBy'] = usermail;
        data['replaceWith']['customerId'] = _selectedCustomerId;
        data['replaceWith']["accuracy"] = _ccmsAcc == '' ? _hubAcc : _ccmsAcc;
        data['replaceWith']["slatitude"] = _ccmsLat == '' ? _hubLat : _ccmsLat;
        data['replaceWith']["slongitude"] =
            _ccmsLong == '' ? _hubLong : _ccmsLong;
        data['replaceWith']["location"] = filteredmanualEnteredLocation;
      }
    }

    var res = _firstDeviceType == "ILM" ||
            _firstDeviceType == "LUMINODE" ||
            _firstDeviceType == 'ILM-4G'
        ? await _service.ilmReplaceService(ref, context, data)
        : await _service.gwReplaceService(ref, context, clickeventIsFor, data);
    if (res == 1) {
      await _telemetryService
          .pushValuesToUserTelemetry({"activityMode": storedMode});
      bool isLocationTrackingRequi = await isLocationTrackingRequired();
      if (isLocationTrackingRequi) {
        ref.read(userTrackingController).activityLocationTracking(
            ref,
            _firstDeviceType == "ILM"
                ? 'ILM Replace'
                : clickeventIsFor == 'ebMeterReplace'
                    ? 'EB Meter Replace'
                    : 'GW Replace',
            _firstDeviceType == "ILM"
                ? _secondDeviceName
                : clickeventIsFor == 'ebMeterReplace'
                    ? _newEbMeterNo
                    : _secondDeviceName);
      }
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await successTick(
          context,
          ErrorMessages.deviceReplaceSuccessAlert(
              firstDeviceName: clickeventIsFor == 'ebMeterReplace'
                  ? _ebMeterNo
                  : _firstDeviceName,
              secondDeviceName: clickeventIsFor == 'ebMeterReplace'
                  ? _newEbMeterNo
                  : _secondDeviceName));
      ref.read(bottomMenuStateProvider.state).state = 0;
      await Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    } else if (res is Map &&
        res.containsKey('status') &&
        res['status'] != 200 &&
        res['status'] != 500) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, res['message'].toString());
      await Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    } else if (res == 401) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await tokenExpired(context, ref);
    } else if (res == '500' ||
        (res is Map && (res["status"] == 500 || res["status"] == 503))) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  Future<void> deviceRemove(WidgetRef ref, context, data) async {
    String usermail = ref.watch(loginController).userMail;
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);
    if (_firstDeviceType == "ILM") {
      data = {
        "remove": {"ilmId": _firstDeviceId},
        "removedBy": usermail,
        "auditImg": _auditImg,
        "region": _poleRegion == ''
            ? _lpregion == ''
                ? _selectedRegion
                : _lpregion
            : _poleRegion,
        "customerId": _selectedCustomerId,
        "activityMode": storedMode,
      };
    } else {
      data['ccmsId'] = _ccmsAssetsId;
      data['auditImg'] = _auditImg;
      data['replaceWith'] = {};
      data['activityMode'] = storedMode;
    }

    var res = _firstDeviceType == "ILM"
        ? await _service.ilmReplaceService(ref, context, data)
        : await _service.gwReplaceService(ref, context, clickeventIsFor, data);
    if (res == 1) {
      await _telemetryService
          .pushValuesToUserTelemetry({"activityMode": storedMode});
      bool isLocationTrackingRequi = await isLocationTrackingRequired();
      if (isLocationTrackingRequi) {
        ref
            .read(userTrackingController)
            .activityLocationTracking(ref, 'ILM Remove', _firstDeviceName);
      }
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await successTick(context,
          ErrorMessages.deviceRemoveSuccessAlert(deviceName: _firstDeviceName));
      ref.read(bottomMenuStateProvider.state).state = 0;
      await Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    } else if (res == 401) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await tokenExpired(context, ref);
    } else if (res == 404 || res == 400) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.invalidQRError);
    } else if (res.toString() == "Server Timeout. Please try Again!") {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  Future<void> lampRemove(WidgetRef ref, context, data) async {
    String usermail = ref.watch(loginController).userMail;
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);
    data = {
      "remove": {"lampId": _lampId},
      "removedBy": usermail,
      "auditImg": _auditImg,
      "region": _poleRegion == ''
          ? _lpregion == ''
              ? _selectedRegion
              : _lpregion
          : _poleRegion,
      "customerId": _selectedCustomerId,
      "activityMode": storedMode,
    };
    if (_firstDeviceName != '') {
      data["remove"]["ilmId"] = _firstDeviceId;
    }

    var res = await _service.lampReplaceService(ref, context, data);
    if (res == 1) {
      await _telemetryService
          .pushValuesToUserTelemetry({"activityMode": storedMode});
      bool isLocationTrackingRequi = await isLocationTrackingRequired();
      if (isLocationTrackingRequi) {
        ref.read(userTrackingController).activityLocationTracking(
            ref,
            'Lamp Remove',
            '$_lampName,${_firstDeviceName.isEmpty ? '-' : _firstDeviceName}');
      }
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await successTick(context,
          ErrorMessages.deviceRemoveSuccessAlert(deviceName: _lampName));
      ref.read(bottomMenuStateProvider.state).state = 0;
      await Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    } else if (res == 401) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await tokenExpired(context, ref);
    } else if (res == 404 || res == 400) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.invalidQRError);
    } else if (res == '500' ||
        (res is Map && (res["status"] == 500 || res["status"] == 503))) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  Future<void> lampOnlyReplace(WidgetRef ref, context, repData) async {
    String usermail = ref.watch(loginController).userMail;
    String landmarkOrLocation =
        _poleLocation == '' ? _lpLandmark : _poleLocation;
    String concatenatedmanualEnteredLocation =
        "$_manualEnteredLocation,$landmarkOrLocation";

    String filteredmanualEnteredLocation = concatenatedmanualEnteredLocation
        .replaceAll(RegExp(r',\s*'), ',')
        .replaceAll(RegExp(r'^,\s*'), '')
        .trim();

    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);

    var data = {
      "activityMode": storedMode,
      "latitude": _poleLat == '' ? _lpLat : _poleLat,
      "longitude": _poleLong == '' ? _lpLong : _poleLong,
      "accuracy": _poleAccuracy == '' ? _lpAccuracy : _poleAccuracy,
      "landmark": filteredmanualEnteredLocation,
      "wardName": _lpward,
      "zoneName": _lpzone,
      "region": _lpregion,
      "auditImg": _auditImg,
      "installedOn": DateTime.now().millisecondsSinceEpoch.toString(),
      "installedBy": usermail,
      "customerId": _selectedCustomerId,
      "wardId": _deviceOrAssetWardId,
      "lightPointId": _lampAssetsId,
      "poleId": _poleId,
      "remove": {"lampId": _lampId}
    };
    if (_poleId != "") {
      data["pole"] = {
        "name": _poleName,
        "armCount": _armCount,
        "type": _poleSubtype,
        "connection": _lampConnection,
        "lampProfiles": lampProfiles
      };
    }
    //If users not skip the lamp while replace
    if (_secondLampName != '') {
      int intLmpWattage = int.tryParse(_secondLampWatts) ?? 0;
      data["lamp"] = {
        "name": _secondLampName,
        "type": _secondLampAssetType.toLowerCase(),
        "lampWatts": intLmpWattage,
        "manufacturer": _secondLampManufacturer,
        "lampType": _secondLampTypeSignify,
        "dimmable": _secondLampDimmable,
        "year": _secondLampYear
      };
    }

    var res = await _service.lampReplaceService(ref, context, data);
    if (res == 1) {
      await _telemetryService
          .pushValuesToUserTelemetry({"activityMode": storedMode});
      bool isLocationTrackingRequi = await isLocationTrackingRequired();
      if (isLocationTrackingRequi) {
        ref.read(userTrackingController).activityLocationTracking(
            ref,
            'Lamp Only Replace',
            _secondLampName.isEmpty
                ? '-'
                : '$_secondLampManufacturer-$_secondLampWatts-$secondLampAssetType-$_secondLampDimmable-$_secondLampYear-$_secondLampName');
      }
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await successTick(
          context,
          ErrorMessages.deviceReplaceSuccessAlert(
              firstDeviceName: _lampName,
              secondDeviceName:
                  '$_secondLampManufacturer-$_secondLampWatts-$secondLampAssetType-$_secondLampDimmable-$_secondLampYear-$_secondLampName'));
      ref.read(bottomMenuStateProvider.state).state = 0;
      await Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    } else if (res is Map &&
        res.containsKey('status') &&
        res['status'] != 200 &&
        res['status'] != 500) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, res['message'].toString());
      await Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    } else if (res == 401) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await tokenExpired(context, ref);
    } else if (res == '500' ||
        (res is Map && (res["status"] == 500 || res["status"] == 503))) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  Future<void> lampAndILMReplace(WidgetRef ref, context, repData) async {
    String usermail = ref.watch(loginController).userMail;
    String landmarkOrLocation =
        _poleLocation == '' ? _lpLandmark : _poleLocation;

    String concatenatedmanualEnteredLocation =
        "$_manualEnteredLocation,$landmarkOrLocation";

    String filteredmanualEnteredLocation = concatenatedmanualEnteredLocation
        .replaceAll(RegExp(r',\s*'), ',')
        .replaceAll(RegExp(r'^,\s*'), '')
        .trim();

    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);

    var data = {
      "ilm": {"name": _secondDeviceName},
      "activityMode": storedMode,
      "latitude": _poleLat == '' ? _lpLat : _poleLat,
      "longitude": _poleLong == '' ? _lpLong : _poleLong,
      "accuracy": _poleAccuracy == '' ? _lpAccuracy : _poleAccuracy,
      "landmark": filteredmanualEnteredLocation,
      "wardName": _lpward,
      "zoneName": _lpzone,
      "region": _lpregion,
      "auditImg": _auditImg,
      "installedOn": DateTime.now().millisecondsSinceEpoch.toString(),
      "installedBy": usermail,
      "customerId": _selectedCustomerId,
      "wardId": _deviceOrAssetWardId,
      "lightPointId": _lampAssetsId,
      "poleId": _poleId,
      "remove": {"ilmId": _firstDeviceId, "lampId": _lampId}
    };
    if (_poleId != "") {
      data["pole"] = {
        "name": _poleName,
        "armCount": _armCount,
        "type": _poleSubtype,
        "connection": _lampConnection,
        "lampProfiles": lampProfiles
      };
    }
    if (_secondLampName != '') {
      int intLmpWattage = int.tryParse(_secondLampWatts) ?? 0;
      data["lamp"] = {
        "name": _secondLampName,
        "type": "lamp",
        "lampWatts": intLmpWattage,
        "manufacturer": _secondLampManufacturer,
        "lampType": _secondLampTypeSignify,
        "dimmable": _secondLampDimmable,
        "year": _secondLampYear
      };
    }

    var res = await _service.lampReplaceService(ref, context, data);
    if (res == 1) {
      await _telemetryService
          .pushValuesToUserTelemetry({"activityMode": storedMode});
      bool isLocationTrackingRequi = await isLocationTrackingRequired();
      if (isLocationTrackingRequi) {
        ref.read(userTrackingController).activityLocationTracking(
            ref,
            'Lamp & ILM Replace',
            '${_secondLampName.isEmpty ? '-' : '$_secondLampManufacturer-$_secondLampWatts-$secondLampAssetType-$_secondLampDimmable-$_secondLampYear-$_secondLampName'},$_secondDeviceName');
      }
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await successTick(
          context,
          ErrorMessages.deviceReplaceSuccessAlert(
              firstLampName: _lampName,
              firstDeviceName: _firstDeviceName,
              secondLampName:
                  '$_secondLampManufacturer-$_secondLampWatts-$secondLampAssetType-$_secondLampDimmable-$_secondLampYear-$_secondLampName',
              secondDeviceName: _secondDeviceName));
      ref.read(bottomMenuStateProvider.state).state = 0;
      await Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    } else if (res is Map &&
        res.containsKey('status') &&
        res['status'] != 200 &&
        res['status'] != 500) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, res['message'].toString());
      await Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    } else if (res == 401) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      await tokenExpired(context, ref);
    } else if (res == '500' ||
        (res is Map && (res["status"] == 500 || res["status"] == 503))) {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      EasyLoading.dismiss();
      ref.read(deviceController).enableButton();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  Future<void> deviceListSearch(WidgetRef ref, context, val,
      {int page = 0,
      bool requiredPagination = false,
      String prefixText = ''}) async {
    if (page == 0) {
      _deviceSearchPage = 0;
      _hasMoreDeviceSearch = true;
      _lastSearchQuery = val;
    } else {
      toggleDeviceSearchLoadingMore(true);
      val = _lastSearchQuery;
    }

    var res = await _service.deviceListSearchService(
        ref,
        context,
        val,
        page,
        requiredPagination: requiredPagination,
        prefixText);
    if (res == 1) {
      if (page != 0) {
        _deviceSearchPage = page;
      }
    } else if (res == 401) {
      await tokenExpired(context, ref);
    } else if (res == 404 || res == 400) {
      if (page == 0) {
        ref.read(deviceController).emptyDeviceSearchList();
        showSnackBar(ref, context,
            'No device/ asset is found. Please try with another one.');
      } else {
        _hasMoreDeviceSearch = false;
      }
    } else if (res.toString() == "Server Timeout. Please try Again!") {
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
    toggleDeviceSearchLoadingMore(false);
    ref.read(poleController).toggleSearchLoader(false);
  }

  void s3imageUpload(
      ref, context, filePath, firstOrSecondDevice, fileName, activity) {
    _auditImg = '$fileName.jpg';
    // var postDt = {"name": _auditImg, "activity": activity, "auditImg": image};
    // log('s3 upload data: ${postDt.toString()}');
    _s3Service.updateSurveyImageServiceS3(filePath, _auditImg);
  }

  void s3ThreeImagesUpload(List<String> filePaths, List<String> fileNames) {
    final names = fileNames.map((n) => '$n.jpg').toList();
    _auditImg = jsonEncode(names);
    for (int i = 0; i < filePaths.length; i++) {
      _s3Service.updateSurveyImageServiceS3(filePaths[i], names[i]);
    }
  }

  bool isWattageEqualRecommended(int wattage) {
    return _recommendedWattage
        .any((items) => items['recommended_wattage'] == wattage);
  }

  void setLampLightPointId(String value) {
    _lampLightPointId = value;
    notifyListeners();
  }

  Future<void> scanLampAsset(ref, context, firstOrSecond, clickEventIsFor,
      {String scannedResponse = ''}) async {
    _firstOrSecondDevice = firstOrSecond;
    isLocationFetchingComplete(true);

    try {
      if (scannedResponse != "") {
        EasyLoading.show(
          status: '',
          dismissOnTap: false,
        );
        String device = scannedResponse;
        log(device);
        Map<String, dynamic> decodedData = jsonDecode(device);
        final requiredKeys = ['m', 'w', 'l', 'd', 'y', 'i'];
        final isValidQr = requiredKeys.every(
          (key) =>
              decodedData.containsKey(key) &&
              decodedData[key] != null &&
              decodedData[key].toString().trim().isNotEmpty,
        );

        if (!isValidQr) {
          EasyLoading.dismiss();
          showSnackBar(ref, context, ErrorMessages.invalidQRError);
          return;
        }
        _newLmpName = decodedData['i'];
        _newManufacturer = decodedData['m'];
        _newLmpYear = decodedData['y'];
        _newDimmable = decodedData['d'];
        _newLmpWattage = decodedData['w'];
        _newLmpType = decodedData['l'];
        _finalNewLmpName =
            '$_newManufacturer-$_newLmpWattage-$_newLmpType-$_newDimmable-$_newLmpYear-$_newLmpName';
        int intLmpWattage = int.tryParse(_newLmpWattage) ?? 0;
        if (_newLmpName.isNotEmpty) {
          var res = await _service.getDeviceDataService(
              ref, context, _finalNewLmpName, firstOrSecond, clickEventIsFor);
          EasyLoading.dismiss();

          if (res == 1) {
            if (_lampState == 'INSTALLED') {
              // if (isWattageEqualRecommended(intLmpWattage)) {
              await userAlertWithNoAction(
                  ref,
                  context,
                  ErrorMessages.lampFoundScanAnotherAlert(
                      lampName: _lampName, lampWard: _lampWard));
            } else if (_lampState == 'INSTALLABLE') {
              if (isWattageEqualRecommended(intLmpWattage)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LampDetailsPage(),
                  ),
                );
              } else {
                List<dynamic> wattages = _recommendedWattage
                    .map((map) => map['recommended_wattage'] ?? 'N/A')
                    .toSet()
                    .toList();
                var recommWattages = wattages.join(', ');
                await warningPopup(
                    ref,
                    context,
                    ErrorMessages.lampWattageMismatchWarning(
                        intLmpWattage: intLmpWattage,
                        recommWattages: recommWattages));
              }
            }
          } else if (res == 401) {
            await tokenExpired(context, ref);
          } else if (res == 404) {
            if (isWattageEqualRecommended(intLmpWattage)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LampDetailsPage(),
                ),
              );
            } else {
              List<dynamic> wattages = _recommendedWattage
                  .map((map) => map['recommended_wattage'] ?? 'N/A')
                  .toSet()
                  .toList();
              var recommWattages = wattages.join(', ');
              await warningPopup(
                  ref,
                  context,
                  ErrorMessages.lampWattageMismatchWarning(
                      intLmpWattage: intLmpWattage,
                      recommWattages: recommWattages));
            }
          } else if (res.toString() == "Server Timeout. Please try Again!") {
            showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
          } else {
            showSnackBar(ref, context, ErrorMessages.tryAgainError);
          }
        } else {
          EasyLoading.dismiss();
          showSnackBar(ref, context, ErrorMessages.invalidQRError);
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      showSnackBar(ref, context, ErrorMessages.invalidQRError);
    }
  }

  Future<void> lampCount(WidgetRef ref, context, wardId, usermail) async {
    EasyLoading.show(
      status: '',
      dismissOnTap: false,
    );
    var res =
        await _service.lampCountService(ref, context, wardId, updateLampCount);
    if (res == 1) {
      await lampInstallationHistory(ref, context, wardId, usermail);
    } else if (res == 401) {
      EasyLoading.dismiss();
      await tokenExpired(context, ref);
    } else if (res.toString() == ErrorMessages.serverTimeOutError) {
      EasyLoading.dismiss();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      EasyLoading.dismiss();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  Future<void> installedLampNavigation(WidgetRef ref, context,
      deviceOrAssetName, firstOrSecond, clickEventIsFor) async {
    EasyLoading.show(
      status: '',
      dismissOnTap: false,
    );
    var installedLampOrIlmName = deviceOrAssetName;
    var res = await _service.getDeviceDataService(
        ref, context, installedLampOrIlmName, 1, clickEventIsFor);
    if (res == 1) {
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const IlmMaintenance(),
        ),
      );
    } else if (res == 401) {
      EasyLoading.dismiss();
      await tokenExpired(context, ref);
    } else if (res.toString() == ErrorMessages.serverTimeOutError) {
      EasyLoading.dismiss();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      EasyLoading.dismiss();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  String getTitleBasedOnActivity(String clickeventIsFor) {
    if (['addILM', 'addILMViaPole', 'scanLampViaILM', 'withoutLampViaILM']
        .contains(clickeventIsFor)) {
      return _installDevice('ilm', firstDeviceLable);
    }

    if (['addLampInMaintenance', 'addLamp', 'recordExistingLamp']
        .contains(clickeventIsFor)) {
      log('values for $finalNewLmpName: $newLmpType and $newLmpWattage');
      return _installDevice('lamp', finalNewLmpName);
    }

    if (clickeventIsFor == '1') {
      String iconType = firstDeviceType == "GW" ? 'gw' : 'ilm';
      return _installDevice(iconType, firstDeviceLable);
    }

    if (clickeventIsFor == 'ilmReplace') {
      return _replaceDevice('ilm', secondDeviceLable);
    }

    if (clickeventIsFor == 'lampOnlyReplace') {
      return _replaceLamp();
    }

    if (clickeventIsFor == 'lamp+ilmReplace') {
      return _replaceLampAndDevice();
    }

    if (clickeventIsFor == 'gwReplace') {
      return _replaceDevice('gw', secondDeviceLable);
    }

    if (clickeventIsFor == 'semcReplace') {
      return _replaceDevice('semc', secondDeviceLable);
    }

    if (clickeventIsFor == 'ebMeterReplace') {
      return _replaceDevice('eb', _newEbMeterNo);
    }

    if (clickeventIsFor == 'ilmRemove') {
      return _removeDevice('ilm', firstDeviceLable);
    }

    if (clickeventIsFor == 'removeLamp') {
      return _removeLamp();
    }

    return '';
  }

  String _installDevice(String type, String deviceLabel) {
    mapIconPath = imageLocation[type]!;
    deviceNameForImgAppend = deviceLabel;
    return 'INSTALLING $deviceLabel';
  }

  String _replaceDevice(String type, String deviceLabel) {
    mapIconPath = imageLocation[type]!;
    deviceNameForImgAppend = deviceLabel;
    return 'REPLACING $deviceLabel';
  }

  String _replaceLamp() {
    mapIconPath = imageLocation['lamp']!;
    if (secondLmpName.isEmpty) {
      deviceNameForImgAppend = '';
      return 'REPLACING the lamp';
    }
    deviceNameForImgAppend =
        '$secondLampManufacturer-$secondLampWatts-$secondLampTypeSignify-$secondLampDimmable-$secondLampYear-$secondLmpName';
    return 'REPLACING $deviceNameForImgAppend';
  }

  String _replaceLampAndDevice() {
    mapIconPath = imageLocation['lamp']!;
    if (secondLmpName.isEmpty) {
      deviceNameForImgAppend = secondDeviceLable;
      return 'REPLACING the lamp and $secondDeviceLable';
    }
    deviceNameForImgAppend =
        '$secondLampManufacturer-$secondLampWatts-$secondLampTypeSignify-$secondLampDimmable-$secondLampYear-$secondLmpName and $secondDeviceLable';
    return 'REPLACING $deviceNameForImgAppend';
  }

  String _removeDevice(String type, String deviceLabel) {
    mapIconPath = imageLocation[type]!;
    deviceNameForImgAppend = deviceLabel;
    return 'REMOVING $deviceLabel';
  }

  String _removeLamp() {
    mapIconPath = imageLocation['lamp']!;
    deviceNameForImgAppend = lampName.isEmpty
        ? '$newManufacturer-$newLmpWattage-$newLmpType-$newDimmable-$newLmpYear-$newLmpName'
        : lampName;
    return 'REMOVING $deviceNameForImgAppend';
  }

  Future<void> lampInstallationHistory(
      WidgetRef ref, context, wardId, usermail) async {
    var res = await _service.lampInstallationHistory(
        ref, context, usermail, wardId, lampHistoryData);
    if (res == 1) {
      ref.read(deviceController).emptyDeviceSearchList();
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PoleScanPage(),
        ),
      );
    } else if (res == 401) {
      EasyLoading.dismiss();
      await tokenExpired(context, ref);
    } else if (res.toString() == ErrorMessages.serverTimeOutError) {
      EasyLoading.dismiss();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      EasyLoading.dismiss();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
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

  void userSelectedDeviceOrAsset(userSelectedDeviceOrAsset) {
    _userSelectedDeviceOrAssetName = userSelectedDeviceOrAsset;
    notifyListeners();
  }

  void updateLampCount(data) async {
    _newLampCount = data['lamp_count'];
    notifyListeners();
  }

  void lampHistoryData(Map<String, dynamic> data) async {
    _lampHistoryData = [data['User_history']];
    _lampSpecificUserCount = data['Total_count'];
    notifyListeners();
  }

  void emptyLocation() {
    _firstDeviceRegionName = "";
    _firstDeviceWardName = "";
    _firstDeviceZoneName = "";
  }

  Future<void> recordExistingLampUnderPole(context, int index) async {
    String generatedLampId = 'L${(index + 1).toString().padLeft(2, '0')}';
    _finalNewLmpName = '$_poleName-$generatedLampId';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LampDetailsPage()),
    );
  }

  void setLampDetailsForRecordExistingLamp(String type, String wattage) {
    _newLmpType = type;
    _newLmpWattage = wattage;
    notifyListeners();
  }

  void emptyProjContext() {
    _selectedCustomer = '';
    _selectedRegion = '';
    _selectedWard = '';
    _selectedZone = '';
  }

  Future<void> updateWardId(
      BuildContext context, WidgetRef ref, wardName, id, desc) async {
    _selectedWard = wardName;
    _selectedWardId = id;
    _selectedContextId = id;
    ref.read(deviceController).selectedWardUpdate(wardName, id, desc);
    storeSelectedWardDetails(wardName, id);
    EasyLoading.dismiss();
    ref.read(bottomMenuStateProvider.state).state = 0;
    notifyListeners();
  }

  Future<void> updatedSelectedZone(zoneName, zoneId, desc) async {
    _selectedZone = zoneName;
    _selectedZoneId = zoneId;
    _selectedZoneDesc = desc;
    _selectedContextId = zoneId;
    storeSelectedZoneDetails(zoneName, zoneId);
    storeSelectedWardDetails('', '');
    notifyListeners();
  }

  Future<void> updatedSelectedRegion(
      regionName, regionId, poleSchema, desc) async {
    _selectedRegion = regionName;
    _selectedRegionId = regionId;
    _selectedContextId = regionId;
    _selectedRegionDesc = desc;

    _selectedRegionPoleSchema = poleSchema;
    storeSelectedRegionDetails(regionName, regionId);
    storeSelectedZoneDetails('', '');
    storeSelectedWardDetails('', '');

    notifyListeners();
  }

  void updatedSelectedCustomer(custName, custId) {
    _selectedCustomer = custName;
    _selectedCustomerId = custId;
    _selectedContextId = custId;
    storeSelectedCustomerDetails(
      custName,
      custId,
    );
    storeSelectedRegionDetails('', '');
    storeSelectedZoneDetails('', '');
    storeSelectedWardDetails('', '');

    notifyListeners();
  }

  void updateSelectedLocation(
      WidgetRef ref, String locationType, String value) {
    List<Ward> wardList = ref.read(locationController).wardList;
    switch (locationType) {
      case 'customer':
        _selectedRegion = value;
        _selectedZone = value;
        _selectedWard = value;
        ref.read(deviceController).updatedSelectedRegion('', '', '', '');
        ref.read(deviceController).updatedSelectedZone('', '', '');
        ref.read(deviceController).selectedWardUpdate('', '', '');
        wardList.clear();
        break;
      case 'region':
        _selectedZone = value;
        _selectedWard = value;
        ref.read(deviceController).updatedSelectedZone('', '', '');
        ref.read(deviceController).selectedWardUpdate('', '', '');
        wardList.clear();
        break;
      default:
        _selectedWard = value;
        ref.read(deviceController).selectedWardUpdate('', '', '');
    }
    notifyListeners();
  }

  void removeActivityOnTap(
      WidgetRef ref, BuildContext context, String clickEventIsFor, lat, long) {
    String userProximityRadius =
        ref.read(mapController).userProximityRadius.toString();
    EasyLoading.show(status: '');
    Utility.isConnected().then((value) async {
      if (value) {
        final isLocationServiceOn =
            await Utility.ensureLocationServiceEnabled();
        if (!isLocationServiceOn) return; //check if location is on

        bool isUserWithInProximity =
            await ref.read(panelController).checkUserProximity(ref, lat, long);
        EasyLoading.dismiss();
        if (!isUserWithInProximity) {
          wardRequiredAlert(context, ref,
              'You must be within $userProximityRadius m of the device/asset to control it.');

          return;
        }
        ref.read(deviceController).updateDevicecount(3);
        final cameras = await availableCameras();
        final firstCamera = cameras.first;
        await ref.read(deviceController).clickEventIsFor(clickEventIsFor);
        ref.read(deviceController).isLocationFetchingComplete(true);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TakePictureScreen(
                camera: firstCamera,
                clickeventIsFor: clickEventIsFor,
              ),
            ),
          );
        }
      } else {
        EasyLoading.dismiss();
        if (context.mounted) {
          await snackBar(context, ErrorMessages.offlineErrorTitle,
              ErrorMessages.offlineErrorMessage);
        }
      }
    });
  }

  void replaceInstallActivityOnTap(WidgetRef ref, BuildContext context,
      firstOrSecond, String clickEventIsFor, lat, long) async {
    String userProximityRadius =
        ref.read(mapController).userProximityRadius.toString();
    EasyLoading.show(status: '');
    Utility.isConnected().then((value) async {
      if (value) {
        try {
          final isLocationServiceOn =
              await Utility.ensureLocationServiceEnabled();
          if (!isLocationServiceOn) return; //check if location is on

          log('latitude: $lat, longitude: $long');

          bool isUserWithInProximity = await ref
              .read(panelController)
              .checkUserProximity(ref, lat, long);
          EasyLoading.dismiss();
          if (!isUserWithInProximity) {
            wardRequiredAlert(context, ref,
                'You must be within $userProximityRadius m of the device/asset to control it.');

            return;
          }
          await ref.read(deviceController).clickEventIsFor(clickEventIsFor);

          if (context.mounted) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ScanQRWithCustomScreen(
                  firstOrSecond: firstOrSecond,
                  clickEventIsFor: clickEventIsFor),
            ));
          }
        } catch (e) {
          log(e.toString());
        }
      } else {
        EasyLoading.dismiss();
        if (context.mounted) {
          await snackBar(context, ErrorMessages.offlineErrorTitle,
              ErrorMessages.offlineErrorMessage);
        }
      }
    });
  }

  String get lampOrILMscanForReplace => _lampOrILMScanForReplace;
  List get deviceSearchList => _deviceSearchList;
  List get poleSearchList => _poleSearchList;
  List get spSearchList => _spSearchList;
  List get transSearchList => _transSearchList;
  String get selectedWard => _selectedWard;
  String get selectedWardId => _selectedWardId;
  String get selectedZone => _selectedZone;
  String get selectedZoneId => _selectedZoneId;
  String get selectedRegion => _selectedRegion;
  String get selectedRegionId => _selectedRegionId;
  String get selectedRegionPoleSchema => _selectedRegionPoleSchema;
  String get selectedCustomer => _selectedCustomer;
  int get firstOrSecondDevice => _firstOrSecondDevice;
  String get userSelectedWardid => _userSelectedWardid;
  String get selectedCustomerId => _selectedCustomerId;
  String get fetchedLat => _fetchedLat;
  String get fetchedLong => _fetchedLong;
  String get fetchedAcc => _fetchedAcc;
  String get selectedContextId => _selectedContextId;

  String get lightpointState => _lightpointState;
  String get firstDeviceWardId => _firstDeviceWardId;
  int get ccmslastCommunicatedStatus => _ccmslastCommunicatedStatus;
  int get hublastCommunicatedStatus => _hublastCommunicatedStatus;

  String get gwAssetName => _gwAssetName;

  String get poleState => _poleState;
  int get poleInstalledOn => _poleInstalledOn;
  String get poleInstalledBy => _poleInstalledBy;

  String get firstDeviceLampWatts => _firstDeviceLampWatts;
  String get firstDeviceAccuracy => _firstDeviceAccuracy;

  String get lampManufacturer => _lampManufacturer;
  String get lampDimmable => _lampDimmable;
  String get lampTypeSignify => _lampTypeSignify;
  String get lampYear => _lampYear;

  String get firstDeviceLable => _firstDeviceName;
  String get firstDeviceId => _firstDeviceId;
  String get firstDeviceType => _firstDeviceType;
  String get lpregion => _lpregion;
  String get lpward => _lpward;
  String get lpzone => _lpzone;
  String get fisrDevicelandmark => _fisrDevicelandmark;
  int get firstDevicelastCommunicatedStatus =>
      _firstDevicelastCommunicatedStatus;
  int get lplastCommunicatedStatus => _lplastCommunicatedStatus;

  String get lpLandmark => _lpLandmark;
  int get deviceInstalledOn => _deviceInstalledOn;
  int get lightpointInstalledOn => _lightpointInstalledOn;
  String get lampAssets => _lampAssets;
  String get lampName => _lampName;
  String get lampAssetType => _lampAssetType;
  String get lampWatts => _lampWatts;
  int get lmpInstalledOn => _lmpInstalledOn;
  String get devicePath => _devicePath;
  bool get isButtonEnabled => _isButtonEnabled;
  String get userSelectedDeviceOrAssetName => _userSelectedDeviceOrAssetName;
  String get hubLandmark => _hubLandmark;
  String get hubState => _hubState;
  String get assetType => _assetType;
  String get hubregion => _hubregion;
  String get hubward => _hubward;
  String get hubzone => _hubzone;
  String get hubName => _hubName;
  String get ccmsLandmark => _ccmsLandmark;
  String get clickeventIsFor => _clickEventIsFor;
  String get lpInstallBy => _lpInstallBy;
  String get lpLat => _lpLat;
  String get lpLong => _lpLong;
  String get lpAccuracy => _lpAccuracy;
  String get lampInstallBy => _lampInstallBy;
  String get firstDeviceInstallBy => _firstDeviceInstallBy;
  String get ccmsregion => _ccmsregion;
  String get ccmsAssetsId => _ccmsAssetsId;
  String get ccmsward => _ccmsward;
  String get ccmszone => _ccmszone;
  String get ccmsLat => _ccmsLat;
  String get ccmsLong => _ccmsLong;
  String get hubLat => _hubLat;
  String get hubLong => _hubLong;
  String get ccmsState => _ccmsState;
  String get ebMeterNo => _ebMeterNo;
  String get ebMeterPhase => _ebMeterPhase;
  String get ebMeterReadingOffset => _ebMeterReadingOffset;
  String get ebMeterReplacedBy => _ebMeterReplacedBy;
  int get ebMeterReplacedOn => _ebMeterReplacedOn;
  int get ccmsInstalledOn => _ccmsInstalledOn;
  int get hubInstalledOn => _hubInstalledOn;
  int get gplastCommunicatedStatus => _gplastCommunicatedStatus;
  int get gwInstalledOn => _gwInstalledOn;
  String get gwState => _gwState;
  String get ccmsInstallBy => _ccmsInstallBy;
  String get hubInstallBy => _hubInstallBy;
  String get ccmsAssetName => _ccmsAssetName;
  bool get isLocationFetched => _isLocationFetched;
  String get newLmpName => _newLmpName;
  String get finalNewLmpName => _finalNewLmpName;
  String get newDimmable => _newDimmable;
  String get newLmpYear => _newLmpYear;
  String get newLmpType => _newLmpType;
  String get newManufacturer => _newManufacturer;
  int get newLampCount => _newLampCount;
  List get lmpHistoryData => _lampHistoryData;
  int get lampSpecificUserCount => _lampSpecificUserCount;
  String get newLmpWattage => _newLmpWattage;
  List<dynamic> get recommendedWattage => _recommendedWattage;
  String get poleSpNo => _poleSpNo;
  bool get isValidSp => _isValidSp;
  String get poleTransformerNo => _poleTransformerNo;
  String get newRoadCategory => _newRoadCategory;
  String get poleRoadType => _poleRoadType;
  String get incomingTransmissionLine => _incomingTransmissionLine;
  String get poleName => _poleName;
  String get poleLocation => _poleLocation;
  List get lampProfiles => _lampProfiles;
  String get poleLat => _poleLat;
  String get poleLong => _poleLong;
  String get poleWardName => _poleWardName;
  String get poleZoneName => _poleZoneName;
  String get poleRegion => _poleRegion;
  String get poleAccuracy => _poleAccuracy;
  String get poleClampDimension => _poleClampDimension;
  int get armCount => _armCount;
  List get lampNamesInRelation => _lampNamesInRelation;
  List get lampLightPointIdInRelation => _lampLightPointIdInRelation;
  List get ilmNamesInRelation => _ilmNamesInRelation;
  String get secondDeviceLable => _secondDeviceName;
  String get secondLmpName => _secondLampName;
  String get secondLampId => _secondLampId;
  String get secondLampAssetType => _secondLampAssetType;
  String get secondLampWatts => _secondLampWatts;
  String get secondLampManufacturer => _secondLampManufacturer;
  String get secondLampTypeSignify => _secondLampTypeSignify;
  String get secondLampYear => _secondLampYear;
  String get secondLampDimmable => _secondLampDimmable;
  String get selectedRegionDesc => _selectedRegionDesc;
  String get selectedZoneDesc => _selectedZoneDesc;
  String get selectedWardDesc => _selectedWardDesc;

  String get smslcAssetId => _smslcAssetId;
  String get smslcAssetName => _smslcAssetName;
  String get smslcLandmark => _smslcLandmark;
  String get smslcInstallBy => _smslcInstallBy;
  String get smslcregion => _smslcregion;
  String get smslcward => _smslcward;
  String get smslczone => _smslczone;
  String get smslcAcc => _smslcAcc;
  String get smslcLong => _smslcLong;
  String get smslcLat => _smslcLat;

  String get smslcState => _smslcState;
  int get smslcInstalledOn => _smslcInstalledOn;
}
