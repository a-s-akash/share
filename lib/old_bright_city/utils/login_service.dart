// import 'dart:convert';
// import 'dart:developer';
// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'constants.dart';
// import 'error_messages.dart';

// //this login service is not for user login
// //its for token generation for backend communication
// class LoginService {
//   Future<dynamic> validateUser(UserModel user) async {
//     final prefs = await SharedPreferences.getInstance();

//     Map<String, String> data = {
//       "username": user.username.trim(),
//       "password": user.password,
//       "app": "luminator",
//       "version": "3.8.0"
//     };

//     try {
//       Response response = await Dio().post('$apiURL/api/login/',
//           data: data,
//           options: Options(
//             contentType: Headers.formUrlEncodedContentType,
//           ));
//       var res = jsonDecode(response.data);
//       if (response.statusCode == 200 && res.containsKey('token')) {
//         log("-----------------logged in----------------");
//         UserModel data = UserModel.fromJson(jsonDecode(response.data));
//         prefs.setString('token', data.token!);
//         prefs.setString('refreshToken', data.refreshToken!);
//         await saveUser(jsonEncode(user.toJson()));
//         return 1;
//       } else if (res.containsKey('status') && res['status'] != 200) {
//         return res;
//       } else {
//         return 0;
//       }
//     } catch (e) {
//       log(e.toString());
//       if (e is DioException) {
//         return "500";
//       } else {
//         return ErrorMessages.tryAgainError;
//       }
//     }
//   }

//   Future<UserModel> validateToken(UserModel user) async {
//     try {
//       Dio dio = Dio();
//       Response response = await dio.get(
//         '${apiURL}login/refresh',
//         options: Options(
//           contentType: 'application/json',
//           headers: {"authorization": user.token},
//         ),
//       );
//       if (response.statusCode == 200 && response.data != "") {
//         var data = response.data;
//         if (data["status"] == true) {
//           user.token = data["token"];
//         }
//         return user;
//       } else {
//         return user;
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print(e);
//       }
//       return user;
//     }
//   }
// }

// class UserModel {
//   String username = '';
//   String password = '';
//   String? token;
//   String? refreshToken;

//   UserModel(
//       {required this.username,
//       required this.password,
//       this.token,
//       this.refreshToken});

//   UserModel.fromJson(Map<String, dynamic> json) {
//     username = json['username'].toString();
//     password = json['password'].toString();
//     token = json['token'];
//     refreshToken = json['refreshToken'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = {};
//     data['username'] = username;
//     data['password'] = password;
//     data['token'] = token;
//     data['refreshToken'] = refreshToken;
//     return data;
//   }
// }

// Future<void> saveUser(String user) async {
//   final prefs = await SharedPreferences.getInstance();
//   prefs.setString('user', user);
// }
