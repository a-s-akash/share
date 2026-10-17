import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:schnell_luminator/utils/asset_folder.dart';

import 'device_controller.dart';

class ImageAddressAppender {
  String currentLocation = '';
  String formattedDate = '';
  String manualEneteredLoc = '';
  String location = '';
  String latlong = '';
  String datetime = '';
  String projectContext = '';
  String devicename = '';

  Future<void> appendAddressToImage(
    WidgetRef ref,
    List<String> imagePaths,
    String manualEnteredLocation,
    String landmark,
    // String lng,
    Uint8List iconData,
    String projContext,
    String deviceName,
  ) async {
    String formattedAccr = '';
    String lpLat = ref.watch(deviceController).lpLat;
    String lpLong = ref.watch(deviceController).lpLong;
    String poleLat = ref.watch(deviceController).poleLat;
    String poleLong = ref.watch(deviceController).poleLong;
    String fetchedLong = ref.watch(deviceController).fetchedLong;
    String fetchedLat = ref.watch(deviceController).fetchedLat;
    String poleAccuracy = ref.watch(deviceController).poleAccuracy;
    String lpAccuracy = ref.watch(deviceController).lpAccuracy;
    String fetchedAcc = ref.watch(deviceController).fetchedAcc;
    String ccmsLat = ref.watch(deviceController).ccmsLat;
    String ccmsLong = ref.watch(deviceController).ccmsLong;
    String hubLat = ref.watch(deviceController).hubLat;
    String hubLong = ref.watch(deviceController).hubLong;
    var deviceType = ref.watch(deviceController).firstDeviceType;

    String latitude = deviceType == "GW"
        ? ccmsLat.isEmpty
            ? (hubLat.isEmpty ? fetchedLat : hubLat)
            : ccmsLat
        : poleLat.isEmpty
            ? (lpLat.isEmpty ? fetchedLat : lpLat)
            : poleLat;
    String longitude = deviceType == "GW"
        ? ccmsLong.isEmpty
            ? (hubLong.isEmpty ? fetchedLong : hubLong)
            : ccmsLong
        : poleLong.isEmpty
            ? (lpLong.isEmpty ? fetchedLong : lpLong)
            : poleLong;

    String accuracy = poleAccuracy == ''
        ? lpAccuracy.isEmpty
            ? fetchedAcc
            : lpAccuracy
        : poleAccuracy;
    if (accuracy != '') {
      double accrDouble = double.parse(accuracy);
      formattedAccr = accrDouble.toStringAsFixed(2);
    }

    location = landmark;
    manualEneteredLoc = manualEnteredLocation;

    projectContext = projContext;
    devicename = deviceName;

    DateTime now = DateTime.now();
    formattedDate = _formatDate(now);
    latlong = 'Lat: $latitude, Long: $longitude';
    if (accuracy != '') {
      latlong = 'Lat: $latitude, Long: $longitude, Acc: $formattedAccr m';
    }
    datetime = formattedDate;

    // Decode icons once to be reused across all images
    img.Image icon = img.decodeImage(iconData)!;
    img.Image resizedIcon = img.copyResize(icon, width: 50, height: 50);

    File file = Assets.gMapPointerWaterMark;
    Uint8List iconBytes1 = file.readAsBytesSync();
    img.Image icon1 = img.decodeImage(iconBytes1)!;
    img.Image resizedIcon1 = img.copyResize(icon1, width: 25, height: 25);

    double calculateTextWidth(String text, TextStyle style) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      return textPainter.size.width;
    }

    int containerWidth1 =
        calculateTextWidth(projectContext, const TextStyle(fontSize: 14.0))
                .toInt() +
            55;
    int containerHeight1 = 30;
    int containerX1 = 8;
    int containerY1 = 8;

    int x11 = containerX1;
    int x21 = containerX1 + containerWidth1;
    int y11 = containerY1;
    int y21 = containerY1 + containerHeight1;
    int radius1 = 8;

    int iconX1 = containerX1 + 5;
    int iconY1 = 12;

    for (String imagePath in imagePaths) {
      File capturedImage = File(imagePath);

      img.Image? image1 = img.decodeImage(capturedImage.readAsBytesSync());
      if (image1 == null) {
        // print('Error decoding image.');
        continue;
      }

      // Define position and size for the container
      int containerWidth = image1.width ~/ 1.03;
      int containerHeight = 142;
      int containerX = 6;
      int containerY = image1.height - containerHeight - 10;

      int x1 = containerX;
      int x2 = containerX + containerWidth;
      int y1 = containerY;
      int y2 = containerY + containerHeight;
      int radius = 20;

      // Draw the rounded rectangle
      _drawRoundedRect(image1, x1, y1, x2, y2, radius);

      // Draw the resized icon on the container
      int iconX = containerX + 10;
      int iconY = containerY + (containerHeight - resizedIcon.height) ~/ 2;
      img.compositeImage(image1, resizedIcon, dstX: iconX, dstY: iconY);

      // Draw location text on image within the container
      _drawTextOnImage(image1, containerX + resizedIcon.width + 20, containerY);

      // Draw the top bar rounded rectangle
      _drawRoundedRect(image1, x11, y11, x21, y21, radius1);

      // Draw top icon
      img.compositeImage(image1, resizedIcon1, dstX: iconX1, dstY: iconY1);

      // Draw location text on image within the container
      _drawProjectContextOnImage(image1, containerX1, containerY1);

      File editedImageFile = File(imagePath);
      log(imagePath);
      await editedImageFile.writeAsBytes(img.encodeJpg(image1));
    }
  }

  String _formatDate(DateTime dateTime) {
    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    String year = dateTime.year.toString();
    String hour = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12)
        .toString()
        .padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year $hour:$minute $period';
  }

  void _drawRoundedRect(
      img.Image image, int x1, int y1, int x2, int y2, int radius) {
    img.fillRect(image,
        x1: x1,
        y1: y1 + radius,
        x2: x2,
        y2: y2 - radius,
        color: img.ColorUint8.rgb(0, 0, 0));
    img.fillRect(image,
        x1: x1 + radius,
        y1: y1,
        x2: x2 - radius,
        y2: y2,
        color: img.ColorUint8.rgb(0, 0, 0));
    img.drawCircle(image,
        x: x1 + radius,
        y: y1 + radius,
        radius: radius,
        color: img.ColorUint8.rgb(0, 0, 0));
    img.drawCircle(image,
        x: x2 - radius,
        y: y1 + radius,
        radius: radius,
        color: img.ColorUint8.rgb(0, 0, 0));
    img.drawCircle(image,
        x: x1 + radius,
        y: y2 - radius,
        radius: radius,
        color: img.ColorUint8.rgb(0, 0, 0));
    img.drawCircle(image,
        x: x2 - radius,
        y: y2 - radius,
        radius: radius,
        color: img.ColorUint8.rgb(0, 0, 0));
    img.fillCircle(image,
        x: x1 + radius,
        y: y1 + radius,
        radius: radius,
        color: img.ColorUint8.rgb(0, 0, 0));
    img.fillCircle(image,
        x: x2 - radius,
        y: y1 + radius,
        radius: radius,
        color: img.ColorUint8.rgb(0, 0, 0));
    img.fillCircle(image,
        x: x1 + radius,
        y: y2 - radius,
        radius: radius,
        color: img.ColorUint8.rgb(0, 0, 0));
    img.fillCircle(image,
        x: x2 - radius,
        y: y2 - radius,
        radius: radius,
        color: img.ColorUint8.rgb(0, 0, 0));
  }

  void _drawTextOnImage(img.Image image, int x, int y) {
    img.drawString(image, devicename,
        font: img.arial14,
        x: x,
        y: y + 10,
        color: img.ColorUint8.rgb(255, 255, 255));
    img.drawString(
      image,
      manualEneteredLoc,
      wrap: true,
      font: img.arial14,
      x: x,
      y: y + 31,
      color: img.ColorUint8.rgb(255, 255, 255),
    );
    img.drawString(
      image,
      location,
      wrap: true,
      font: img.arial14,
      x: x,
      y: y + 69,
      color: img.ColorUint8.rgb(255, 255, 255),
    );
    img.drawString(image, latlong,
        font: img.arial14,
        x: x,
        y: y + 107,
        color: img.ColorUint8.rgb(255, 255, 255));
    img.drawString(image, datetime,
        font: img.arial14,
        x: x,
        y: y + 122,
        color: img.ColorUint8.rgb(255, 255, 255));
  }

  Future<void> _drawProjectContextOnImage(img.Image image, int x, int y) async {
    // final fontZipFile = await File('assets/fonts/paul.zip').readAsBytes();
    // final font = img.BitmapFont.fromZip(fontZipFile);
    img.drawString(image, projectContext,
        font: img.arial14,
        x: x + 32,
        y: y + 10,
        color: img.ColorUint8.rgb(255, 255, 255));
  }
}
