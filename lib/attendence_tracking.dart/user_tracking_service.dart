import 'dart:convert';
import 'dart:developer';
import 'package:battery_plus/battery_plus.dart';
import 'package:carrier_info/carrier_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_device_imei/flutter_device_imei.dart';
import 'package:flutter_internet_signal/flutter_internet_signal.dart';
import 'package:schnell_luminator/utils/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import '../utils/secure_storage.dart';

class UserTrackingService {
  Future<dynamic> pushLocationToUserTelemetry() async {
    final sharedPreference = await SharedPreferences.getInstance();
    final secureStorage = SecureStorageService();
    String userId = await secureStorage.getUserId() ?? '';
    log('get stored userId: $userId');

    var storedLocation = sharedPreference.getStringList("locations");
    Dio dio = DioClient.dio;
    List<String> locationsToRemove = [];

    if (storedLocation != null) {
      for (var location in List.from(storedLocation)) {
        try {
          var decodedLocation = jsonDecode(location);
          final response = await dio.post(
            '$thingsboardURL/api/plugins/telemetry/USER/$userId/timeseries/ANY',
            options: Options(
              headers: {
                'accept': 'application/json',
                'Content-Type': 'application/json',
                // 'X-Authorization': 'Bearer $token',
              },
            ),
            data: decodedLocation,
          );
          log('Location update response: ${response.statusCode}');
          if (response.statusCode == 200) {
            locationsToRemove.add(location);
            log('Location successfully updated to user telemetry and marked for removal');
          }
        } catch (e) {
          if (e is DioError) {
            if (e.error == 'Session expired. Please login again.') {
              return 'refresht token expired';
            }
          }
        }
      }
      // Remove successfully sent locations from storedLocation
      storedLocation
          .removeWhere((location) => locationsToRemove.contains(location));
      await sharedPreference.setStringList("locations", storedLocation);
      log("Remaining stored locations: $storedLocation");
      log("*** Locations marked for removal: $locationsToRemove");
    }
  }

  Future<Map<String, dynamic>> fetchNetworkDetails(
      {bool fetchBattery = true}) async {
    String deviceMake = '';
    String deviceModel = '';
    String imei = '';
    String carrierName = '';
    int signalStrengthLevel = 0;
    int batteryLevel = -1;

    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      // // Permissions
      // try {
      //   await Permission.locationWhenInUse.status;
      //   await ensurePermission(Permission.phone);
      // } catch (e) {
      //   log("Permission error: $e");
      // }

      // Device Info
      try {
        final deviceInfoPlugin = DeviceInfoPlugin();
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceMake = androidInfo.manufacturer;
        deviceModel = androidInfo.model;
        log("Device Make: $deviceMake");
        log("Device Model: $deviceModel");
      } catch (e) {
        log("Error fetching device info: $e");
      }

      // IMEI
      try {
        imei = await FlutterDeviceImei.instance.getIMEI() ?? '';
        log("android imei: $imei");
      } catch (e) {
        log("Error fetching IMEI: $e");
      }

      // Battery Info
      if (fetchBattery) {
        try {
          final battery = Battery();
          batteryLevel = await battery.batteryLevel;
          log("Battery Level: $batteryLevel%");
        } catch (e) {
          log("Error fetching battery info: $e");
        }
      }

      // Network details
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        carrierName = 'wifi/Others';
        try {
          int? signalStrength =
              await FlutterInternetSignal().getWifiSignalStrength();
          signalStrengthLevel = mapDbmToLevel(signalStrength ?? 0);
        } catch (e) {
          log("Error fetching wifi signal strength: $e");
        }
        log("Connected to Wifi, Carrier: $carrierName, Signal: $signalStrengthLevel/5");
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        try {
          final carrierInfo = await CarrierInfo.getAndroidInfo();
          TelephonyInfo? activeSim;

          if (carrierInfo?.telephonyInfo != null) {
            try {
              activeSim = carrierInfo!.telephonyInfo.firstWhere(
                (sim) => sim.simState == 'SIM_STATE_READY',
              );
              carrierName = activeSim.carrierName;
            } catch (_) {
              carrierName = 'Unknown';
            }
          } else {
            carrierName = 'Unknown';
          }

          int? signalStrength =
              await FlutterInternetSignal().getMobileSignalStrength();
          signalStrengthLevel = mapDbmToLevel(signalStrength ?? 0);

          log("Connected to Mobile Data, Carrier: $carrierName, Signal: $signalStrengthLevel/5");
        } catch (e) {
          carrierName = 'Unknown';
          log("Error fetching mobile details: $e");
        }
      } else {
        carrierName = 'offline';
        signalStrengthLevel = 0;
        log("No Internet Connection");
      }
    } catch (e, st) {
      log("Unexpected error in fetchNetworkDetails: $e\n$st");
    }
    return {
      "deviceMake": deviceMake,
      "deviceModel": deviceModel,
      "imei": imei,
      "carrierName": carrierName,
      "signalStrengthLevel": signalStrengthLevel,
      "batteryLevel": '$batteryLevel%'
    };
  }

  int mapDbmToLevel(int dbm) {
    if (dbm >= -85) return 5;
    if (dbm >= -95) return 4;
    if (dbm >= -105) return 3;
    if (dbm >= -115) return 2;
    if (dbm >= -125) return 1;
    return 0;
  }
}
