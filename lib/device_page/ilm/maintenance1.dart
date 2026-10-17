import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/device_page/gw/panel_actions_controller.dart';
import 'package:schnell_luminator/qr_scan_online.dart';
import 'package:schnell_luminator/survey/background_connectivity_monitoring.dart';
import 'package:schnell_luminator/ticket_notification/ticket_controller.dart';
import 'package:schnell_luminator/ticket_notification/ticket_list_page.dart';
import 'package:schnell_luminator/utils/animated_glow_card.dart';
import 'package:schnell_luminator/utils/asset_folder.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:schnell_luminator/utils/session.dart';
import 'package:schnell_luminator/utils/utility.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../home_page/map_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';

class IlmMaintenance extends ConsumerWidget {
  final bool isFromTickets;
  final bool isFromTicketsList;
  const IlmMaintenance(
      {super.key, this.isFromTickets = false, this.isFromTicketsList = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String clickeventIsFor = ref.watch(deviceController).clickeventIsFor;
    String userSelectedDeviceOrAssetName =
        ref.watch(deviceController).userSelectedDeviceOrAssetName;
    String firstDeviceLable = ref.watch(deviceController).firstDeviceLable;
    if (clickeventIsFor == "addILM") {
      firstDeviceLable = "";
    }
    String lampName = ref.watch(deviceController).lampName;
    String poleName = ref.watch(deviceController).poleName;
    String lampAssets = ref.watch(deviceController).lampAssets;
    String lpRegion = ref.watch(deviceController).lpregion;
    String lpzone = ref.watch(deviceController).lpzone;
    String lpward = ref.watch(deviceController).lpward;
    String lpLat = ref.read(deviceController).lpLat;
    String lpLong = ref.read(deviceController).lpLong;

    final animationController = ref.watch(animationControllerProvider);
    var qrViewController = ref
        .watch(ref.watch(isSecondTime) ? qrController2 : qrController)
        .qrViewController;
    final addIlm = _addILmButton(
      context,
      onTap: () async {
        ref.read(deviceController).replaceInstallActivityOnTap(
            ref, context, 1, "addILM", lpLat, lpLong);
      },
      text: "Install ILM",
      bgcolor: Theme.of(context).primaryColor,
      iccolor: Theme.of(context).cardColor,
      icon: Icons.add,
    );

    final addLamp = _addILmButton(
      context,
      onTap: () async {
        ref.read(deviceController).replaceInstallActivityOnTap(
            ref, context, 1, "addLampInMaintenance", lpLat, lpLong);
      },
      text: "Install Lamp",
      bgcolor: Theme.of(context).primaryColor,
      iccolor: Theme.of(context).cardColor,
      icon: Icons.add,
    );

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (qrViewController != null) {
            qrViewController.resumeCamera();
          }
          if (isFromTickets && isFromTicketsList) {
            EasyLoading.show(status: 'loading...', dismissOnTap: false);
            await ref
                .read(ticketController)
                .getTicketsBasedOnStatusFB(context, ref, 'Pending')
                .then((value) {
              EasyLoading.dismiss();
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TicketListPage()),
                );
              }
            });
          }
          return true;
        },
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).cardColor,
                ),
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
                "LIGHT MAINTENANCE",
                style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontWeight: FontWeight.w500),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    logoutPop(context, ref);
                  },
                  icon: Icon(
                    Icons.logout_outlined,
                    size: 30,
                    color: Theme.of(context).cardColor,
                  ),
                ),
              ],
            ),
            body: ConnectivityBanner(
              child: SingleChildScrollView(
                child: Column(children: [
                  UsableWidgets.projContextContainerInMaintenace(
                      context, ref, lpRegion, lpzone, lpward, null),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: <Widget>[
                        //LightPoint Details
                        userSelectedDeviceOrAssetName == poleName ||
                                userSelectedDeviceOrAssetName == lampAssets
                            // ? FlickerNeonContainer(
                            //     spreadColor:
                            //         const Color.fromARGB(255, 121, 161, 194),
                            //     borderWidth: 0.5,
                            //     borderRadius: BorderRadius.circular(10),
                            //     lightSpreadRadius: 3,
                            //     lightBlurRadius: 3,
                            //     flickerTimeInMilliSeconds: 1000,
                            ? AnimatedBuilder(
                                animation: animationController,
                                builder: (context, child) {
                                  return entireLpAndPoleDetailsCard(
                                      ref, context);
                                })
                            : entireLpAndPoleDetailsCard(ref, context),
                        const SizedBox(
                          height: 23,
                        ),
                        //Lamp Details
                        if (lampName.isNotEmpty)
                          entireLampDetailsCard(ref, context),

                        if (lampName.isEmpty)
                          Container(
                            // padding: const EdgeInsets.symmetric(vertical: 1),
                            decoration: BoxDecoration(
                                color: Theme.of(context).canvasColor,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Theme.of(context)
                                          .dialogTheme
                                          .backgroundColor!,
                                      blurRadius: 5,
                                      spreadRadius: 5)
                                ]),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: ListTile(
                                  leading: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 0.0, top: 10),
                                    child: Image.file(
                                        height: 30, width: 50, Assets.lamp),
                                  ),
                                  title: addLamp),
                            ),
                          ),
                        const SizedBox(
                          height: 18,
                        ),
                        //ILM Details
                        if (firstDeviceLable == "")
                          Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context).canvasColor,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Theme.of(context)
                                          .dialogTheme
                                          .backgroundColor!,
                                      blurRadius: 5,
                                      spreadRadius: 5)
                                ]),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: ListTile(
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 17.0),
                                    child: Image.file(
                                        height: 30, width: 30, Assets.wifi),
                                  ),
                                  title: addIlm),
                            ),
                          ),
                        if (firstDeviceLable != "")
                          userSelectedDeviceOrAssetName == firstDeviceLable
                              ? AnimatedBuilder(
                                  animation: animationController,
                                  builder: (context, child) {
                                    return entireIlmDetailsCard(ref, context);
                                  })
                              : entireIlmDetailsCard(ref, context)

                        //addIlm
                      ],
                    ),
                  ),
                ]),
              ),
            )),
      ),
    );
  }
}

Widget entireLpAndPoleDetailsCard(WidgetRef ref, BuildContext context) {
  String lpLandmark = ref.watch(deviceController).lpLandmark;
  int firstDevicelastCommunicatedStatus =
      ref.watch(deviceController).firstDevicelastCommunicatedStatus;
  DateTime deviceformEndDate =
      DateTime.fromMillisecondsSinceEpoch(firstDevicelastCommunicatedStatus);
  String deviceLstdate =
      DateFormat('yyyy-MM-dd hh:mm:ss').format(deviceformEndDate);
  String poleWardName = ref.watch(deviceController).poleWardName;
  String poleZoneName = ref.watch(deviceController).poleZoneName;
  String poleRegion = ref.watch(deviceController).poleRegion;
  int lightpointInstalledOn = ref.watch(deviceController).lightpointInstalledOn;
  DateTime lpInstalledformDate =
      DateTime.fromMillisecondsSinceEpoch(lightpointInstalledOn);
  String lpInstalledOn =
      DateFormat('yyyy-MM-dd hh:mm:ss').format(lpInstalledformDate);
  String lpInstallBy = ref.watch(deviceController).lpInstallBy;
  String lpLat = ref.watch(deviceController).lpLat;
  String lpLong = ref.watch(deviceController).lpLong;
  String poleLat = ref.watch(deviceController).poleLat;
  String poleLong = ref.watch(deviceController).poleLong;
  String poleName = ref.watch(deviceController).poleName;
  String destinationLatitude = poleLat.isEmpty ? lpLat : poleLat;
  String destinationLongitude = poleLong.isEmpty ? lpLong : poleLong;
  String userSelectedDeviceOrAssetName =
      ref.watch(deviceController).userSelectedDeviceOrAssetName;
  final animationController = ref.watch(animationControllerProvider);
  String lampAssets = ref.watch(deviceController).lampAssets;

  return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: userSelectedDeviceOrAssetName == poleName ||
                        userSelectedDeviceOrAssetName == lampAssets
                    ? Theme.of(context).disabledColor
                    : Theme.of(context)
                        .unselectedWidgetColor
                        .withValues(alpha: 0.3),
                blurRadius: 5,
                spreadRadius: userSelectedDeviceOrAssetName == poleName ||
                        userSelectedDeviceOrAssetName == lampAssets
                    ? animationController.value * 5
                    : 5)
          ]),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            if (poleName.isNotEmpty)
              ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(left: 1.0, top: 12),
                  child: Text(
                    poleName.toString(),
                    style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                subtitle: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 1.0, top: 12),
                      child: UsableWidgets.selectedContextContainer(context,
                          ref, '$poleRegion > $poleZoneName > $poleWardName'),
                    ),
                  ],
                ),
                leading: Image.file(height: 40, width: 40, Assets.pole),
              ),
            ListTile(
              title: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 1.0, top: 12),
                    child: Text(
                      lpLandmark,
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              leading: Image.file(height: 40, width: 40, Assets.lightpoint),
              trailing: GestureDetector(
                onTap: () async {
                  loc.Location location = loc.Location();
                  loc.LocationData locationData;
                  locationData = await location.getLocation();
                  launchUrl(Uri.parse(
                      "https://www.google.com/maps/dir/?api=1&origin=${locationData.latitude!},${locationData.longitude!}&destination=$destinationLatitude,$destinationLongitude"));
                },
                child: Image.file(height: 45, width: 45, Assets.gMapLocation),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Divider(
                color: Theme.of(context)
                    .unselectedWidgetColor
                    .withValues(alpha: 0.35),
                thickness: 1,
                height: 10,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                deviceLstdate != "1970-01-01 05:30:00"
                    ? RichText(
                        text: TextSpan(
                          text: 'Last Comm at ',
                          style: TextStyle(
                            color: Theme.of(context).secondaryHeaderColor,
                            fontSize: 12,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: deviceLstdate.toString(),
                              style: TextStyle(
                                  color: Theme.of(context).secondaryHeaderColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        "No Communication Yet",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).secondaryHeaderColor),
                      ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Divider(
                color: Theme.of(context)
                    .unselectedWidgetColor
                    .withValues(alpha: 0.35),
                thickness: 1,
                height: 20,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (lpInstallBy != "" && lpInstallBy.runtimeType == String)
                    Container(
                      width: 170,
                      height: 25,
                      decoration: BoxDecoration(
                          color: Theme.of(context).canvasColor,
                          border: Border.all(
                              color: Theme.of(context).secondaryHeaderColor),
                          borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 2,
                          right: 2,
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                Text(
                                  lpInstallBy,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .secondaryHeaderColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (lpInstalledOn != "1970-01-01 05:30:00")
                    Row(
                      children: [
                        Container(
                          width: 120,
                          height: 25,
                          decoration: BoxDecoration(
                              color: Theme.of(context).canvasColor,
                              border: Border.all(
                                  color:
                                      Theme.of(context).secondaryHeaderColor),
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 1,
                              right: 2,
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  lpInstalledOn,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .secondaryHeaderColor),
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
          ],
        ),
      ));
}

Widget entireLampDetailsCard(WidgetRef ref, BuildContext context) {
  String firstDeviceLabel = ref.watch(deviceController).firstDeviceLable;
  String lampName = ref.watch(deviceController).lampName;
  String lpward = ref.watch(deviceController).lpward;
  String poleName = ref.watch(deviceController).poleName;
  String userSelectedDeviceOrAssetName =
      ref.watch(deviceController).userSelectedDeviceOrAssetName;
  final animationController = ref.watch(animationControllerProvider);
  String userProximityRadius =
      ref.read(mapController).userProximityRadius.toString();
  String lpLat = ref.read(deviceController).lpLat;
  String lpLong = ref.read(deviceController).lpLong;

  return AnimatedBuilder(
    animation: animationController,
    builder: (context, child) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: userSelectedDeviceOrAssetName == lampName
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).dialogTheme.backgroundColor!,
              blurRadius: 5,
              spreadRadius: userSelectedDeviceOrAssetName == lampName
                  ? animationController.value * 5
                  : 5,
            ),
          ],
        ),
        height: MediaQuery.of(context).size.height / 2.38,
        width: MediaQuery.of(context).size.width * 1,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const LampCard(),
            Align(
              alignment: const Alignment(1.1, -1.1),
              child: InkWell(
                onTap: () async {
                  Utility.isConnected().then((value) async {
                    if (value) {
                      try {
                        EasyLoading.show(status: '');
                        bool isLocationTrackingRequi =
                            await isLocationTrackingRequired();
                        if (isLocationTrackingRequi) {
                          final isLocationServiceOn =
                              await Utility.ensureLocationServiceEnabled();
                          if (!isLocationServiceOn) {
                            return;
                          } //check if location is on
                        }
                        bool isUserWithInProximity = await ref
                            .read(panelController)
                            .checkUserProximity(ref, lpLat, lpLong);
                        EasyLoading.dismiss();
                        if (!isUserWithInProximity) {
                          wardRequiredAlert(context, ref,
                              'You must be within $userProximityRadius m of the device/asset to control it.');

                          return;
                        }
                        await ref
                            .read(deviceController)
                            .clickEventIsFor("removeLamp");
                        ref.read(deviceController).updateDevicecount(3);

                        if (context.mounted) {
                          await lampRemoveAlert(
                            ref,
                            context,
                            firstDeviceLabel != ''
                                ? ErrorMessages.removeLampWithLuminodeWarning(
                                    lampName: lampName,
                                    deviceLabel: firstDeviceLabel,
                                    poleName: poleName,
                                    ward: lpward)
                                : ErrorMessages.removeLampWarning(
                                    lampName: lampName,
                                    poleName: poleName,
                                    ward: lpward),
                          );
                        }
                      } catch (e) {
                        log(e.toString());
                      }
                    } else {
                      if (context.mounted) {
                        await snackBar(context, ErrorMessages.offlineErrorTitle,
                            ErrorMessages.offlineErrorMessage);
                      }
                    }
                  });
                },
                child: Container(
                  height: 46,
                  width: 46,
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.power_off_rounded,
                        color: Theme.of(context).canvasColor,
                        size: 22,
                      ),
                      Text(
                        "Remove",
                        style: TextStyle(
                          color: Theme.of(context).canvasColor,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget entireIlmDetailsCard(WidgetRef ref, BuildContext context) {
  String clickeventIsFor = ref.watch(deviceController).clickeventIsFor;
  String firstDeviceLable = ref.watch(deviceController).firstDeviceLable;
  if (clickeventIsFor == "addILM") {
    firstDeviceLable = "";
  }
  int deviceInstalledOn = ref.watch(deviceController).deviceInstalledOn;
  DateTime deviceInstalledformDate =
      DateTime.fromMillisecondsSinceEpoch(deviceInstalledOn);
  String deviceDateInstalledOn =
      DateFormat('yyyy-MM-dd hh:mm:ss').format(deviceInstalledformDate);
  String firstDeviceInstallBy =
      ref.watch(deviceController).firstDeviceInstallBy;
  String userSelectedDeviceOrAssetName =
      ref.watch(deviceController).userSelectedDeviceOrAssetName;
  final animationController = ref.watch(animationControllerProvider);
  String lpLat = ref.read(deviceController).lpLat;
  String lpLong = ref.read(deviceController).lpLong;

  final shorting = maintenanceActivityButton(context, onTap: () async {
    ref
        .read(deviceController)
        .removeActivityOnTap(ref, context, "ilmRemove", lpLat, lpLong);
  },
      text: "Shorting\nCap",
      bgcolor: orange,
      iccolor: Theme.of(context).canvasColor,
      image: Assets.shortingCap);

  final replace = maintenanceActivityButton(context, onTap: () async {
    ref.read(deviceController).replaceInstallActivityOnTap(
        ref, context, 2, "ilmReplace", lpLat, lpLong);
  },
      text: "ILM",
      bgcolor: darkYellow,
      iccolor: Theme.of(context).canvasColor,
      image: Assets.ilmDeviceWithBg);

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 5),
    decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: userSelectedDeviceOrAssetName == firstDeviceLable
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).dialogTheme.backgroundColor!,
              blurRadius: 5,
              spreadRadius: userSelectedDeviceOrAssetName == firstDeviceLable
                  ? animationController.value * 5
                  : 5)
        ]),
    child: SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          ListTile(
            leading: Padding(
              padding: const EdgeInsets.only(left: 1.0),
              child: Image.file(height: 45, width: 45, Assets.ilmDeviceWithBg),
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                firstDeviceLable,
                style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (firstDeviceInstallBy != "" &&
                    firstDeviceInstallBy.runtimeType == String)
                  Container(
                    width: 170,
                    height: 25,
                    decoration: BoxDecoration(
                        color: Theme.of(context).canvasColor,
                        border: Border.all(
                            color: Theme.of(context).secondaryHeaderColor),
                        borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 2,
                        right: 2,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [
                              Text(
                                firstDeviceInstallBy,
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).secondaryHeaderColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (deviceDateInstalledOn != "1970-01-01 05:30:00")
                  Row(
                    children: [
                      Container(
                        width: 120,
                        height: 25,
                        decoration: BoxDecoration(
                            color: Theme.of(context).canvasColor,
                            border: Border.all(
                                color: Theme.of(context).secondaryHeaderColor),
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 1,
                            right: 2,
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                deviceDateInstalledOn,
                                style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        Theme.of(context).secondaryHeaderColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                      //
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),

          SizedBox(
            width: 300,
            height: 150,
            child: Center(
              child: Stack(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(
                        left: 40, right: 40, top: 20, bottom: 50),
                    decoration: BoxDecoration(
                        color: Theme.of(context).canvasColor,
                        border: Border.all(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.8),
                        ),
                        borderRadius: BorderRadius.circular(8)),
                  ),

                  Positioned(
                    left: 100,
                    child: Container(
                      width: 100,
                      height: 40,
                      decoration: const ShapeDecoration(
                        shape: RoundedRectangleBorder(),
                        color: Colors.transparent,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            color: Theme.of(context).canvasColor,
                            // .withOpacity(0.8),
                          ),
                          child: Center(
                            child: Text(
                              'Replace With',
                              style: TextStyle(
                                color: Theme.of(context).secondaryHeaderColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(top: 50, left: 1, child: shorting), //Container
                  Positioned(top: 50, right: 1, child: replace), //Container
                ], //<Widget>[]
              ), //Stack
            ), //Center
          ) //SizedBox
        ],
      ),
    ),
  );
}

Widget _addILmButton(BuildContext context,
    {VoidCallback? onTap,
    required String text,
    Color? bgcolor,
    Color? iccolor,
    required IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: SizedBox(
      width: 143,
      child: Material(
        elevation: 5,
        color: bgcolor,
        borderRadius: BorderRadius.circular(10.0),
        child: MaterialButton(
          height: 60,
          onPressed: onTap,
          child: Stack(
              // fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                      color: Theme.of(context).canvasColor, fontSize: 16),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(0),
                      decoration:
                          BoxDecoration(color: iccolor, shape: BoxShape.circle),
                      child: Icon(icon,
                          color: Theme.of(context).canvasColor, size: 30),
                    )
                  ],
                )
              ]),
        ),
      ),
    ),
  );
}

Widget stateContainer(BuildContext context, WidgetRef ref) {
  String lampWatts = ref.watch(deviceController).lampWatts;
  return Column(
    children: [
      if (lampWatts != "")
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Divider(
            color:
                Theme.of(context).unselectedWidgetColor.withValues(alpha: 0.35),
            thickness: 1,
            height: 20,
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(left: 80),
        child: Row(
          children: [
            if (lampWatts != "")
              Icon(
                Icons.light_mode_outlined,
                color: Theme.of(context).secondaryHeaderColor,
              ),
            const SizedBox(
              width: 3,
            ),
            if (lampWatts != "")
              Text(
                '$lampWatts W',
                style: TextStyle(color: Theme.of(context).secondaryHeaderColor),
              ),
          ],
        ),
      ),
      if (lampWatts != "")
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Divider(
            color:
                Theme.of(context).unselectedWidgetColor.withValues(alpha: 0.35),
            thickness: 1,
            height: 20,
          ),
        ),
    ],
  );
}

class LampCard extends ConsumerWidget {
  const LampCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int lampInstalledOn = ref.watch(deviceController).lmpInstalledOn;
    DateTime lmpInstalledformDate =
        DateTime.fromMillisecondsSinceEpoch(lampInstalledOn);
    String lmpInstalledOn =
        DateFormat('yyyy-MM-dd hh:mm:ss').format(lmpInstalledformDate);
    String lampInstallBy = ref.watch(deviceController).lampInstallBy;
    String lampName = ref.watch(deviceController).lampName;
    String firstDeviceLable = ref.watch(deviceController).firstDeviceLable;
    String userSelectedDeviceOrAssetName =
        ref.watch(deviceController).userSelectedDeviceOrAssetName;
    final animationController = ref.watch(animationControllerProvider);
    String lpLat = ref.read(deviceController).lpLat;
    String lpLong = ref.read(deviceController).lpLong;

    final lampOnly = maintenanceActivityButton(context, onTap: () async {
      ref.read(deviceController).replaceInstallActivityOnTap(
          ref, context, 2, "lampOnlyReplace", lpLat, lpLong);
    },
        text: "Lamp",
        bgcolor: darkYellow,
        iccolor: Theme.of(context).canvasColor,
        image: Assets.lamp);

    final lampAndILm = maintenanceActivityButton(context, onTap: () async {
      if (firstDeviceLable != '') {
        await ref.read(deviceController).lampOrILMScanForReplace("lamp");
        ref.read(deviceController).replaceInstallActivityOnTap(
            ref, context, 2, "lamp+ilmReplace", lpLat, lpLong);
      } else {
        null;
      }
    },
        text: "Lamp +\nILM",
        bgcolor: firstDeviceLable == ''
            ? Theme.of(context).unselectedWidgetColor
            : darkYellow,
        iccolor: firstDeviceLable == ''
            ? Colors.transparent.withValues(alpha: 0.3)
            : Theme.of(context).canvasColor,
        // icon: Icons.catching_pokemon,
        image: Assets.lampAndILm);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: userSelectedDeviceOrAssetName == lampName
                    ? Theme.of(context).disabledColor
                    : Theme.of(context)
                        .unselectedWidgetColor
                        .withValues(alpha: 0.3),
                blurRadius: 5,
                spreadRadius: userSelectedDeviceOrAssetName == lampName
                    ? animationController.value * 5
                    : 5)
          ]),
      child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              ListTile(
                leading: Padding(
                  padding: const EdgeInsets.only(left: 5.0, top: 25),
                  child: Image.file(height: 30, width: 50, Assets.lamp),
                ),
                title: Padding(
                  padding: const EdgeInsets.only(right: 30.0, top: 25),
                  child: Text(
                    lampName,
                    style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              stateContainer(context, ref),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (lampInstallBy != "" &&
                        lampInstallBy.runtimeType == String)
                      Container(
                        width: 170,
                        height: 25,
                        decoration: BoxDecoration(
                            color: Theme.of(context).canvasColor,
                            border: Border.all(
                                color: Theme.of(context).secondaryHeaderColor),
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 2,
                            right: 2,
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                children: [
                                  Text(
                                    lampInstallBy,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .secondaryHeaderColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (lmpInstalledOn != "1970-01-01 05:30:00")
                      Row(
                        children: [
                          Container(
                            width: 120,
                            height: 25,
                            decoration: BoxDecoration(
                                color: Theme.of(context).canvasColor,
                                border: Border.all(
                                    color:
                                        Theme.of(context).secondaryHeaderColor),
                                borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 1,
                                right: 2,
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    lmpInstalledOn,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .secondaryHeaderColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          //
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              SizedBox(
                width: 300,
                height: 150,
                child: Center(
                  child: Stack(
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(
                            left: 40, right: 40, top: 20, bottom: 50),
                        decoration: BoxDecoration(
                            color: Theme.of(context).canvasColor,
                            border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.8),
                            ),
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      Positioned(
                        left: 100,
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: const ShapeDecoration(
                            shape: RoundedRectangleBorder(),
                            color: Colors.transparent,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                color: Theme.of(context).canvasColor,
                                // .withOpacity(0.8),
                              ),
                              child: Center(
                                child: Text(
                                  'Replace',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).secondaryHeaderColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(top: 50, left: 1, child: lampAndILm),
                      Positioned(top: 50, right: 1, child: lampOnly),
                    ],
                  ),
                ),
              )
            ],
          )),
    );
  }
}
