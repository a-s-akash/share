import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:hive_flutter/adapters.dart';
import 'package:image/image.dart' as img;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../attendence_tracking.dart/attendance_record.dart';
import '../attendence_tracking.dart/gps_details_model.dart';
import '../attendence_tracking.dart/ppe_queue_item.dart';
import '../pole_install.dart/pole_history_model.dart';
import '../ticket_notification/offline/ticket_queue_item.dart';
import '../ticket_notification/offline/ticket_update_queue_item.dart';
import '../ticket_notification/ticket_model.dart';
import 'constants.dart';
import 'dialog_box.dart';
import 'error_messages.dart';

class Utility {
  static Future<bool> isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    log(connectivityResult.toString());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      try {
        final result = await InternetAddress.lookup('iotpro.io');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      try {
        final result = await InternetAddress.lookup('iotpro.io');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    }
    return false;
  }

  static Future<bool> ensureLocationServiceEnabled() async {
    final Location location = Location();
    final serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      return await location.requestService();
    }

    return true;
  }

  static Future<String> activityCompressImage(
      String imagePath, String fileName) async {
    final imageFile = File(imagePath);
    final originalBytes = await imageFile.readAsBytes();

    // Decode image
    img.Image? originalImage = img.decodeImage(originalBytes);
    if (originalImage == null) throw Exception("Failed to decode image");

    // Resize to fixed width (e.g. 1080) to reduce resolution
    final resizedImage =
        img.copyResize(originalImage, width: 1080); // maintain aspect ratio

    // Compress with fixed quality
    final compressedBytes = Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: 70),
    );

    final sizeKB = compressedBytes.lengthInBytes / 1024;
    log("Compressed size: ${sizeKB.toStringAsFixed(2)} KB");

    // Save to app directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final compressedImagesDir =
        Directory('${appDocDir.path}/compressed_images');

    if (!await compressedImagesDir.exists()) {
      await compressedImagesDir.create(recursive: true);
    }

    final compressedFilePath = path.join(compressedImagesDir.path, fileName);

    final compressedFile = File(compressedFilePath);
    await compressedFile.writeAsBytes(compressedBytes);

    log("Compressed image saved at: $compressedFilePath");

    return compressedFilePath;
  }

  static Future<Box<InstallationHistory>> openInstallationHistoryBox() async {
    if (!Hive.isBoxOpen(installationHistoryBoxName)) {
      return await Hive.openBox<InstallationHistory>(
          installationHistoryBoxName);
    }
    return Hive.box<InstallationHistory>(installationHistoryBoxName);
  }

  static Future<Box<TravelLocationEntity>> openLocationTrackingBox() async {
    if (!Hive.isBoxOpen(locationTrackingBox)) {
      return await Hive.openBox<TravelLocationEntity>(locationTrackingBox);
    }
    return Hive.box<TravelLocationEntity>(locationTrackingBox);
  }

  static Future<Box<AttendanceRecord>> openAttendanceBox() async {
    if (!Hive.isBoxOpen(attendanceBox)) {
      return await Hive.openBox<AttendanceRecord>(attendanceBox);
    }
    return Hive.box<AttendanceRecord>(attendanceBox);
  }

  static Future<Box<PpeQueueItem>> openPpeQueueBox() async {
    if (!Hive.isBoxOpen(ppeQueueBox)) {
      return await Hive.openBox<PpeQueueItem>(ppeQueueBox);
    }
    return Hive.box<PpeQueueItem>(ppeQueueBox);
  }

  /// Closes and reopens the attendance box to pick up any background writes.
  static Future<void> refreshAttendanceBox() async {
    if (Hive.isBoxOpen(attendanceBox)) {
      await Hive.box<AttendanceRecord>(attendanceBox).close();
    }
    await Hive.openBox<AttendanceRecord>(attendanceBox);
  }

  /// Closes and reopens the ticket create/update queue boxes to pick up any
  /// writes made by the background sync isolate (performTicketSync and
  /// performTicketUpdateSync run inside WorkManager's own isolate, which has
  /// its own in-memory Box instance — a Box already open here won't see those
  /// writes until it's reopened).
  static Future<void> refreshTicketQueueBox() async {
    if (Hive.isBoxOpen(ticketQueueBox)) {
      await Hive.box<TicketQueueItem>(ticketQueueBox).close();
    }
    await Hive.openBox<TicketQueueItem>(ticketQueueBox);
    if (Hive.isBoxOpen(ticketUpdateQueueBox)) {
      await Hive.box<TicketUpdateQueueItem>(ticketUpdateQueueBox).close();
    }
    await Hive.openBox<TicketUpdateQueueItem>(ticketUpdateQueueBox);
  }

  static Future<Box> openHiveBox(boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }
}

extension StringExtension on String {
  static String displayTimeAgoFromMilliseconds(String milliseconds) {
    final DateTime videoDate =
        DateTime.fromMillisecondsSinceEpoch(int.parse(milliseconds));
    final int diffInHours = DateTime.now().difference(videoDate).inHours;

    String timeAgo = '';
    String timeUnit = '';
    int timeValue = 0;

    if (diffInHours < 1) {
      final diffInMinutes = DateTime.now().difference(videoDate).inMinutes;
      timeValue = diffInMinutes;
      timeUnit = 'minute';
    } else if (diffInHours < 24) {
      timeValue = diffInHours;
      timeUnit = 'hour';
    } else {
      timeValue = (diffInHours / 24).floor();
      timeUnit = 'day';
    }
    timeAgo = '$timeValue $timeUnit';
    timeAgo += timeValue > 1 ? 's' : '';

    return '$timeAgo ago';
  }
}

Future<void> launchMap(BuildContext context, Ticket ticket) async {
  try {
    launchUrl(Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${ticket.latitude},${ticket.longitude}"));
  } catch (e) {
    if (context.mounted) {
      await snackBar(context, ErrorMessages.networkErrorTitle,
          ErrorMessages.networkErrorMessage);
    }
  }
}
