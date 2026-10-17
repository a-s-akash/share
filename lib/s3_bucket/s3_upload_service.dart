import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 's3_config.dart';

class S3UploadService {
  static Future<String?> uploadImageFileToS3({
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    try {
      log('Starting S3 upload for file: $fileName (bytes: ${bytes.length})');

      if (bytes.isEmpty) {
        log('Error: File bytes are empty');
        return null;
      }

      // Create the S3 key (path)
      final key = '${S3Config.grievanceFolder}/$fileName';
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
    final canonicalHeaders =
        headers.entries
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
    final kDate = _hmacSha256(
      utf8.encode('AWS4${S3Config.secretKey}'),
      dateStamp,
    );
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
      log('Starting S3 upload using http package...');

      final now = DateTime.now().toUtc();
      final dateStamp = _formatDate(now);
      final timeStamp = _formatDateTime(now);

      final uri = Uri.parse('${S3Config.s3uri}/$key');

      // Create headers for signing
      final headersForSigning = <String, String>{
        'host': S3Config.s3Host,
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

      final headers = <String, String>{
        'Host': S3Config.s3Host,
        'x-amz-date': timeStamp,
        'x-amz-content-sha256': _sha256Hash(bytes),
        'Authorization': authHeader,
        'Content-Type': contentType,
        'Content-Length': bytes.length.toString(),
      };

      try {
        final response = await http.put(uri, headers: headers, body: bytes);

        final statusCode = response.statusCode;

        if (statusCode == 200 || statusCode == 204) {
          log('S3 upload successful - Status: $statusCode');
          return uri.toString();
        } else {
          log('S3 upload failed - Status: $statusCode');
          log('Error response: ${response.body}');
          return null;
        }
      } catch (e) {
        log('HTTP PUT failed: $e');
        return null;
      }
    } catch (e) {
      log('S3 upload error: $e');
      return null;
    }
  }
}
