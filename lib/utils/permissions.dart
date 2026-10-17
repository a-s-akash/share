import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestNotificationPermissionUntilGranted(
    BuildContext context) async {
  var status = await Permission.notification.status;

  // If already granted, return immediately
  if (status.isGranted) {
    log("Notification permission already granted.");
    return true;
  }

  // First request
  status = await Permission.notification.request();

  if (status.isGranted) {
    log("Notification permission granted.");
    return true;
  } else if (status.isPermanentlyDenied) {
    // Show alert dialog before opening app settings
    bool shouldOpenSettings = await _showPermissionRequiredDialog(context);

    if (shouldOpenSettings) {
      await openAppSettings();

      // Wait for the user to return from settings
      // Note: This will detect app resuming but you might want a more robust solution
      // with AppLifecycleState for production apps
      await Future.delayed(const Duration(seconds: 2));

      // Check if permission was granted in settings
      status = await Permission.notification.status;

      if (status.isGranted) {
        return true;
      } else {
        return requestNotificationPermissionUntilGranted(context);
      }
    } else {
      return false;
    }
  } else {
    // Denied but not permanently
    log("Permission denied. Will request again...");
    // You might want to show a dialog explaining why the permission is needed
    await Future.delayed(const Duration(seconds: 1));
    return requestNotificationPermissionUntilGranted(context);
  }
}

Future<void> ensurephoneCallsPermission(Permission permission) async {
  while (true) {
    final status = await Permission.phone.request();

    if (status.isGranted) {
      break;
    } else if (status.isPermanentlyDenied) {
      log('${permission.toString()} permanently denied');
      await openAppSettings();
      break;
    } else {
      log('${permission.toString()} denied, asking again...');
    }
  }
}

Future<bool> _showPermissionRequiredDialog(BuildContext context) async {
  bool result = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Notification Permission Required'),
        content: const Text(
            'This app needs notification permission to function properly. '
            'Please grant notification permission in app settings.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              result = true;
            },
            child: const Text('Open Settings'),
          ),
        ],
      );
    },
  );

  return result;
}
