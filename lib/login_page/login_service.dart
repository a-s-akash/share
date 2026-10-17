import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:schnell_luminator/attendence_tracking.dart/attendance_service.dart';
import 'package:schnell_luminator/utils/dio_client.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../attendence_tracking.dart/gps_details_model.dart';
import '../env.dart';
import '../utils/secure_storage.dart';
import '../utils/session.dart';
import '../utils/utility.dart';
import 'login_model.dart';

class LoginService {
  Future<dynamic> validateUser(context, UserModel user) async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
    );

    final secureStorage = SecureStorageService();

    Map<String, dynamic> data = {
      "username": user.username.trim(),
      "password": user.password,
      "app": "luminator",
      //for attendance tracking
      "ts": DateTime.now().millisecondsSinceEpoch.toString(),
      "latitude": position.latitude,
      "longitude": position.longitude
    };
    try {
      Response response = await Dio().post('$baseURL/api/login/',
          data: data,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
          ));
      var res = jsonDecode(response.data);
      log(res.toString());
      if (response.statusCode == 200 && res.containsKey('token')) {
        UserModel data = UserModel.fromJson(jsonDecode(response.data));
        await secureStorage.saveAccessToken(data.token!);
        await secureStorage.saveRefreshToken(data.refreshToken!);
        String? accessToken = await secureStorage.getAccessToken();
        String? refreshToken = await secureStorage.getRefreshToken();
        log('DioClient: access token: $accessToken');
        log('DioClient: refresh token: $refreshToken');
        await storeLoginFlagsForUserTracking(
          res['isAttendanceCaptureRequired'] ?? false,
          res['isLocationTrackingRequired'] ?? false,
          res['isPPERequired'] ?? false,
          res['locationTrackingInterval'] ?? 0,
        );

        await secureStorage.saveUserDetails(
            jsonEncode(user.toJson()), data.userId ?? '', user.username);
        await secureStorage.saveUserPassword(user.password);

        final box = await Utility.openLocationTrackingBox();
        final loginTs = DateTime.now().millisecondsSinceEpoch;
        await box.add(
          TravelLocationEntity(
            lat: position.latitude,
            long: position.longitude,
            timestamp: loginTs,
          ),
        );
        log('Box data during login: ${box.length} items → ${box.values.map((e) => e.lat).toList()}');

        // Persist offline session metadata so biometric re-entry works for 7 days
        final sessionId = const Uuid().v4();
        final expiryTs =
            DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
        await secureStorage.saveOfflineSessionMeta(
          sessionId: sessionId,
          expiryTimestamp: expiryTs,
        );

        if (res['isAttendanceCaptureRequired'] == true) {
          // Seed a synced login record so hasSyncedLoginToday() returns true
          await AttendanceService.queueLogin(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: loginTs,
            synced: true,
          );
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isUserLoggedIn', true);

        return 1;
      } else if (res.containsKey('status') && res['status'] != 200) {
        return res;
      } else {
        return 0;
      }
    } catch (e) {
      if (e is DioError) {
        return "500";
      } else {
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future<dynamic> logoutService(context) async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
    );
    var data = FormData.fromMap({
      "ts": DateTime.now().millisecondsSinceEpoch.toString(),
      "latitude": position.latitude,
      "longitude": position.longitude
    });
    log('$data');
    try {
      Dio dio = DioClient.dio;
      Response response = await dio.post('$baseURL/api/logout/',
          data: data,
          options: Options(
              // contentType: Headers.formUrlEncodedContentType,
              ));
      var res = jsonDecode(response.data);
      if (response.statusCode == 200) {
        return 1;
      } else if (res.containsKey('status') && res['status'] != 200) {
        return res;
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (e is DioError) {
        log(e.message);
        if (e.error == 'Session expired. Please login again.') {
          return 401;
        }
      }
    }
  }
}
