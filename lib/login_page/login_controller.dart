import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schnell_luminator/attendence_tracking.dart/attendance_service.dart';
import 'package:schnell_luminator/attendence_tracking.dart/ppe_integration.dart';
import 'package:schnell_luminator/attendence_tracking.dart/user_tracking_controller.dart';
import 'package:schnell_luminator/location_selection/location_controller.dart';
import 'package:schnell_luminator/offline_login/biometric_service.dart';
import 'package:schnell_luminator/ticket_notification/ticket_controller.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:schnell_luminator/utils/utility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../attendence_tracking.dart/gps_details_model.dart';
import '../attendence_tracking.dart/worker_thread.dart';
import '../device_page/device_controller.dart';
import '../device_page/telemetry_service.dart';
import '../survey/background_sync_manager.dart';
import '../survey/connectivity_sync_service.dart';
import '../env.dart';
import '../home_page/webview.dart';
import '../location_selection/customer_list.dart';
import '../utils/constants.dart';
import '../utils/dialog_box.dart';
import '../utils/session_context_controller.dart';
import '../utils/permissions.dart';
import '../utils/secure_storage.dart';
import 'login_model.dart';
import 'login_service.dart';

final loginController =
    ChangeNotifierProvider<LoginProvider>((ref) => LoginProvider());

class LoginProvider extends ChangeNotifier {
  final LoginService _service = LoginService();
  final TelemetryService _telemetryService = TelemetryService();
  bool _passwordVisible = true;
  String _userMail = '';
  bool _loginLoader = false;
  // bool _isUserLoggedIn = true;
  String _oldAppAlertMsg = '';
  final UserModel _userLogin = UserModel(username: '', password: '');
  String accessToken = '';
  dynamic urlEncodedData;
  String _accessTokenForWebView = '';
  String _stateParamsForWeView = '';

  passwordVisibleChange() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }

  textFieldUpdate(val, isUserName) {
    if (isUserName) {
      _userLogin.username = val;
    } else {
      _userLogin.password = val;
    }
    notifyListeners();
  }

  clearLoginFieldValues() {
    _userLogin.username = '';
    _userLogin.password = '';
    notifyListeners();
  }

  void loginLoadChange() {
    _loginLoader = !_loginLoader;
    notifyListeners();
  }

  void logoutLoadfalse() {
    _loginLoader = false;
    notifyListeners();
  }

  Future<void> validateLogin(context, WidgetRef ref, username, password) async {
    var result = await _service.validateUser(
      context,
      UserModel(username: username, password: password),
    );
    final prefs = await SharedPreferences.getInstance();
    bool? isLocationTrackingRequired =
        prefs.getBool('isLocationTrackingRequired');
    bool? isPPERequired = prefs.getBool('isPPERequired');
    int? locationTrackingInterval =
        prefs.getInt('locationTrackingInterval'); //in millisecs

    if (result == 1) {
      await ref.read(ticketController).getLocalTicketsList(username);
      ref.read(sessionContextController).clearVehicleDetailsValues();
      _userMail = username.toString();

      //for auto logout after 24 hrs
      prefs.setInt('loginTimestamp', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('isUserLoggedIn', true);

      // only for the users who have rights to track the location
      if (isLocationTrackingRequired!) {
        await requestNotificationPermissionUntilGranted(context);
        // notification permission
        if (await Permission.notification.isGranted) {
          await ref
              .read(userTrackingController)
              .initForegroundTask(locationTrackingInterval!);
          await initializeService();
        } else {
          log("Cannot proceed without notification permission");
          await requestNotificationPermissionUntilGranted(context);
        }
        // phone call permission for accessing carrier/network name
        try {
          await Permission.locationWhenInUse.status;
          await ensurephoneCallsPermission(Permission.phone);
        } catch (e) {
          log("Permission error: $e");
        }
        loginLoadChange();
      }

      // only for the users who have rights to access safety kit
      if (isPPERequired!) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PpeTakePictureScreen(),
          ),
        );
      }
      if (!isPPERequired) {
        await ref.read(locationController).getStoredContext(userMail);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerList()),
        );
      }
    } else if (result is Map && result["status"] == 400) {
      loginLoadChange();
      showSnackBar(ref, context, result['message'].toString());
      if (ModalRoute.of(context)!.settings.name != loginRoute) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(loginRoute, (route) => false);
      }
    } else if (result is Map &&
        result.containsKey('status') &&
        result['status'] != 200 &&
        result['status'] != 500) {
      if (result['status'] == 1001) {
        _oldAppAlertMsg = result['message'].toString();
        loginLoadChange();
        Navigator.of(context)
            .pushNamedAndRemoveUntil(updateRoute, (route) => false);
      } else {
        loginLoadChange();
        showSnackBar(ref, context, result['message'].toString());
        if (ModalRoute.of(context)!.settings.name != loginRoute) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(loginRoute, (route) => false);
        }
      }
    } else if (result == '500' ||
        (result is Map &&
            (result["status"] == 500 || result["status"] == 503))) {
      loginLoadChange();
      showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
      if (ModalRoute.of(context)!.settings.name != loginRoute) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(loginRoute, (route) => false);
      }
    } else {
      loginLoadChange();
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
      if (ModalRoute.of(context)!.settings.name != loginRoute) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(loginRoute, (route) => false);
      }
    }
  }

  /// Called by the auth bottom sheet after the user successfully authenticates.
  /// Handles everything after auth: GPS, attendance queue, location tracking,
  /// server refresh, and navigation.
  Future<void> proceedAfterAuth(BuildContext context, WidgetRef ref) async {
    loginLoadChange(); // show loader

    final secureStorage = SecureStorageService();
    final prefs = await SharedPreferences.getInstance();

    final storedUsername = await secureStorage.getUserName() ?? '';
    _userMail = storedUsername;
    notifyListeners();

    final bool isLocationTrackingRequired =
        prefs.getBool('isLocationTrackingRequired') ?? false;
    final bool isAttendanceTrackingRequired =
        prefs.getBool('shallCaptureAttendance') ?? false;
    final bool isPPERequired = prefs.getBool('isPPERequired') ?? false;
    final int locationTrackingInterval =
        prefs.getInt('locationTrackingInterval') ?? 0;

    // Best-effort GPS — silent fallback to 0,0 if unavailable offline
    double lat = 0.0;
    double lng = 0.0;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (e) {
      log('proceedAfterAuth: GPS unavailable, queuing with 0,0: $e');
    }
    final isOnline = await Utility.isConnected();

    if (isAttendanceTrackingRequired) {
      await AttendanceService.queueLogin(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      if (isOnline) {
        BackgroundSyncWorkManager.triggerImmediateSync();
      }
    }

    await prefs.setBool('isUserLoggedIn', true);
    await prefs.setInt('loginTimestamp', DateTime.now().millisecondsSinceEpoch);

    if (isLocationTrackingRequired) {
      if (context.mounted) {
        await requestNotificationPermissionUntilGranted(context);
      }
      if (await Permission.notification.isGranted) {
        await ref
            .read(userTrackingController)
            .initForegroundTask(locationTrackingInterval);
        await initializeService();
      }
      try {
        await Permission.locationWhenInUse.status;
        await ensurephoneCallsPermission(Permission.phone);
      } catch (e) {
        log('proceedAfterAuth: permission error: $e');
      }
      loginLoadChange(); // hide loader after tracking setup
    }

    if (!context.mounted) return;

    if (isOnline) {
      await ref.read(ticketController).getLocalTicketsList(_userMail);
      ref.read(locationController).refreshFromServer(storedUsername);
    }

    if (!context.mounted) return;

    if (isPPERequired) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PpeTakePictureScreen()),
      );
    } else {
      await ref.read(locationController).getStoredContext(storedUsername);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerList()),
        );
      }
    }

    if (!isLocationTrackingRequired) {
      loginLoadChange(); // hide loader when tracking not needed
    }
  }

  /// Convenience wrapper used when there is no custom bottom sheet
  /// (e.g. direct call path). Runs auth then calls [proceedAfterAuth].
  Future<void> continueOffline(BuildContext context, WidgetRef ref,
      {bool biometricOnly = false}) async {
    final authenticated =
        await BiometricService.authenticate(biometricOnly: biometricOnly);
    if (!authenticated) {
      if (context.mounted) {
        showSnackBar(ref, context, 'Authentication failed. Please try again.');
      }
      return;
    }
    if (context.mounted) {
      await proceedAfterAuth(context, ref);
    }
  }

  Future<void> onUserLogout(context, WidgetRef ref) async {
    EasyLoading.show(
      status: '',
      dismissOnTap: false,
    );
    final prefs = await SharedPreferences.getInstance();
    bool? isLocationTrackingRequired =
        prefs.getBool('isLocationTrackingRequired');

    if (isLocationTrackingRequired!) {
      final totalKm =
          await ref.read(userTrackingController).calculateSessionDistance();
      log('OnUserLogout: Calculated session distance: $totalKm km');
      final isOnlineForTelemetry = await Utility.isConnected();
      if (isOnlineForTelemetry) {
        await _telemetryService.pushValuesToUserTelemetry(
            {"distanceKm": totalKm.toStringAsFixed(2)});
      } else {
        // Queue for sync — performTelemetrySync() sends this when internet returns
        await SimpleSyncService.enqueueTelemetry(
            {'distanceKm': totalKm.toStringAsFixed(2)});
        log('OnUserLogout: offline — queued distanceKm=$totalKm');
      }
    }

    final isOnline = await Utility.isConnected();

    // Best-effort GPS for logout record
    double lat = 0.0;
    double lng = 0.0;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (e) {
      log('onUserLogout: GPS unavailable: $e');
    }

    if (isOnline) {
      var result = await _service.logoutService(context);
      EasyLoading.dismiss();

      if (result == 1 || result == 401) {
        await AttendanceService.queueLogout(
            latitude: lat,
            longitude: lng,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            synced: true);
        _performLogoutCleanup(ref, isLocationTrackingRequired);
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              offlineLoginRoute, (Route<dynamic> route) => false);
        }
      } else if (result is Map &&
          result.containsKey('status') &&
          result['status'] != 200 &&
          result['status'] != 500) {
        EasyLoading.dismiss();
        await AttendanceService.queueLogout(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        showSnackBar(ref, context, result['message'].toString());
      } else if (result == '500' ||
          (result is Map &&
              (result["status"] == 500 || result["status"] == 503))) {
        EasyLoading.dismiss();
        await AttendanceService.queueLogout(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        showSnackBar(ref, context, ErrorMessages.systemNotResponsiveError);
      } else {
        // Fallback: still queue the logout for later and proceed
        await AttendanceService.queueLogout(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        EasyLoading.dismiss();
        _performLogoutCleanup(ref, isLocationTrackingRequired);
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              offlineLoginRoute, (Route<dynamic> route) => false);
        }
      }
    } else {
      // Offline — queue the logout payload for sync when connectivity returns
      await AttendanceService.queueLogout(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      EasyLoading.dismiss();
      _performLogoutCleanup(ref, isLocationTrackingRequired);
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
            offlineLoginRoute, (Route<dynamic> route) => false);
      }
    }
  }

  void _performLogoutCleanup(WidgetRef ref, bool isLocationTrackingRequired) {
    if (isLocationTrackingRequired) {
      stopLocationTracking();
      if (Hive.isBoxOpen(locationTrackingBox)) {
        Hive.box<TravelLocationEntity>(locationTrackingBox).clear();
      }
    }
    ref.read(deviceController).emptyLocation();
    ref.read(deviceController).emptyProjContext();
    ref.read(loginController).logoutLoadfalse();
    // Do NOT clear secureStorage — local session is preserved for biometric re-entry
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool('isUserLoggedIn', false));
  }

  Future<void> paramsForTheWebViewCustomer(
      WidgetRef ref, selectedCustomerId, selectedCustomerName) async {
    final secureStorage = SecureStorageService();
    accessToken = await secureStorage.getAccessToken() ?? '';
    log(' customerId: $selectedCustomerId customerName: $selectedCustomerName');
    final data = [
      {
        "id": "default",
        "params": {
          "selectedCustomer": {
            "entityId": {"id": selectedCustomerId, "entityType": "CUSTOMER"},
            "entityName": selectedCustomerName
          },
          "selectedEntity": {
            "entityId": {"id": selectedCustomerId, "entityType": "CUSTOMER"},
            "entityName": selectedCustomerName,
            "entityLabel": selectedCustomerName
          },
          "targetEntityParamName": "selectedEntity"
        }
      }
    ];
    final jsonData = json.encode(data);
    final base64Data = base64.encode(utf8.encode(jsonData));
    urlEncodedData = Uri.encodeComponent(base64Data);
    log('Url for the webview : $thingsboardURL/dashboard/$webviewDashboardId?accessToken=$accessToken&state=$urlEncodedData');
    // return {'accessToken': accessToken, 'stateParam': urlEncodedData};
    _accessTokenForWebView = accessToken;
    _stateParamsForWeView = urlEncodedData;
  }

  Future<void> reloadWebView(
      WidgetRef ref, accessTokenForWebView, stateParamsForWeView) async {
    var webViewController = ref.watch(inappController).webViewController;
    if (webViewController != null) {
      await webViewController.loadUrl(
        urlRequest: URLRequest(
            url: WebUri(
                '$thingsboardURL/dashboard/$webviewDashboardId?accessToken=$accessTokenForWebView&state=$stateParamsForWeView')),
      );
    }
  }

  Future<void> paramsForTheWebViewWard(WidgetRef ref, regionZoneOrWardId,
      regionZoneOrWardName, regionZoneOrWardLabel) async {
    final secureStorage = SecureStorageService();
    final accessToken = await secureStorage.getAccessToken() ?? '';
    String selectedCustomerId = ref.watch(deviceController).selectedCustomerId;
    String selectedCustomerName = ref.watch(deviceController).selectedCustomer;
    log('regionLabel: $regionZoneOrWardLabel  regionId: $regionZoneOrWardId  regionName: $regionZoneOrWardName  customerId: $selectedCustomerId customerName: $selectedCustomerName');
    final data = [
      {
        "id": "default",
        "params": {
          "selectedCustomer": {
            "entityId": {"id": selectedCustomerId, "entityType": "CUSTOMER"},
            "entityName": selectedCustomerName
          },
          "selectedEntity": {
            "entityId": {"id": regionZoneOrWardId, "entityType": "ASSET"},
            "entityName": regionZoneOrWardName,
            "entityLabel": regionZoneOrWardLabel
          },
          "targetEntityParamName": "selectedEntity"
        }
      }
    ];
    final jsonData = json.encode(data);
    final base64Data = base64.encode(utf8.encode(jsonData));
    urlEncodedData = Uri.encodeComponent(base64Data);
    log('Url for the webview : $thingsboardURL/dashboard/$webviewDashboardId?accessToken=$accessToken&state=$urlEncodedData');
    _accessTokenForWebView = accessToken;
    _stateParamsForWeView = urlEncodedData;
    // reloadWebView(ref, _accessTokenForWebView, _stateParamsForWeView);
  }

  Future<void> launchUrls() async {
    try {
      launchUrl(Uri.parse(
          'market://details?id=com.schnell.schnell_luminator.schnell_luminator'));
      // launch("market://details?id=" +
      //     'com.schnell.schnell_luminator.schnell_luminator');
    } on PlatformException catch (e) {
      log('PlatformException: $e');
      // launch("https://play.google.com/store/apps/details?id=" +
      //     'com.schnell.schnell_luminator.schnell_luminator');
      launchUrl(Uri.parse(
          'https://play.google.com/store/apps/details?id=com.schnell.schnell_luminator.schnell_luminator'));
    } finally {
      launchUrl(Uri.parse(
          'https://play.google.com/store/apps/details?id=com.schnell.schnell_luminator.schnell_luminator'));
    }
  }

  void setUserMail(String value) {
    _userMail = value;
    notifyListeners();
  }

  // Future<bool> rootDetection(context) async {
  //   try {
  //     bool isSecure = await SecurityService.isDeviceSecure();

  //     if (!isSecure) {
  //       showSecurityAlert(context,
  //           "This app cannot run on rooted devices or emulators for security reasons.");
  //       return false;
  //     } else {
  //       log('Vulnerability check :Device is secure');
  //       return true;
  //     }
  //   } catch (e) {
  //     log('Vulnerability check :Error in root detection :$e');
  //     return false;
  //   }
  // }

  bool get passwordVisible => _passwordVisible;
  bool get loginLoader => _loginLoader;
  String get userMail => _userMail;
  String get oldAppAlertMsg => _oldAppAlertMsg;
  String get stateParamsForWeView => _stateParamsForWeView;
  String get accessTokenForWebView => _accessTokenForWebView;
  UserModel get userLogin => _userLogin;
}
