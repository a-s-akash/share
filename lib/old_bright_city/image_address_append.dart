
// import 'dart:typed_data';
// import 'package:image/image.dart' as img;

// class ImageAddressAppender {
//   String landmark = '';
//   String datetime = '';
//   String latlong = '';

//   Future<Uint8List> appendAddressToImage(
//     Uint8List imageBytes,
//     String landmark,
//     String lat,
//     String long,
//   ) async {
//     return appendAddressCore(imageBytes, landmark, lat, long);
//   }

//   Future<Uint8List> appendAddressCore(
//     Uint8List imageBytes,
//     String landmark,
//     String lat,
//     String long,
//   ) async {
//     this.landmark = landmark;
//     datetime = _formatDate(DateTime.now());
//     latlong = 'Lat: $lat, Long: $long';

//     img.Image? image1 = img.decodeImage(imageBytes);
//     await Future.delayed(const Duration(milliseconds: 1));
//     if (image1 == null) {
//       return Uint8List(0);
//     }

//     int containerWidth = image1.width - 12;
//     int containerHeight = 100;
//     int containerX = 6;
//     int containerY = image1.height - containerHeight - 10;
//     int radius = 20;

//     _drawRoundedRect(image1, containerX, containerY,
//         containerX + containerWidth, containerY + containerHeight, radius);
//     await Future.delayed(const Duration(milliseconds: 1));

//     _drawTextOnImage(image1, containerX + 10, containerY + 10);
//     await Future.delayed(const Duration(milliseconds: 1));

//     await Future.delayed(const Duration(milliseconds: 1));
//     final stamped = img.encodeJpg(image1);
//     return Uint8List.fromList(stamped);
//   }

//   String _formatDate(DateTime dateTime) {
//     String day = dateTime.day.toString().padLeft(2, '0');
//     String month = dateTime.month.toString().padLeft(2, '0');
//     String year = dateTime.year.toString();
//     String hour = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12)
//         .toString()
//         .padLeft(2, '0');
//     String minute = dateTime.minute.toString().padLeft(2, '0');
//     String period = dateTime.hour >= 12 ? 'PM' : 'AM';
//     return '$day/$month/$year $hour:$minute $period';
//   }

//   void _drawRoundedRect(
//       img.Image image, int x1, int y1, int x2, int y2, int radius) {
//     img.fillRect(image,
//         x1: x1,
//         y1: y1 + radius,
//         x2: x2,
//         y2: y2 - radius,
//         color: img.ColorUint8.rgb(0, 0, 0));
//     img.fillRect(image,
//         x1: x1 + radius,
//         y1: y1,
//         x2: x2 - radius,
//         y2: y2,
//         color: img.ColorUint8.rgb(0, 0, 0));
//     img.drawCircle(image,
//         x: x1 + radius,
//         y: y1 + radius,
//         radius: radius,
//         color: img.ColorUint8.rgb(0, 0, 0));
//     img.drawCircle(image,
//         x: x2 - radius,
//         y: y1 + radius,
//         radius: radius,
//         color: img.ColorUint8.rgb(0, 0, 0));
//     img.drawCircle(image,
//         x: x1 + radius,
//         y: y2 - radius,
//         radius: radius,
//         color: img.ColorUint8.rgb(0, 0, 0));
//     img.drawCircle(image,
//         x: x2 - radius,
//         y: y2 - radius,
//         radius: radius,
//         color: img.ColorUint8.rgb(0, 0, 0));
//     img.fillCircle(image,
//         x: x1 + radius,
//         y: y1 + radius,
//         radius: radius,
//         color: img.ColorUint8.rgb(0, 0, 0));
//     img.fillCircle(image,
//         x: x2 - radius,
//         y: y1 + radius,
//         radius: radius,
//         color: img.ColorUint8.rgb(0, 0, 0));
//     img.fillCircle(image,
//         x: x1 + radius,
//         y: y2 - radius,
//         radius: radius,
//         color: img.ColorUint8.rgb(0, 0, 0));
//     img.fillCircle(image,
//         x: x2 - radius,
//         y: y2 - radius,
//         radius: radius,
//         color: img.ColorUint8.rgb(0, 0, 0));
//   }

//   void _drawTextOnImage(img.Image image, int x, int y) {
//     img.drawString(image, landmark,
//         font: img.arial14,
//         wrap: true,
//         x: x,
//         y: y,
//         color: img.ColorUint8.rgb(255, 255, 255));
//     img.drawString(image, latlong,
//         font: img.arial14,
//         x: x,
//         y: y + 50,
//         color: img.ColorUint8.rgb(255, 255, 255));
//     img.drawString(image, datetime,
//         font: img.arial14,
//         x: x,
//         y: y + 70,
//         color: img.ColorUint8.rgb(255, 255, 255));
//   }
// }
