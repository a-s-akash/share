import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../device_page/device_controller.dart';
import '../env.dart';
import '../login_page/login_controller.dart';
import '../qr_scan_online.dart';
import '../utils/dialog_box.dart';

final inappController =
    ChangeNotifierProvider<WebProvider>((ref) => WebProvider());

class WebProvider extends ChangeNotifier {
  InAppWebViewController? webViewController;

  void setControllerForQr(InAppWebViewController controller) {
    webViewController = controller;
    notifyListeners();
  }

  void clearController() {
    webViewController = null;
    notifyListeners();
  }
}

class WebviewDashboard extends ConsumerStatefulWidget {
  const WebviewDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<WebviewDashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<WebviewDashboard> {
  final webViewKey = GlobalKey();

  InAppWebViewController? _webViewController; // local reference

  InAppWebViewSettings options = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    javaScriptEnabled: true,
    supportZoom: false,
    cacheEnabled: true,
    useHybridComposition: true,
    thirdPartyCookiesEnabled: true,
  );

  @override
  void dispose() {
    // _webViewController?.clearCache();
    _webViewController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String selectedCustomer = ref.watch(deviceController).selectedCustomer;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;
    String accessTokenForWebView =
        ref.watch(loginController).accessTokenForWebView;
    String stateParamsForWeView =
        ref.watch(loginController).stateParamsForWeView;

    log({
      'insidedashboardclass accesstoken: $accessTokenForWebView, stateparams:$stateParamsForWeView'
    }.toString());

    final screenSize = MediaQuery.of(context).size;
    final webViewHeight = screenSize.height / 1.45;

    var qrViewController = ref
        .watch(ref.watch(isSecondTime) ? qrController2 : qrController)
        .qrViewController;

    Future<void> handleDeviceId(viewname, deviceId) async {
      log('Updated selectedElementFromWebView: $deviceId');

      /// Prevent navigation for auto-regenerated lamp IDs
      if (deviceId.toString().length < 32) {
        await ref
            .read(deviceController)
            .webViewMaintenance(ref, context, viewname, deviceId);
      }
      EasyLoading.dismiss();
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).cardColor,
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => HomePage(),
                  //   ),
                  // );
                },
              );
            },
          ),
          backgroundColor:
              Theme.of(context).primaryColor.withValues(alpha: 0.19),
          elevation: 0.0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Theme.of(context).textTheme.bodySmall!.color,
            fontSize: 18.0,
          ),
          title: Text(
            "DASHBOARD",
            style: TextStyle(
                color: Theme.of(context).cardColor,
                fontWeight: FontWeight.w500),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SelectedLocationData(
                selectedCustomer: selectedCustomer,
                selectedRegion: selectedRegion,
                selectedZone: selectedZone,
                selectedWard: selectedWard,
              ),
            ),
            // projContextContainerInMaintenace(
            //     context, ref, selectedRegion, selectedZone, selectedWard, null),
            // const SizedBox(
            //   height: 15,
            // ),
            SizedBox(
              height: webViewHeight,
              width: screenSize.width,
              child: InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(
                  url: WebUri(
                    '$thingsboardURL/dashboard/$webviewDashboardId?accessToken=$accessTokenForWebView&state=$stateParamsForWeView',
                  ),
                ),
                initialSettings: options,
                onWebViewCreated: (controller) {
                  // Keep both local and provider references
                  _webViewController = controller;
                  ref.read(inappController).setControllerForQr(controller);

                  log("onWebViewCreated");
                  controller.addJavaScriptHandler(
                    handlerName: 'SelectedDeviceHandler',
                    callback: (args) {
                      final details = jsonDecode(args[0]);
                      log("Received device value from web in handler: $details");
                      final viewname = details['viewName'];
                      final deviceId = details['deviceId'];
                      EasyLoading.show(status: '', dismissOnTap: false);
                      handleDeviceId(viewname, deviceId);
                    },
                  );
                },
                onLoadStart: (controller, url) async {
                  log('onLoadStart: $url');
                  await controller.evaluateJavascript(source: '''
                    document.addEventListener('click', function(e) {
                      setTimeout(() => {
                        var storedData = window.localStorage.getItem('details');
                        console.log('Current selected storedData:', storedData);
                        if (storedData !== null) {
                          var details = JSON.parse(storedData);
                          console.log('viewName:', details.viewName);
                          console.log('deviceId:', details.deviceId);
                          window.flutter_inappwebview.callHandler('SelectedDeviceHandler', storedData);
                          window.localStorage.removeItem('details');
                        }
                      }, 50);
                    }, true);
                  ''');
                },
                onReceivedHttpError: (controller, request, errorResponse) {
                  if (errorResponse.statusCode == 401) {
                    log('status code onReceivedHttpError ${errorResponse.statusCode}');
                    log('Session expired due to token expiration');
                    // tokenExpired(context, ref);
                  } else {
                    log('HTTP error: ${errorResponse.statusCode}');
                  }
                },
                onReceivedError: (controller, request, error) {
                  log('onLoadError: $request message: $error');
                },
                onPermissionRequest: (controller, request) async {
                  log('onPermissionRequest origin: ${request.origin}, resources: ${request.resources}');
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
