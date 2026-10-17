import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:excel/excel.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:schnell_luminator/utils/utility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

final lampController =
    ChangeNotifierProvider<LampProvider>((ref) => LampProvider());

class LampProvider extends ChangeNotifier {
  static const String masterFileName = 'luminator_lamp_data.xlsx';

  /// Save lamp installation data to Hive local storage
  Future<void> saveLampActivityToHive(
    Map<String, dynamic> apiData,
    lampName,
    int apiStatus,
    bool isUploaded,
  ) async {
    final box = await Utility.openHiveBox(lampInstallationBox);

    await box.add({
      "lampName": lampName,
      "lampType": apiData['lamp']['type'],

      "poleName": apiData['pole']['name'],
      "poleType": apiData['pole']['type'],
      // "poleConnection": apiData['pole']['connection'],
      "poleArmCount": apiData['pole']['armCount'],
      "poleLampProfiles": apiData['pole']['lampProfiles'],

      "latitude": apiData['latitude'],
      "longitude": apiData['longitude'],
      // "accuracy": apiData['accuracy'],
      "landmark": apiData['landmark'],

      "wardName": apiData['wardName'],
      "zoneName": apiData['zoneName'],
      "region": apiData['region'],
      "installedOn": apiData['installedOn'],
      "installedBy": apiData['installedBy'],
      "customerId": apiData['customerId'],
      "wardId": apiData['wardId'],
      "lightPointId": apiData['lightPointId'],
      "poleId": apiData['poleId'],
      "auditImg": apiData['auditImg'],
      "apiStatusCode": apiStatus,
      "isUploaded": isUploaded ? "true" : "false",
      // Export tracking flags
      "excelUpdated": false,
      "createdAt": DateTime.now().millisecondsSinceEpoch,
    });

    log('lamp data: ${box.toMap()}');

    notifyListeners();
  }

  static const String sheetName = 'Lamp Installations';

  /// ================= PERMISSIONS =================
  /// Request appropriate storage permissions based on Android version
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt < 30) {
        final storage = await Permission.storage.status;
        if (storage.isDenied) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return storage.isGranted;
      }
      return true;
    }
    return true;
  }

  /// ================= DIRECTORY =================
  Future<Directory> _getExportDirectory() async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        final exportDir = Directory('${directory.path}/exports');
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        return exportDir;
      }
    }
    return await getApplicationDocumentsDirectory();

    // if (directory == null) {
    //   throw Exception('Could not access storage directory');
    // }
  }

  /// ================= FETCH PENDING =================
  Future<List<Map<String, dynamic>>> getPendingLampInstallations() async {
    final box = await Utility.openHiveBox(lampInstallationBox);
    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < box.length; i++) {
      final e = box.getAt(i);
      if (e is Map && e['excelUpdated'] == false) {
        result.add({'_index': i, ...Map<String, dynamic>.from(e)});
      }
    }

    log('Pending lamps: ${result.length}');
    return result;
  }

  /// ================= HEADERS =================
  List<String> _getHeaders() => [
        'Lamp Name',
        'Lamp Profiles',
        'Pole Name',
        'Pole Type',
        'Pole Arm Count',
        'Latitude',
        'Longitude',
        'Landmark',
        'Ward',
        'Zone',
        'Region',
        'Installed By',
        'Installed On',
        'Is Uploaded',
        'API Status Code',
      ];

  List<String> _getKeys() => [
        'lampName',
        'poleLampProfiles',
        'poleName',
        'poleType',
        'poleArmCount',
        'latitude',
        'longitude',
        'landmark',
        'wardName',
        'zoneName',
        'region',
        'installedBy',
        'installedOn',
        'isUploaded',
        'apiStatusCode',
      ];

  /// ================= EXPORT EXCEL =================
  Future<Map<String, dynamic>> exportLampInstallationsToExcel(
      List<Map<String, dynamic>> lamps) async {
    final directory = await _getExportDirectory();
    final file = File('${directory.path}/$masterFileName');

    Excel excel;
    Sheet sheet;

    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      excel = Excel.decodeBytes(bytes);

      sheet = excel.sheets[sheetName] ?? excel[sheetName];
      log('Loaded sheet "$sheetName" with rows: ${sheet.rows.length}');
    } else {
      excel = Excel.createExcel();
      sheet = excel[sheetName];

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      for (int i = 0; i < _getHeaders().length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(_getHeaders()[i]);
        cell.cellStyle = CellStyle(bold: true);
      }
    }

    int startRow = sheet.rows.length;
    final keys = _getKeys();

    for (int r = 0; r < lamps.length; r++) {
      final lamp = lamps[r];
      for (int c = 0; c < keys.length; c++) {
        final v = lamp[keys[c]];
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: startRow + r));

        if (v is int) {
          cell.value = IntCellValue(v);
        } else if (v is double) {
          cell.value = DoubleCellValue(v);
        } else if (v is bool) {
          cell.value = TextCellValue(v ? 'Yes' : 'No');
        } else {
          cell.value = TextCellValue(v?.toString() ?? '');
        }
      }
    }

    final bytes = excel.encode();
    await file.writeAsBytes(bytes!, flush: true);

    return {
      'filePath': file.path,
      'fileName': masterFileName,
      'newRecords': lamps.length,
      'totalRecords': sheet.rows.length - 1,
      'fileSize': await file.length(),
    };
  }

  /// ================= MARK EXPORTED =================
  Future<void> markExcelUpdated(List<Map<String, dynamic>> exported) async {
    final box = await Utility.openHiveBox(lampInstallationBox);

    for (final e in exported) {
      final index = e['_index'];
      final data = Map<String, dynamic>.from(box.getAt(index));
      data['excelUpdated'] = true;
      data['excelUpdatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await box.putAt(index, data);
    }

    notifyListeners();
  }

  /// ================= EXPORT DIALOG =================
  Future<void> showLampExportDialog(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 12),
              Text('Exporting lamps...'),
            ],
          ),
        ),
      );

      if (!await requestPermissions()) {
        Navigator.pop(context);
        return;
      }

      final lamps = await getPendingLampInstallations();
      final result = await exportLampInstallationsToExcel(lamps);
      await markExcelUpdated(lamps);

      Navigator.pop(context);
      _showSuccess(context, result);
    } catch (e) {
      Navigator.pop(context);
      _showError(context, e.toString());
    }
  }

  void _showSuccess(BuildContext c, Map<String, dynamic> r) {
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File: $masterFileName'),
            const SizedBox(height: 8),
            Text('Size: ${(r['fileSize'] / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 8),
            // Text('Total Records: $totalRecords'),
            // // Text('Uploaded: $uploadedRecords'),
            // // Text('Pending: $pendingRecords'),
            // const SizedBox(height: 16),
            const Text(
              'The file has been saved to your device.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        // content: Text(
        //     'New: ${r['newRecords']}\nTotal: ${r['totalRecords']}\nSize: ${(r['fileSize'] / 1024).toStringAsFixed(1)} KB'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('OK')),
          ElevatedButton(
              onPressed: () => OpenFile.open(r['filePath']),
              child: const Text('Open File')),
        ],
      ),
    );
  }

  void _showError(BuildContext c, String msg) {
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Export Failed'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> cleanupExportedLampData({int days = 7}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRun = prefs.getInt('lamp_cleanup_ts') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    // cleanup only once per day
    if (now - lastRun < const Duration(hours: 24).inMilliseconds) {
      return;
    }

    final box = await Utility.openHiveBox(lampInstallationBox);
    final expiry = days * 24 * 60 * 60 * 1000;

    final List<int> deleteIndexes = [];

    for (int i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data is Map &&
          data['excelUpdated'] == true &&
          data['excelUpdatedAt'] != null &&
          now - data['excelUpdatedAt'] >= expiry) {
        deleteIndexes.add(i);
      }
    }

    // Delete from last index to avoid shifting
    for (final i in deleteIndexes.reversed) {
      await box.deleteAt(i);
    }

    await prefs.setInt('lamp_cleanup_ts', now);

    log('Deleted ${deleteIndexes.length} exported lamp records');
  }
}
