import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schnell_luminator/luminator_app.dart';
import 'attendence_tracking.dart/attendance_record.dart';
import 'attendence_tracking.dart/gps_details_model.dart';
import 'attendence_tracking.dart/ppe_queue_item.dart';
import 'device_page/lamp/lamp_controller.dart';
import 'env.dart';
import 'firebase_setup/firebase_config.dart';
import 'firebase_setup/firebase_options_luminator.dart' as luminator;
import 'firebase_setup/firebase_services.dart';
import 'pole_install.dart/pole_history_model.dart';
import 's3_bucket/s3_config.dart';
import 'survey/background_sync_manager.dart';
import 'survey/survey_controller.dart';
import 'ticket_notification/offline/ticket_queue_item.dart';
import 'ticket_notification/offline/ticket_repository.dart';
import 'ticket_notification/offline/ticket_update_queue_item.dart';
import 'utils/constants.dart';
import 'utils/custom_loading.dart';
import 'utils/utility.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: luminator.DefaultFirebaseOptions.android,
  );

  await Firebase.initializeApp(
    name: 'Tickets',
    options: ticketsFirebaseOptions,
  );

  final directory = await getApplicationDocumentsDirectory();
  final hivePath = directory.path;
  Hive.init(hivePath);
  log('hivePath: $hivePath');
  Hive.registerAdapter(InstallationHistoryAdapter());
  Hive.registerAdapter(TravelLocationEntityAdapter());
  Hive.registerAdapter(AttendanceRecordAdapter());
  Hive.registerAdapter(PpeQueueItemAdapter());
  Hive.registerAdapter(TicketQueueItemAdapter());
  Hive.registerAdapter(TicketUpdateQueueItemAdapter());
  await Utility.openHiveBox('geoFenceBox');
  await Utility.openHiveBox(assetNameBox);
  await Utility.openHiveBox(ticketListBox);
  await Utility.openAttendanceBox();
  await Utility.openPpeQueueBox();
  BackgroundSyncWorkManager.initialize();

  final container = ProviderContainer();
  await container.read(lampController).cleanupExportedLampData(days: 7);
  await TicketRepository().cleanupSyncedTickets(days: 7);
  HiveSyncManager.setupSyncPort(() async {
    log('Main Isolate: Reloading assetNameBox...');
    if (Hive.isBoxOpen(assetNameBox)) {
      await Hive.box(assetNameBox).close();
    }
    await Utility.openHiveBox(assetNameBox);
    log('Main Isolate: assetNameBox reloaded.');

    log('Main Isolate: Reloading ticketListBox...');
    if (Hive.isBoxOpen(ticketListBox)) {
      await Hive.box(ticketListBox).close();
    }
    await Utility.openHiveBox(ticketListBox);
    log('Main Isolate: ticketListBox reloaded.');

    container.read(hiveSyncProvider.notifier).state++;
  });

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
    (_) {
      HttpOverrides.global = MyHttpOverrides();
      log('currentEnvironment: $currentEnvironment');
      log('baseUrl: $baseURL');
      log('thingsboardUrl: $thingsboardURL');
      log('Bucket Name: ${S3Config.bucketName}');
      log('S3 Endpoint: ${S3Config.s3Endpoint}');
      log("Firebase App Name: ${FirebaseServices.ticketsFirestore.app.name}");
      log("Project ID: ${FirebaseServices.ticketsFirestore.app.options.projectId}");

      runApp(ProviderScope(
        parent: container,
        child: const LuminatorApp(),
      ));
      configLoading();
    },
  );
}

void configLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.light
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..textColor = Colors.green
    ..maskColor = Colors.green.withValues(alpha: 0.5)
    ..userInteractions = false
    ..dismissOnTap = false
    ..customAnimation = CustomAnimation()
    ..progressColor = Colors.green
    ..backgroundColor = const Color.fromARGB(255, 144, 184, 210)
    ..indicatorColor = Colors.green;
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
