// import 'dart:convert';
// import 'dart:developer';

// import 'package:citizen_complaints_list_web/utils/constants.dart';
// import 'package:flutter/material.dart';
// import 'package:dio/dio.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'error_messages.dart';

// Future<dynamic> getCreatedTicketName(context, createdTicketCustomerId,
//     createdAlarmId, createdTicketComments) async {
//   final prefs = await SharedPreferences.getInstance();
//   String? token = prefs.getString('token');
//   Dio dio = Dio();
//   Map<String, dynamic> headers = {
//     'Content-Type': 'application/json',
//     'X-Authorization': 'Bearer $token',
//   };
//   try {
//     Response response = await dio.get(
//       '$ticketURL/api/tickets/serializer/?alarm_id=$createdAlarmId&customer_id=$createdTicketCustomerId',
//       options: Options(headers: headers),
//     );
//     if (response.statusCode == 200 && response.data != '') {
//       log("----------------");
//       log(response.data.toString());
//       var details = jsonDecode(response.data);
//       var ticketName = details["details"]["ticket_name"];
//       Response commentResponse = await dio.post(
//         '$ticketURL/api/alarm/$createdAlarmId/comment',
//         data: {
//           "alarmId": {"id": createdAlarmId, "entityType": "ALARM"},
//           "comment": {"text": createdTicketComments}
//         },
//         options: Options(headers: headers),
//       );
//       if (response.statusCode == 200 && response.data != '') {
//         var resultData = {
//           "status": commentResponse.statusCode,
//           "ticketName": ticketName,
//         };
//         return resultData;
//       }
//     } else if (response.statusCode == 401) {
//       showSnackBar(context, 'tokenExpired');
//     } else {
//       showSnackBar(context, ErrorMessages.tryAgainError);
//     }
//   } catch (e) {
//     if (e is DioException) {
//       if (e.message == "Http status error [401]") {
//         showSnackBar(context, 'tokenExpired');
//       } else {
//         log('internal server error on updateTicketService');
//       }
//     } else {
//       log('Something went wrong. Please try Again! - updateTicketService');
//       showSnackBar(context, ErrorMessages.tryAgainError);
//     }
//   }
// }

// Future<dynamic> createTicketService(context, postData) async {
//   log(postData.toString());
//   final prefs = await SharedPreferences.getInstance();
//   String? token = prefs.getString('token');
//   Dio dio = Dio();
//   Map<String, dynamic> headers = {
//     'Content-Type': 'application/json',
//     'X-Authorization': 'Bearer $token',
//   };
//   try {
//     Response response = await dio.post(
//       '$ticketURL/api/alarm',
//       data: postData,
//       options: Options(headers: headers),
//     );
//     if (response.statusCode == 200 && response.data != '') {
//       log(response.data.toString());
//       log("++++++++++++++++++++++++++");

//       // var res = await getCreatedTicketName(
//       //     context,
//       //     response.data["tenantId"]["id"],
//       //     response.data["id"]["id"],
//       //     postData['details']['t_comment']);
//       // log(res.toString());
//       // return res;
//     } else if (response.statusCode == 401) {
//       showSnackBar(context, 'tokenExpired');
//     } else {
//       showSnackBar(context, ErrorMessages.tryAgainError);
//     }
//   } catch (e) {
//     if (e is DioException) {
//       if (e.message == "Http status error [401]") {
//         showSnackBar(context, 'tokenExpired');
//       } else {
//         log('internal server error on updateTicketService');
//       }
//     } else {
//       log('Something went wrong. Please try Again! - updateTicketService');
//       showSnackBar(context, ErrorMessages.tryAgainError);
//     }
//   }
// }

// Future<dynamic> createTicketDetails(
//     BuildContext context,
//     String regionID,
//     String problemStatement,
//     String location,
//     String latitude,
//     String longitude,
//     String comments,
//     String ticketID,
//     String? createdBy) async {
//   // final Map<String, dynamic> postData = {
//   //   "tenantId": {
//   //     "entityType": "TENANT",
//   //     "id": "911947b0-752b-11ed-a1d5-c72869dcd693"
//   //   },
//   //   "customerId": {
//   //     "entityType": "CUSTOMER",
//   //     "id": "85c9de00-fb78-11ed-8e35-33a78cfa9a56"
//   //   },
//   //   "type": "Pole damaged",
//   //   "originator": {
//   //     "entityType": "ASSET",
//   //     "id": "17da4f50-c47b-11f0-9250-074134424cce"
//   //   },
//   //   "severity": "MINOR",
//   //   "acknowledged": false,
//   //   "cleared": false,
//   //   "assigneeId": null,
//   //   "startTs": 1765255621799,
//   //   "endTs": 1765255621799,
//   //   "ackTs": 0,
//   //   "clearTs": 0,
//   //   "assignTs": 0,
//   //   "details": {
//   //     "t_ward": "ERO1-10",
//   //     "t_location":
//   //         "3XJQ+FMW,Saravanampatti,Coimbatore,Tamil Nadu 641035,India",
//   //     "t_priority": "Minor",
//   //     "t_complainer": "O&M (CMS)",
//   //     "t_complainer_mobile_number": "6387926333",
//   //     "t_verified": false,
//   //     "t_created_by": "Princy",
//   //     "t_type": "Manual",
//   //     "customerName": "ERODE",
//   //     "t_comment": "",
//   //     "t_entityType": "pole",
//   //     "t_latitude": 11.080973539697768,
//   //     "t_longitude": 76.99265956907205
//   //   },
//   //   "propagate": true,
//   //   "propagateToOwner": false,
//   //   "propagateToOwnerHierarchy": false,
//   //   "propagateToTenant": false,
//   //   "propagateRelationTypes": [],
//   //   "id": {"entityType": "ALARM", "id": "d4447ec6-ffe7-4211-8535-c96285588aca"},
//   //   "createdTime": 1765255621799,
//   //   "name": "Pole damaged",
//   //   "status": "ACTIVE_UNACK"
//   // };
//   final Map<String, dynamic> postData = {
//     "type": '$ticketID-$problemStatement',
//     "originator": {
//       // "id": "02e88410-6cbf-11ee-bdd9-6f026d8bdec2", //tnk
//       // "id": "96d16800-cc9a-11ee-8858-09d49ff209bf", //snk
//       "id": regionID,
//       "entityType": "ASSET"
//     },
//     "severity": "MAJOR",
//     "acknowledged": false,
//     "cleared": false,
//     "ackTs": 0,
//     "clearTs": 0,
//     "assignTs": 0,
//     "details": {
//       "mobile_number": "dashboard",
//       "t_location": location,
//       "t_priority": "Major",
//       "t_complainer": "V-Team",
//       "t_verified": "false",
//       "t_created_by": createdBy,
//       "t_comment": comments,
//       "t_type": "Manual",
//       "t_latitude": latitude,
//       "t_longitude": longitude
//     }
//   };
//   try {
//     log("Before shared prefs");
//     final prefs = await SharedPreferences.getInstance();
//     log("After shared prefs");

//     String? token = prefs.getString('token');
//     log(token.toString());
//     await createTicketService(context, postData);
//   } catch (err) {
//     log(err.toString());
//   }
// }
