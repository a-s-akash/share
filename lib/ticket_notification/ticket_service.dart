import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/utils/dio_client.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../device_page/device_controller.dart';
import '../env.dart';
import '../firebase_setup/firebase_config.dart';
import '../firebase_setup/firebase_services.dart';
import '../utils/dialog_box.dart';

class TicketService {
  Future<dynamic> getDefaultTicketServiceFB(
    context,
    ref,
    String latestContext,
    String latestContextName,
    List<String> statuses,
    bool isTicketsOfSpecificDevice, {
    dynamic cursor = 0,
    List<String> entityIds =
        const [], // device or asset id for fetching tickets of specific device or asset
  }) async {
    try {
      Query query = FirebaseServices.ticketsFirestore.collection(
        ticketCollectionName,
      );

      if (latestContext.isNotEmpty && latestContextName.isNotEmpty) {
        query = query.where(latestContext, isEqualTo: latestContextName);
      }

      if (!isTicketsOfSpecificDevice) {
        if (statuses.isNotEmpty) {
          if (statuses.length > 1) {
            query = query.where('status', whereIn: statuses);
          } else {
            query = query.where('status', isEqualTo: statuses.first);
          }
        } else {
          // query = query.where('status', isNotEqualTo: 'Verified-Duplicate');
          query = query.where('status', whereNotIn: ['Verified-Duplicate']);
          query = query.orderBy('status');
          // query = query.where('status', whereIn: [
          //   'Open',
          //   'Assigned',
          //   'Closed',
          //   'Visited-Closed',
          //   'Visited-Not Closed',
          //   'Verified-Opened',
          //   'Verified-Closed',
          //   'Waiting-For-Support'
          // ]);
        }
      }

      if (isTicketsOfSpecificDevice && entityIds.isNotEmpty) {
        if (entityIds.isNotEmpty) {
          if (entityIds.length > 1) {
            query = query.where('entity_id', whereIn: entityIds);
          } else {
            query = query.where('entity_id', isEqualTo: entityIds.first);
          }
        }
      }

      int totalCount = 0;
      try {
        final countSnapshot = await query.count().get();
        totalCount = countSnapshot.count ?? 0;
        log('totalCount: $totalCount');
      } catch (e) {
        dev.log("Error fetching count in getDefaultTicketServiceFB: $e");
      }

      int pageSize = 30;
      query = query
          .orderBy('ticket_opened_on', descending: true)
          .limit(pageSize + 1);

      if (cursor is DocumentSnapshot) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.get();
      List<DocumentSnapshot> fetchedDocs = snapshot.docs;

      // 1. Filter out the unwanted statuses locally in Dart
      if (isTicketsOfSpecificDevice && statuses.isNotEmpty) {
        fetchedDocs.removeWhere((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null || !data.containsKey('status')) return false;
          return statuses.contains(data['status']);
        });
      }

      bool hasNext = false;
      DocumentSnapshot? lastDocument;

      if (fetchedDocs.length > pageSize) {
        hasNext = true;
        lastDocument = fetchedDocs[pageSize - 1];
        fetchedDocs = fetchedDocs.take(pageSize).toList();
      } else {
        hasNext = false;
        if (fetchedDocs.isNotEmpty) {
          lastDocument = fetchedDocs.last;
        }
      }

      return {
        "data": fetchedDocs,
        "totalElements": totalCount,
        "hasNext": hasNext,
        "cursor": lastDocument,
      };
    } catch (e) {
      EasyLoading.dismiss();
      dev.log(e.toString());
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  Future<List<DocumentSnapshot>> fetchMyTicketServiceFB(String usermail) async {
    try {
      Query query = FirebaseServices.ticketsFirestore.collection(
        ticketCollectionName,
      );

      if (usermail.isNotEmpty) {
        query = query.where("assignee_mail_id", isEqualTo: usermail);
      }

      // Unlike the "All Tickets" browse view, My Tickets is scoped to a
      // single user's assigned tickets — a realistically small set — so
      // it's fetched in full rather than paginated.
      query = query.orderBy('ticket_opened_on', descending: true);

      final snapshot = await query.get();
      log('fetchMyTicketServiceFB: fetched ${snapshot.docs.length} tickets for $usermail');
      return snapshot.docs;
    } catch (e) {
      EasyLoading.dismiss();
      dev.log(e.toString());
      // showSnackBar(ref, context, ErrorMessages.tryAgainError);
      // A transient Firestore error here must not crash the login/splash
      // flow that awaits this (see TicketProvider.getLocalTicketsList) —
      // fail soft with an empty list; the next login/splash refresh retries.
      return [];
    }
  }

  Future<dynamic> updateTicketServiceFB(
      context, ref, String ticketId, Map data) async {
    try {
      Dio dio = Dio();
      Response response = await dio.post(updateTicketUrl,
          data: {
            'env':
                currentEnvironment == Environment.development ? "dev" : "prod",
            'data': data,
            "alarm_id": ticketId
          },
          options: Options(
            headers: {"SecPassKey": updateTicketSecKey},
          ));
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success') {
          return 1;
        }
      }
      log(response.toString());

      return 0;
    } catch (e) {
      log(e.toString());
      // context/ref are null when called from the background ticket-update
      // sync, where there is no UI to report to.
      if (context != null && ref != null) {
        showSnackBar(ref, context, ErrorMessages.tryAgainError);
        EasyLoading.dismiss();
      }
      return 0;
    }
  }

  Future<dynamic> fetchTicketsCountService(
      ref, context, String currentContext, String contextId, dynamic status,
      {bool isTotalCountRequired = false}) async {
    Dio dio = DioClient.dio;
    try {
      Response response = await dio.post(ticketCountUrl,
          data: {
            "statuses": status,
            "context": currentContext,
            "contextId": contextId,
            "isTotalCountRequired": isTotalCountRequired
          },
          options: Options(
            contentType: Headers.jsonContentType,
          ));
      if (response.statusCode == 200 && response.data != '') {
        return response.data['data']['count'];
      } else {
        return 0;
      }
    } catch (e) {
      dev.log(e.toString());
      return 0;
    }
  }

  Future<dynamic> getTicketDevicesLocation(context, ref, String deviceId,
      String selectedDeviceType, Function callback) async {
    Dio dio = DioClient.dio;

    try {
      String type = selectedDeviceType == 'ilm' ||
              selectedDeviceType == 'gw' ||
              selectedDeviceType == 'ilm-4g' ||
              selectedDeviceType == 'semc'
          ? 'DEVICE'
          : 'ASSET';
      String fieldName = selectedDeviceType == 'ccms' ||
              selectedDeviceType == 'gw' ||
              selectedDeviceType == 'hub' ||
              selectedDeviceType == 'pole' ||
              selectedDeviceType == 'lamp' ||
              selectedDeviceType == 'smslc' ||
              selectedDeviceType == 'semc'
          ? 'location'
          : 'landmark';

      String url =
          '$thingsboardURL/api/plugins/telemetry/$type/$deviceId/values/attributes/SERVER_SCOPE?keys=$fieldName%2Cregion%2CzoneName%2CwardName';
      // http://iotpro.io/api/plugins/telemetry/DEVICE/995cb9c0-436a-11ef-b1fb-53c7aa78ce39/values/attributes/SERVER_SCOPE?keys=landmark%2Cregion%2CzoneName%2CwardName
      Response response = await dio.get(
        url,
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            // 'X-Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        ),
      );
      if (response.statusCode == 200 && response.data != '') {
        log(response.data.toString());

        String? getValueByKey(listOfFields, List<String> keys) {
          for (var item in listOfFields) {
            if (keys.contains(item['key'])) {
              return item['value'];
            }
          }
          return null;
        }

        List res = response.data;
        String regionName = getValueByKey(res, ['region']) ?? '';
        String wardData = getValueByKey(res, ['wardName']) ?? '';
        String zoneData = getValueByKey(res, ['zoneName']) ?? '';
        double lat = double.parse(getValueByKey(res, ['latitude']) ?? '0.0');
        double long = double.parse(getValueByKey(res, ['longitude']) ?? '0.0');
        String locationData =
            getValueByKey(res, ['location', 'landmark']) ?? '';
        callback(locationData, zoneData, wardData, regionName, lat, long);
        EasyLoading.dismiss();
      } else if (response.statusCode == 401) {
        EasyLoading.dismiss();
        await tokenExpired(context, ref);
      } else {
        EasyLoading.dismiss();
        showSnackBar(ref, context, ErrorMessages.tryAgainError);
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          await tokenExpired(context, ref);
        } else {
          dev.log(ErrorMessages.updateTicketServiceError);
        }
      } else {
        dev.log(ErrorMessages.updateTicketServiceTryAgainError);
        showSnackBar(ref, context, ErrorMessages.tryAgainError);
      }
    }
  }

  Future<dynamic> getdeviceId(
      context, WidgetRef ref, selectedDeviceType, deviceOrAssetName) async {
    Dio dio = DioClient.dio;

    // Map<String, dynamic> headers = {
    //   'X-Authorization': 'Bearer $token',
    // };
    String type = selectedDeviceType == 'ilm' ||
            selectedDeviceType == 'gw' ||
            selectedDeviceType == 'ilm-4g' ||
            selectedDeviceType == 'semc'
        ? 'devices'
        : 'assets';
    String key = selectedDeviceType == 'ilm' ||
            selectedDeviceType == 'gw' ||
            selectedDeviceType == 'ilm-4g' ||
            selectedDeviceType == 'semc'
        ? 'deviceName'
        : 'assetName';
    // if (selectedDeviceType == 'lamp') {
    //   var decodedData = jsonDecode(deviceOrAssetName);

    //   String lmpName = decodedData['i'];
    //   String manufacturer = decodedData['m'];
    //   String lmpYear = decodedData['y'];
    //   String dimmable = decodedData['d'];
    //   String lmpWattage = decodedData['w'];
    //   String lmpType = decodedData['l'];
    //   deviceOrAssetName =
    //       '$manufacturer-$lmpWattage-$lmpType-$dimmable-$lmpYear-$lmpName';
    // }
    try {
      Response response = await dio.get(
        '$thingsboardURL/api/tenant/$type',
        options: Options(),
        queryParameters: {key: deviceOrAssetName},
      );
      if (response.statusCode == 200 && response.data != '') {
        dev.log(response.data.toString());
        Map<String, dynamic> originator = response.data["id"];
        String updatedCustomerId = response.data['ownerId']['id'];
        ref.read(deviceController).updateSelectedCustomerid(updatedCustomerId);
        return originator;
      } else if (response.statusCode == 401) {
        EasyLoading.dismiss();
        await tokenExpired(context, ref);
      } else {
        EasyLoading.dismiss();
        showSnackBar(ref, context, ErrorMessages.tryAgainError);
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          await tokenExpired(context, ref);
        } else {
          dev.log(ErrorMessages.updateTicketServiceError);
        }
      } else {
        dev.log(ErrorMessages.updateTicketServiceTryAgainError);
        showSnackBar(ref, context, ErrorMessages.tryAgainError);
      }
    }
  }

  Future<dynamic> createTicketServiceFB(postData) async {
    try {
      // Copy rather than mutate: the caller may still queue postData offline
      // if this call fails, and the queued payload must keep its alarm_id.
      final data = Map<String, dynamic>.from(postData);
      final String alarmId = data.remove('alarm_id');
      Dio dio = Dio();
      Response response = await dio.post(createTicketUrl,
          data: {
            'env':
                currentEnvironment == Environment.development ? "dev" : "prod",
            'data': data,
            'alarm_id': alarmId
          },
          options: Options(
            headers: {"SecPassKey": createTicketSecKey},
          ));
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success') {
          return {
            'ticketId': responseData['data']['ticket_id'],
            'status': 'success'
          };
        }
      }
      return {'ticketId': null, 'status': 'failed'};
    } catch (error) {
      return {'ticketId': null, 'status': 'failed'};
    }
  }

  Future<dynamic> getMeterSerialNoService(
    String deviceOrAssetName,
  ) async {
    Dio dio = Dio();
    dio.options.contentType = Headers.formUrlEncodedContentType;
    try {
      Response response = await dio.get(
        '$baseURL/api/entity/detail/',
        options: Options(contentType: 'application/json'),
        queryParameters: {'entityName': deviceOrAssetName},
      );
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
      if (e is DioError) {
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

  Future<dynamic> getDeviceDetailsService(
    String deviceOrAssetName,
    String deviceType,
  ) async {
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;

    try {
      Response response = await dio.get(
        '$baseURL/api/entity/detail/',
        options: Options(contentType: 'application/json'),
        queryParameters: {'entityName': deviceOrAssetName},
      );
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

          String matchedType = deviceType == 'lamp' ? 'lightPoint' : deviceType;
          String panelDevice = '';
          String meterDevice = '';
          String spDevice = '';

          switch (matchedType) {
            case 'gw':
            case 'ccms':
              matchedType = 'ccms';
              panelDevice = 'ccms';
              meterDevice = 'gw';
              break;
            case 'semc':
            case 'smslc':
              matchedType = 'smslc';
              panelDevice = 'smslc';
              meterDevice = 'semc';
              break;
            case 'ilm':
            case 'ilm-4g':
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
          final spDeviceDetails =
              !['ccms', 'smslc', 'pole'].contains(matchedType)
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
              'panelId': panelId,
              'meterSerialNo': meterSerialNo,
              'spNo': spNo,
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
      if (e is DioError) {
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

  Future<dynamic> getLpDetailsForLampService(ref, context, scannedData) async {
    Dio dio = DioClient.dio;
    // dio.options.headers["token"] = token;

    try {
      Response response = await dio.get(
        '$baseURL/api/entity/detail/',
        options: Options(contentType: 'application/json'),
        queryParameters: {'entityName': scannedData},
      );

      if (response.data != "" &&
          !(jsonDecode(response.data).containsKey('status'))) {
        final jsonData = jsonDecode(response.data);
        log(jsonData.toString());

        return {
          "lmpRegion":
              jsonData['deviceDetails'][0]['lightPoint']['region'] ?? '',
          "lmpWard":
              jsonData['deviceDetails'][0]['lightPoint']['wardName'] ?? '',
          "lmpZone":
              jsonData['deviceDetails'][0]['lightPoint']['zoneName'] ?? '',
          "lmpLocation":
              jsonData['deviceDetails'][0]['lightPoint']['landmark'] ?? '',
          "lmLatitude": double.parse(
              jsonData['deviceDetails'][0]['lightPoint']['latitude'] ?? '0.0'),
          "lmLongitude": double.parse(
              jsonData['deviceDetails'][0]['lightPoint']['longitude'] ?? '0.0'),
        };
      } else if (jsonDecode(response.data).containsKey('status')) {
        var res = jsonDecode(response.data);
        return res['status'];
      } else {
        return 0;
      }
    } catch (e) {
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          await tokenExpired(context, ref);
        } else {
          dev.log(ErrorMessages.updateTicketServiceError);
        }
      } else {
        return ErrorMessages.tryAgainError;
      }
    }
  }

  Future<dynamic> getMcbAlarmForPanelCtrl(
    context,
    ref,
    String assetId,
  ) async {
    Dio dio = DioClient.dio;

    try {
      Response response = await dio.get(
        '$thingsboardURL/api/alarm/ASSET/$assetId?status=ACTIVE_UNACK&pageSize=1000&page=0',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            // "Authorization": "Bearer $token",
          },
        ),
      );

      if ((response.statusCode == 200 && response.data != '')) {
        dev.log(response.data.toString());
        List<dynamic> data = response.data['data'];

        // Iterate through the list to check for "MCB Trip"
        for (var item in data) {
          if (item['name'] == 'MCB Trip' || item['type'] == 'MCB Trip') {
            return true; // Found "MCB Trip"
          }
        }
      }

      return false; // "MCB Trip" not found
    } catch (e) {
      EasyLoading.dismiss();
      if (e is DioError) {
        if (e.error == 'Session expired. Please login again.') {
          await tokenExpired(context, ref);
        } else {
          dev.log(ErrorMessages.updateTicketServiceError);
        }
      } else {
        dev.log(ErrorMessages.updateTicketServiceTryAgainError);
        showSnackBar(ref, context, ErrorMessages.tryAgainError);
      }
    }
  }
}

List<Map<String, dynamic>> removeDuplicates(List<dynamic> data) {
  Set<String> alarmIds = {};
  List<Map<String, dynamic>> uniqueData = [];

  for (var alarm in data) {
    String alarmId = alarm['id']['id'];
    if (!alarmIds.contains(alarmId)) {
      alarmIds.add(alarmId);
      uniqueData.add(alarm);
    }
  }
  return uniqueData;
}
