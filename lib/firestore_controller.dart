import 'dart:developer';
import 'package:citizen_complaints_list_web/firebase_setup/firebase_services.dart';
import 'package:dio/dio.dart';

import 'firebase_setup/firbase_config.dart';

Future<dynamic> addTicketToFireStore(dynamic data) async {
  try {
    Dio dio = Dio();
    Response response = await dio.post(createTicketUrl,
        data: {
          // 'env': environment == "production" ? "prod" : "dev",
          'data': data
        },
        options: Options(
          headers: {"SecPassKey": createTicketSecKey},
        ));
    if (response.statusCode == 200) {
      final responseData = response.data;
      if (responseData['status'] == 'success') {
        return {
          'ticketId': responseData['data']['ticket_id'],
          'alarmId': responseData['data']['alarm_id'],
          'status': 'created'
        };
      }
    }
    return {'ticketId': null, 'status': 'failed'};
  } catch (error) {
    return {'ticketId': null, 'status': 'failed'};
  }
}

Future<dynamic> updateTicketInFirestore(
    String ticketId, Map<String, dynamic> data) async {
  try {
    Dio dio = Dio();
    Response response = await dio.post(updateTicketUrl,
        data: {
          // 'env': environment == "production" ? "prod" : "dev",
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
    return 0;
  }
}

Future<void> updateRegionsList() async {
  Map<String, String> regions = {
    "Alandur": "ALA",
    "Anakaputhur": "ANA",
    "Aniyapuram": "ANI",
    "AnnamalaiUniversity": "AMU",
    "Arani": "ARN",
    "Arumparuthi": "ARU",
    "BangaloreUrban": "BLU",
    "Banglore": "BLR",
    "Bhavani": "BVN",
    "Bommasandra": "BMS",
    "Byrathi": "BRT",
    "Chinnavedampatti": "CVP",
    "Chithode": "CTD",
    "Dindigul1": "DG1",
    "Dindigul2": "DG2",
    "ECR": "ECR",
    "Edapaadi": "EPD",
    "ERODE": "ERD",
    "Gandhipuram": "GDP",
    "Gudiyatham": "GDY",
    "KumarNagar": "KMN",
    "Kunnathur": "KNT",
    "Mahabalipuram": "MBP",
    "Manjur": "MNJ",
    "Nanjapura": "NJP",
    "Nasiyanur": "NSY",
    "Oruvandur": "ORV",
    "Parali": "PRL",
    "Perundurai": "PRD",
    "Rajapalayam": "RJP",
    "Ramanathapuram": "RMP",
    "Saravanampatti": "SVM",
    "SEMCDemo1": "SD1",
    "SEMCDemo2": "SD2",
    "SEMCDemo3": "SD3",
    "Singanallur": "SGN",
    "spectrumdemo": "SPD",
    "Tambaram": "TBM",
    "Tenkasi": "TKS",
    "Test": "TST",
    "Testing_Mohanur": "TMR",
    "TheNilgiris": "NLG",
    "Thindal": "TDL",
    "Thiruchendur1": "TCR",
    "THUDIYALUR": "TDR",
    "Tiruppur": "TPR",
    "Tiruvannamalai": "TVM",
    "Ullal": "ULL",
    "Voimedu": "VMD",
    "CBE": "CBE",
    "Coimbatore": "CBE",
    "KCT": "KCT",
    "KOVAI": "CBE",
    "KSC": "KSC",
    "PNP": "PNP",
    "SNK": "SNK",
    "TNK": "TNK"
  };
  try {
    await FirebaseServices.ticketsFirestore
        .collection('utils')
        .doc('prefix')
        .set(regions);
    log("Regions list updated successfully");
  } catch (e) {
    log("Error updating regions list: \$e");
  }
}

Future<void> updateProblemTypes() async {
  Map<String, dynamic> probs = {
    'slc': {
      'auto': {
        'R Voltage High',
        'R Voltage Low',
        'Y Current High',
        'Y Relay Fail',
        'B InCom Cut',
        'Y Outgoing Cut',
        'B Voltage High',
        'B Outgoing Cut',
        'Y Voltage Low',
        'R Current High',
        'B Voltage Low',
        'B Current High',
        'Y Voltage High',
        'Y InCom Cut',
        'R Outgoing Cut',
        'R InCom Cut',
        'B Relay Fail',
        'R Relay Fail'
      },
      "manual": {
        'Low Voltage',
        'High Voltage',
        'High Current / Power Theft',
        'MCB Trip',
        'Power Failure',
        'Relay Failure',
        'Meter Comm. Failure',
        'Lamps not burning',
        'Day time burning',
        'Timing issue',
        'No Communication / Offline',
        'Preventive Maintenance',
        'RF Signal Rank Poor',
        '4G network poor',
        'Input Cable Damaged',
        'Load always ON',
        'Bypass',
        'Others',
        'Not Communicating',
        'Replace Meter',
        'Meter Replaced',
        'Abnormal Reading',
        "Clock Drift"
      }
    },
    'lamp': [
      "Not burning",
      "Flickering",
      "Day time burning",
      "No Load",
      "Meter Comm. Failure",
      "Relay Failure",
      "Not Communicating",
      "Input Power unavailable",
      "RF Signal Rank Poor",
      "4G network poor",
      "Others"
    ],
    'gw': [
      "Not communicating",
      "Input Power unavailable / Power Failure",
      "RF Signal Rank Poor",
      "4G network poor",
      "Others",
      "Clock Drift"
    ],
    'ilm': {
      "manual": {
        "Not burning",
        "Flickering",
        "Day time burning",
        "No Load",
        "Meter Comm. Failure",
        "Relay Failure",
        "Not Communicating",
        "Input Power unavailable",
        "RF Signal Rank Poor",
        "4G network poor",
        "Others",
        "Clock Drift",
      },
      "auto": {"Relay Fault"}
    },
    'pole': ['Pole damaged', 'Others'],
    'others': ['Others'],
    "general": [
      'Day time burning',
      'Lamps not burning',
      'Flickering',
      'Panel damaged',
      'Panel door opened',
      'Pole damaged',
      'Web Application Down',
      'Others'
    ],
  };
  try {
    await FirebaseServices.ticketsFirestore
        .collection('utils')
        .doc('problem_types')
        .set(probs);
    log("Problem types list updated successfully");
  } catch (e) {
    log("Error updating problem types list: \$e");
  }
}

// Future<dynamic> updateFireStoreDatabase() async {
//   //   "Development": {
//   //     "customer_id": "b2662a10-6cbe-11ee-bdd9-6f026d8bdec2",
//   //     "regions": {
//   //       "TNK": {
//   //         "region_id": "02e88410-6cbf-11ee-bdd9-6f026d8bdec2",
//   //         "zones": {
//   //           "TNK-1": {
//   //             "zone_id": "0ebdfef0-6cbf-11ee-bdd9-6f026d8bdec2",
//   //             "wards": {
//   //               "TNK-1-1": {"ward_id": "27775770-6cbf-11ee-bdd9-6f026d8bdec2"},
//   //               "TNK-1-2": {"ward_id": "2779ef80-6cbf-11ee-bdd9-6f026d8bdec2"},
//   //               "TNK-1-3": {"ward_id": "2779ef81-6cbf-11ee-bdd9-6f026d8bdec2"},
//   //             },
//   //           },
//   //           "TNK-2": {
//   //             "zone_id": "dd9b9820-ccb6-11ee-8858-09d49ff209bf",
//   //             "wards": {
//   //               "TNK-2-1": {"ward_id": "020a27a0-cf3d-11f0-ba06-e9537df27ad2"},
//   //               "TNK-2-2": {"ward_id": "020a0090-cf3d-11f0-ba06-e9537df27ad2"},
//   //               "TNK-2-3": {"ward_id": "020a0091-cf3d-11f0-ba06-e9537df27ad2"},
//   //             },
//   //           },
//   //           "TNK-3": {
//   //             "zone_id": "e5ed4370-ccb6-11ee-8858-09d49ff209bf",
//   //             "wards": {},
//   //           },
//   //         },
//   //       },
//   //       "SNK": {
//   //         "region_id": "02e88410-6cbf-11ee-bdd9-6f026d8bdec2",
//   //         "zones": {
//   //           "SNK-1": {
//   //             "zone_id": "0ebdfef0-6cbf-11ee-bdd9-6f026d8bdec2",
//   //             "wards": {
//   //               "SNK-1-1": {"ward_id": "27775770-6cbf-11ee-bdd9-6f026d8bdec2"},
//   //               "SNK-1-2": {"ward_id": "2779ef80-6cbf-11ee-bdd9-6f026d8bdec2"},
//   //               "SNK-1-3": {"ward_id": "2779ef81-6cbf-11ee-bdd9-6f026d8bdec2"},
//   //             },
//   //           },
//   //           "SNK-2": {
//   //             "zone_id": "dd9b9820-ccb6-11ee-8858-09d49ff209bf",
//   //             "wards": {
//   //               "SNK-2-1": {"ward_id": "020a27a0-cf3d-11f0-ba06-e9537df27ad2"},
//   //               "SNK-2-2": {"ward_id": "020a0090-cf3d-11f0-ba06-e9537df27ad2"},
//   //               "SNK-2-3": {"ward_id": "020a0091-cf3d-11f0-ba06-e9537df27ad2"},
//   //             },
//   //           },
//   //           "SNK-3": {
//   //             "zone_id": "e5ed4370-ccb6-11ee-8858-09d49ff209bf",
//   //             "wards": {},
//   //           },
//   //         },
//   //       },
//   //     },
//   //   },
//   //   "COIMBATORE": {
//   //     "customer_id": "b4da7a00-d00b-11f0-be55-47e2afc83cf7",
//   //     "regions": {
//   //       "CBE": {
//   //         "region_id": "ca7eca50-d00b-11f0-be55-47e2afc83cf7",
//   //         "zones": {
//   //           "Eachanari": {
//   //             "zone_id": "56db2b20-d015-11f0-be55-47e2afc83cf7",
//   //             "wards": {
//   //               "Eachanari1-1": {
//   //                 "ward_id": "7f1182b0-d015-11f0-be55-47e2afc83cf7",
//   //               },
//   //               "Eachanari1-2": {
//   //                 "ward_id": "7f1182b1-d015-11f0-be55-47e2afc83cf7",
//   //               },
//   //               "Eachanari1-3": {
//   //                 "ward_id": "7f115ba0-d015-11f0-be55-47e2afc83cf7",
//   //               },
//   //             },
//   //           },
//   //         },
//   //       },
//   //     },
//   //   },
//   // };

//   await FirebaseFirestore.instance
//       .collection(ticketCollection)
//       .doc('config')
//       .set({
//     "CBE": {"counter": 0, "prefix": "CBE"},
//     "TNK": {"counter": 0, "prefix": "TNK"},
//     "PNP": {"counter": 0, "prefix": "PNP"},
//     "SNK": {"counter": 0, "prefix": "SNK"},
//     "KOVAI": {"counter": 0, "prefix": "KVI"},
//   });
//   return;
//   // final response =
//   //     await FirebaseFunctions.instance.httpsCallable("createTickets").call({
//   //   "collection": ticketCollection,
//   //   "data": {"region": "TNK"}
//   // });
//   // final result = response.data;
//   // log(result.toString());
//   // if (result['code'] == 200) {
//   //   log("Ticket createds: ${result['data']['ticket_id']}");
//   // }

//   // Dio dio = Dio();
//   // try {
//   //   Response response = await dio.post(
//   //     'https://us-central1-customergrievance-9acd9.cloudfunctions.net/ticketsCount',
//   //     data: {
//   //       "collection": "iotpro-tickets",
//   //       "status": "Closed",
//   //       "context": "ward",
//   //       "id": "27775770-6cbf-11ee-bdd9-6f026d8bdec2"
//   //     },
//   //   );
//   //   log(response.data.toString());
//   // } catch (e) {
//   //   log(e.toString());
//   // }
//   // try {
//   //   Response response = await dio.post(
//   //     'https://us-central1-customergrievance-9acd9.cloudfunctions.net/createTicket',
//   //     data: {
//   //       "collection": "iotpro-tickets",
//   //       "data": {"region": "TNK"}
//   //     },
//   //   );
//   //   log(response.data.toString());
//   // } catch (e) {
//   //   log(e.toString());
//   // }

//   return;
// }
