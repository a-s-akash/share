import 'dart:async';
import 'dart:developer';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schnell_luminator/attendence_tracking.dart/gps_details_model.dart';
import 'package:schnell_luminator/attendence_tracking.dart/user_tracking_service.dart';
import 'package:schnell_luminator/utils/session.dart';
import 'package:schnell_luminator/utils/utility.dart';
import 'package:shared_preferences/shared_preferences.dart';

final UserTrackingService userTrackingService = UserTrackingService();

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

Future<void> initializeService() async {
  await startLocationTracking();
}

Future<void> startLocationTracking() async {
  final prefs = await SharedPreferences.getInstance();
  final startTime = DateTime.now().millisecondsSinceEpoch;
  await prefs.setInt('periodicTrackingStartTime', startTime);
  await FlutterForegroundTask.startService(
    notificationTitle: 'Tracking Location',
    notificationText: '',
    callback: startCallback,
  );
}

Future<void> stopLocationTracking() async {
  bool isServiceRunning = await FlutterForegroundTask.isRunningService;
  log('$isServiceRunning');
  log("Location tracking service cancelled");
  await FlutterForegroundTask.stopService();
}

class LocationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    log('Foreground task started');
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TravelLocationEntityAdapter());
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final startTime = prefs.getInt('periodicTrackingStartTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final elapsedTime = currentTime - startTime;

    //auto stop tracking after 8 hrs
    if (elapsedTime >= 8 * 60 * 60 * 1000) {
      await FlutterForegroundTask.stopService();
      return;
    }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      final networkDetails = await userTrackingService.fetchNetworkDetails();
      log('Network Details: ${networkDetails['batteryLevel']}');
      if (serviceEnabled) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final latitude = position.latitude;
        final longitude = position.longitude;

        log("Fetched location (hourly): $latitude, $longitude at $time");
        final box = await Utility.openLocationTrackingBox();
        await box.add(
          TravelLocationEntity(
            lat: latitude,
            long: longitude,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        log('Box length: ${box.length}');
        await storeLocationLocally(time,
            lat: latitude,
            long: longitude,
            locationEnabled: true,
            carrierName: networkDetails['carrierName'],
            signalStrengthLevel: networkDetails['signalStrengthLevel'],
            deviceMake: networkDetails['deviceMake'],
            deviceModel: networkDetails['deviceModel'],
            imei: networkDetails['imei'],
            batteryLevel: networkDetails['batteryLevel']);
      } else {
        log("Location services disabled at $time");
        await storeLocationLocally(
          time,
          locationEnabled: false,
          carrierName: networkDetails['carrierName'],
          signalStrengthLevel: networkDetails['signalStrengthLevel'],
          deviceMake: networkDetails['deviceMake'],
          deviceModel: networkDetails['deviceModel'],
          imei: networkDetails['imei'],
        );
      }
      Utility.isConnected().then((value) async {
        if (value) {
          //if internet available else location details just stored locally
          await UserTrackingService().pushLocationToUserTelemetry();
        }
      });
    } catch (e) {
      log("Location error: $e");
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _checkAndRestartServiceIfNeeded();
    log('Foreground task stopped');
  }

  Future<void> _checkAndRestartServiceIfNeeded() async {
    await Future.delayed(const Duration(seconds: 3));
    // Check if app is still running but service was killed
    bool isServiceRunning = await FlutterForegroundTask.isRunningService;
    // bool shouldBeRunning = /* get from your app state/preferences */;

    if (!isServiceRunning) {
      await startLocationTracking();
    }
  }
}
