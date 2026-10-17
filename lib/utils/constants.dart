import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

const appVersion = '3.13.0';
const splashRoute = '/';
const loginRoute = '/login';
const deviceScanRoute = '/deviceScan';
const homeRoute = '/home';
const regionRoute = '/region';
const customerRoute = '/customer';
const lampDetailsRoute = '/lampDetailsRoute';
const poleDetailsRoute = '/poleDetailsRoute';
const poleScanRoute = '/poleScanRoute';
const ticketListRoute = '/ticketListRoute';
const searchRoute = '/searchRoute';
const zoneRoute = '/zone';
const wardRoute = '/ward';
const mapRoute = '/map';
const updateRoute = '/update';
const String offlineLoginRoute = '/offlineLogin';
const String installationHistoryBoxName = 'installation_history_box';
const String countBox = 'countBox';
const String lampInstallationBox =
    'lampInstallationBox'; //storing lamp details of installation activity to update in excel
const String assetNameBox =
    'assetNameBox'; // For storing asset names(sp && trans)[prepopulated dropdown]
const String hiveSyncPortName = 'hive_sync_port';
const String locationTrackingBox = 'locationTrackingBox';
const String attendanceBox = 'attendanceBox';
const String ppeQueueBox = 'ppeQueueBox';
const String ticketCollectionName = 'tickets';
const String ticketQueueBox = 'ticketQueueBox';
const String ticketListBox = 'ticketListBox';
const String ticketUpdateQueueBox = 'ticketUpdateQueueBox';
const String ticketImagesQueueBox = 'ticketImagesQueueBox';

const selectedModePrefsKey = 'selectedAppMode';
const vehicleTypePrefsKey = 'saved_vehicle_type';
const vehicleNumberPrefsKey = 'saved_vehicle_number';

String appName = 'Luminator';

Future<bool> getFileDirectory(String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  File file = File('${dir.path}/$fileName');
  if (!await file.exists()) {
    log('Missing file: $fileName');
    return false;
  }
  return true;
}
