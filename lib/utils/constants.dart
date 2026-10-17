import 'dart:convert';
import 'package:citizen_complaints_list_web/screens/api/api_services.dart';
import 'package:flutter/material.dart';

const String publicCustomerId = '6dabb128-10d8-465b-8ff6-e7868229f88d';

final ValueNotifier<bool> sessionExpiredNotifier = ValueNotifier(false);
final ValueNotifier<bool> isDashboardPreparingNotifier = ValueNotifier(true);

const dashboardVersion = '1.0.9';

enum Environment {
  development,
  staging,
  production,
}

dynamic decodeToken(token) {
  final parts = token.split('.');

  if (parts.length != 3) {
    throw Exception('Invalid JWT');
  }

  final decodedPayload =
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));

  final Map<String, dynamic> payload =
      jsonDecode(decodedPayload) as Map<String, dynamic>;

  return ({
    "name": "${payload['firstName'] ?? ''} ${payload['lastName'] ?? ''}",
    "mail": payload['sub'] ?? '',
    "userId": payload["userId"] ?? ''
  });
}

Environment get currentEnvironment {
  const flavor = String.fromEnvironment('flavor');
  switch (flavor) {
    case 'development':
      return Environment.development;
    case 'staging':
      return Environment.staging;
    case 'production':
    default:
      return Environment.production;
  }
}

String get apiURL {
  switch (currentEnvironment) {
    case Environment.development:
      return 'https://qa-api.iotpro.io';
    case Environment.staging:
      return 'https://beta.api.schnelliot.in';
    case Environment.production:
      return 'https://api.schnelliot.in';
  }
}

String get baseURL {
  switch (currentEnvironment) {
    case Environment.development:
      return 'https://iotpro.io';
    case Environment.staging:
      return 'https://schnelliot.in';
    case Environment.production:
      return 'https://schnelliot.in';
  }
}

String get environment => currentEnvironment.name;

late String user;
late String userId;
late String userEmail;
late String token;

setVariables(userName, id, email, accessToken) async {
  user = userName;
  userId = id;
  userEmail = email;
  token = accessToken;
  // Note: environment is now determined by --dart-define=flavor=...
}

Future<dynamic> login() async {
  var res = await loginService();

  if (res != 0) {
    return res.toString();
  }
  return '';
}

ThemeData lightTheme(context) => ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: Theme.of(context).canvasColor,
      primaryColor: const Color(0xFF1D7569),
      // primaryColor: Colors.red,
      dividerColor: const Color(0xFF1D7569),
      canvasColor: Colors.white,
      highlightColor: Colors.blue,
      unselectedWidgetColor: Colors.grey,
      secondaryHeaderColor: Colors.black,
      tabBarTheme: const TabBarThemeData(indicatorColor: Colors.red),
    );

class ErrorMessages {
  static const String tryAgainError = 'Something went wrong. Please try again.';
  static const String serverTimeOutError = 'Server timeout.';
  static const String sessionExpiredError =
      'Session expired. Please login again.';
}

String getCurrentFormattedDateTime() {
  DateTime now = DateTime.now();
  String datetime = '${now.year}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}';
  return datetime;
}
