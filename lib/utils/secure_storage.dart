import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userDetailsKey = 'user_details';
  static const _offlineSessionMetaKey = 'offline_session_meta';
  static const _userPasswordKey = 'user_password';

  /// Save Values
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<void> saveUserDetails(
      String user, String userId, String userName) async {
    await _storage.write(key: _userDetailsKey, value: user);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userNameKey, value: userName);
  }

  Future<void> saveUserPassword(String password) async {
    await _storage.write(key: _userPasswordKey, value: password);
  }

  Future<String?> getUserPassword() async {
    return _storage.read(key: _userPasswordKey);
  }

  /// Read values
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<String?> getUserDetails() async {
    return _storage.read(key: _userDetailsKey);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  Future<String?> getUserName() async {
    return _storage.read(key: _userNameKey);
  }

  // ---------------------------------------------------------------------------
  // Offline session metadata
  // Stores sessionId and 7-day expiry so the app can allow biometric re-entry
  // without network. Only written after a successful online login.
  // ---------------------------------------------------------------------------

  Future<void> saveOfflineSessionMeta({
    required String sessionId,
    required int expiryTimestamp,
  }) async {
    await _storage.write(
      key: _offlineSessionMetaKey,
      value: '$sessionId|$expiryTimestamp',
    );
  }

  /// Returns `{sessionId, expiryTimestamp}` or `null` if not set.
  Future<Map<String, dynamic>?> getOfflineSessionMeta() async {
    final raw = await _storage.read(key: _offlineSessionMetaKey);
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    return {
      'sessionId': parts[0],
      'expiryTimestamp': int.tryParse(parts[1]) ?? 0,
    };
  }

  Future<void> clearOfflineSessionMeta() async {
    await _storage.delete(key: _offlineSessionMetaKey);
  }

  /// Clear all on logout
  Future<void> clearAllSecuredDetails() async {
    await _storage.deleteAll();
  }
}
