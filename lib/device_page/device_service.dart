import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/home_page/map_controller.dart';
import 'package:schnell_luminator/ticket_notification/ticket_controller.dart';
import 'package:schnell_luminator/utils/dio_client.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../env.dart';

class DeviceService {
  //get a single device detals and attributed based on name
  Future<dynamic> getDeviceDataService(WidgetRef ref, BuildContext context,
      deviceOrAssetName, type, clickEventIsFor) async {
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;
    String url = clickEventIsFor == 'ebMeterReplace'
        ? '$baseURL/api/ebmeter/isinstallable/'
        : '$baseURL/api/entity/detail/';
    var params = clickEventIsFor == 'ebMeterReplace'
        ? {'ebMeterNo': deviceOrAssetName}
        : {'entityName': deviceOrAssetName};

    try {
      Response response = await dio.get(
        url,
        options: Options(contentType: 'application/json'),
        queryParameters: params,
      );
      log(response.data.toString());
      if (response.data != "" &&
          !(jsonDecode(response.data).containsKey('status'))) {
        final jsonData = jsonDecode(response.data);
        log(jsonData.toString());
        if (clickEventIsFor == 'ebMeterReplace') {
          return jsonData;
        }
        if (jsonData['deviceDetails'][0].containsKey("pole"))
        // considered as entire luminar(lp, lmp, ilm, pole)
        {
          if (jsonData['deviceDetails'][0]['pole'].isEmpty) {
            type == 1
                ? ref
                    .read(deviceController)
                    .addFirstDevice(jsonData, clickEventIsFor)
                : ref
                    .read(deviceController)
                    .addSecondDevice(jsonData, clickEventIsFor);
          } else {
            if (jsonData['deviceDetails'][0]['pole']['armCount'] != '0') {
              // if (jsonData['deviceDetails'][0]['pole']['lampProfiles']
              //     .isNotEmpty) {
              //   if (context.mounted) {
              //     final recommendedWattage = await getPoleWattageService(
              //         ref,
              //         context,
              //         jsonData['customer']['id'],
              //         jsonData['deviceDetails'][0]['pole']['lampProfiles']);
              //     ref.read(deviceController).addWattage(recommendedWattage);
              //   }
              // } else {
              //   ref.read(deviceController).addWattage([]);
              // }
              type == 1
                  ? ref
                      .read(deviceController)
                      .addFirstDevice(jsonData, clickEventIsFor)
                  : ref
                      .read(deviceController)
                      .addSecondDevice(jsonData, clickEventIsFor);
            } else {
              type == 1
                  ? ref
                      .read(deviceController)
                      .addFirstDevice(jsonData, clickEventIsFor)
                  : ref
                      .read(deviceController)
                      .addSecondDevice(jsonData, clickEventIsFor);
            }
          }
        } else {
          type == 1
              ? ref
                  .read(deviceController)
                  .addFirstDevice(jsonData, clickEventIsFor)
              : ref
                  .read(deviceController)
                  .addSecondDevice(jsonData, clickEventIsFor);
        }
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
        return ErrorMessages.tryAgainError;
      }
    }
  }

  // Future<dynamic> getPoleWattageService(
  //     WidgetRef ref, context, customerId, lampProfiles) async {
  //   Dio dio = DioClient.dio;
  //   // dio.options.headers["token"] = token;

  //   try {
  //     Response response = await dio.get(
  //       '$baseURL/api/get/project/wattage/',
  //       options: Options(contentType: 'application/json'),
  //       queryParameters: {
  //         'customerId': customerId,
  //         'lampProfiles': lampProfiles,
  //       },
  //     );
  //     if (response.data != "") {
  //       String jsonsDataString = response.data.toString();
  //       final jsonData = jsonDecode(jsonsDataString);
  //       return jsonData;
  //     } else if (jsonDecode(response.data).containsKey('status')) {
  //       var res = jsonDecode(response.data);
  //       return res['status'];
  //     } else {
  //       return 0;
  //     }
  //   } catch (e) {
  //     if (e is DioError) {
  //       if (e.error == 'Session expired. Please login again.') {
  //         return 401;
  //       } else {
  //         return ErrorMessages.serverTimeOutError;
  //       }
  //     } else {
  //       return ErrorMessages.tryAgainError;
  //     }
  //   }
  // }

  Future<dynamic> panelControlService(deviceId, controlType) async {
    final dio = DioClient.dio;
    var headers = {
      // 'X-Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    String data = '';
    if (controlType == 'on') {
      data = json.encode({
        "method": "ctrl",
        "params": {"lamp": 1}
      });
    } else if (controlType == 'off') {
      data = json.encode({
        "method": "ctrl",
        "params": {"lamp": 0}
      });
    } else if (controlType == 'mcbReset') {
      data = json.encode({
        "method": "ctrl",
        "params": {"mcb": 1}
      });
    } else if (controlType == 'mcbClear') {
      data = json.encode({"method": "clr", "params": 8});
    } else if (controlType == 'getLive') {
      data = json.encode({
        "method": "get",
        "params": {"value": 0}
      });
    }

    try {
      var response = await dio.request(
        '$thingsboardURL/api/plugins/rpc/oneway/$deviceId',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        log(json.encode(response.data));
        return 1;
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

  Future<dynamic> fetchTelemetryData(
      assetOrDevice, assetOrDeviceId, keys) async {
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;
    final url =
        '$thingsboardURL/api/plugins/telemetry/$assetOrDevice/$assetOrDeviceId/values/timeseries?keys=$keys';

    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'accept': 'application/json',
            // 'X-Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data != "") {
        log('${response.data}');
        return response.data;
      }
    } catch (e) {
      log('Error fetching telemetry data: $e');
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          return 401;
        }
      }
    }
  }

  Future<dynamic> deviceListSearchService(
      WidgetRef ref, context, val, page, prefixText,
      {bool requiredPagination = false}) async {
    log('pageCount - $page');
    Dio dio = DioClient.dio;
    Map<String, dynamic> requiredParameters = {'text_search': val};
    if (requiredPagination) {
      requiredParameters['page'] = page;
    }
    if (prefixText.isNotEmpty) {
      requiredParameters['starts_with'] = prefixText;
    }
    log('requiredParameters - $requiredParameters');
    // dio.options.headers["token"] = token;

    try {
      Response response = await dio.get(
        '$baseURL/api/entities/search/',
        options: Options(contentType: 'application/json'),
        queryParameters: requiredParameters,
      );
      if (response.data != "") {
        // String searchList = response.data['data'];
        final searchList = jsonDecode(response.data);
        log('response from the api : $searchList');
        if (requiredPagination) {
          if (searchList['data'].isNotEmpty) {
            ref
                .read(deviceController)
                .updateDeviceSearchListForPagination(searchList, page);
          } else {
            return 404;
          }
        } else {
          if (searchList.isNotEmpty) {
            ref.read(deviceController).updateDeviceSearchList(searchList);
          } else {
            return 404;
          }
        }
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
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future<dynamic> ilmInstallService(ref, context, data) async {
    log("check check check");
    log(data.toString());
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;

    try {
      Response response = await dio.post('$baseURL/api/luminaire/maintain/',
          options: Options(contentType: 'application/json'), data: data);
      var res = jsonDecode(response.data);
      if (res['status'] == 200 && response.data != "") {
        return 1;
      } else if (res.containsKey('status') && res['status'] != 200) {
        return res;
      } else {
        return 0;
      }
    } catch (e) {
      if (e is DioError) {
        log(e.toString());
        if (e.error == 'Session expired. Please login again.') {
          log(e.toString());
          return 401;
        } else {
          return ErrorMessages.serverTimeOutError;
        }
      } else {
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future<dynamic> lampInstallService(ref, context, data) async {
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;
    var encodedJson = jsonEncode(data);
    log(encodedJson);
    try {
      Response response = await dio.post('$baseURL/api/luminaire/maintain/',
          options: Options(contentType: 'application/json'), data: data);
      var res = jsonDecode(response.data);
      log(res.toString());
      return {
        'uploaded': res['status'] == 200,
        'statusCode': res['status'],
        'message': res['message'] ?? '',
      };
      // if (res['status'] == 200 && response.data != "") {
      //   return 1;
      // } else if (res.containsKey('status') && res['status'] != 200) {
      //   return res;
      // } else {
      //   return 0;
      // }
    } catch (e) {
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          // return 401;
          return {
            'uploaded': false,
            'statusCode': 401,
            'message': 'Session expired',
          };
        } else {
          // return ErrorMessages.serverTimeOutError;
          return {
            'uploaded': false,
            'statusCode': 500,
            'message': 'Server Timeout error',
          };
        }
      } else {
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future<dynamic> ilmReplaceService(ref, context, data) async {
    log(data.toString());

    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;
    dio.options.headers["Content-Type"] = "application/json";
    try {
      Response response = await dio.post('$baseURL/api/luminaire/maintain/',
          options: Options(contentType: 'application/json'), data: data);
      var res = jsonDecode(response.data);
      if (res['status'] == 200 && response.data != "") {
        return 1;
      } else if (res.containsKey('status') && res['status'] != 200) {
        return res;
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

  Future<dynamic> lampReplaceService(ref, context, data) async {
    log(data.toString());
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;
    dio.options.headers["Content-Type"] = "application/json";
    try {
      Response response = await dio.post('$baseURL/api/luminaire/maintain/',
          options: Options(contentType: 'application/json'), data: data);
      var res = jsonDecode(response.data);
      if (res['status'] == 200 && response.data != "") {
        return 1;
      } else if (res.containsKey('status') && res['status'] != 200) {
        return res;
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

  Future<dynamic> gwInstallService(ref, context, data, deviceType) async {
    Dio dio = DioClient.dio;
    log(data.toString());
    var url = deviceType == "SEMC"
        ? '$baseURL/api/slc/install/'
        : '$baseURL/api/gw/install/';
    // dio.options.headers["token"] = token;
    try {
      Response response = await dio.post(url,
          options: Options(contentType: 'application/json'), data: data);
      var res = jsonDecode(response.data);
      if (res['status'] == 200 && response.data != "") {
        return 1;
      } else if (res.containsKey('status') && res['status'] != 200) {
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

  Future<dynamic> gwReplaceService(ref, context, clickeventIsFor, data) async {
    log(data.toString());
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;
    // String url = clickeventIsFor == 'ebMeterReplace'
    //     ? '$baseURL/api/ebmeter/replace/'
    //     : '$baseURL/api/gw/replace/';
    String url;
    switch (clickeventIsFor) {
      case 'ebMeterReplace':
        url = '$baseURL/api/ebmeter/replace/';
        break;
      case 'semcReplace':
        url = '$baseURL/api/slc/replace/';
        break;
      default:
        url = '$baseURL/api/gw/replace/';
    }
    try {
      Response response = await dio.post(url,
          options: Options(contentType: 'application/json'), data: data);
      var res = jsonDecode(response.data);
      if (res['status'] == 200 && response.data != "") {
        return 1;
      } else if (res.containsKey('status') && res['status'] != 200) {
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

  // Future<dynamic> s3imageUploadService(ref, context, data) async {
  //   Dio dio = DioClient.dio;
  //   // dio.options.headers["token"] = token;
  //   try {
  //     Response response = await dio.post('$baseURL/api/image/upload/',
  //         options: Options(contentType: 'application/json'), data: data);
  //     log(response.data.toString());
  //     var res = jsonDecode(response.data);
  //     if (res['status'] == 200 && response.data != "") {
  //       return 1;
  //     } else if (res.containsKey('status') && res['status'] != 200) {
  //       var res = jsonDecode(response.data);
  //       return res['status'];
  //     } else {
  //       return 0;
  //     }
  //   } catch (e) {
  //     log(e.toString());
  //   }
  // }

  Future<dynamic> getMapDataService(WidgetRef ref, context, entityID) async {
    String selectedContextType =
        ref.watch(ticketController).selectedContextType;
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;

    try {
      Response response = await dio.get(
        '$baseURL/api/geo_location/$selectedContextType/$entityID/pole,lightPoint,switchPoint,slc,hub',
        options: Options(contentType: 'application/json'),
      );
      log('url: $baseURL/api/geo_location/$selectedContextType/$entityID/pole,lightPoint,switchPoint,slc,hub');

      if ((response.data != "" &&
          !(jsonDecode(response.data).containsKey('status')))) {
        await ref
            .read(mapController)
            .updateMapLatLong(ref, context, response.data);
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
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future<dynamic> getGeoFenceService(
      WidgetRef ref, context, userMail, entityType, entityID) async {
    Dio dio = DioClient.dio;

    try {
      Response response = await dio.get(
        '$baseURL/api/geo_fence/$entityType/$entityID',
        options: Options(contentType: 'application/json'),
      );
      // log(response.data.toString());
      if (response.data != "" && !(response.data.containsKey('status'))) {
        final fenceBox = await Hive.openBox('geoFenceBox');
        // await fenceBox.clear();

        final data = fenceBox.get(userMail) ?? {};
        final incoming = response.data;

        if (data.isEmpty) {
          data.addAll(incoming);
        } else {
          incoming.forEach((key, value) {
            data[key] = value;
          });
        }
        fenceBox.put(userMail, data);
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
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future<dynamic> lampCountService(
      WidgetRef ref, context, val, Function callback) async {
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;

    try {
      Response response = await dio.get(
        '$baseURL/api/get/entity/count/',
        options: Options(contentType: 'application/json'),
        queryParameters: {'wardId': val, 'assetType': 'lamp'},
      );
      if (response.data != "") {
        log('$baseURL/api/get/entity/count/,${response.data.runtimeType.toString()}');

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
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future<dynamic> lampInstallationHistory(
      WidgetRef ref, context, userName, wardId, Function callback) async {
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;

    try {
      Response response = await dio.get(
        '$baseURL/api/get/user/installation/count/',
        options: Options(contentType: 'application/json'),
        queryParameters: {
          'user': userName,
          'assetType': 'lamp',
          'wardId': wardId
        },
      );

      if (response.data != "" &&
          !(jsonDecode(response.data).containsKey('status'))) {
        String jsonsDataString = response.data.toString();
        final jsonData = jsonDecode(jsonsDataString);
        log('pole Installation history : $jsonData');
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
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future<dynamic> getCustomerCount(
      WidgetRef ref, BuildContext context, customerId) async {
    // var headers = {'Authorization': 'Bearer $token'};
    var dio = DioClient.dio;
    final types = ['ilm', 'ilm-4g', 'lamp', 'ccms', 'hub', 'pole'];

    try {
      List<Future<MapEntry<String, dynamic>>> futures = types.map((type) async {
        final deviceOrAsset =
            (type == 'ilm' || type == 'ilm-4g') ? 'devices' : 'assets';
        var response = await dio.request(
          '$thingsboardURL/api/customer/$customerId/$deviceOrAsset?pageSize=1000&page=0&type=$type',
          options: Options(
            method: 'GET',
            // headers: headers,
          ),
        );

        if (response.statusCode == 200) {
          return MapEntry(type, response.data['totalElements']);
        } else {
          return MapEntry(type, 0);
        }
      }).toList();

      var results = await Future.wait(futures);
      return Map<String, dynamic>.fromEntries(results);
    } catch (e) {
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          return 401;
        }
      }
    }
  }
}
