import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:schnell_luminator/utils/dio_client.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../env.dart';

class LocationService {
  // Future getCustomerService(WidgetRef ref, context) async {
  //   Dio dio = DioClient.dio;
  //   dio.options.contentType = Headers.formUrlEncodedContentType;
  //   // dio.options.headers["token"] = token;
  //   try {
  //     Response response = await dio.get('$baseURL/api/customers/',
  //         //data: data,
  //         options: Options(contentType: Headers.formUrlEncodedContentType));
  //     if (response.data != "" &&
  //         !jsonDecode(response.data).containsKey('status')) {
  //       String jsonsDataString = response.data.toString();
  //       final jsonData = jsonDecode(jsonsDataString);
  //       log('customer list : $jsonData');
  //       await ref.read(locationController).updateCustomer(jsonData);
  //       return 1;
  //     } else if (jsonDecode(response.data).containsKey('status')) {
  //       var res = jsonDecode(response.data);
  //       return res['status'];
  //     } else {
  //       return 0;
  //     }
  //   } catch (e) {
  //     if (e is DioError) {
  //       // final errorMessage = DioExceptions.fromDioError(e).toString();
  //       if (e.error == 'Session expired. Please login again.') {
  //         return 401;
  //       } else {
  //         return ErrorMessages.serverTimeOutError;
  //       }
  //     } else {
  //       // return e;
  //       return ErrorMessages.tryAgainError;
  //     }
  //   }
  // }

  Future<dynamic> getGeocodingLocation(latitude, longitude) async {
    Dio dio = DioClient.dio;
    try {
      log('trying to post data to location API');
      Response response = await dio.get(
        '$baseURL/api/get/location/',
        options: Options(contentType: 'application/json'),
        queryParameters: {
          'lat': latitude,
          'long': longitude,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return jsonDecode(response.data);
      } else {
        log('Unexpected response: ${response.statusCode}');
        return '';
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

  Future getAllContextService(userMail) async {
    Dio dio = DioClient.dio;
    dio.options.contentType = Headers.formUrlEncodedContentType;
    // dio.options.headers["token"] = token;
    try {
      Response response = await dio.get('$baseURL/api/project_context',
          //data: data,
          options: Options(contentType: Headers.formUrlEncodedContentType));
      if (response.data != "" &&
          !jsonDecode(response.data).containsKey('status')) {
        String jsonsDataString = response.data.toString();
        final jsonData = jsonDecode(jsonsDataString);
        // String userMail = ref.watch(loginController).userMail;
        final box = await Hive.openBox("locationContext");
        await box.put(userMail, jsonData);
        log('Saved context for user: $userMail');
        // await ref
        //     .read(locationController)
        //     .saveLocationContext(userMail, jsonData);
        return 1;
      } else if (jsonDecode(response.data).containsKey('status')) {
        var res = jsonDecode(response.data);
        return res['status'];
      } else {
        return 0;
      }
    } catch (e) {
      if (e is DioError) {
        // final errorMessage = DioExceptions.fromDioError(e).toString();
        if (e.error == 'Session expired. Please login again.') {
          return 401;
        } else {
          return ErrorMessages.serverTimeOutError;
        }
      } else {
        // return e;
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future getRegionService(
      context, WidgetRef ref, data, Function callback) async {
    Dio dio = DioClient.dio;
    dio.options.contentType = Headers.formUrlEncodedContentType;
    // dio.options.headers["token"] = token;
// 85c9de00-fb78-11ed-8e35-33a78cfa9a56
    try {
      Response response = await dio.get('$baseURL/api/regions/',
          queryParameters: {'customerId': data},
          options: Options(contentType: Headers.formUrlEncodedContentType));
      if (response.data != "" &&
          !jsonDecode(response.data).containsKey('status')) {
        String jsonsDataString = response.data.toString();
        log('region details : $jsonsDataString');
        final jsonData = jsonDecode(jsonsDataString);
        callback(jsonData);
        return 1;
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
        // return e;
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future getZoneService(context, WidgetRef ref, data, Function callback) async {
    Dio dio = DioClient.dio;
    dio.options.contentType = Headers.formUrlEncodedContentType;
    // dio.options.headers["token"] = token;

    try {
      Response response = await dio.get('$baseURL/api/zones/',
          queryParameters: {'regionId': data},
          options: Options(contentType: Headers.formUrlEncodedContentType));
      if (response.data != "" &&
          !jsonDecode(response.data).containsKey('status')) {
        String jsonsDataString = response.data.toString();
        final jsonData = jsonDecode(jsonsDataString);
        callback(jsonData);
        return 1;
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
        // return e;
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future getWardService(context, WidgetRef ref, data, Function callback) async {
    Dio dio = DioClient.dio;
    dio.options.contentType = Headers.formUrlEncodedContentType;
    // dio.options.headers["token"] = token;
    try {
      Response response = await dio.get('$baseURL/api/wards/',
          queryParameters: {'zoneId': data},
          options: Options(contentType: Headers.formUrlEncodedContentType));
      if (response.data != "" &&
          !jsonDecode(response.data).containsKey('status')) {
        log('${response.data}');
        String jsonsDataString = response.data.toString();
        final jsonData = jsonDecode(jsonsDataString);
        callback(jsonData);

        // if (jsonData['zones'].length == 1) {
        //   zoneName = jsonData["zones"][0]["name"];
        //   zoneId = jsonData["zones"][0]["id"];
        //   await ref
        //       .read(locationController)
        //       .getWardDetails(context, ref, zoneId, zoneName);
        //   return 2;
        // } else {
        return 1;
        // }
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
        // return e;
        return ErrorMessages.tryAgainError;
      }
    }
  }
}
