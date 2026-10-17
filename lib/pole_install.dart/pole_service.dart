import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:schnell_luminator/env.dart';
import '../utils/dio_client.dart';

class PoleService {
  Future<Map<String, dynamic>?> poleInstallationHistoryService(
      wardId, usermail, assetType) async {
    Dio dio = DioClient.dio;
    try {
      Response response = await dio.get(
        '$baseURL/api/get/user/installation/count/?user=$usermail&assetType=$assetType&wardId=$wardId',
      );
      if (response.data != "" &&
          !(jsonDecode(response.data).containsKey('status'))) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        if (data is Map<String, dynamic> && data.containsKey('User_history')) {
          log('Installation history for $assetType : $data');

          return data;
        }
      } else if (jsonDecode(response.data).containsKey('status')) {
        var res = jsonDecode(response.data);
        return res['status'];
      } else {
        return null;
      }
    } catch (e) {
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          return null;
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> assetWardCountService(
      String wardId, String assetType) async {
    Dio dio = DioClient.dio;

    try {
      final res = await dio.get(
        '$baseURL/api/get/entity/count/',
        queryParameters: {'wardId': wardId, 'assetType': assetType},
      );

      if (res.data != "" && !(jsonDecode(res.data).containsKey('status'))) {
        return jsonDecode(res.data);
      }

      if (jsonDecode(res.data).containsKey('status')) {
        return null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
