import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> storeSelectedCustomerDetails(
    String custName, String custId) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('custName', custName);
  prefs.setString('custId', custId);
}

Future<void> storeSelectedRegionDetails(
    String regionName, String regionId) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('regionName', regionName);
  prefs.setString('regionId', regionId);
}

Future<void> storeSelectedWardDetails(String wardName, String wardId) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('wardId', wardId);
  prefs.setString('wardName', wardName);
}

Future<void> storeSelectedZoneDetails(String zoneName, String zoneId) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('zoneName', zoneName);
  prefs.setString('zoneId', zoneId);
}

Future<String> getStoredSelectedCustomer() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('custName') ?? '';
}

Future<String> getStoredSelectedRegion() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('regionName') ?? '';
}

Future<String> getStoredSelectedZone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('zoneName') ?? '';
}

Future<String> getStoredSelectedWard() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('wardName') ?? '';
}

Future<bool> isLocationTrackingRequired() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLocationTrackingRequired') ?? false;
}

Future<bool> isPPERequired() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isPPERequired') ?? false;
}

Future<void> storeLocationLocally(timestamp,
    {double? lat,
    double? long,
    bool locationEnabled = true,
    String? activityName,
    String? entityName,
    String? entityType,
    String? carrierName,
    int? signalStrengthLevel,
    String? deviceMake,
    String? deviceModel,
    String? imei,
    String? batteryLevel,
    bool? isTicket}) async {
  final prefs = await SharedPreferences.getInstance();

  List<String> locations = prefs.getStringList("locations") ?? [];
  Map<String, dynamic> values = {
    if (!locationEnabled) ...{
      "locationEnabled": false,
    } else if (activityName == null) ...{
      // for periodic tracking
      "latitude": lat,
      "longitude": long,
      "activity": "Periodic Tracking",
      "locationEnabled": true,
      "signalStrength": {
        carrierName: signalStrengthLevel,
      },
      "deviceInfo": {
        "make": deviceMake,
        "model": deviceModel,
        "imei": imei,
        "batteryLevel": batteryLevel,
      }
    } else if (isTicket == true) ...{
      "latitude": lat,
      "longitude": long,
      "activity": activityName,
      "entityName": entityName,
      "entityType": entityType,
      "locationEnabled": true,
      "signalStrength": {
        carrierName: signalStrengthLevel,
      },
      "deviceInfo": {"make": deviceMake, "model": deviceModel, "imei": imei}
    } else ...{
      // Activity tracking
      "latitude": lat,
      "longitude": long,
      "activity": activityName,
      "entityName": entityName,
      "locationEnabled": true,
      "signalStrength": {
        carrierName: signalStrengthLevel,
      },
      "deviceInfo": {"make": deviceMake, "model": deviceModel, "imei": imei}
    }
  };
  locations.add(jsonEncode({"ts": timestamp, "values": values}));
  await prefs.setStringList("locations", locations);
  var storedLocations = prefs.getStringList("locations");
  log("Location saved locally $storedLocations");
}

Future<void> storeLoginFlagsForUserTracking(shallCaptureAttendance,
    isLocationTrackingRequired, isPPERequired, locationTrackingInterval) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('shallCaptureAttendance', shallCaptureAttendance);
  await prefs.setBool('isLocationTrackingRequired', isLocationTrackingRequired);
  await prefs.setBool('isPPERequired', isPPERequired);
  await prefs.setInt('locationTrackingInterval', locationTrackingInterval);
}
