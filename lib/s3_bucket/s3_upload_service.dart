import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../device_page/telemetry_service.dart';
import '../utils/image_compression_util.dart';
import 's3_config.dart';

class S3UploadService {
  final TelemetryService _telemetryService = TelemetryService();

  Future<String> updateSurveyImageServiceS3(String filePath, String fileName,
      {bool isPPE = false}) async {
    try {
      log('Starting S3 upload for file: $fileName');

      final result = await uploadImageFileToS3(
        filePath: filePath,
        fileName: fileName,
        folder: isPPE ? S3Config.ppeImageFolder : S3Config.luminatorFolder,
        contentType: 'image/jpeg',
      );

      log('S3 upload result: $result');

      // Check if upload was successful
      if (result != null && result.isNotEmpty) {
        log('S3 upload successful, URL: $result');
        var status = isPPE
            ? await _telemetryService
                .pushValuesToUserTelemetry({"ppeImageUrl": result})
            : '200';
        await ImageCompressionUtil.deleteCompressedImage(filePath);

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

  static Future<String?> uploadImageFileToS3({
    required String filePath,
    required String fileName,
    required String folder,
    String contentType = 'image/jpeg',
  }) async {
    try {
      log('Starting S3 upload for file: $fileName from path: $filePath');
      final file = File(filePath);
      if (!await file.exists()) {
        log('Error: File does not exist at path: $filePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      log('File read successfully, bytes length: ${bytes.length}');

      if (bytes.isEmpty) {
        log('Error: File bytes are empty');
        return null;
      }

      // Create the S3 key (path)
      final key = '$folder/$fileName';
      log('S3 Key: $key');

      // Upload using HttpClient
      final result = await _uploadWithHttpClient(
        bytes: bytes,
        key: key,
        contentType: contentType,
      );

      if (result != null) {
        log('S3 upload successful, URL: $result');
        return result;
      } else {
        log('S3 upload failed');
        return null;
      }
    } catch (e) {
      log('S3 upload error: $e');
      return null;
    }
  }

  // /// Upload using AWS Signature Version 4
  // static Future<String?> _uploadWithSignature({
  //   required Uint8List bytes,
  //   required String key,
  //   required String contentType,
  // }) async {
  //   try {
  //     final now = DateTime.now().toUtc();
  //     final dateStamp = _formatDate(now);
  //     final timeStamp = _formatDateTime(now);

  //     // Create the URL
  //     final url =
  //         'https://${S3Config.bucketName}.s3.${S3Config.region}.amazonaws.com/$key';

  //     // Create headers
  //     final headers = <String, String>{
  //       'Host': '${S3Config.bucketName}.s3.${S3Config.region}.amazonaws.com',
  //       'Content-Type': contentType,
  //       'Content-Length': bytes.length.toString(),
  //       'x-amz-date': timeStamp,
  //       'x-amz-content-sha256': _sha256Hash(bytes),
  //     };

  //     // Create authorization header
  //     final authHeader = _createAuthorizationHeader(
  //       method: 'PUT',
  //       uri: '/$key',
  //       headers: headers,
  //       dateStamp: dateStamp,
  //       timeStamp: timeStamp,
  //       payloadHash: _sha256Hash(bytes),
  //     );

  //     headers['Authorization'] = authHeader;

  //     log('Uploading to URL: $url');
  //     log('Headers: $headers');

  //     // Make the PUT request
  //     final response = await _dio.put(
  //       url,
  //       data: bytes,
  //       options: Options(
  //         headers: headers,
  //         contentType: contentType,
  //         responseType: ResponseType.plain,
  //       ),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 204) {
  //       return url;
  //     } else {
  //       log('Upload failed with status: ${response.statusCode}');
  //       log('Response: ${response.data}');
  //       return null;
  //     }
  //   } catch (e) {
  //     log('Upload with signature error: $e');
  //     return null;
  //   }
  // }

  /// Create AWS Signature Version 4 authorization header
  static String _createAuthorizationHeader({
    required String method,
    required String uri,
    required Map<String, String> headers,
    required String dateStamp,
    required String timeStamp,
    required String payloadHash,
  }) {
    // Step 1: Create canonical request
    final canonicalHeaders = headers.entries
        .map((e) => '${e.key.toLowerCase()}:${e.value.trim()}')
        .toList()
      ..sort();

    final signedHeaders = headers.keys.map((k) => k.toLowerCase()).toList()
      ..sort();

    final canonicalRequest = [
      method,
      uri,
      '', // query string
      '${canonicalHeaders.join('\n')}\n',
      signedHeaders.join(';'),
      payloadHash,
    ].join('\n');

    // Step 2: Create string to sign
    final credentialScope = '$dateStamp/${S3Config.region}/s3/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      timeStamp,
      credentialScope,
      _sha256Hash(utf8.encode(canonicalRequest)),
    ].join('\n');

    // Step 3: Calculate signature
    final signature = _calculateSignature(
      stringToSign: stringToSign,
      dateStamp: dateStamp,
    );

    // Step 4: Create authorization header
    return 'AWS4-HMAC-SHA256 '
        'Credential=${S3Config.accessKey}/$credentialScope, '
        'SignedHeaders=${signedHeaders.join(';')}, '
        'Signature=$signature';
  }

  /// Calculate AWS Signature Version 4 signature
  static String _calculateSignature({
    required String stringToSign,
    required String dateStamp,
  }) {
    final kDate =
        _hmacSha256(utf8.encode('AWS4${S3Config.secretKey}'), dateStamp);
    final kRegion = _hmacSha256(kDate, S3Config.region);
    final kService = _hmacSha256(kRegion, 's3');
    final kSigning = _hmacSha256(kService, 'aws4_request');
    final signature = _hmacSha256(kSigning, stringToSign);

    return signature.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// HMAC-SHA256 helper
  static List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  /// SHA256 hash helper
  static String _sha256Hash(List<int> data) {
    return sha256.convert(data).toString();
  }

  /// Format date for AWS (YYYYMMDD)
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Format datetime for AWS (YYYYMMDDTHHMMSSZ)
  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)}T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}Z';
  }

  static Future<String?> _uploadWithHttpClient({
    required Uint8List bytes,
    required String key,
    required String contentType,
  }) async {
    try {
      log('Starting S3 upload using HttpClient...');

      final now = DateTime.now().toUtc();
      final dateStamp = _formatDate(now);
      final timeStamp = _formatDateTime(now);

      final uri = Uri.parse(
          'https://${S3Config.bucketName}.s3.${S3Config.region}.amazonaws.com/$key');

      // Create headers for signing
      final headersForSigning = <String, String>{
        'Host': '${S3Config.bucketName}.s3.${S3Config.region}.amazonaws.com',
        'x-amz-date': timeStamp,
        'x-amz-content-sha256': _sha256Hash(bytes),
      };

      final authHeader = _createAuthorizationHeader(
        method: 'PUT',
        uri: '/$key',
        headers: headersForSigning,
        dateStamp: dateStamp,
        timeStamp: timeStamp,
        payloadHash: _sha256Hash(bytes),
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      try {
        final request = await client.putUrl(uri);

        request.headers.set('Host',
            '${S3Config.bucketName}.s3.${S3Config.region}.amazonaws.com');
        request.headers.set('x-amz-date', timeStamp);
        request.headers.set('x-amz-content-sha256', _sha256Hash(bytes));
        request.headers.set('Authorization', authHeader);
        request.headers.set('Content-Type', contentType);
        request.headers.set('Content-Length', bytes.length.toString());

        log('Uploading ${bytes.length} bytes to S3...');

        request.add(bytes);

        final response = await request.close();
        final statusCode = response.statusCode;

        if (statusCode == 200 || statusCode == 204) {
          log('S3 upload successful - Status: $statusCode');
          return uri.toString();
        } else {
          final responseBody = await response.transform(utf8.decoder).join();
          log('S3 upload failed - Status: $statusCode');
          log('Error response: $responseBody');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      log('S3 upload error: $e');
      return null;
    }
  }
}
