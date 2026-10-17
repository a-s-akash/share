import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/home_page/map_controller.dart';

import '../../ticket_notification/ticket_service.dart';
import '../../utils/dialog_box.dart';
import '../../utils/error_messages.dart';
import '../device_service.dart';
import '../telemetry_data_model.dart';

final panelController =
    ChangeNotifierProvider<PanelProvider>((ref) => PanelProvider());

class PanelProvider extends ChangeNotifier {
  final DeviceService _service = DeviceService();
  final TicketService _ticketService = TicketService();
  TelemetryData? _telemetryData;
  String _commStatusForPanel = '';
  String _relayStatusForPanel = '';
  bool _isMcbTripPanel = false;
  bool _toggleButton = true;
  bool _isWithInUserProximity = true;
  String warningMessage = "";

  void updateRelayStatusForPanel(String status) {
    _relayStatusForPanel = status;
    notifyListeners();
  }

  void toggleButtonValue(bool value) {
    _toggleButton = value;
    notifyListeners();
  }

  Future<bool> checkUserProximity(WidgetRef ref, lat, long) async {
    int userProximityRadius = ref.watch(mapController).userProximityRadius;
    double doubleLat = double.parse(lat);
    double doubleLong = double.parse(long);
    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(accuracy: LocationAccuracy.high));

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        doubleLat,
        doubleLong,
      );

      log("User distance from panel: $distance meters");

      if (distance <= userProximityRadius) {
        _isWithInUserProximity = true;
        warningMessage = "";
        log(warningMessage);
        return true;
      } else {
        _isWithInUserProximity = false;
        warningMessage =
            "You must be within $userProximityRadius m of the panel to control it.";
        log(warningMessage);
        return false;
      }
    } catch (e) {
      log("Error fetching location: $e");
      warningMessage = "Could not fetch location. Please enable GPS.";
      return false;
    }
  }

  Future<void> fetchTelemetryData(BuildContext context, WidgetRef ref) async {
    String firstDeviceId = ref.read(deviceController).firstDeviceId;
    final telemetryDataResponse = await _service.fetchTelemetryData(
        'DEVICE',
        firstDeviceId,
        'systime%2Crly%2Crv%2Cyv%2Cbv%2Cri%2Cyi%2Cbi%2Crw%2Cyw%2Cbw%2Cfault%2CtbtOpen%2Cpkt%2CtbtClose');
    _telemetryData = TelemetryData.fromJson(telemetryDataResponse);
    notifyListeners();
  }

  Future<void> updateTelemetryData(WidgetRef ref, BuildContext context) async {
    String firstDeviceId = ref.read(deviceController).firstDeviceId;

    // EasyLoading.show(
    //   status: '',
    //   dismissOnTap: false,
    // );
    var res = await _service.panelControlService(firstDeviceId, 'getLive');
    if (res == 1) {
      // EasyLoading.dismiss();
      await Future.delayed(const Duration(seconds: 5));
      await fetchTelemetryData(context, ref);
    } else {
      // EasyLoading.dismiss();
      await failureAlert(context, ErrorMessages.unableToRequestData);
    }
  }

  Future<void> commRelayStatusCalculation(WidgetRef ref, BuildContext context,
      {String deviceType = ''}) async {
    String assetsId = deviceType == 'SEMC'
        ? ref.read(deviceController).smslcAssetId
        : ref.read(deviceController).ccmsAssetsId;
    String firstDeviceId = ref.read(deviceController).firstDeviceId;
    final alarmDataForMcb =
        await _ticketService.getMcbAlarmForPanelCtrl(ref, context, assetsId);
    log('alarm Data For Mcb : $alarmDataForMcb');
    if (alarmDataForMcb) {
      _isMcbTripPanel = true;
    } else {
      _isMcbTripPanel = false;
    }
    log('is McbTrip Panel : $isMcbTripPanel');
    final telemetryDataForComm =
        await _service.fetchTelemetryData('ASSET', assetsId, 'systime%2Cpkt');

    log('telemetry Data ForComm : $telemetryDataForComm');
    if (telemetryDataForComm.isNotEmpty) {
      if (telemetryDataForComm['systime'][0]['value'] != null) {
        String systime = telemetryDataForComm['systime'][0]['value'];
        String pktData = telemetryDataForComm['pkt'][0]['value'];
        int intSystimeValue = int.parse(systime);
        int intPktData = int.parse(pktData);
        int currentTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        log('Current Timestamp (ms): $currentTimeStamp');
        if (intPktData == 8) {
          log('comm Status For Panel : OFFLINE(PF)');
          _commStatusForPanel = 'offline(pf)';
        } else if ((currentTimeStamp - intSystimeValue) < 14400) {
          //14400 value is a ccmsthreshold
          log('comm Status For Panel : ONLINE');
          _commStatusForPanel = 'online';
        } else {
          log('comm Status For Panel : OFFLINE');
          _commStatusForPanel = 'offline';
        }
      } else {
        log('comm Status For Panel : OFFLINE');
        _commStatusForPanel = 'offline';
      }
    }

    if (_commStatusForPanel == 'online') {
      String assetLat = deviceType == 'SEMC'
          ? ref.read(deviceController).smslcLat
          : ref.read(deviceController).ccmsLat;
      String assetLong = deviceType == 'SEMC'
          ? ref.read(deviceController).smslcLong
          : ref.read(deviceController).ccmsLong;
      final telemetryDataForRelay =
          await _service.fetchTelemetryData('DEVICE', firstDeviceId, 'rly');
      log('telemetry Data For Relay : $telemetryDataForRelay');
      await checkUserProximity(ref, assetLat, assetLong);

      if (telemetryDataForRelay['rly'][0]['value'] != null) {
        String rly = telemetryDataForRelay['rly'][0]['value'];
        int intRlyValue = int.parse(rly);
        if (intRlyValue == 1) {
          log('relay Status For Panel : ON');
          toggleButtonValue(false);
          updateRelayStatusForPanel('on');
        } else {
          log('relay Status For Panel : OFF');
          toggleButtonValue(true);
          updateRelayStatusForPanel('off');
        }
      } else {
        log('relay Status For Panel : OFF');
        toggleButtonValue(true);
        updateRelayStatusForPanel('off');
      }
    } else {
      log('relay Status For Panel : unknown');
      toggleButtonValue(true);
      updateRelayStatusForPanel('unknown');
    }
  }

  Future<dynamic> panelControl(
      WidgetRef ref, BuildContext context, controlType) async {
    String firstDeviceId = ref.read(deviceController).firstDeviceId;

    if (controlType != 'on' && controlType != 'off') {
      EasyLoading.show(
        status: '',
        dismissOnTap: false,
      );
    }
    var res = await _service.panelControlService(firstDeviceId, controlType);
    String errorMssg = '';
    if (controlType != 'on' && controlType != 'off') {
      EasyLoading.dismiss();
    }
    if (res == 1) {
      if (controlType != 'on' && controlType != 'off') {
        if (controlType == 'mcbReset') {
          errorMssg = 'MCB Reset successfully completed';
        } else if (controlType == 'mcbClear') {
          errorMssg = 'MCB Trip Count successfully cleared';
        }
        if (context.mounted) {
          await successTick(context, errorMssg);
        }
      } else {
        return 'success';
      }
    } else if (res == 401) {
      ref.read(deviceController).enableButton();
      if (context.mounted) {
        await tokenExpired(context, ref);
      }
    } else if (res == '500' ||
        (res is Map && (res["status"] == 500 || res["status"] == 503))) {
      ref.read(deviceController).enableButton();
      if (context.mounted) {
        showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
      }
    } else {
      ref.read(deviceController).enableButton();
      if (context.mounted) {
        showSnackBar(ref, context, ErrorMessages.tryAgainError);
      }
    }
  }

  String get relayStatusForPanel => _relayStatusForPanel;
  String get commStatusForPanel => _commStatusForPanel;
  bool get isMcbTripPanel => _isMcbTripPanel;
  bool get toggleButton => _toggleButton;
  bool get isWithInUserProximity => _isWithInUserProximity;
  TelemetryData? get telemetryData => _telemetryData;
}
