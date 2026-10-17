import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:schnell_luminator/attendence_tracking.dart/attendance_record.dart';
import 'package:schnell_luminator/env.dart';
import 'package:schnell_luminator/utils/secure_storage.dart';
import 'package:schnell_luminator/utils/utility.dart';
import 'package:uuid/uuid.dart';

import '../utils/dio_client.dart';

class AttendanceService {
  /// Queue a login event captured at offline login time.
  /// Skipped if a synced login record already exists for today (idempotency).
  static Future<void> queueLogin({
    required double latitude,
    required double longitude,
    required int timestamp,
    bool synced = false,
  }) async {
    // if (!synced && await hasSyncedLoginToday()) {
    if (synced) {
      log('AttendanceService: login already recorded today, skipping queue');
    }
    final box = await Utility.openAttendanceBox();
    final sessionData = await SecureStorageService().getOfflineSessionMeta();
    final sessionId = sessionData?['sessionId'] ?? const Uuid().v4();
    await box.add(AttendanceRecord(
      sessionId: sessionId,
      type: 'login',
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      synced: synced,
    ));
    log('AttendanceService: queued login ts=$timestamp synced=$synced');
  }

  /// Queue a logout event captured at offline/online logout time.
  static Future<void> queueLogout({
    required double latitude,
    required double longitude,
    required int timestamp,
    bool synced = false,
  }) async {
    final box = await Utility.openAttendanceBox();
    final meta = await SecureStorageService().getOfflineSessionMeta();
    final sessionId = meta?['sessionId'] ?? const Uuid().v4();
    await box.add(AttendanceRecord(
      sessionId: sessionId,
      type: 'logout',
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      synced: synced,
    ));
    log('AttendanceService: queued logout ts=$timestamp synced=$synced');
  }

  /// Returns true if a synced login record exists for today.
  /// Used to prevent double-queueing on repeated offline launches.
  // static Future<bool> hasSyncedLoginToday() async {
  //   final box = await Utility.openAttendanceBox();
  //   final todayStart = _todayStartMs();
  //   return box.values
  //       .any((r) => r.type == 'login' && r.synced && r.timestamp >= todayStart);
  // }

  /// Replays all unsynced attendance records against the existing
  /// login / logout API endpoints in chronological order.
  /// Uses the original [timestamp] so GreytHR records the correct punch time.
  static Future<void> syncPending() async {
    final isOnline = await Utility.isConnected();
    if (!isOnline) return;

    final box = await Utility.openAttendanceBox();

    final pending = box.values.where((r) => !r.synced).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (pending.isEmpty) return;

    final secureStorage = SecureStorageService();
    final token = await secureStorage.getAccessToken();
    if (token == null) return;

    final username = await secureStorage.getUserName();
    final password = await secureStorage.getUserPassword();

    for (final record in pending) {
      try {
        final endpoint = record.type == 'login'
            ? '$baseURL/api/login/'
            : '$baseURL/api/logout/';

        final data = {
          'ts': record.timestamp.toString(),
          'latitude': record.latitude,
          'longitude': record.longitude,
        };

        if (record.type == 'login') {
          data['app'] = 'luminator';
          if (username != null) data['username'] = username;
          if (password != null) data['password'] = password;
        }

        Dio dio = record.type == 'login' ? Dio() : DioClient.dio;

        final response = await dio.post(
          endpoint,
          data: data,
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          record.synced = true;
          await record.save();
          log('AttendanceService: synced ${record.type} ts=${record.timestamp}');
        }
      } catch (e) {
        log('AttendanceService: sync failed for ${record.type}: $e');
        // Leave unsynced; will retry on next performSync() call.
      }
    }
  }

  static int _todayStartMs() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  }
}
