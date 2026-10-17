import 'dart:typed_data';
import 'dart:async';
import 'dart:developer';
import 'package:citizen_complaints_list_web/s3_bucket/s3_upload_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';


Future<Uint8List> activityCompressImage(Uint8List bytes) async {
  return await FlutterImageCompress.compressWithList(
    bytes,
    minWidth: 1080,
    quality: 70,
  );
}

s3Upload(Uint8List bytes, String fileName) async {
  try {
    log('Starting S3 upload for file: $fileName');

    final result = await S3UploadService.uploadImageFileToS3(
      bytes: bytes,
      fileName: fileName,
    );

    log('S3 upload result: $result');

    if (result != null && result.isNotEmpty) {
      log('S3 upload successful, URL: $result');
      var status = '200';
      return status;
    } else {
      log('S3 upload failed - result is null or empty');
      return "400";
    }
  } catch (e) {
    log('S3 upload error: $e');
    log('S3 upload error type: ${e.runtimeType}');
    return 'Something Went Wrong';
  }
}
