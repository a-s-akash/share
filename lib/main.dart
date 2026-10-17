import 'dart:developer';

import 'package:citizen_complaints_list_web/screens/Tickets_List/tickets_list_screen.dart';
import 'package:citizen_complaints_list_web/screens/api/api_controller.dart';
import 'package:citizen_complaints_list_web/utils/app_overlay_builder.dart';
import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:citizen_complaints_list_web/utils/ticket_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_setup/firbase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Uri uri = Uri.base;

  String token = uri.queryParameters['token'] ?? "";

  // token = await login();

  dynamic payload = decodeToken(token);
  String user = payload['name'] ?? "";
  String userId = payload['userId'] ?? "";
  String userEmail = payload['mail'] ?? "";

  try {
    await setVariables(user, userId, userEmail, token);
    await Firebase.initializeApp(
      name: 'Tickets',
      options: ticketsFirebaseOptions,
    );
    await Hive.initFlutter();
    final metaBox = await Hive.openBox('sync_meta_box');
    final ticketsBox = await Hive.openBox('tickets_box');
    metaBox.clear();
    ticketsBox.clear();
  } catch (e, stack) {
    log("Error during initialization: $e");
    log(stack.toString());
  }

  // final metaBox = await Hive.openBox('sync_meta_box');

  // if (metaBox.get('initial_data_cleanup_completed') != true) {
  //   final ticketsBox = await Hive.openBox('tickets_box');
  //   await ticketsBox.clear();
  //   await metaBox.clear();
  //   await metaBox.put('initial_data_cleanup_completed', true);
  //   debugPrint('One-time local tickets data cleanup performed.');
  // } else {
  //   await Hive.openBox('tickets_box');
  // }

  final bool isUpdaterequired = await isUpdateRequired();
  if (!isUpdaterequired) {
    fetchProblemTypesAndIssuesIdentified();
    fetchProjectContext();
  }

  runApp(
    ProviderScope(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: appOverlayBuilder,
            title: 'Tickets Dashboard',
            theme: lightTheme(context),
            home: isUpdaterequired
                ? const TicketUpdateScreen()
                : const TicketsListScreen(),
          );
        },
      ),
    ),
  );
}
