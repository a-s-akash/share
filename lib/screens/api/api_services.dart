import 'dart:convert';
import 'dart:developer';
import 'package:citizen_complaints_list_web/firebase_setup/firebase_services.dart';
import 'package:citizen_complaints_list_web/screens/api/api_controller.dart';
import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

Future<dynamic> fetchProjectContextService() async {
  Dio dio = Dio();
  dio.options.contentType = Headers.formUrlEncodedContentType;
  try {
    Response response = await dio.get(
      '$apiURL/api/project_context?context=all',
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'token': token},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      dynamic jsonData;
      if (response.data is String) {
        jsonData = jsonDecode(response.data);
      } else {
        jsonData = response.data;
      }

      if (jsonData is Map) {
        if (!jsonData.containsKey('status')) {
          final Map<String, dynamic> structured = structureData(jsonData);

          // try {
          //   final DocumentReference regionDoc = FirebaseServices
          //       .ticketsFirestore
          //       .collection('utils')
          //       .doc('regions_list');
          //   final DocumentSnapshot docSnapshot = await regionDoc.get();

            // if (docSnapshot.exists && docSnapshot.data() != null) {
            //   final data = docSnapshot.data() as Map<String, dynamic>;
            //   if (data.containsKey('regions') && data['regions'] is List) {
            //     // final List<String> regionList =
            //     //     List<String>.from(data['regions']);
            //     // structured['Public'] = {
            //     //   'customer_id': publicCustomerId,
            //     //   'regions': {
            //     //     for (var r in regionList)
            //     //       r: {
            //     //         'region_id': '',
            //     //         'zones': {},
            //     //       }
            //     //   }
            //     // };
            //   }
            // }
          // } catch (e) {
          //   log("Error fetching public regions: $e");
          // }

          return structured;
        } else {
          log("API Error Status: ${jsonData['status']}");
          // showSnackBar(context, jsonData['message']);
          sessionExpiredNotifier.value = true;
          return ErrorMessages.tryAgainError;
        }
      }
      return null;
    } else if (jsonDecode(response.data).containsKey('status')) {
      return ErrorMessages.tryAgainError;
    } else {
      return ErrorMessages.tryAgainError;
    }
  } catch (e) {
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

Future<dynamic> fetchProblemTypesAndIssuesIdentifiedService() async {
  try {
    final DocumentSnapshot probsSnapshot = await FirebaseServices
        .ticketsFirestore
        .collection('utils')
        .doc('problem_types')
        .get();
    final DocumentSnapshot issuesSnapshot = await FirebaseServices
        .ticketsFirestore
        .collection('utils')
        .doc('issues_identified')
        .get();

    if (probsSnapshot.exists &&
        probsSnapshot.data() != null &&
        issuesSnapshot.exists &&
        issuesSnapshot.data() != null) {
      final Map<String, dynamic> structured = {
        'problem_types': probsSnapshot.data(),
        'issues_identified': issuesSnapshot.data()
      };

      return structured;
    }
  } catch (e) {
    log(e.toString());
    return ErrorMessages.tryAgainError;
  }
}

Future<dynamic> loginService() async {
  Dio dio = Dio();
  try {
    log(baseURL);
    Response response = await dio.post(
      '$baseURL/api/auth/login',
      data: {
        'username': 'grievance@sl2.qa.iotpro',
        'password': 'schnell@123',
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      return response.data['token'];
    }
  } catch (e) {
    log(e.toString());
    return 0;
  }
}

Future<dynamic> closeAutoTicketsService(alarmId) async {
  Dio dio = Dio();
  try {
    Response response = await dio.post(
      '$baseURL/api/alarm/$alarmId/clear',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    log(response.toString());
  } catch (e) {
    log(e.toString());
    return 0;
  }
}
