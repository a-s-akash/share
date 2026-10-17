// import 'package:cool_alert/cool_alert.dart';
// import 'package:flutter/material.dart';

// const orgNameIcon = 'assets/icons/schnell_name.png';
// const s3BucketPath =
//     'https://luminator-iotpro.s3.us-east-1.amazonaws.com/grievances/';
// String apiURL = 'https://api.schnelliot.in';
// // String ticketURL = 'https://schnelliot.in';
// String ticketURL = 'https://iotpro.io';
// const customer = 'schnell';
// const grievanceMailId = 'grievance@sl2.qa.iotpro';
// const grievanceMailPassword = 'schnell@123';
// const originatorId = 'a3c6e5a0-8a07-11ef-99aa-176a51745c8a';

// Color primaryColor = const Color.fromARGB(248, 64, 124, 161);
// Color primaryColorLight = const Color.fromARGB(255, 224, 237, 241);
// Color iconColor = const Color.fromARGB(255, 185, 222, 233);
// Color cardColor = const Color.fromARGB(248, 173, 204, 223);
// Color indicatorColor = Colors.red;
// Color tableColumnHeading = const Color.fromARGB(255, 124, 124, 124);
// Color backgroundColor = const Color.fromARGB(255, 255, 255, 255);

// void showSnackBar(BuildContext context, String msg,
//     {Color backgroundColor = Colors.red}) {
//   SnackBar snackBar = SnackBar(
//     duration: const Duration(seconds: 4),
//     content: Text(msg),
//     backgroundColor: backgroundColor,
//     behavior: SnackBarBehavior.floating,
//   );
//   ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {});
// }

// ticketCreatedSuccessFully(context) async => await CoolAlert.show(
//       context: context,
//       type: CoolAlertType.loading,
//       showCancelBtn: false,
//       width: 500,
//       text: 'Ticket created successfuly',
//       lottieAsset: 'assets/animation/tick.json',
//       autoCloseDuration: const Duration(seconds: 3),
//     );
