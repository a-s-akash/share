import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_compression/image_compression.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:schnell_luminator/attendence_tracking.dart/swipe_records_page.dart';
import 'package:schnell_luminator/attendence_tracking.dart/user_tracking_controller.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/device_page/device_search.dart';
import 'package:schnell_luminator/device_page/gw/panel_actions_controller.dart';
import 'package:schnell_luminator/device_page/ilm/maintenance1.dart';
import 'package:schnell_luminator/device_page/ilm/scantest.dart';
import 'package:schnell_luminator/device_page/lamp/lamp_details_page.dart';
import 'package:schnell_luminator/home_page/map_controller.dart';
import 'package:schnell_luminator/location_selection/customer_list.dart';
import 'package:schnell_luminator/login_page/login_controller.dart';
import 'package:schnell_luminator/qr_scan_online.dart';
import 'package:schnell_luminator/ticket_notification/ticket_controller.dart';
import 'package:schnell_luminator/utils/constants.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:schnell_luminator/utils/utility.dart';
import 'package:lottie/lottie.dart';
import '../device_page/device_service.dart';
import '../device_page/gw/gw_maintenance1.dart';
import '../device_page/pole/pole_page.dart';
import '../device_page/take_photo.dart';
import '../env.dart';
import '../home_page/dashboard.dart';
import '../location_selection/location_controller.dart';
import '../location_selection/region_list.dart';
import '../location_selection/ward_list.dart';
import '../location_selection/zone_list.dart';
import 'app_theme.dart';
import 'asset_folder.dart';
import 'secure_storage.dart';
import 'session.dart';

final DeviceService _service = DeviceService();

warningPopup(WidgetRef ref, BuildContext context, String msg) async {
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.file(Assets.userAlertLottie, height: 150, width: 150),
            const SizedBox(height: 20),
            Text(msg, textAlign: TextAlign.center),
          ],
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                },
                child: Text("Back",
                    style: TextStyle(
                        color: Theme.of(context).unselectedWidgetColor)),
              ),
              const SizedBox(width: 50),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  side: BorderSide(color: Theme.of(context).cardColor),
                  backgroundColor: Theme.of(context).cardColor,
                ),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LampDetailsPage()),
                  );
                },
                child: Text(
                  "Proceed",
                  style: TextStyle(color: Theme.of(context).canvasColor),
                ),
              ),
            ],
          ),
        ],
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      );
    },
  );
}

addLampUnderPole(context, WidgetRef ref, lampLightPointId, index, msg) {
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          return true;
        },
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120.0,
                height: 135.0,
                child: Lottie.file(
                  Assets.userAlertLottie,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                msg,
                style: TextStyle(color: Theme.of(context).secondaryHeaderColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _buildButton(
                context,
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                  await ref
                      .read(deviceController)
                      .clickEventIsFor("recordExistingLamp");
                  await ref
                      .read(deviceController)
                      .recordExistingLampUnderPole(context, index);
                },
                text: "Record Existing Lamp",
                bgcolor: darkYellow,
                iccolor: Colors.transparent.withValues(alpha: 0.3),
                icon: Icons.settings_backup_restore_rounded,
              ),
              _buildButton(
                context,
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  await ref.read(deviceController).clickEventIsFor("addLamp");

                  ref
                      .read(deviceController)
                      .setLampLightPointId(lampLightPointId);

                  if (context.mounted) {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ScanQRWithCustomScreen(
                          firstOrSecond: 1, clickEventIsFor: "addLamp"),
                    ));
                  }
                },
                text: "Install New Lamp",
                bgcolor: Theme.of(context).primaryColor,
                iccolor: Theme.of(context).cardColor,
                icon: Icons.construction,
              ),
            ],
          ),
        ),
      );
    },
  );
}

addIlmWarningPopup(WidgetRef ref, BuildContext context, String msg) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.file(
                Assets.userAlertLottie,
                height: 150,
                width: 150,
              ),
              const SizedBox(height: 20),
              Text(msg, textAlign: TextAlign.center),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: Text("Cancel",
                      style: TextStyle(
                          color: Theme.of(context).unselectedWidgetColor)),
                ),
                const SizedBox(width: 40),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    side: BorderSide(color: Theme.of(context).cardColor),
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                  onPressed: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    await ref
                        .read(deviceController)
                        .clickEventIsFor("addILMViaPole");
                    if (context.mounted) {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ScanQRWithCustomScreen(
                            firstOrSecond: 1, clickEventIsFor: "addILMViaPole"),
                      ));
                    }
                  },
                  child: Text(
                    "OK",
                    style: TextStyle(color: Theme.of(context).canvasColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

skipWarning(WidgetRef ref, BuildContext context, String msg,
    String clickEventIsFor) async {
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  String clickeventIsFor = ref.watch(deviceController).clickeventIsFor;
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.file(Assets.userAlertLottie, height: 150, width: 150),
              const SizedBox(height: 20),
              Text(msg, textAlign: TextAlign.center),
            ],
          ),
          actions: <Widget>[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                },
                child: Text("NO",
                    style: TextStyle(
                        color: Theme.of(context).unselectedWidgetColor)),
              ),
              const SizedBox(width: 50),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    side: BorderSide(color: Theme.of(context).cardColor),
                    backgroundColor: Theme.of(context).cardColor),
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (clickEventIsFor == "lampOnlyReplace") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TakePictureScreen(
                          camera: firstCamera,
                          clickeventIsFor: clickeventIsFor,
                        ),
                      ),
                    );
                  } else {
                    await ref
                        .read(deviceController)
                        .lampOrILMScanForReplace("ilm");
                    if (context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScanQRWithCustomScreen(
                            firstOrSecond: 2,
                            clickEventIsFor: clickEventIsFor,
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  "YES",
                  style: TextStyle(color: Theme.of(context).canvasColor),
                ),
              ),
            ]),
          ],
        ),
      );
    },
  );
}

snackBar(context, title, msg) {
  Flushbar(
      backgroundColor: Theme.of(context).tabBarTheme.indicatorColor!,
      title: title,
      message: msg,
      icon: Icon(Icons.cancel_outlined,
          size: 30, color: Theme.of(context).canvasColor),
      isDismissible: false,
      blockBackgroundInteraction: true,
      leftBarIndicatorColor: Theme.of(context).canvasColor,
      onTap: (flushbar) {
        flushbar.dismiss();
      }
      // duration: Duration(seconds: 20),
      ).show(context);
}

warningAlert(ref, context, msg) async {
  await QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor!,
      headerBackgroundColor: Theme.of(context).tabBarTheme.indicatorColor!,
      title: msg,
      barrierDismissible: false,
      showCancelBtn: false,
      showConfirmBtn: false,
      text: 'Please Wait!',
      autoCloseDuration: const Duration(seconds: 5));
}

alertPopUp(context, msg, type) => QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      showCancelBtn: false,
      width: 500,
      text: msg,
      autoCloseDuration: const Duration(seconds: 3),
    );

alertPopUp1(context, msg, type) => QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      showCancelBtn: false,
      width: 500,
      text: msg,
      autoCloseDuration: const Duration(seconds: 5),
    );
wardRequiredAlert(BuildContext context, WidgetRef ref, String msg) {
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          contentPadding: const EdgeInsets.all(0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4)),
                  color: Theme.of(context).unselectedWidgetColor,
                ),
                width: double.infinity,
                child: Lottie.file(
                  Assets.wardRequiredLottie,
                  height: 150,
                  width: 150,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Access Denied!',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Text(msg, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 15),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    side: BorderSide(color: Theme.of(context).cardColor),
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                  onPressed: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    if (qrViewController != null) {
                      qrViewController.resumeCamera();
                    }
                  },
                  child: Text(
                    "OK",
                    style: TextStyle(color: Theme.of(context).canvasColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Drawer customHomeDrawer(
  String usernmae,
  String usermail,
  BuildContext context,
  WidgetRef ref,
) {
  String selectedContextId = ref.watch(ticketController).selectedContextId;
  String selectedRegion = ref.watch(deviceController).selectedRegion;

  return Drawer(
    backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
    child: ListView(
      children: <Widget>[
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.7)),
          accountName: Text(usernmae,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).canvasColor,
              )),
          accountEmail: Text(usermail,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).canvasColor,
              )),
          currentAccountPicture: GestureDetector(
            child: CircleAvatar(
              backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
              child: Icon(Icons.person,
                  color: Theme.of(context).textTheme.bodySmall!.color),
            ),
          ),
        ),
        InkWell(
            onTap: () async {
              bool isLocationTrackingRequi = await isLocationTrackingRequired();
              if (isLocationTrackingRequi) {
                //auto logout after 24 hrs
                bool didAutoLogout = await ref
                    .read(userTrackingController)
                    .autoLogout(context, ref);
                if (didAutoLogout) return;
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
              ref.read(bottomMenuStateProvider.state).state = 0;
              if (context.mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ),
                );
              }
            },
            child: ListTile(
              title: Text('Home',
                  style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).cardColor)),
              leading: Icon(Icons.home, color: Theme.of(context).cardColor),
            )),
        InkWell(
            onTap: () {
              if (selectedRegion.isEmpty) {
                wardRequiredAlert(
                    context, ref, ErrorMessages.regionRequiredAlertMessage);
                return;
              }
              Utility.isConnected().then((value) async {
                if (value) {
                  EasyLoading.show(
                    status: '',
                    dismissOnTap: false,
                  );
                  bool isLocationTrackingRequi =
                      await isLocationTrackingRequired();
                  if (isLocationTrackingRequi) {
                    //auto logout after 24 hrs
                    bool didAutoLogout = await ref
                        .read(userTrackingController)
                        .autoLogout(context, ref);
                    if (didAutoLogout) return;
                  }
                  // if (selectedWard != '') {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  await ref.read(locationController).fetchCurrentLocation();
                  if (context.mounted) {
                    await ref
                        .read(mapController)
                        .getLatLongBasedonWard(ref, context, selectedContextId);
                  }
                  EasyLoading.dismiss();
                  ref.read(bottomMenuStateProvider.state).state = 1;

                  if (context.mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ),
                    );
                  }
                  // } else {
                  //   wardRequiredAlert(
                  //       context, ref, ErrorMessages.wardRequiredAlertMessage);
                  // }
                } else {
                  if (context.mounted) {
                    await snackBar(context, ErrorMessages.offlineErrorTitle,
                        ErrorMessages.offlineErrorMessage);
                  }
                }
              });
            },
            child: ListTile(
              title: Text('Map View',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).cardColor,
                  )),
              leading: Icon(
                Icons.my_location_outlined,
                color: Theme.of(context).cardColor,
              ),
            )),
        InkWell(
            onTap: () {
              Utility.isConnected().then((value) async {
                if (value) {
                  bool isLocationTrackingRequi =
                      await isLocationTrackingRequired();
                  if (isLocationTrackingRequi) {
                    //auto logout after 24 hrs
                    bool didAutoLogout = await ref
                        .read(userTrackingController)
                        .autoLogout(context, ref);
                    if (didAutoLogout) return;
                  }
                  // if (selectedWard != '') {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  if (context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ScanQRWithCustomScreen(
                          firstOrSecond: 1, clickEventIsFor: "1"),
                    ));
                  }
                  // } else {
                  //   wardRequiredAlert(
                  //       context, ref, ErrorMessages.wardRequiredAlertMessage);
                  // }
                } else {
                  if (context.mounted) {
                    await snackBar(context, ErrorMessages.offlineErrorTitle,
                        ErrorMessages.offlineErrorMessage);
                  }
                }
              });
            },
            child: ListTile(
              title: Text('Scan QR',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).cardColor,
                  )),
              leading: Icon(
                Icons.qr_code,
                color: Theme.of(context).cardColor,
              ),
            )),
        InkWell(
            onTap: () {
              // Utility.isConnected().then((value) async {
              //   if (value) {
              ref.read(bottomMenuStateProvider.state).state = 0;
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerList(),
                  ),
                );
              }
              //   } else {
              //     if (context.mounted) {
              //       await snackBar(context, ErrorMessages.offlineErrorTitle,
              //           ErrorMessages.offlineErrorMessage);
              //     }
              //   }
              // });
            },
            child: ListTile(
              title: Text('Change Customer',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).cardColor,
                  )),
              leading: Icon(
                Icons.location_on_outlined,
                color: Theme.of(context).cardColor,
              ),
            )),
        InkWell(
            onTap: () async {
              Navigator.pop(context);
              // await Utility.refreshAttendanceBox();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SwipeRecordsPage()),
              );
            },
            child: ListTile(
              title: Text('View Swipes',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).cardColor,
                  )),
              leading: Icon(
                Icons.swap_vert_circle_outlined,
                color: Theme.of(context).cardColor,
              ),
            )),
        const SizedBox(
          height: 150,
        ),
        Divider(color: Theme.of(context).hoverColor),
        InkWell(
            onTap: () {
              Navigator.pop(context);
              logoutPop(context, ref);
            },
            child: ListTile(
              title: Text('Logout',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).cardColor,
                  )),
              leading: Icon(
                Icons.logout_outlined,
                color: Theme.of(context).cardColor,
              ),
            )),
        const SizedBox(
          height: 130,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 110),
          child: Text(
            baseURL.contains('iotpro') ? '$appVersion - Beta' : appVersion,
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

class SelectedLocationData extends ConsumerWidget {
  const SelectedLocationData({
    super.key,
    required this.selectedCustomer,
    required this.selectedRegion,
    required this.selectedZone,
    required this.selectedWard,
    this.selectedRoute = '',
    this.isMapPage = false,
  });
  final String selectedCustomer;
  final String selectedRegion;
  final String selectedZone;
  final String selectedWard;
  final String selectedRoute;
  final bool isMapPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String selectedRegionDesc = ref.watch(deviceController).selectedRegionDesc;
    String selectedZoneDesc = ref.watch(deviceController).selectedZoneDesc;
    String selectedWardDesc = ref.watch(deviceController).selectedWardDesc;
    String selectedContextDesc = selectedRegion == ''
        ? ''
        : selectedZone == ''
            ? selectedRegionDesc
            : selectedWard == ''
                ? selectedZoneDesc
                : selectedWardDesc;
    return Container(
      color: Theme.of(context).canvasColor,
      // height: MediaQuery.of(context).size.height * 0.158,
      child: Column(
        children: [
          isMapPage
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: Theme.of(context).cardColor,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        if (selectedRoute == 'customer') {
                          null;
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerList(),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 0.0, bottom: 5.0),
                        child: Container(
                          height: 35,
                          width: MediaQuery.of(context).size.width / 1.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.8),
                            // border: Border.all(
                            //     width: 2,
                            //     color: Theme.of(context)
                            //         .primaryColor
                            //         .withValues(alpha: 0.8))
                          ),
                          child: Center(
                            child: AutoSizeText(
                              selectedCustomer == ''
                                  ? 'Select a Customer'
                                  : selectedCustomer,
                              style: TextStyle(
                                  color: Theme.of(context).canvasColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search,
                          color: Theme.of(context).cardColor),
                      onPressed: () {
                        // if (selectedWard != '') {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //       builder: (context) => const DeviceSearch()),
                        // );
                        ref.read(deviceController).emptyDeviceSearchList();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DeviceSearch()));
                        // } else {
                        //   wardRequiredAlert(context, ref,
                        //       ErrorMessages.wardRequiredAlertMessage);
                        // }
                      },
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: () {
                    if (selectedRoute == 'customer') {
                      null;
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerList(),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0.0, bottom: 5.0),
                    child: Container(
                      height: 35,
                      width: MediaQuery.of(context).size.width / 1,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.8),
                        // border: Border.all(
                        //     width: 2,
                        //     color: Theme.of(context)
                        //         .primaryColor
                        //         .withValues(alpha: 0.8))
                      ),
                      child: Center(
                        child: AutoSizeText(
                          selectedCustomer == ''
                              ? 'Select a Customer'
                              : selectedCustomer,
                          style: TextStyle(
                              color: Theme.of(context).canvasColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (selectedRoute == 'region') {
                      null;
                    } else {
                      if (selectedCustomer != '') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegionList()),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    height: 35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: selectedCustomer != ''
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.8)
                          : Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.3),
                      // border: Border.all(
                      //   width: 2,
                      //   color: selectedCustomer != ''
                      //       ? Theme.of(context)
                      //           .primaryColor
                      //           .withValues(alpha: 0.8)
                      //       : Theme.of(context)
                      //           .dialogTheme
                      //           .backgroundColor!
                      //           .withValues(alpha: 0.8),
                      // ),
                    ),
                    child: Center(
                      child: AutoSizeText(
                        selectedRegion == '' ? 'All Regions' : selectedRegion,
                        style: TextStyle(
                            color: selectedCustomer != ''
                                ? Theme.of(context).canvasColor
                                : Theme.of(context).cardColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (selectedRoute == 'zone') {
                      null;
                    } else {
                      if (selectedRegion != '') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ZoneList()),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    height: 35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: selectedRegion != ''
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.8)
                          : Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.3),
                      // border: Border.all(
                      //   width: 2,
                      //   color: selectedRegion != ''
                      //       ? Theme.of(context)
                      //           .primaryColor
                      //           .withValues(alpha: 0.8)
                      //       : Theme.of(context)
                      //           .dialogTheme
                      //           .backgroundColor!
                      //           .withValues(alpha: 0.8),
                      // ),
                    ),
                    child: Center(
                      child: AutoSizeText(
                        selectedZone == '' ? 'All Zones' : selectedZone,
                        style: TextStyle(
                            color: selectedRegion != ''
                                ? Theme.of(context).canvasColor
                                : Theme.of(context).cardColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (selectedRoute == 'ward') {
                      null;
                    } else {
                      if (selectedZone != '') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const WardList()),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    height: 35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: selectedZone != ''
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.8)
                          : Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.3),
                      // border: Border.all(
                      //   width: 2,
                      //   color: selectedZone != ''
                      //       ? Theme.of(context)
                      //           .primaryColor
                      //           .withValues(alpha: 0.8)
                      //       : Theme.of(context)
                      //           .dialogTheme
                      //           .backgroundColor!
                      //           .withValues(alpha: 0.8),
                      // ),
                    ),
                    child: Center(
                      child: AutoSizeText(
                        selectedWard == '' ? 'All Wards' : selectedWard,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selectedZone != ''
                              ? Theme.of(context).canvasColor
                              : Theme.of(context).cardColor,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (selectedContextDesc != '')
            Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Center(
                child: AutoSizeText(
                  selectedContextDesc,
                  style: TextStyle(
                      color: Theme.of(context).hoverColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
              ),
            ),
          const SizedBox(
            height: 5,
          ),
        ],
      ),
    );
  }
}

Widget maintenanceActivityButton(BuildContext context,
    {VoidCallback? onTap,
    required String text,
    Color? bgcolor,
    Color? iccolor,
    required File? image}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: SizedBox(
      width: 145,
      child: Material(
        elevation: 5,
        color: bgcolor,
        borderRadius: BorderRadius.circular(10.0),
        child: MaterialButton(
          padding: const EdgeInsets.only(left: 10),
          height: 60,
          onPressed: onTap,
          child: Stack(alignment: Alignment.centerLeft, children: [
            Text(
              text,
              style:
                  TextStyle(color: Theme.of(context).canvasColor, fontSize: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: iccolor,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Image.file(
                        image!,
                        height: 42,
                        width: 42,
                      ),
                    ),
                  ),
                )
              ],
            )
          ]),
        ),
      ),
    ),
  );
}

informationAlert(WidgetRef ref, BuildContext context, String msg) {
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.file(
                Assets.userAlertLottie,
                height: 150,
                width: 150,
              ),
              const SizedBox(height: 15),
              Text(msg, textAlign: TextAlign.center),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    side: BorderSide(color: Theme.of(context).cardColor),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    if (qrViewController != null) {
                      qrViewController.resumeCamera();
                    }
                  },
                  child: Text(
                    "OK",
                    style: TextStyle(color: Theme.of(context).canvasColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

void showSnackBar(WidgetRef ref, BuildContext context, String msg) {
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  SnackBar snackBar = SnackBar(
    // dismissDirection: DismissDirection.horizontal,
    duration: const Duration(seconds: 4),
    content: Text(msg),
    backgroundColor: Theme.of(context).tabBarTheme.indicatorColor,
    behavior: SnackBarBehavior.floating,
  );
  // ScaffoldMessenger.of(context).showSnackBar(snackBar);
  ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
    if (qrViewController != null) {
      qrViewController.resumeCamera();
    }
  });
}

successTick(context, msg) async {
  await QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor!,
      headerBackgroundColor: Theme.of(context).tabBarTheme.indicatorColor!,
      title: '',
      barrierDismissible: false,
      showCancelBtn: false,
      showConfirmBtn: false,
      text: msg,
      autoCloseDuration: const Duration(seconds: 3));
}

failureAlert(context, msg) async {
  await QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor!,
      headerBackgroundColor: Theme.of(context).tabBarTheme.indicatorColor!,
      title: '',
      barrierDismissible: false,
      showCancelBtn: false,
      showConfirmBtn: false,
      text: msg,
      autoCloseDuration: const Duration(seconds: 3));
}

installationConfirmwithDiffCust(context, WidgetRef ref, msg, clickEventIsFor) {
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  String clickeventIsFor = ref.watch(deviceController).clickeventIsFor;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120.0,
                height: 135.0,
                child: Lottie.file(
                  Assets.userAlertLottie,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                msg,
                style: TextStyle(color: Theme.of(context).secondaryHeaderColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (clickEventIsFor == "addILM" ||
                  clickEventIsFor == "addILMViaPole")
                _buildButton(
                  context,
                  onTap: () async {
                    final cameras = await availableCameras();
                    final firstCamera = cameras.first;
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TakePictureScreen(
                            camera: firstCamera,
                            clickeventIsFor: clickeventIsFor,
                          ),
                        ),
                      );
                    }
                  },
                  text: "Proceed to Install",
                  bgcolor: Theme.of(context).hintColor,
                  iccolor: Colors.transparent.withValues(alpha: 0.3),
                  icon: Icons.check_sharp,
                ),
              _buildButton(
                context,
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                },
                text: "Try another Device/Asset",
                bgcolor: darkYellow,
                iccolor: Colors.transparent.withValues(alpha: 0.3),
                icon: Icons.settings_backup_restore_rounded,
              ),
            ],
          ),
        ),
      );
    },
  );
}

installationConfirmwithDiffCustForPole(context, WidgetRef ref, msg) {
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120.0,
                height: 135.0,
                child: Lottie.file(
                  Assets.userAlertLottie,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                msg,
                style: TextStyle(color: Theme.of(context).secondaryHeaderColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _buildButton(
                context,
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                },
                text: "Try another Device/Asset",
                bgcolor: darkYellow,
                iccolor: Colors.transparent.withValues(alpha: 0.3),
                icon: Icons.settings_backup_restore_rounded,
              ),
            ],
          ),
        ),
      );
    },
  );
}

installationConfirmForPole(context, WidgetRef ref, msg, navigationPath) {
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120.0,
                height: 135.0,
                child: Lottie.file(
                  Assets.userAlertLottie,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                msg,
                style: TextStyle(color: Theme.of(context).secondaryHeaderColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _buildButton(
                context,
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                },
                text: "Try another Device/Asset",
                bgcolor: darkYellow,
                iccolor: Colors.transparent.withValues(alpha: 0.3),
                icon: Icons.settings_backup_restore_rounded,
              ),
              _buildButton(
                context,
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PoleDetails(),
                      settings: const RouteSettings(name: poleDetailsRoute),
                    ),
                  );
                },
                text: "Take to Maintenance",
                bgcolor: Theme.of(context).primaryColor,
                iccolor: Theme.of(context).cardColor,
                icon: Icons.construction,
              ),
            ],
          ),
        ),
      );
    },
  );
}

installationConfirm(context, WidgetRef ref, msg, deviceType, clickEventIsFor) {
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  String clickEventIsFor = ref.watch(deviceController).clickeventIsFor;
  String assetType = ref.watch(deviceController).assetType;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120.0,
                height: 135.0,
                child: Lottie.file(
                  Assets.userAlertLottie,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                msg,
                style: TextStyle(color: Theme.of(context).secondaryHeaderColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (clickEventIsFor == "addILM" ||
                  clickEventIsFor == "addILMViaPole")
                _buildButton(
                  context,
                  onTap: () async {
                    final cameras = await availableCameras();
                    final firstCamera = cameras.first;
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TakePictureScreen(
                            camera: firstCamera,
                            clickeventIsFor: clickEventIsFor,
                          ),
                        ),
                      );
                    }
                  },
                  text: "Proceed to Install",
                  bgcolor: Theme.of(context).hintColor,
                  iccolor: Colors.transparent.withValues(alpha: 0.3),
                  icon: Icons.check_sharp,
                ),
              _buildButton(
                context,
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                },
                text: "Try another Device/Asset",
                bgcolor: darkYellow,
                iccolor: Colors.transparent.withValues(alpha: 0.3),
                icon: Icons.settings_backup_restore_rounded,
              ),
              _buildButton(
                context,
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (deviceType == "GW") {
                    if (assetType == 'ccms' || assetType == 'smslc') {
                      String firstDeviceType =
                          ref.read(deviceController).firstDeviceType;
                      await ref
                          .read(panelController)
                          .commRelayStatusCalculation(ref, context,
                              deviceType: firstDeviceType);
                    }
                    if (context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GwMaintenance(),
                        ),
                      );
                    }
                  } else {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const IlmMaintenance(),
                      ),
                    );
                  }
                },
                text: "Take to Maintenance",
                bgcolor: Theme.of(context).primaryColor,
                iccolor: Theme.of(context).cardColor,
                icon: Icons.construction,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildButton(BuildContext context,
    {VoidCallback? onTap,
    required String text,
    Color? bgcolor,
    Color? iccolor,
    required IconData? icon}) {
  return Padding(
    padding:
        const EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0, bottom: 10.0),
    child: Material(
      elevation: 5,
      color: bgcolor,
      borderRadius: BorderRadius.circular(15.0),
      child: MaterialButton(
        height: 55,
        onPressed: onTap,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Text(
              text,
              style:
                  TextStyle(color: Theme.of(context).canvasColor, fontSize: 12),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration:
                      BoxDecoration(color: iccolor, shape: BoxShape.circle),
                  child: Icon(
                    icon,
                    color: Theme.of(context).canvasColor,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    ),
  );
}

logoutPop(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.file(
              Assets.logoutLottie,
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 15),
            const Text(
              'Are you sure you want to Logout?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: Text("Cancel",
                      style: TextStyle(
                          color: Theme.of(context).unselectedWidgetColor)),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      side: BorderSide(
                          color: Theme.of(context).tabBarTheme.indicatorColor!),
                      backgroundColor:
                          Theme.of(context).tabBarTheme.indicatorColor),
                  onPressed: () async {
                    await ref.read(loginController).onUserLogout(context, ref);
                  },
                  child: Text(
                    "Logout",
                    style: TextStyle(color: Theme.of(context).canvasColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

showDialogFunc(
    context, ref, data, deviceImage, lamp, clickEventIsFor, poleName) {
  File imageFile = File(deviceImage);
  ImageFile inputImageFile = ImageFile(
    rawBytes: imageFile.readAsBytesSync(),
    filePath: deviceImage,
  );

  return showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).canvasColor,
              ),
              padding: const EdgeInsets.all(15),
              height: MediaQuery.of(context).size.height * 0.76,
              width: MediaQuery.of(context).size.width * 0.88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Device successfully installed!",
                    style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).canvasColor,
                          border: Border.all(
                              width: 10,
                              color: Theme.of(context)
                                  .dialogTheme
                                  .backgroundColor!),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20))),
                      child: SizedBox(
                        // width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.height / 2,
                        child: Image.memory(inputImageFile.rawBytes),
                      ),
                    ),
                  ),
                  // const SizedBox(
                  //   height: 20,
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: <Widget>[
                  //       const SizedBox(
                  //         height: 18,
                  //       ),
                  // lineDesign(context, 'Device', deviceName),
                  // infoDivider(context),
                  // lineDesign(context, 'Accuracy', result),
                  // infoDivider(context),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(
                    height: 25,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      width: 170,
                      child: Material(
                        elevation: 5,
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(15.0),
                        child: MaterialButton(
                          // minWidth: MediaQuery.of(context).size.width * 1,
                          height: 70,
                          onPressed: () async {
                            if (clickEventIsFor == 'addILMViaPole') {
                              EasyLoading.show(
                                status: '',
                                dismissOnTap: false,
                              );

                              await _service.getDeviceDataService(
                                  ref, context, poleName, 1, "scanAPole");
                              await EasyLoading.dismiss();
                              if (context.mounted) {
                                Navigator.popUntil(
                                    context,
                                    (route) =>
                                        route.settings.name ==
                                        poleDetailsRoute);
                                Navigator.pushReplacementNamed(
                                    context, poleDetailsRoute);
                              }
                            } else {
                              ref.read(bottomMenuStateProvider.state).state = 0;
                              await Navigator.of(context)
                                  .pushNamedAndRemoveUntil(homeRoute,
                                      (Route<dynamic> route) => false);
                            }
                          },
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Text("Done",
                                  style: TextStyle(
                                      color: Theme.of(context).canvasColor,
                                      fontSize: 16)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        shape: BoxShape.circle),
                                    child: Icon(Icons.check,
                                        color: Theme.of(context).canvasColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void showGifDialog(BuildContext context) {
  List<Map<String, dynamic>> gifs = [
    {"path": Assets.ilmOutsideGif, "name": "ILM Outside"},
    {"path": Assets.ilmInsideGif, "name": "ILM Inside"},
    {"path": Assets.ccmsPanelGif, "name": "CCMS Panel"},
    {"path": Assets.lumiHubOutsideGif, "name": "LumiHub Outside"},
    {"path": Assets.lumiHubInsideGif, "name": "LumiHub Inside"}
  ];
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: double.maxFinite,
            height: 250,
            child: FlutterCarousel.builder(
              options: FlutterCarouselOptions(
                floatingIndicator: false,
                disableCenter: true,
                reverse: false,
                height: 55.0,
                showIndicator: true,
                slideIndicator: CircularSlideIndicator(
                    slideIndicatorOptions: SlideIndicatorOptions(
                        currentIndicatorColor:
                            Theme.of(context).secondaryHeaderColor,
                        indicatorRadius: 5,
                        indicatorBorderColor:
                            Theme.of(context).secondaryHeaderColor)),
              ),
              itemCount: gifs.length,
              itemBuilder: (BuildContext context, int index, int itemCount) {
                final gif = gifs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        gif['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).secondaryHeaderColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Image.file(gif['path']!),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      });
}

userAlert(WidgetRef ref, BuildContext context, String msg, String deviceType,
    String clickEventIsFor) async {
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  String currentClickEvent = ref.watch(deviceController).clickeventIsFor;
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        contentPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.file(Assets.userAlertLottie, height: 150, width: 150),
            const SizedBox(height: 20),
            Text(
              msg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    if (qrViewController != null) {
                      qrViewController.resumeCamera();
                    }
                  },
                  child: Text("Cancel",
                      style: TextStyle(
                          color: Theme.of(context).unselectedWidgetColor)),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      side: BorderSide(color: Theme.of(context).cardColor),
                      backgroundColor: Theme.of(context).cardColor),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();

                    if (deviceType == "ILM") {
                      if (clickEventIsFor == "addILM" ||
                          clickEventIsFor == "addILMViaPole") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TakePictureScreen(
                                camera: firstCamera,
                                clickeventIsFor: currentClickEvent),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScanSelectionPage(),
                          ),
                        );
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TakePictureScreen(
                              camera: firstCamera,
                              clickeventIsFor: currentClickEvent),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "OK",
                    style: TextStyle(color: Theme.of(context).canvasColor),
                  ),
                )
              ],
            ),
          ],
        ),
      );
    },
  );
}

repUserAlert(WidgetRef ref, BuildContext context, msg, clickEventIsFor) async {
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  String clickeventIsFor = ref.watch(deviceController).clickeventIsFor;
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.file(Assets.userAlertLottie, width: 150, height: 150),
              const SizedBox(height: 20),
              Text(
                msg,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                },
                child: Text("Cancel",
                    style: TextStyle(
                        color: Theme.of(context).unselectedWidgetColor)),
              ),
              const SizedBox(width: 50),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    side: BorderSide(color: Theme.of(context).cardColor),
                    backgroundColor: Theme.of(context).cardColor),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakePictureScreen(
                          camera: firstCamera,
                          clickeventIsFor: clickeventIsFor),
                    ),
                  );
                },
                child: Text(
                  "OK",
                  style: TextStyle(color: Theme.of(context).canvasColor),
                ),
              ),
            ]),
          ],
        );
      },
    );
  }
}

userAlertWithNoAction(WidgetRef ref, BuildContext context, String msg) async {
  QRViewController? qrViewController = ref
      .read(ref.watch(isSecondTime) ? qrController2 : qrController)
      .qrViewController;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.file(
                Assets.userAlertLottie,
                height: 150,
                width: 150,
              ),
              const SizedBox(height: 15),
              Text(
                'Alert..!',
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(msg, textAlign: TextAlign.center),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    side: BorderSide(color: Theme.of(context).cardColor),
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    if (qrViewController != null) {
                      qrViewController.resumeCamera();
                    }
                  },
                  child: Text(
                    "OK",
                    style: TextStyle(color: Theme.of(context).canvasColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

poleVaultAlert(WidgetRef ref, context, msg) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.file(Assets.userAlertLottie, width: 150, height: 150),
            const SizedBox(height: 20),
            Text(
              msg,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text("Cancel",
                  style: TextStyle(
                      color: Theme.of(context).unselectedWidgetColor)),
            ),
            const SizedBox(width: 40),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  side: BorderSide(color: Theme.of(context).cardColor),
                  backgroundColor: Theme.of(context).cardColor),
              onPressed: () {
                ref.read(deviceController).poleVaultLaunchUrl();
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text(
                "Install",
                style: TextStyle(color: Theme.of(context).canvasColor),
              ),
            ),
          ]),
        ],
      );
    },
  );
}

lampRemoveAlert(WidgetRef ref, BuildContext context, String msg) async {
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  String clickeventIsFor = ref.watch(deviceController).clickeventIsFor;

  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.file(
                  Assets.userAlertLottie,
                  height: 150,
                  width: 150,
                ),
                const SizedBox(height: 15),
                Text(msg, textAlign: TextAlign.center),
              ],
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                    child: Text("Cancel",
                        style: TextStyle(
                            color: Theme.of(context).unselectedWidgetColor)),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      side: BorderSide(
                          color: Theme.of(context).tabBarTheme.indicatorColor!),
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      backgroundColor:
                          Theme.of(context).tabBarTheme.indicatorColor,
                    ),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      ref
                          .read(deviceController)
                          .isLocationFetchingComplete(true);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TakePictureScreen(
                            camera: firstCamera,
                            clickeventIsFor: clickeventIsFor,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "Remove",
                      style: TextStyle(color: Theme.of(context).canvasColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

tokenExpired(context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          icon: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              color: Theme.of(context).primaryColor,
            ),
            width: double.infinity,
            child: Lottie.file(
              Assets.expiredLottie,
              height: 200,
              width: 200,
            ),
          ),
          iconPadding: const EdgeInsets.all(0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              Text(ErrorMessages.sessionExpiredError,
                  textAlign: TextAlign.center),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    side: BorderSide(color: Theme.of(context).cardColor),
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                  onPressed: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(deviceController).emptyLocation();
                    ref.read(deviceController).emptyProjContext();
                    ref.read(loginController).logoutLoadfalse();
                    ref.read(loginController).textFieldUpdate('', true);
                    ref.read(loginController).textFieldUpdate('', false);
                    final secureStorage = SecureStorageService();
                    await secureStorage.clearAllSecuredDetails();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        loginRoute, (Route<dynamic> route) => false);
                  },
                  child: Text(
                    "OK",
                    style: TextStyle(color: Theme.of(context).canvasColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

permissionRequiredAlert(context, msg) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          icon: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              color: Theme.of(context).primaryColor,
            ),
            width: double.infinity,
            child: Lottie.file(
              Assets.expiredLottie,
              height: 200,
              width: 200,
            ),
          ),
          iconPadding: const EdgeInsets.all(0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              Text(msg, textAlign: TextAlign.center),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    side: BorderSide(color: Theme.of(context).cardColor),
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                  onPressed: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    await ph.openAppSettings();
                  },
                  child: Text(
                    "OK",
                    style: TextStyle(color: Theme.of(context).canvasColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<void> updatePopup(BuildContext context, WidgetRef ref, String message,
    Map<String, dynamic> releaseNotesMap) async {
  double width = MediaQuery.of(context).size.width;
  bool _isExpanded = false;

  return await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24.0)),
            ),
            insetPadding: const EdgeInsets.all(8.0),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height / 200),
                  Text(
                    message,
                    softWrap: true,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(5.0),
                      margin: const EdgeInsets.only(left: 3),
                      color: Theme.of(context)
                          .unselectedWidgetColor
                          .withValues(alpha: 0.1),
                      width: width / 1.02,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          expansionTileTheme: ExpansionTileThemeData(
                            collapsedTextColor: Theme.of(context).cardColor,
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                        ),
                        child: ExpansionTile(
                          title: const Text("Release Notes"),
                          onExpansionChanged: (bool expanded) {
                            setState(() => _isExpanded = expanded);
                          },
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Theme.of(context).secondaryHeaderColor,
                                ),
                                children: [
                                  for (String title
                                      in releaseNotesMap.keys) ...[
                                    TextSpan(
                                      text: '$title:\n',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    for (String message
                                        in releaseNotesMap[title]) ...[
                                      WidgetSpan(
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.star,
                                            size: 12,
                                            color: Theme.of(context)
                                                .secondaryHeaderColor,
                                          ),
                                        ),
                                      ),
                                      TextSpan(
                                        text: " " + message + '\n',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                    if (releaseNotesMap.keys.last != title)
                                      const WidgetSpan(
                                        child: SizedBox(height: 25.0),
                                      ),
                                  ]
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Center(
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          ref.read(loginController).launchUrls();
                        },
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Center(
                            child: Text(
                              'Update',
                              style: TextStyle(
                                color: Theme.of(context).canvasColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void showSecurityAlert(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text("Security Breach Detected"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
