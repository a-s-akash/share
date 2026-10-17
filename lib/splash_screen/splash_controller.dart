import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:schnell_luminator/attendence_tracking.dart/user_tracking_controller.dart';
import 'package:schnell_luminator/firebase_setup/firebase_services.dart';
import 'package:schnell_luminator/location_selection/location_controller.dart';
import 'package:schnell_luminator/login_page/login_controller.dart';
import 'package:schnell_luminator/utils/constants.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../ticket_notification/ticket_controller.dart';
import '../utils/asset_folder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/secure_storage.dart';
import '../utils/session.dart';

final splashController = ChangeNotifierProvider<SplashProvider>(
  (ref) => SplashProvider(),
);

class SplashProvider extends ChangeNotifier {
  late Timer timer;
  String _latestVersion = "";

  Future<dynamic> _fetchLatestAppVersion(context, ref) async {
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 1),
      ),
    );

    try {
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      // Offline or fetch failed — Remote Config uses cached values automatically.
      // If no cache exists (first install, offline), getString returns '' and
      // we skip the version check rather than crashing.
      log('RemoteConfig fetch failed (offline?): $e');
    }

    _latestVersion = remoteConfig.getString('app_version');
    bool isUpdateRequired = remoteConfig.getBool('is_update_required');
    String releaseNotes = remoteConfig.getString('release_notes');
    Map<String, dynamic> releaseNotesMap = jsonDecode(releaseNotes);
    int currentAppVersion = int.parse(appVersion.split('.').join());
    int latestAppVersion = int.parse(_latestVersion.split('.').join());
    if (currentAppVersion < latestAppVersion) {
      if (isUpdateRequired) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(updateRoute, (route) => false);
        return true;
      } else {
        await updatePopup(
          context,
          ref,
          ErrorMessages.updateAlert(latestVersion: _latestVersion),
          releaseNotesMap,
        );
      }
    }
  }

  fetchProblemTypesAndIssuesIdentified() async {
    final box = await Hive.openBox('problemTypesAndIssuesIdentified');

    if (!box.containsKey("problem_types") ||
        !box.containsKey("issues_identified")) {
      log('Problem Type Box empty fetching in foreground...');
      final probsAndIssues =
          await fetchProblemTypesAndIssuesIdentifiedService();
      if (probsAndIssues != null && probsAndIssues is! String) {
        log(probsAndIssues.toString());
        await box.put("problem_types", probsAndIssues['problem_types']);
        await box.put("issues_identified", probsAndIssues['issues_identified']);
        log('Problems and Issues List Cached in Hive');
      } else {
        log('Failed to fetch problems and issues list');
      }
    } else {
      log('Problem Type Box empty fetching in foreground...');

      Future(() async {
        final probsAndIssues =
            await fetchProblemTypesAndIssuesIdentifiedService();
        if (probsAndIssues != null && probsAndIssues is! String) {
          log(probsAndIssues.toString());
          await box.put("problem_types", probsAndIssues['problem_types']);
          await box.put(
              "issues_identified", probsAndIssues['issues_identified']);
          log('Problems and Issues List Updated in Hive (Background)');
        }
      });
    }
  }

  Future<bool> checkAppVersion(BuildContext context, WidgetRef ref) async {
    await _fetchLatestAppVersion(context, ref);
    fetchProblemTypesAndIssuesIdentified();
    await ref.read(assetsController).initializeAssets();
    await ref.read(locationController).initHive();

    final secureStorage = SecureStorageService();
    var data = await secureStorage.getUserDetails();

    bool isLocationTrackingRequi = await isLocationTrackingRequired();
    if (isLocationTrackingRequi) {
      //auto logout after 24 hrs
      bool didAutoLogout =
          await ref.read(userTrackingController).autoLogout(context, ref);
      if (didAutoLogout) return false;
    }
    timer = Timer(const Duration(milliseconds: 2000), () async {
      const ph.Permission locationPermission = ph.Permission.location;
      const ph.Permission backgroundPermission = ph.Permission.locationAlways;
      bool locationStatus = false;
      bool isPermanentlyDenied = await locationPermission.isPermanentlyDenied;

      if (isPermanentlyDenied) {
        log(ErrorMessages.locationDeniedError);
        if (context.mounted) {
          permissionRequiredAlert(context, ErrorMessages.enableLocationAlert);
        }
      } else {
        var locationStatusResult = await locationPermission.request();

        if (locationStatusResult.isGranted || locationStatusResult.isLimited) {
          // Check for background permission if Android 11+
          if (await backgroundPermission.isDenied ||
              await backgroundPermission.isRestricted) {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => WillPopScope(
                onWillPop: () async {
                  return false;
                },
                child: AlertDialog(
                  title: const Text('Background Location Access'),
                  content: Text(
                    'Luminator collects location data in the background, even when the app is closed or not in use, to track field personnel movements, record attendance, and calculate daily allowances.',
                    style: TextStyle(
                        color: Theme.of(context).secondaryHeaderColor),
                  ),
                  actions: [
                    // TextButton(
                    //   onPressed: () => Navigator.of(context).pop(false),
                    //   child: const Text('Cancel'),
                    // ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Allow Location Access'),
                    ),
                  ],
                ),
              ),
            );

            if (result == true) {
              // Request background permission only after user agrees
              // await Permission.locationAlways.request();
              var backgroundStatusResult = await backgroundPermission.request();
              if (!backgroundStatusResult.isGranted) {
                log("Background location not granted");
                if (context.mounted) {
                  await permissionRequiredAlert(
                      context, ErrorMessages.enableLocationAlert);
                }
              }
            }
          }

          // Location permission granted
          locationStatus = true;

          if (locationStatus) {
            if (context.mounted) {
              if (data == '' || data == null) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(loginRoute, (route) => false);
              } else {
                // Existing session — check 7-day offline expiry
                final meta = await secureStorage.getOfflineSessionMeta();
                final expiryTs = meta?['expiryTimestamp'] as int? ?? 0;
                final now = DateTime.now().millisecondsSinceEpoch;
                if (expiryTs > 0 && now > expiryTs) {
                  log('Offline session expired — forcing re-login');
                  await secureStorage.clearOfflineSessionMeta();
                  if (context.mounted) {
                    await snackBar(
                      context,
                      'Session Expired',
                      'Your offline session has expired. Please login again.',
                    );
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(loginRoute, (route) => false);
                  }
                  return;
                }

                final userMail = await secureStorage.getUserName() ?? '';
                ref.read(loginController).setUserMail(userMail);
                ref.read(locationController).refreshFromServer(userMail);
                await ref.read(ticketController).getLocalTicketsList(userMail);

                EasyLoading.dismiss();

                final prefs = await SharedPreferences.getInstance();
                final isLoggedIn = prefs.getBool('isUserLoggedIn') ?? false;

                if (context.mounted) {
                  if (isLoggedIn) {
                    // Active session — go directly to home without biometric
                    await ref
                        .read(locationController)
                        .getStoredContext(userMail);
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          customerRoute, (route) => false);
                    }
                  } else {
                    // User logged out — require biometric re-authentication
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        offlineLoginRoute, (route) => false);
                  }
                }
              }
            }
          }
        } else {
          if (context.mounted) {
            await permissionRequiredAlert(
                context, ErrorMessages.enableLocationAlert);
          }
          if (locationStatus == false) {
            if (context.mounted) {
              await checkAppVersion(context, ref);
            }
          }
        }
        log(locationStatus.toString());
      }
    });
    return Future.value(true);
  }

  String get latestVersion => _latestVersion;
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
