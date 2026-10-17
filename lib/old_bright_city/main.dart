// import 'dart:developer';

// import 'package:citizen_complaints_list_web/utils/constants.dart';
// import 'package:citizen_complaints_list_web/utils/login_service.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'tickets_table.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final Uri uri = Uri.base;
//   final String? region = uri.queryParameters['region'];
//   final String? createdBy = uri.queryParameters['createdBy'] ?? '';
//   log('selected region: $region');
//   await Firebase.initializeApp(
//     options: const FirebaseOptions(
//         apiKey: 'AIzaSyBR-DdLJJQSzpV9H8zNH-_ppF5_a6v0L50',
//         appId: '1:821794595069:web:4238c111e619c6a5409e94',
//         messagingSenderId: '821794595069',
//         projectId: 'customergrievance-9acd9'
//         ),
//   );

//   final LoginService _service = LoginService();
//   await _service.validateUser(
//     UserModel(
//       username: grievanceMailId,
//       password: grievanceMailPassword,
//     ),
//   );

//   runApp(
//     MaterialApp(
//       builder: EasyLoading.init(),
//       title: 'Citizen Complaints List',
//       home: FilteredComplaintsTable(region: region, createdBy: createdBy),
//     ),
//   );
// }
