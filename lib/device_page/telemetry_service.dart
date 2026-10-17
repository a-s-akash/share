import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:schnell_luminator/utils/dio_client.dart';
import '../env.dart';
import '../utils/secure_storage.dart';

class TelemetryService {
  Future<dynamic> pushValuesToUserTelemetry(data) async {
    final secureStorage = SecureStorageService();
    String userId = await secureStorage.getUserId() ?? '';
    log('get stored userId: $userId');

    Dio dio = DioClient.dio;
    try {
      // var decodedLocation = jsonDecode(location);
      final response = await dio.post(
        '$thingsboardURL/api/plugins/telemetry/USER/$userId/timeseries/ANY',
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            // 'X-Authorization': 'Bearer $token',
          },
        ),
        data: data,
      );
      if (response.statusCode == 200) {
        return "200";
      } else {
        return response.statusCode;
      }
    } catch (e) {
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          return 'refresht token expired';
        }
      }
    }
  }
}
