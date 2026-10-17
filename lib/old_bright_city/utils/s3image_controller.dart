// import 'dart:convert';
// import 'dart:developer';

// import 'package:dio/dio.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'constants.dart';

// void s3imageUpload(
//        context, image, fileName) {
//     var postDt = {"name": '$fileName.jpg', "activity": 'grievanceAppIssues', "auditImg": image};
//     log('s3 upload data: ${postDt.toString()}');
//     s3imageUploadService(context, postDt);
//   }

// Future<dynamic> s3imageUploadService( context, data) async {
//   final prefs = await SharedPreferences.getInstance();
//   String? token = prefs.getString('token');

//   Dio dio = Dio();
//   dio.options.headers["token"] = token;
//   try {
//     Response response = await dio.post('$apiURL/api/image/upload/',
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
