import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:developer';
import 'dart:ui';
import 'dart:isolate';
import '../attendence_tracking.dart/attendance_record.dart';
import '../attendence_tracking.dart/ppe_queue_item.dart';
import '../ticket_notification/offline/ticket_queue_item.dart';
import '../ticket_notification/offline/ticket_update_queue_item.dart';
import '../utils/constants.dart';
import 'connectivity_sync_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  log(">>> Entered callbackDispatcher");

  Workmanager().executeTask((task, inputData) async {
    log('WorkManager callback triggered for task: $task');
    try {
      log('registered task: $task');
      final directory = await getApplicationDocumentsDirectory();
      final hivePath = directory.path;
      log('hivePath in workmanager: $hivePath');
      Hive.init(hivePath);
      // WorkManager runs in a separate isolate — adapters registered in main()
      // are not available here, so they must be re-registered before any box
      // is opened.
      // if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(InstallationHistoryAdapter());
      // if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TravelLocationEntityAdapter());
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(AttendanceRecordAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(PpeQueueItemAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(TicketQueueItemAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(TicketUpdateQueueItemAdapter());
      }
      log('Hive adapters registered in background isolate');
      switch (task) {
        case 'periodicSyncTask':
          log('Executing periodic sync...');
          return await SimpleSyncService.performSync();
        case 'immediateSyncTask':
          log('Executing immediate sync...');
          return await SimpleSyncService.performSync();
        case 'manualSyncTask':
          log('Executing manual sync...');
          return await SimpleSyncService.performSync();
        case 'internetCheckTask':
          log('Executing internet check...');
          return await SimpleSyncService.performInternetCheck();
        default:
          log('Unknown task: $task');
          return false;
      }
    } catch (e) {
      log('WorkManager task failed: $e');
      return false;
    }
  });
}

class BackgroundSyncWorkManager {
  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;
  static const String syncTaskName = 'periodicSyncTask';
  static const String internetCheckTaskName = 'internetCheckTask';
  static const String manualSyncTaskName = 'manualSyncTask';
  static const String immediateSyncTaskName = 'immediateSyncTask';

  static void initialize() {
    log('Initializing BackgroundSyncWorkManager...');
    Workmanager().initialize(callbackDispatcher);
    log('Initialized BackgroundSyncWorkManager...');
  }

  static Future<void> triggerPeriodicSyncTasks() async {
    await ensureInitialized();

    Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  // One-time sync trigger (when data is added)
  static Future<void> triggerImmediateSync() async {
    await ensureInitialized();
    log('Triggering immediate sync task...');
    Workmanager().registerOneOffTask(
      immediateSyncTaskName,
      immediateSyncTaskName,
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  // One-time manual sync trigger (user initiated)
  static Future<void> triggerManualSync() async {
    await ensureInitialized();
    log('Triggering immediate sync task...');
    Workmanager().registerOneOffTask(
      manualSyncTaskName,
      manualSyncTaskName,
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static void registerInternetCheckTask() {
    Workmanager().registerOneOffTask(
        internetCheckTaskName, internetCheckTaskName,
        existingWorkPolicy: ExistingWorkPolicy.keep);
  }

  /// Ensure Workmanager is initialized before using
  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    _initCompleter ??= Completer<void>();

    log('Initializing BackgroundSyncWorkManager...');
    await Workmanager().initialize(callbackDispatcher);
    _isInitialized = true;
    _initCompleter?.complete();
    log('Initialized BackgroundSyncWorkManager...');
  }
}

class HiveSyncManager {
  static ReceivePort? _receivePort;

  static void setupSyncPort(Future<void> Function() onSync) {
    if (_receivePort != null) return;

    _receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(hiveSyncPortName);
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      hiveSyncPortName,
    );

    _receivePort!.listen((message) async {
      log('Main Isolate: Received sync signal: $message');

      // Notify the caller to refresh Hive boxes and UI
      await onSync();
    });

    log('Main Isolate: Sync port registered');
  }

  static void notifySync() {
    final SendPort? sendPort =
        IsolateNameServer.lookupPortByName(hiveSyncPortName);
    if (sendPort != null) {
      log('Background: Sending sync signal to main isolate');
      sendPort.send('sync');
    } else {
      log('Background: Sync port not found');
    }
  }
}
