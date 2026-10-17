import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';

import '../env.dart';
import 'secure_storage.dart';
import 'utility.dart';

class DioClient {
  // Prevents concurrent requests from each consuming the single-use refresh token.
  static Completer<void>? _refreshLock;

  static final Dio dio = Dio()
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final secureStorage = SecureStorageService();
        String? accessToken = await secureStorage.getAccessToken();

        final now = DateTime.now().millisecondsSinceEpoch;
        final expiry = _getJwtExpiry(accessToken);

        if (expiry != null && expiry < now + 30000) {
          final isOnline = await Utility.isConnected();

          if (!isOnline) {
            // Offline — skip refresh, let the request fail with a network error
            log('DioClient: token expired but offline — skipping refresh');
          } else if (_refreshLock != null) {
            // Another request is already refreshing — wait and reuse new token
            log('DioClient: refresh in progress — waiting...');
            await _refreshLock!.future.catchError((_) {});
            accessToken = await secureStorage.getAccessToken();
          } else {
            _refreshLock = Completer<void>();
            try {
              final newToken = await _refreshToken(secureStorage);

              if (newToken != null) {
                // Refresh token was valid — new tokens already saved inside _refreshToken
                accessToken = newToken;
                log('DioClient: token refreshed successfully');
                _refreshLock!.complete();
              } else {
                // Refresh token also expired — silent re-login with stored credentials
                log('DioClient: refresh token expired — attempting silent re-login');
                final reLoginToken = await _silentReLogin(secureStorage);

                if (reLoginToken != null) {
                  accessToken = reLoginToken;
                  log('DioClient: silent re-login successful');
                  _refreshLock!.complete();
                } else {
                  _refreshLock!.completeError('auth_failed');
                  _refreshLock = null;
                  return handler.reject(DioError(
                    requestOptions: options,
                    error: 'Session expired. Please login again.',
                  ));
                }
              }
            } catch (e) {
              _refreshLock?.completeError(e);
              _refreshLock = null;
              return handler.reject(DioError(
                requestOptions: options,
                error: 'Session expired. Please login again.',
              ));
            }
            _refreshLock = null;
          }
        }

        if (accessToken != null) {
          options.headers['X-Authorization'] = 'Bearer $accessToken';
          options.headers['token'] = accessToken;
        }

        return handler.next(options);
      },
    ));

  /// Attempts to refresh using the stored refresh token.
  /// Returns the new access token on success, or null if the refresh token is expired.
  static Future<String?> _refreshToken(
      SecureStorageService secureStorage) async {
    try {
      final refreshToken = await secureStorage.getRefreshToken();
      final tempDio = Dio();
      final response = await tempDio.post(
        '$thingsboardURL/api/auth/token',
        options: Options(
          headers: {'X-Authorization': 'Bearer $refreshToken'},
        ),
        data: json.encode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final newAccessToken = response.data['token'] as String;
        final newRefreshToken = response.data['refreshToken'] as String;
        await secureStorage.saveAccessToken(newAccessToken);
        await secureStorage.saveRefreshToken(newRefreshToken);
        return newAccessToken;
      }
      // 401 → refresh token itself expired
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Re-logs in using the stored username and password when both tokens are expired.
  /// Returns the new access token on success, or null if credentials are missing/invalid.
  static Future<String?> _silentReLogin(
      SecureStorageService secureStorage) async {
    try {
      final username = await secureStorage.getUserName();
      final password = await secureStorage.getUserPassword();
      if (username == null ||
          username.isEmpty ||
          password == null ||
          password.isEmpty) {
        log('DioClient: silent re-login skipped — no stored credentials');
        return null;
      }

      final tempDio = Dio();
      final response = await tempDio.post(
        '$baseURL/api/login/',
        data: {'username': username, 'password': password, 'app': 'luminator'},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      if (response.statusCode == 200) {
        final res = response.data is String
            ? json.decode(response.data)
            : response.data;
        if (res is Map && res.containsKey('token')) {
          final newAccessToken = res['token'] as String;
          final newRefreshToken = res['refreshToken'] as String;
          await secureStorage.saveAccessToken(newAccessToken);
          await secureStorage.saveRefreshToken(newRefreshToken);
          log('DioClient: silent re-login — new AT and RT saved');
          return newAccessToken;
        }
      }
      return null;
    } catch (e) {
      log('DioClient: silent re-login error — $e');
      return null;
    }
  }

  // Synchronous JWT expiry decode — no I/O needed
  static int? _getJwtExpiry(String? token) {
    try {
      final parts = token?.split('.');
      if (parts == null || parts.length != 3) return null;
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final Map<String, dynamic> data = json.decode(payload);
      return (data['exp'] as int) * 1000;
    } catch (_) {
      return null;
    }
  }
}
