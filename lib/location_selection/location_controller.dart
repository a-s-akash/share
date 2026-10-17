import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:schnell_luminator/location_selection/ward_list.dart';
import 'customer_list.dart';
import 'location_service.dart';
import 'region_list.dart';
import 'zone_list.dart';

final locationController =
    ChangeNotifierProvider<SplashProvider>((ref) => SplashProvider());

class SplashProvider extends ChangeNotifier {
  List<Customer> _customerList = [];
  List<Region> _regionList = [];
  List<Zone> _zoneList = [];
  List<Ward> _wardList = [];
  bool _loading = false;
  LatLng? _userLocation;
  late final Box _contextBox;

  void loadingChange() {
    _loading = !_loading;
    notifyListeners();
  }

  Future<void> fetchCurrentLocation() async {
    try {
      final location = await determinePosition();

      _userLocation = location;
    } catch (e) {
      _userLocation = const LatLng(11.0678, 76.9465);

      log('Error fetching location: $e');
    }
  }

  Future<LatLng> determinePosition() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await Location().serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Location().requestService();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }
    }

    permissionGranted = await Location().hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await Location().requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permissionGranted == PermissionStatus.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Location().getLocation();
    return LatLng(position.latitude!, position.longitude!);
  }

  Future<void> initHive() async {
    _contextBox = await Hive.openBox("locationContext");
  }

  //  Get full saved data for user
  Future<Map<String, dynamic>?> _getUserContext(String userMail) async {
    final data = _contextBox.get(userMail);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

//  Get all customers
  Future<Map<dynamic, dynamic>?> _getCustomers(String userMail) async {
    final data = await _getUserContext(userMail);
    return data?['customers'] as Map<dynamic, dynamic>?;
  }

//  Get all regions for a customer
  Future<Map<dynamic, dynamic>?> _getRegions(
      String userMail, String customerId) async {
    final customers = await _getCustomers(userMail);
    if (customers == null) return null;

    // Find customer by customer_id
    final customerEntry = customers.entries
        .firstWhere((entry) => entry.value['customer_id'] == customerId);

    return customerEntry.value['regions'] as Map<dynamic, dynamic>?;
  }

//  Get all zones for a region
  Future<Map<dynamic, dynamic>?> _getZones(
      String userMail, String customerId, String regionId) async {
    final regions = await _getRegions(userMail, customerId);
    return regions?[regionId]?['zones'] as Map<dynamic, dynamic>?;
  }

// Get all wards for a zone
  Future<Map<dynamic, dynamic>?> _getWards(String userMail, String customerId,
      String regionId, String zoneId) async {
    final zones = await _getZones(userMail, customerId, regionId);
    return zones?[zoneId]?['wards'] as Map<dynamic, dynamic>?;
  }

  Future<void> loadCustomerList(String userMail) async {
    final customersData = await _getCustomers(userMail);
    if (customersData != null) {
      _customerList = customersData.entries
          .map((entry) => Customer(
                id: entry.value['customer_id'] ?? '',
                name: entry.key,
              ))
          .toList();
      _customerList.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> loadRegionList(String userMail, String customerId) async {
    final regionsData = await _getRegions(userMail, customerId);
    if (regionsData != null) {
      _regionList = regionsData.entries
          .map((entry) => Region(
              id: entry.key,
              customerId: entry.value['customerId'] ?? '',
              name: entry.value['region_name'] ?? '',
              type: 'region',
              poleSchema: entry.value['poleSchema'] ?? '',
              compatibleAssets: entry.value['compatibleAssets'] ?? '',
              desc: entry.value['description'] ?? '',
              wardList: entry.value['zones']?.values
                      .expand((zone) => (zone['wards'] as Map).keys)
                      .toList() ??
                  [],
              userProximityRadius: entry.value['userProximityRadius'] ?? 0,
              isLedTypeInstallAllowed:
                  entry.value['isLedToLedInstallationAllowed'] ?? false,
              isSwitchPointRequiredForPanel:
                  entry.value['isSwitchPointRequired'] ?? false))
          .toList();
      _regionList.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> loadZoneList(
      String userMail, String customerId, String regionId) async {
    final zonesData = await _getZones(userMail, customerId, regionId);
    if (zonesData != null) {
      _zoneList = zonesData.entries
          .map((entry) => Zone(
                id: entry.key,
                name: entry.value['zone_name'] ?? '',
                type: entry.value['type'] ?? 'zone',
                desc: entry.value['description'] ?? '',
                wardList: entry.value['wards']?.keys.toList() ?? [],
              ))
          .toList();
      _zoneList.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> loadWardList(String userMail, String customerId, String regionId,
      String zoneId) async {
    final wardsData = await _getWards(userMail, customerId, regionId, zoneId);
    if (wardsData != null) {
      _wardList = wardsData.entries
          .map((entry) => Ward(
                id: entry.key,
                name: entry.value['ward_name'] ?? '',
                type: entry.value['type'] ?? 'ward',
                desc: entry.value['description'] ?? '',
              ))
          .toList();
      _wardList.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  // Save context for each user
  Future<void> saveLocationContext(
      String userMail, Map<String, dynamic> jsonData) async {
    final box = await Hive.openBox("locationContext");
    await box.put(userMail, jsonData);
    log('Saved context for user: $userMail');
  }

  Future<void> getStoredContext(userMail) async {
    // Try to load locally saved context first
    final savedData = await _getUserContext(userMail);

    if (savedData != null) {
      // log('Loaded project context from Hive for $userMail - $savedData');
      await loadCustomerList(userMail);
    } else {
      log('No local context found, fetching from API...');
      int result = await LocationService().getAllContextService(userMail);
      if (result == 1) {
        await loadCustomerList(userMail);
      } else {
        log('Context API failed or session expired');
      }
    }
  }

  Future<void> refreshFromServer(userMail) async {
    try {
      int result = await LocationService().getAllContextService(userMail);
      if (result == 1) {
        await loadCustomerList(userMail);
        notifyListeners();
      } else {
        log('Context API failed or session expired');
      }
    } catch (e) {
      debugPrint("Background fetch failed: $e");
    }
  }

  bool get loading => _loading;
  LatLng? get userLocation => _userLocation;
  List<Region> get regionList => _regionList;
  List<Customer> get customerList => _customerList;
  List<Zone> get zoneList => _zoneList;
  List<Ward> get wardList => _wardList;
}
