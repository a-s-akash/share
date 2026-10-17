import 'dart:convert';
import 'dart:developer';

import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

List<Map<String, String>> parseSearchResults(dynamic responseData) {
  if (responseData != null) {
    var decoded = responseData;
    if (decoded['data'] != null && decoded['data'] is List) {
      List<dynamic> data = decoded['data'];
      return data
          .map<Map<String, String>>((item) {
            String id = item['entityId']?['id']?.toString() ?? '';
            String value = '';
            try {
              value = item['latest']?['ENTITY_FIELD']?['name']?['value']
                      ?.toString() ??
                  '';
            } catch (e) {
              value = '';
            }
            return {'id': id, 'value': value};
          })
          .where((e) => e['value']!.isNotEmpty)
          .toList();
    }
  }
  return [];
}

Future<List<Map<String, String>>> searchAssetsService(
  selectedContextId,
  selectedEntityType,
  type,
  searchResult,
) async {
  Dio dio = Dio();

  try {
    Response response = await dio.post(
      '$baseURL/api/entitiesQuery/find',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {
        "entityFields": [
          {"type": "ENTITY_FIELD", "key": "name"},
          {"type": "ENTITY_FIELD", "key": "type"},
          {"type": "ENTITY_FIELD", "key": "label"},
        ],
        "latestValues": [],
        "entityFilter": {
          "type": "${type}SearchQuery",
          "rootEntity": {"entityType": "ASSET", "id": selectedContextId},
          "direction": "FROM",
          "fetchLastLevelOnly": false,
          "${type}Types": selectedEntityType,
        },
        "pageLink": {
          "dynamic": true,
          "page": 0,
          "pageSize": 10000,
          "sortOrder": {
            "key": {"key": "name", "type": "ENTITY_FIELD"},
            "direction": "ASC",
          },
          "textSearch": '$searchResult',
        },
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      return await compute(parseSearchResults, response.data);
    }
    return [];
  } catch (e) {
    log("Error in search asset results: $e");
    if (e is DioException && e.response?.statusCode == 401) {
      sessionExpiredNotifier.value = true;
    }
    return [];
  }
}

// Future<dynamic> sendConfirmationWhatsAppMsg({
//   dynamic data,
//   String? ticketId,
// }) async {
//   Dio dio = Dio();

//   try {
//     Response response = await dio.post('$apiURL/api/message/whatsapp/',
//         options: Options(
//             // headers: {'token': token},
//             ),
//         data: {
//           "contact_number": ["${data['contact_number']}"],
//           "message": {
//             "template_name": "smartlights_alert_notifications",
//             "header": {
//               "type": "location",
//               "location": {
//                 "latitude": data['latitude'],
//                 "longitude": data['longitude'],
//                 "name": data['location'],
//                 "address": data['location']
//               }
//             },
//             "body": {
//               "variables": {
//                 "1": ticketId,
//                 "2": data['status'],
//                 "3": data['time'],
//                 "4": data['problem_type'],
//                 "5": data['device'],
//                 "6": data['ward'],
//                 "7": data['customer']
//               }
//             }
//           }
//         });
//     log(response.data.toString());
//     return 200;
//   } catch (e) {
//     log(e.toString());
//     return 0;
//   }
// }

Future<dynamic> getDeviceDetailsService(
  String deviceOrAssetName,
  List<String> deviceTypes,
) async {
  Dio dio = Dio();
  dio.options.contentType = Headers.formUrlEncodedContentType;
  try {
    Response response = await dio.get('$apiURL/api/entity/detail/',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'token': token},
        ),
        queryParameters: {'entityName': deviceOrAssetName});
    if (response.statusCode == 200 && response.data != null) {
      var details =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (details != null &&
          details is Map &&
          details.containsKey('deviceDetails')) {
        final deviceDetails = details['deviceDetails'];

        dynamic getValue(dynamic data, String key) {
          if (data is Map) return data[key];

          if (data is List) {
            for (final e in data) {
              if (e is Map && e.containsKey(key)) {
                return e[key];
              }
            }
          }
          return null;
        }

        String pickType(List<String> types, dynamic data) {
          if (types.contains('ilm')) return 'ilm';
          if (types.contains('lamp')) return 'lightPoint';

          return types.firstWhere(
            (t) => getValue(data, t) != null,
            orElse: () => '',
          );
        }

        String matchedType = pickType(deviceTypes, deviceDetails);
        String panelDevice = '';
        String meterDevice = '';
        String spDevice = '';

        switch (matchedType) {
          case 'gw':
          case 'ccms':
            // case 'hub':
            matchedType = 'ccms';
            panelDevice = 'ccms';
            // matchedType = getValue(deviceDetails, 'ccms') != null ? 'ccms' : 'hub';
            // panelDevice = matchedType;
            meterDevice = 'gw';
            break;
          case 'semc':
          case 'smslc':
            matchedType = 'smslc';
            panelDevice = 'smslc';
            meterDevice = 'semc';
            break;
          case 'ilm':
          case 'lightPoint':
            panelDevice = 'lightPoint';
            spDevice = 'pole';
            break;
        }

        final specificDetails =
            matchedType.isEmpty ? null : getValue(deviceDetails, matchedType);
        final panelDeviceDetails =
            !['ccms', 'smslc', 'pole'].contains(matchedType)
                ? panelDevice.isEmpty
                    ? null
                    : getValue(deviceDetails, panelDevice)
                : null;
        final meterDeviceDetails =
            meterDevice.isEmpty ? null : getValue(deviceDetails, meterDevice);
        final spDeviceDetails = !['ccms', 'smslc', 'pole'].contains(matchedType)
            ? spDevice.isEmpty
                ? null
                : getValue(deviceDetails, spDevice)
            : null;

        if (specificDetails != null) {
          double latitude = double.tryParse(specificDetails[
                          ['ccms', 'smslc'].contains(matchedType)
                              ? 'slatitude'
                              : 'latitude']
                      ?.toString() ??
                  '0.0') ??
              0.0;
          double longitude = double.tryParse(specificDetails[
                          ['ccms', 'smslc'].contains(matchedType)
                              ? 'slongitude'
                              : 'longitude']
                      ?.toString() ??
                  '0.0') ??
              0.0;
          String location = specificDetails[
                      ['ilm', 'ilm-4g', 'lightPoint'].contains(matchedType)
                          ? 'landmark'
                          : 'location']
                  ?.toString() ??
              '';

          String panelId = '';
          String meterSerialNo = '';
          String spNo = '';

          panelId = ['ccms', 'smslc'].contains(matchedType)
              ? specificDetails['name']?.toString() ?? ''
              : matchedType == 'pole'
                  ? (specificDetails['relations'] as List).isNotEmpty
                      ? specificDetails['relations'][0]['poweredBy']
                              ?.toString() ??
                          ''
                      : ''
                  : panelDeviceDetails['poweredBy']?.toString() ?? '';
          meterSerialNo = ['ccms', 'smslc'].contains(matchedType)
              ? meterDeviceDetails['name']?.toString() ?? ''
              : panelId != ''
                  ? await getMeterSerialNoService(panelId)
                  : '';
          spNo = ['ccms', 'smslc', 'pole'].contains(matchedType)
              ? specificDetails['switchPointNo']?.toString() ?? ''
              : spDeviceDetails['switchPointNo']?.toString() ?? '';

          return {
            'panel_id': panelId,
            'meter_serial_no': meterSerialNo,
            'sp_no': spNo,
            'latitude': latitude,
            'longitude': longitude,
            'location': location,
            'region': specificDetails['region']?.toString() ?? '',
            'zone': specificDetails['zoneName']?.toString() ?? '',
            'ward': specificDetails['wardName']?.toString() ?? ''
          };
        }
      }
      return null;
    } else if (jsonDecode(response.data).containsKey('status')) {
      return ErrorMessages.tryAgainError;
    } else {
      return ErrorMessages.tryAgainError;
    }
  } catch (e) {
    log(e.toString());
    if (e is DioException) {
      if (e.error == 'Session expired. Please login again.') {
        return ErrorMessages.sessionExpiredError;
      } else {
        return ErrorMessages.serverTimeOutError;
      }
    } else {
      return ErrorMessages.tryAgainError;
    }
  }
}

Future<dynamic> getMeterSerialNoService(
  String deviceOrAssetName,
) async {
  Dio dio = Dio();
  dio.options.contentType = Headers.formUrlEncodedContentType;
  try {
    Response response = await dio.get('$apiURL/api/entity/detail/',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'token': token},
        ),
        queryParameters: {'entityName': deviceOrAssetName});
    if (response.statusCode == 200 && response.data != null) {
      var details =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (details != null &&
          details is Map &&
          details.containsKey('deviceDetails')) {
        final deviceDetails = details['deviceDetails'];

        dynamic getValue(dynamic data, String key) {
          if (data is Map) return data[key];

          if (data is List) {
            for (final e in data) {
              if (e is Map && e.containsKey(key)) {
                return e[key];
              }
            }
          }
          return null;
        }

        String meterDevice =
            getValue(deviceDetails, 'gw') != null ? 'gw' : 'semc';

        final meterDetails =
            meterDevice.isEmpty ? null : getValue(deviceDetails, meterDevice);
        return meterDetails != null ? meterDetails['name'] : null;
      }
      return null;
    } else if (response.data != null &&
        (response.data is String ? jsonDecode(response.data) : response.data)
            .containsKey('status')) {
      return ErrorMessages.tryAgainError;
    } else {
      return ErrorMessages.tryAgainError;
    }
  } catch (e) {
    log(e.toString());
    if (e is DioException) {
      if (e.error == 'Session expired. Please login again.') {
        return ErrorMessages.sessionExpiredError;
      } else {
        return ErrorMessages.serverTimeOutError;
      }
    } else {
      return ErrorMessages.tryAgainError;
    }
  }
}

Future<List<Map<String, String>>> fetchAssigneesByRegionService(
    String selectedRegionId) async {
  Dio dio = Dio();
  try {
    log(baseURL);
    Response usersResponse = await dio.get(
      '$apiURL/api/get/assignees/list?region_id=$selectedRegionId',
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'token': token},
      ),
    );
    log(usersResponse.toString());

    List<Map<String, String>> assignees = [];
    if (usersResponse.statusCode == 200 && usersResponse.data != null) {
      // final decodedUsers = (usersResponse.data as List)
      //     .map((e) => Map<String, String>.from(e))
      //     .toList();
      final decodedUsers = (usersResponse.data as List).map((e) {
        final user = Map<String, String>.from(e);

        if ((user['name'] ?? '').trim().isEmpty) {
          user['name'] = user['email'] ?? '';
        }

        return user;
      }).toList();

      assignees = decodedUsers;
    }
    return assignees;
  } catch (e) {
    log("Error fetching assignees: $e");
    if (e is DioException && e.response?.statusCode == 401) {
      sessionExpiredNotifier.value = true;
    }
    return [];
  }
}
