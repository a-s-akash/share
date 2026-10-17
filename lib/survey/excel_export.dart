import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:device_info_plus/device_info_plus.dart';

import '../s3_bucket/s3_config.dart';

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

/// Get all survey entries (Pole + Switch Point + Transformer) from Hive
Future<Map<String, List<Map<String, dynamic>>>> getAllSurveyEntries() async {
  try {
    if (Hive.isBoxOpen('surveyBox')) {
      await Hive.box('surveyBox').close();
    }
    final box = await Hive.openBox('surveyBox');

    final List<Map<String, dynamic>> poleSurveys = [];
    final List<Map<String, dynamic>> spSurveys = [];
    final List<Map<String, dynamic>> transformerSurveys = [];

    for (var entry in box.values) {
      try {
        if (entry is Map) {
          final map = Map<String, dynamic>.from(entry);
          if (map['assetType'] == 'Pole') {
            poleSurveys.add(map);
          } else if (map['assetType'] == 'Switch Point') {
            spSurveys.add(map);
          } else if (map['assetType'] == 'Transformer') {
            transformerSurveys.add(map);
          }
        } else {
          log("Skipping invalid entry in Hive box: ${entry.runtimeType}");
        }
      } catch (e) {
        log("Error processing survey entry: $e");
      }
    }

    return {
      'pole': poleSurveys,
      'switchPoint': spSurveys,
      'transformer': transformerSurveys,
    };
  } catch (e) {
    log("Error accessing Hive box: $e");
    return {
      'pole': [],
      'switchPoint': [],
      'transformer': [],
    };
  }
}

/// Export surveys into Excel with three sheets
Future<Map<String, dynamic>> exportLocalSurveysToExcel({
  required List<Map<String, dynamic>> poleSurveys,
  required List<Map<String, dynamic>> spSurveys,
  required List<Map<String, dynamic>> transformerSurveys,
}) async {
  try {
    if (poleSurveys.isEmpty &&
        spSurveys.isEmpty &&
        transformerSurveys.isEmpty) {
      throw Exception('No survey data to export');
    }

    final workbook = xlsio.Workbook();

    final poleSheet = workbook.worksheets[0];
    poleSheet.name = 'Pole Survey';

    final spSheet = workbook.worksheets.addWithName('Switch Point Survey');
    final transSheet = workbook.worksheets.addWithName('Transformer Survey');

    // Pole sheet headers & keys
    final poleHeaders = [
      'Pole Number',
      'EB Pole No',
      'Ex Corp Pole No',
      'Switch Point No',
      'Transformer No',
      'Existing Road Category',
      'Road Type',
      'Road Width',
      'Vehicle Access',
      'Traffic Density',
      'Traffic Speed',
      'Landmark',
      'Latitude',
      'Longitude',
      'Pole Condition',
      'Pole Type',
      'Asset Type',
      'Pole Span',
      'Pole Height',
      'Motor Condition',
      'Motor Rating',
      'Motor Make',
      'Motor Model',
      'Winch Condition',
      'Rope Condition',
      'Incoming Transmission Line',
      'Incoming Transmission Type',
      'Clamp Dimension',
      'Clamp Length',
      'Clamp Width',
      'Clamp Units',
      'Bracket Mounting Height',
      'Earthing',
      'Arm Count',
      'Arm Length',
      'Good Arm Count',
      'Bad Arm Count',
      'Missing Arm Count',
      'Working Count',
      'Not Working Count',
      'Missing Count',
      'Lamp Profiles',
      'Manual Switch Control',
      'Carrier Name',
      'Signal Strength Level',
      'Comments',
      'Image 1',
      'Image 2',
      'Image 3',
      'Installed On',
      'Installed By',
      'Region',
      'Zone',
      'Ward',
      'isUploaded'
    ];
    final poleKeys = [
      'poleNumber',
      'escomPoleNumber',
      'exCorpPoleNo',
      'switchPointNo',
      'poleTransformerNo',
      'roadCategory',
      'roadType',
      'roadWidth',
      'vehicleAccess',
      'trafficDensity',
      'trafficSpeed',
      'landmark',
      'latitude',
      'longitude',
      'poleCondition',
      'poleType',
      'assetType',
      'poleSpan',
      'poleHeight',
      'motorCondition',
      'motorRating',
      'motorMake',
      'motorModel',
      'winchCondition',
      'ropeCondition',
      'incomingTransLine',
      'incomingTransType',
      'clampType',
      'clampTypeLength',
      'clampTypeWidth',
      'clampTypeUnits',
      'bracketMountingHeight',
      'earthingRequired',
      'armCount',
      'armLength',
      'goodArmCount',
      'badArmCount',
      'missingArmCount',
      'workingCount',
      'notWorkingCount',
      'missingCount',
      'selectedLamps',
      'manualSwitchControl',
      'carrierName',
      'signalStrengthLevel',
      'comments',
      'uuidFileName1',
      'uuidFileName2',
      'uuidFileName3',
      'installedOn',
      'installedBy',
      'region',
      'zone',
      'ward',
      'isUploaded'
    ];

    // Switch Point sheet headers & keys
    final spHeaders = [
      'Switch Point No',
      'SP Type',
      'RR No',
      'Transformer No',
      'Panel ID',
      'Landmark',
      'Latitude',
      'Longitude',
      'Meter Working',
      'Connected Load',
      'Meter No',
      'Meter Type',
      'Meter Make',
      'Meter Phase',
      'SP Working Condition',
      'Earthing Condition',
      'Comments',
      'Image 1',
      'Image 2',
      'Image 3',
      'Installed On',
      'Installed By',
      'Region',
      'Zone',
      'Ward',
      'isUploaded'
    ];
    final spKeys = [
      'spNo',
      'spType',
      'rrNo',
      'spTransformerNo',
      'spId',
      'landmark',
      'latitude',
      'longitude',
      'spMeter',
      'spconnectedLoad',
      'spMeterNo',
      'spMeterType',
      'spMeterMake',
      'spMeterPhase',
      'spCondition',
      'spEarthingCondition',
      'comments',
      'uuidFileName1',
      'uuidFileName2',
      'uuidFileName3',
      'installedOn',
      'installedBy',
      'region',
      'zone',
      'ward',
      'isUploaded'
    ];

    /// Transformer sheet headers & keys
    final transHeaders = [
      'Transformer No',
      'Transformer Capacity',
      'Landmark',
      'Latitude',
      'Longitude',
      'Comments',
      'Image 1',
      'Image 2',
      'Image 3',
      'Installed On',
      'Installed By',
      'Region',
      'Zone',
      'Ward',
      'isUploaded'
    ];

    final transKeys = [
      'transformerNo',
      'transCapacity',
      'landmark',
      'latitude',
      'longitude',
      'comments',
      'uuidFileName1',
      'uuidFileName2',
      'uuidFileName3',
      'installedOn',
      'installedBy',
      'region',
      'zone',
      'ward',
      'isUploaded'
    ];

    /// Write Pole data
    for (int i = 0; i < poleHeaders.length; i++) {
      poleSheet.getRangeByIndex(1, i + 1).setText(poleHeaders[i]);
    }
    // for (int row = 0; row < poleSurveys.length; row++) {
    //   final survey = poleSurveys[row];
    //   for (int col = 0; col < poleKeys.length; col++) {
    //     poleSheet
    //         .getRangeByIndex(row + 2, col + 1)
    //         .setText(survey[poleKeys[col]]?.toString() ?? '');
    //   }
    // }
    for (int row = 0; row < poleSurveys.length; row++) {
      final survey = poleSurveys[row];
      for (int col = 0; col < poleKeys.length; col++) {
        final key = poleKeys[col];
        final value = survey[key]?.toString() ?? '';

        final cell = poleSheet.getRangeByIndex(row + 2, col + 1);

        //update image urls to clickable links
        if (value.isNotEmpty &&
            (key == 'uuidFileName1' ||
                key == 'uuidFileName2' ||
                key == 'uuidFileName3')) {
          final url = buildS3Url(value);
          cell.setText(url);
          poleSheet.hyperlinks.add(
            cell,
            xlsio.HyperlinkType.url,
            url,
            null, // optional screen tip
            url, // display the full URL as text
          );
        } else {
          cell.setText(value);
        }
      }
    }

    /// Write Switch Point data
    for (int i = 0; i < spHeaders.length; i++) {
      spSheet.getRangeByIndex(1, i + 1).setText(spHeaders[i]);
    }
    for (int row = 0; row < spSurveys.length; row++) {
      final survey = spSurveys[row];
      for (int col = 0; col < spKeys.length; col++) {
        final key = spKeys[col];
        final value = survey[key]?.toString() ?? '';
        final cell = spSheet.getRangeByIndex(row + 2, col + 1);

        //update image urls to clickable links
        if (value.isNotEmpty &&
            (key == 'uuidFileName1' ||
                key == 'uuidFileName2' ||
                key == 'uuidFileName3')) {
          final url = buildS3Url(value);
          cell.setText(url);
          spSheet.hyperlinks.add(
            cell,
            xlsio.HyperlinkType.url,
            url,
            null, // optional screen tip
            url, // display the full URL as text
          );
        } else {
          cell.setText(value);
        }
      }
    }

    /// Write Transformer data
    for (int i = 0; i < transHeaders.length; i++) {
      transSheet.getRangeByIndex(1, i + 1).setText(transHeaders[i]);
    }
    for (int row = 0; row < transformerSurveys.length; row++) {
      final survey = transformerSurveys[row];
      for (int col = 0; col < transKeys.length; col++) {
        final key = transKeys[col];
        final value = survey[key]?.toString() ?? '';
        final cell = transSheet.getRangeByIndex(row + 2, col + 1);

        //update image urls to clickable links
        if (value.isNotEmpty &&
            (key == 'uuidFileName1' ||
                key == 'uuidFileName2' ||
                key == 'uuidFileName3')) {
          final url = buildS3Url(value);
          cell.setText(url);
          transSheet.hyperlinks.add(
            cell,
            xlsio.HyperlinkType.url,
            url,
            null, // optional screen tip
            url, // display the full URL as text
          );
        } else {
          cell.setText(value);
        }
      }
    }

    /// Save file
    final bytes = workbook.saveAsStream();
    workbook.dispose();

    // Use app-specific directories for Google Play compliance
    Directory? directory;
    String fileName =
        'poleVault_survey_data_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    if (Platform.isAndroid) {
      // Use app-specific external directory for Android (no special permissions needed)
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        final exportDir = Directory('${directory.path}/exports');
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        directory = exportDir;
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('Could not access storage directory');
    }

    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    return {
      'filePath': file.path,
      'fileName': fileName,
      // 'totalRecords': surveys.length,
      // 'uploadedRecords': uploadedCount,
      // 'pendingRecords': pendingCount,
      'fileSize': await file.length(),
      // 'exportTime': timestamp.toIso8601String(),
    };
  } catch (e) {
    throw Exception('Excel export error: $e');
  }
}

Future<void> showExportDialog(BuildContext context) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Preparing export...'),
          ],
        ),
      ),
    );

    final hasPermission = await requestPermissions();
    if (!hasPermission && context.mounted) {
      Navigator.of(context).pop();
      _showErrorDialog(
          context, 'Storage permission is required to export data.');
      return;
    }

    final allData = await getAllSurveyEntries();

    if (allData['pole']!.isEmpty &&
        allData['switchPoint']!.isEmpty &&
        allData['transformer']!.isEmpty) {
      Navigator.of(context).pop();
      _showErrorDialog(context, 'No survey data found to export.');
      return;
    }

    final result = await exportLocalSurveysToExcel(
      poleSurveys: allData['pole']!,
      spSurveys: allData['switchPoint']!,
      transformerSurveys: allData['transformer']!,
    );

    if (context.mounted) {
      Navigator.of(context).pop();
      _showSuccessDialog(context, result);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      _showErrorDialog(context, 'Export failed: ${e.toString()}');
    }
  }
}

/// Show success dialog
void _showSuccessDialog(BuildContext context, Map<String, dynamic> result) {
  final filePath = result['filePath'] as String;
  final fileName = result['fileName'] as String;
  // final totalRecords = result['totalRecords'] as int;
  // final uploadedRecords = result['uploadedRecords'] as int;
  // final pendingRecords = result['pendingRecords'] as int;
  final fileSize = result['fileSize'] as int;

  final fileSizeKB = (fileSize / 1024).toStringAsFixed(1);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Export Successful'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('File: $fileName'),
          const SizedBox(height: 8),
          Text('Size: $fileSizeKB KB'),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _openFile(context, filePath);
          },
          child: const Text('Open File'),
        ),
      ],
    ),
  );
}

/// Show error dialog
void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Text('Export Failed'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Open exported file
Future<void> _openFile(BuildContext context, String filePath) async {
  try {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      _showErrorDialog(context, 'Could not open file: ${result.message}');
    }
  } catch (e) {
    _showErrorDialog(context, 'Error opening file: $e');
  }
}

String buildS3Url(String? fileName) {
  if (fileName == null || fileName.isEmpty) return '';
  return '${S3Config.s3Endpoint}/${S3Config.luminatorFolder}/$fileName';
}
