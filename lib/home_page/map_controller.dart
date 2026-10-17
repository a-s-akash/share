import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/device_page/device_service.dart';
import 'package:schnell_luminator/device_page/gw/gw_maintenance1.dart';
import 'package:schnell_luminator/device_page/gw/panel_actions_controller.dart';
import 'package:schnell_luminator/device_page/ilm/maintenance1.dart';
import 'package:schnell_luminator/env.dart';
import 'package:schnell_luminator/ticket_notification/ticket_controller.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../device_page/pole/pole_page.dart';
import '../login_page/login_controller.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

final mapController =
    ChangeNotifierProvider<MapProvider>((ref) => MapProvider(ref));

class DeviceMarkerData {
  final LatLng point;
  final String icon;
  final String label;
  final Future<void> Function()? onTap;

  DeviceMarkerData({
    required this.point,
    required this.icon,
    required this.label,
    this.onTap,
  });
}

class MapProvider extends ChangeNotifier {
  final DeviceService _service = DeviceService();
  final Map<String, List<DeviceMarkerData>> _markersData = {};
  List<List<LatLng>> _geoFence = [];
  List<String> _availableAssets = [];
  List<String> _choosenAssets = [];
  int _userProximityRadius = 150;
  bool _isLedTypeInstallAllowed = false;
  bool _isSwitchPointRequiredForPanel = false;
  List _wardList = [];
  String _userSelectedDeviceOrAssetName = "";
  bool _showName = false;
  List _regionLevelWardList = [];
  List _zoneLevelWardList = [];

  MapProvider(ref) {
    if (Hive.isBoxOpen('geoFenceBox')) {
      final fenceBox = Hive.box('geoFenceBox');
      fenceBox.watch().listen((event) {
        _onGeoFenceChanged(ref);
      });
    }
  }

  void _onGeoFenceChanged(ref) {
    updateGeoFence(ref);
    notifyListeners();
  }

  final Map<String, dynamic> assetsIcons = {
    'pole': 'assets/images/pole.svg',
    'lightPoint': 'assets/images/lightPoint.svg',
    'switchPoint': 'assets/images/switchPoint.svg',
    'slc': 'assets/images/slc.svg',
    'hub': 'assets/images/hub.svg',
  };

  final Map<String, dynamic> labelName = {
    'pole': 'Pole',
    'lightPoint': 'LP',
    'switchPoint': 'SP',
    'slc': "Panel",
    'hub': "Hub"
  };

  updateToWardList(wardList, [entity]) {
    if (entity == 'region') {
      _regionLevelWardList = wardList;
    } else if (entity == 'zone') {
      _zoneLevelWardList = wardList;
    }
    _wardList = wardList;
    notifyListeners();
  }

  updateFromWardList(entity) {
    if (entity == 'region') {
      _wardList = _regionLevelWardList;
    } else if (entity == 'zone') {
      _wardList = _zoneLevelWardList;
    }
    notifyListeners();
  }

  Future<void> updateMapLatLong(
      WidgetRef ref, BuildContext context, String data) async {
    _markersData.clear();
    Map<String, dynamic> jsonData = json.decode(data);
    for (var asset in _availableAssets) {
      _markersData[asset] = [];

      for (var item in jsonData[asset]) {
        final device = item['name'];
        var lat = asset == 'lightPoint' ? 'latitude' : 'slatitude';
        var long = asset == 'lightPoint' ? 'longitude' : 'slongitude';

        _markersData[asset]!.add(
          DeviceMarkerData(
            point: LatLng(
              item[lat] == "" ? 0 : double.parse(item[lat]),
              item[long] == "" ? 0 : double.parse(item[long]),
            ),
            icon: assetsIcons[asset],
            label: device,
            onTap: () async {
              if (asset == 'switchPoint') {
                return;
              }
              EasyLoading.show(
                status: '',
                dismissOnTap: false,
              );
              userSelectedDeviceOrAsset(device);
              await _service.getDeviceDataService(ref, context, device, 1, "1");
              if (item['assetType'] == 'ccms' ||
                  item['assetType'] == 'slc' ||
                  item['assetType'] == 'smslc') {
                String firstDeviceId = ref.read(deviceController).firstDeviceId;
                String firstDeviceType =
                    ref.read(deviceController).firstDeviceType;
                String assetsId = item['assetType'] == 'smslc'
                    ? ref.read(deviceController).smslcAssetId
                    : ref.read(deviceController).ccmsAssetsId;

                await ref.read(panelController).commRelayStatusCalculation(
                    ref, context,
                    deviceType: firstDeviceType);
                await ref
                    .read(ticketController)
                    .isTicketsOfSpecificDeviceOrAsset(true);
                await ref.read(ticketController).getTicketsBasedOnStatusFB(
                    context, ref, 'Closed',
                    entityIdForSpecificDeviceTicket: [assetsId, firstDeviceId]);
              }

              EasyLoading.dismiss();

              if (asset == 'pole') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PoleDetails(),
                    settings: const RouteSettings(name: poleDetailsRoute),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => asset == 'lightPoint'
                      ? const IlmMaintenance()
                      : GwMaintenance(),
                ),
              );
            },
          ),
        );
      }
    }
    notifyListeners();
  }

  void userSelectedDeviceOrAsset(userSelectedDeviceOrAsset) {
    _userSelectedDeviceOrAssetName = userSelectedDeviceOrAsset;
    notifyListeners();
  }

  Future<void> updateRegionLevelAttributes(assets, userProximityRadius,
      isLedTypeInstallAllowed, isSwitchPointRequiredForPanel) async {
    _userProximityRadius = userProximityRadius;
    _isLedTypeInstallAllowed = isLedTypeInstallAllowed;
    _isSwitchPointRequiredForPanel = isSwitchPointRequiredForPanel;
    dev.log("isLedTypeInstallAllowed: $_isLedTypeInstallAllowed");
    if (assets is List) {
      List<String> input = assets.map((e) => e.toString()).toList();

      List<String> order = ["lightPoint", "pole", "switchPoint", "slc", "hub"];

      _availableAssets = order.where((e) => input.contains(e)).toList();
    } else {
      _availableAssets = [];
    }
    // _availableAssets = ["pole", "switchPoint", "ccms", "hub"];
    notifyListeners();
  }

  void updateChoosenAsset(String asset) {
    if (asset == '') {
      if (_availableAssets.contains('pole')) {
        _choosenAssets = ['pole', 'switchPoint'];
      } else {
        _choosenAssets = ['lightPoint', 'switchPoint'];
      }
    } else if (_choosenAssets.contains(asset)) {
      _choosenAssets.remove(asset);
    } else {
      _choosenAssets.add(asset);
    }
    notifyListeners();
  }

  List<LatLng> sortPolygonPoints(List<LatLng> points) {
    double cx = 0;
    double cy = 0;
    for (var p in points) {
      cx += p.latitude;
      cy += p.longitude;
    }
    cx /= points.length;
    cy /= points.length;

    points.sort((a, b) {
      final angleA = atan2(a.latitude - cx, a.longitude - cy);
      final angleB = atan2(b.latitude - cx, b.longitude - cy);
      return angleA.compareTo(angleB);
    });

    return points;
  }

  Future<void> updateGeoFence(ref) async {
    _geoFence = [];

    String userMail = ref.read(loginController).userMail;

    final fenceBox = await Hive.openBox('geoFenceBox');
    // await fenceBox.clear();

    final data = fenceBox.get(userMail) ?? {};

    for (var id in _wardList) {
      List<LatLng> wardLatLong = [];
      if (data.containsKey(id)) {
        for (var p in data[id]) {
          if (p is List && p.length == 2) {
            wardLatLong.add(
              LatLng(
                p[0] is num ? p[0].toDouble() : double.parse(p[0].toString()),
                p[1] is num ? p[1].toDouble() : double.parse(p[1].toString()),
              ),
            );
          }
        }
      }
      if (wardLatLong.isNotEmpty) {
        _geoFence.add(sortPolygonPoints(wardLatLong));
      }
    }
  }

  void toggleShowName() {
    _showName = !_showName;
    notifyListeners();
  }

  Future<void> getLatLongBasedonWard(ref, context, val) async {
    var res = await _service.getMapDataService(ref, context, val);

    if (res == 1) {
    } else if (res == 401) {
      await tokenExpired(context, ref);
    } else if (res == 404 || res == 400) {
      showSnackBar(ref, context, ErrorMessages.invalidDeviceError);
    } else if (res.toString() == "Server Timeout. Please try Again!") {
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  Future<void> getGeofence(ref, context, userMail, region, regionID) async {
    var res = await _service.getGeoFenceService(
        ref, context, userMail, region, regionID);
    if (res == 1) {
    } else if (res == 401) {
      await tokenExpired(context, ref);
    } else if (res == 404 || res == 400) {
      showSnackBar(ref, context, ErrorMessages.invalidDeviceError);
    } else if (res.toString() == "Server Timeout. Please try Again!") {
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
    } else {
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  final Map<String, int> _assetCounts = {
    "pole": 0,
    "switchPoint": 0,
    "slc": 0,
    "ccms": 0,
    "smslc": 0,
    "hub": 0,
    "lightPoint": 0
  };

  WebSocketChannel? _channel;
  bool _isLoadingCounts = false;
  String? _lastContextId;

  Map<String, int> get assetCounts => _assetCounts;

  Future<void> loadCounts(WidgetRef ref) async {
    if (_isLoadingCounts) return;

    // final selectedContextId = ref.read(deviceController).selectedContextId;
    final selectedContextId = ref.watch(
      ticketController.select((state) => state.selectedContextId),
    );
    dev.log('Selected Context ID: $selectedContextId');

    if (selectedContextId == _lastContextId && _channel != null) return;

    _lastContextId = selectedContextId;
    _isLoadingCounts = true;

    try {
      final secureStorage = SecureStorageService();
      final token = await secureStorage.getAccessToken();

      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }

      _channel = WebSocketChannel.connect(Uri.parse(websocketApi));

      List<Map<String, dynamic>> cmds = [];
      if (_availableAssets.contains("pole")) {
        cmds.add(buildCmd(1, selectedContextId, ["pole"]));
      }
      if (_availableAssets.contains("switchPoint")) {
        cmds.add(buildCmd(2, selectedContextId, ["switchPoint"]));
      }
      if (_availableAssets.contains("slc") ||
          _availableAssets.contains("panel")) {
        cmds.add(buildCmd(3, selectedContextId, ["ccms"]));
        cmds.add(buildCmd(6, selectedContextId, ["smslc"]));
      }

      if (_availableAssets.contains("hub")) {
        cmds.add(buildCmd(4, selectedContextId, ["hub"]));
      }
      if (_availableAssets.contains("lightPoint") ||
          _availableAssets.contains("LightPoint")) {
        cmds.add(buildCmd(5, selectedContextId, ["lightPoint"]));
      }

      Map<String, dynamic> data = {
        "authCmd": {"cmdId": 0, "token": token},
        "cmds": cmds
      };

      _channel!.sink.add(jsonEncode(data));

      _isLoadingCounts = false;

      await for (var message in _channel!.stream) {
        dev.log("NEW WEBSOCKET MESSAGE ARRIVED: ${message.toString()}");
        final res = jsonDecode(message);
        final id = res["cmdId"];
        final count = res["count"];

        if (id == 1) _assetCounts["pole"] = count;
        if (id == 2) _assetCounts["switchPoint"] = count;
        if (id == 3) _assetCounts["ccms"] = count;
        if (id == 4) _assetCounts["hub"] = count;
        if (id == 5) _assetCounts["lightPoint"] = count;
        if (id == 6) _assetCounts["smslc"] = count;

        //Always calculate slc as sum of ccms and smslc
        _assetCounts["slc"] =
            (_assetCounts["ccms"] ?? 0) + (_assetCounts["smslc"] ?? 0);
        notifyListeners();
      }
    } catch (e) {
      dev.log("WebSocket error: $e");
      _isLoadingCounts = false;
      _channel = null;
      // retry after a delay
      await Future.delayed(const Duration(seconds: 5));
      if (_lastContextId == selectedContextId) {
        loadCounts(ref);
      }
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Map<String, dynamic> buildCmd(
      int cmdId, String ctxId, List<String> assetTypes) {
    return {
      "type": "ENTITY_COUNT",
      "query": {
        "entityFilter": {
          "type": "assetSearchQuery",
          "rootStateEntity": true,
          "rootEntity": {"entityType": "ASSET", "id": ctxId},
          "direction": "FROM",
          "assetTypes": assetTypes
        }
      },
      "cmdId": cmdId
    };
  }

  Map<String, List<DeviceMarkerData>> get markersData => _markersData;
  List<List<LatLng>> get geoFence => _geoFence;
  List get wardList => _wardList;
  List<String> get choosenAssets => _choosenAssets;
  List<String> get availableAssets => _availableAssets;
  int get userProximityRadius => _userProximityRadius;
  bool get isLedTypeInstallAllowed => _isLedTypeInstallAllowed;
  bool get isSwitchPointRequiredForPanel => _isSwitchPointRequiredForPanel;

  String get userSelectedDeviceOrAssetName => _userSelectedDeviceOrAssetName;
  bool get showName => _showName;
  List get regionLevelWardList => _regionLevelWardList;
  List get zoneLevelWardList => _zoneLevelWardList;
}
