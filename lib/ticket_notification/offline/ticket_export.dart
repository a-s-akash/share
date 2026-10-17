import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../survey/excel_export.dart' show requestPermissions;
import '../../utils/constants.dart';
import 'ticket_queue_item.dart';
import 'ticket_update_queue_item.dart';

/// Mirrors lib/survey/excel_export.dart's workbook/permission/dialog pattern
/// so offline tickets export exactly the way survey data already does.
///
/// Refreshes the box first — same reason SwipeRecordsPage calls
/// Utility.refreshAttendanceBox() before reading attendanceBox: sync runs in
/// WorkManager's own isolate, so a Box already open here can be holding a
/// stale in-memory snapshot from before the last background sync wrote to it.
Future<List<TicketQueueItem>> getAllQueuedTickets() async {
  final box = await Hive.openBox<TicketQueueItem>(ticketQueueBox);
  return box.values.toList()
    ..sort((a, b) => b.createdAtEpochMs.compareTo(a.createdAtEpochMs));
}

Future<List<TicketUpdateQueueItem>> getAllQueuedTicketUpdates() async {
  final box = await Hive.openBox<TicketUpdateQueueItem>(ticketUpdateQueueBox);
  return box.values.toList()
    ..sort((a, b) => b.updatedAtEpochMs.compareTo(a.updatedAtEpochMs));
}

String _statusLabel(bool uploaded) => uploaded ? 'Synced' : 'Pending';

String _formatDateTime(int epochMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
}

Future<Map<String, dynamic>> exportQueuedTicketsToExcel(
    List<TicketQueueItem> tickets,
    [List<TicketUpdateQueueItem> updates = const []]) async {
  if (tickets.isEmpty && updates.isEmpty) {
    throw Exception('No offline tickets to export');
  }

  final workbook = xlsio.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.name = 'Offline Tickets';

  final headers = [
    'Alarm ID',
    'Ticket ID',
    'Device Type',
    'Device ID',
    'Problem Type',
    'Description',
    'Date & Time',
    'Location',
    'Latitude',
    'Longitude',
    'Attempt Count',
    'Sync Status'
  ];

  for (int i = 0; i < headers.length; i++) {
    sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
  }

  for (int row = 0; row < tickets.length; row++) {
    final t = tickets[row];
    final values = [
      t.alarmId,
      t.remoteTicketId ?? '',
      t.deviceType.toUpperCase(),
      t.deviceId.toUpperCase(),
      t.problemType,
      t.comments,
      _formatDateTime(t.createdAtEpochMs),
      t.locationText,
      t.tlatitude.toString(),
      t.tlongitude.toString(),
      t.attemptCount.toString(),
      _statusLabel(t.uploaded)
    ];
    for (int col = 0; col < values.length; col++) {
      sheet.getRangeByIndex(row + 2, col + 1).setText(values[col]);
    }
  }

  final updateSheet = workbook.worksheets.addWithName('Offline Ticket Updates');
  final updateHeaders = [
    'Alarm ID',
    'Ticket ID',
    'Device ID',
    'Device Type',
    'Update Type',
    'Actions',
    'Comment',
    'Last Updated',
    'Attempt Count',
    'Sync Status'
  ];

  for (int i = 0; i < updateHeaders.length; i++) {
    updateSheet.getRangeByIndex(1, i + 1).setText(updateHeaders[i]);
  }

  for (int row = 0; row < updates.length; row++) {
    final u = updates[row];
    final values = [
      u.alarmId,
      u.ticketId,
      u.deviceId,
      u.deviceType.toUpperCase(),
      u.updateType,
      u.actions,
      u.comments,
      _formatDateTime(u.updatedAtEpochMs),
      u.attemptCount.toString(),
      _statusLabel(u.uploaded)
    ];
    for (int col = 0; col < values.length; col++) {
      updateSheet.getRangeByIndex(row + 2, col + 1).setText(values[col]);
    }
  }

  final bytes = workbook.saveAsStream();
  workbook.dispose();

  Directory? directory;
  final fileName =
      'offline_tickets_${DateTime.now().millisecondsSinceEpoch}.xlsx';

  if (Platform.isAndroid) {
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
    'fileSize': await file.length(),
  };
}

Future<void> showTicketExportDialog(BuildContext context) async {
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
    if (!hasPermission) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(
            context, 'Storage permission is required to export data.');
      }
      return;
    }

    final tickets = await getAllQueuedTickets();
    final updates = await getAllQueuedTicketUpdates();
    if (tickets.isEmpty && updates.isEmpty) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(context, 'No offline tickets found to export.');
      }
      return;
    }

    final result = await exportQueuedTicketsToExcel(tickets, updates);

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

void _showSuccessDialog(BuildContext context, Map<String, dynamic> result) {
  final filePath = result['filePath'] as String;
  final fileName = result['fileName'] as String;
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
            final openResult = await OpenFile.open(filePath);
            if (openResult.type != ResultType.done && context.mounted) {
              _showErrorDialog(
                  context, 'Could not open file: ${openResult.message}');
            }
          },
          child: const Text('Open File'),
        ),
      ],
    ),
  );
}

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
