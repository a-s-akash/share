import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import '../env.dart';
import '../utils/dio_client.dart';
import '../utils/error_messages.dart';

class SurveyService {
  String? status;

  Future<String> updateSurveyDetailService(data) async {
    log('postdata: $data');
    Dio dio = DioClient.dio;
    var url = '';
    if (data['assetType'] == 'Pole') {
      url = '$baseURL/api/pole/install/';
    } else if (data['assetType'] == 'Switch Point') {
      url = '$baseURL/api/switch_point/install/';
    } else if (data['assetType'] == 'Transformer') {
      url = '$baseURL/api/transformer/install/';
    } else {
      url = '$baseURL/api/pole/install/';
    }
    try {
      log('trying to post data to $url');
      log('trying to post data to $data');
      Response response = await dio.post(url,
          data: data,
          options: Options(contentType: 'application/json', headers: {
            // "token": token,
          }));
      if (response.data != "") {
        var result = jsonDecode(response.data);
        log('$result');
        status = result['status'].toString();
      }
      return status ?? 'Unknown';
    } catch (e) {
      log('$e');
      return 'Something Went Wrong';
    }
  }

  Future<dynamic> getSurveyDetailService(assetName) async {
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;
    var params = {'entityName': assetName};

    try {
      Response response = await dio.get(
        '$baseURL/api/entity/detail/',
        options: Options(contentType: 'application/json'),
        queryParameters: params,
      );
      log(response.data.toString());
      if (response.data != "" &&
          !(jsonDecode(response.data).containsKey('status'))) {
        final jsonData = jsonDecode(response.data);
        return jsonData;
      } else if (jsonDecode(response.data).containsKey('status')) {
        var res = jsonDecode(response.data);
        return res['status'];
      }
    } catch (e) {
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          return 401;
        } else {
          return ErrorMessages.serverTimeOutError;
        }
      } else {
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future<dynamic> fetchAssetsDetailsForWard(wardId) async {
    Dio dio = DioClient.dio;
    try {
      Response response = await dio.get(
        '$baseURL/api/geo_location/ward/$wardId/switchPoint,transformer',
        options: Options(contentType: 'application/json'),
      );

      if ((response.data != "" &&
          !(jsonDecode(response.data).containsKey('status')))) {
        return jsonDecode(response.data);
      } else if (jsonDecode(response.data).containsKey('status')) {
        var res = jsonDecode(response.data);
        return res['status'];
      } else {
        return 0;
      }
    } catch (e) {
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          return 401;
        } else {
          return ErrorMessages.serverTimeOutError;
        }
      } else {
        return ErrorMessages.tryAgainError;
      }
    }
  }
}
