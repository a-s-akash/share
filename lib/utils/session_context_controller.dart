import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../device_page/telemetry_service.dart';
import '../survey/connectivity_sync_service.dart';
import 'constants.dart';
import 'utility.dart';

enum AppMode { installation, maintenance }

extension AppModeX on AppMode {
  String get label => switch (this) {
        AppMode.installation => 'Installation',
        AppMode.maintenance => 'Maintenance',
      };

  /// Value persisted to SharedPreferences — distinct from [label], which
  /// is what the UI displays.
  String get storageValue => switch (this) {
        AppMode.installation => 'Installation',
        AppMode.maintenance => 'Maintenance',
      };
}

/// Holds the current session's Operation Mode + Vehicle selection, shown
/// via the Home Screen bottom sheet and reflected as a status chip.
final sessionContextController =
    ChangeNotifierProvider<SessionContextController>(
  (ref) => SessionContextController(),
);

class SessionContextController extends ChangeNotifier {
  AppMode? _mode;
  String? _vehicleType;
  String? _vehicleNumber;
  bool _loaded = false;

  AppMode? get mode => _mode;
  String? get vehicleType => _vehicleType;
  String? get vehicleNumber => _vehicleNumber;

  bool get isComplete =>
      _mode != null &&
      _vehicleType != null &&
      (_vehicleNumber?.isNotEmpty ?? false);

  /// Loads any previously saved selections so the bottom sheet can
  /// pre-fill them and the status chip can render without waiting on
  /// the sheet to be shown. Safe to call multiple times.
  Future<void> loadCached() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(selectedModePrefsKey);
    if (storedMode != null) {
      _mode = AppMode.values.firstWhere(
        (m) => m.storageValue == storedMode,
        orElse: () => AppMode.installation,
      );
    }
    _vehicleType = prefs.getString(vehicleTypePrefsKey);
    _vehicleNumber = prefs.getString(vehicleNumberPrefsKey);
    _loaded = true;
    notifyListeners();
  }

  /// Resets the in-memory mode + vehicle selection. Must be called
  /// whenever these prefs are cleared elsewhere (e.g. on "Login as new
  /// user") — this controller is a single app-lifetime instance, so
  /// [loadCached] alone won't pick up an external prefs clear once it has
  /// already run.
  Future<void> clearVehicleDetailsValues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(vehicleTypePrefsKey);
    await prefs.remove(vehicleNumberPrefsKey);
    await prefs.remove(selectedModePrefsKey);
    _mode = null;
    _vehicleType = null;
    _vehicleNumber = null;
    notifyListeners();
  }

  Future<void> confirmSelections({
    required AppMode mode,
    required String vehicleType,
    required String vehicleNumber,
  }) async {
    final vehicleChanged =
        vehicleType != _vehicleType || vehicleNumber != _vehicleNumber;

    _mode = mode;
    _vehicleType = vehicleType;
    _vehicleNumber = vehicleNumber;
    _loaded = true;
    notifyListeners();

    // Mode is only ever stored locally — it isn't pushed to telemetry.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedModePrefsKey, mode.storageValue);
    await prefs.setString(vehicleTypePrefsKey, vehicleType);
    await prefs.setString(vehicleNumberPrefsKey, vehicleNumber);

    // Vehicle details are pushed to telemetry only when they've actually
    // changed from what was previously saved — re-confirming the same
    // vehicle on a later visit shouldn't re-push it.
    if (!vehicleChanged) return;

    final data = {
      'vehicleType': vehicleType,
      'vehicleNo': vehicleNumber,
    };

    try {
      final isOnline = await Utility.isConnected();
      if (isOnline) {
        await TelemetryService().pushValuesToUserTelemetry(data);
      } else {
        await SimpleSyncService.enqueueTelemetry(data);
      }
    } catch (e) {
      log('Failed to push vehicle telemetry: $e');
    }
  }
}
