import 'dart:math';
import 'dart:developer' as dev;
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/device_page/gw/panel_actions_controller.dart';
import 'package:schnell_luminator/home_page/map_controller.dart';
import 'package:schnell_luminator/qr_scan_online.dart';
import 'package:schnell_luminator/survey/background_connectivity_monitoring.dart';
import 'package:schnell_luminator/utils/animated_glow_card.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:schnell_luminator/utils/session.dart';
import 'package:schnell_luminator/utils/utility.dart';
import 'package:intl/intl.dart';
import '../../ticket_notification/maintenance_ticket_creation.dart';
import '../../ticket_notification/ticket_controller.dart';
import '../../ticket_notification/ticket_details_page.dart';
import '../../ticket_notification/ticket_list_page.dart';
import '../../ticket_notification/ticket_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/asset_folder.dart';
import '../../utils/dialog_box.dart';
import '../../utils/scroll_indicator.dart';
import '../../utils/widgets.dart';
import 'get_live_report.dart';

class GwMaintenance extends ConsumerWidget {
  final bool isFromTickets;
  final bool isFromTicketsList;

  GwMaintenance(
      {super.key, this.isFromTickets = false, this.isFromTicketsList = false});

  final ScrollController scrollViewController = ScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String assetType = ref.watch(deviceController).assetType;
    String relayStatusForPanel = ref.watch(panelController).relayStatusForPanel;
    String commStatusForPanel = ref.watch(panelController).commStatusForPanel;
    bool isMcbTripPanel = ref.watch(panelController).isMcbTripPanel;
    dev.log('ismcb trip : $isMcbTripPanel');
    String ccmsregion = ref.watch(deviceController).ccmsregion;
    String ccmszone = ref.watch(deviceController).ccmszone;
    String ccmsward = ref.watch(deviceController).ccmsward;
    int userProximityRadius = ref.watch(mapController).userProximityRadius;
    String hubregion = ref.watch(deviceController).hubregion;
    String hubward = ref.watch(deviceController).hubward;
    String hubzone = ref.watch(deviceController).hubzone;
    String smslcregion = ref.watch(deviceController).smslcregion;
    String smslcward = ref.watch(deviceController).smslcward;
    String smslczone = ref.watch(deviceController).smslczone;
    String userSelectedDeviceOrAssetName =
        ref.watch(deviceController).userSelectedDeviceOrAssetName;
    final animationController = ref.watch(animationControllerProvider);
    String ccmsAssetName = ref.watch(deviceController).ccmsAssetName;
    String hubName = ref.watch(deviceController).hubName;
    String firstDeviceLable = ref.watch(deviceController).firstDeviceLable;
    final toggleButton = ref.watch(panelController).toggleButton;
    final isWithInUserProximity =
        ref.watch(panelController).isWithInUserProximity;
//If the communication status is 'offline' or 'offline(pf)',disable the button.
    //  If the communication status is 'online' AND
    // `isWithInUserProximity` is false, disable the button.
    final isDisabled = (commStatusForPanel == 'offline' ||
            commStatusForPanel == 'offline(pf)') ||
        (commStatusForPanel == 'online' && !isWithInUserProximity);

    dev.log('is disabled : $isDisabled, $isWithInUserProximity');
    List<Ticket> tickets = ref.watch(ticketController).filteredTickets;
    int fetchedTicketCount = ref.watch(ticketController).fetchedTicketCount;
    dev.log('fetched Ticket Count : $fetchedTicketCount');
    String firstDeviceType = ref.watch(deviceController).firstDeviceType;
    String smslcAssetName = ref.watch(deviceController).smslcAssetName;

    final getLive = panelControlButton(context, onTap: () async {
      commStatusForPanel == 'online'
          ? Utility.isConnected().then((value) async {
              if (value) {
                bool isLocationTrackingRequi =
                    await isLocationTrackingRequired();
                if (isLocationTrackingRequi) {
                  final isLocationServiceOn =
                      await Utility.ensureLocationServiceEnabled();
                  if (!isLocationServiceOn) return; //check if location is on
                }
                EasyLoading.show(
                  status: '',
                  dismissOnTap: false,
                );
                if (context.mounted) {
                  await ref
                      .read(panelController)
                      .fetchTelemetryData(context, ref);
                }
                EasyLoading.dismiss();
                if (context.mounted) {
                  showLiveDataDialog(context);
                }
              } else {
                if (context.mounted) {
                  await snackBar(context, ErrorMessages.offlineErrorTitle,
                      ErrorMessages.offlineErrorMessage);
                }
              }
            })
          : null;
    },
        text: "Get Live",
        width: MediaQuery.of(context).size.width,
        bgcolor: commStatusForPanel == 'online'
            ? Theme.of(context).primaryColor.withValues(alpha: 0.9)
            : Theme.of(context).unselectedWidgetColor,
        borderColor: commStatusForPanel == 'online'
            ? Theme.of(context).primaryColor
            : Theme.of(context).unselectedWidgetColor);

    final mcbReset = panelControlButton(context, onTap: () async {
      isMcbTripPanel && commStatusForPanel == 'online'
          ? Utility.isConnected().then((value) async {
              if (value) {
                bool isLocationTrackingRequi =
                    await isLocationTrackingRequired();
                if (isLocationTrackingRequi) {
                  final isLocationServiceOn =
                      await Utility.ensureLocationServiceEnabled();
                  if (!isLocationServiceOn) return; //check if location is on
                }

                if (context.mounted) {
                  await ref
                      .read(panelController)
                      .panelControl(ref, context, 'mcbReset');
                }
              } else {
                if (context.mounted) {
                  await snackBar(context, ErrorMessages.offlineErrorTitle,
                      ErrorMessages.offlineErrorMessage);
                }
              }
            })
          : null;
    },
        text: "Reset MCB",
        width: MediaQuery.of(context).size.width / 2.3,
        bgcolor: isMcbTripPanel && commStatusForPanel == 'online'
            ? Theme.of(context).primaryColor.withValues(alpha: 0.9)
            : Theme.of(context).unselectedWidgetColor,
        borderColor: isMcbTripPanel && commStatusForPanel == 'online'
            ? Theme.of(context).primaryColor
            : Theme.of(context).unselectedWidgetColor);

    final mcbClear = panelControlButton(context, onTap: () async {
      commStatusForPanel == 'online'
          ? Utility.isConnected().then((value) async {
              if (value) {
                bool isLocationTrackingRequi =
                    await isLocationTrackingRequired();
                if (isLocationTrackingRequi) {
                  final isLocationServiceOn =
                      await Utility.ensureLocationServiceEnabled();
                  if (!isLocationServiceOn) return; //check if location is on
                }

                if (context.mounted) {
                  await ref
                      .read(panelController)
                      .panelControl(ref, context, 'mcbClear');
                }
              } else {
                if (context.mounted) {
                  await snackBar(context, ErrorMessages.offlineErrorTitle,
                      ErrorMessages.offlineErrorMessage);
                }
              }
            })
          : null;
    },
        text: "MCB Trip Count Clear",
        width: MediaQuery.of(context).size.width / 2.3,
        bgcolor: commStatusForPanel == 'online'
            ? Theme.of(context).primaryColor.withValues(alpha: 0.9)
            : Theme.of(context).unselectedWidgetColor,
        borderColor: commStatusForPanel == 'online'
            ? Theme.of(context).primaryColor
            : Theme.of(context).unselectedWidgetColor);

    var qrViewController = ref
        .watch(ref.watch(isSecondTime) ? qrController2 : qrController)
        .qrViewController;
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (qrViewController != null) {
            qrViewController.resumeCamera();
          }
          if (assetType == 'ccms' || assetType == 'smslc') {
            await ref
                .read(ticketController)
                .isTicketsOfSpecificDeviceOrAsset(false);
            if (context.mounted) {
              await ref.read(ticketController).getTicketsBasedOnStatusFB(
                    context,
                    ref,
                    'Pending',
                  );
            }
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
                onPressed: () async {
                  Navigator.pop(context);
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
                  if (assetType == 'ccms' || assetType == 'smslc') {
                    await ref
                        .read(ticketController)
                        .isTicketsOfSpecificDeviceOrAsset(false);

                    if (context.mounted) {
                      await ref
                          .read(ticketController)
                          .getTicketsBasedOnStatusFB(context, ref, 'Pending');
                    }
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
                (firstDeviceType == 'SEMC' || assetType == "smslc")
                    ? 'SMSLC MAINTENANCE'
                    : (assetType == "hub"
                        ? 'HUB MAINTENANCE'
                        : 'CCMS MAINTENANCE'),
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
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton:
                ScrollIndicator(controller: scrollViewController),
            body: ConnectivityBanner(
              child: SingleChildScrollView(
                  controller: scrollViewController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: <Widget>[
                        UsableWidgets.projContextContainerInMaintenace(
                            context,
                            ref,
                            (firstDeviceType == 'GW' ||
                                    (assetType == 'hub' || assetType == 'ccms'))
                                ? (ccmsregion.isNotEmpty
                                    ? ccmsregion
                                    : hubregion)
                                : smslcregion,
                            (firstDeviceType == 'GW' ||
                                    (assetType == 'hub' || assetType == 'ccms'))
                                ? (ccmszone.isNotEmpty ? ccmszone : hubzone)
                                : smslczone,
                            (firstDeviceType == 'GW' ||
                                    (assetType == 'hub' || assetType == 'ccms'))
                                ? (ccmsward.isNotEmpty ? ccmsward : hubward)
                                : smslcward,
                            null),

                        const SizedBox(
                          height: 15,
                        ),
                        //ccms/hub/ smslc Details
                        if (assetType == 'hub' ||
                            assetType == 'ccms' ||
                            firstDeviceType == 'GW')
                          userSelectedDeviceOrAssetName == ccmsAssetName ||
                                  userSelectedDeviceOrAssetName == hubName
                              ? AnimatedBuilder(
                                  animation: animationController,
                                  builder: (conetxt, child) {
                                    return entireCcmsOrHubDetails(ref, context);
                                  })
                              : entireCcmsOrHubDetails(ref, context),
                        if (firstDeviceType == 'SEMC' || assetType == 'smslc')
                          userSelectedDeviceOrAssetName == smslcAssetName
                              ? AnimatedBuilder(
                                  animation: animationController,
                                  builder: (conetxt, child) {
                                    return entireSmslcDetails(ref, context);
                                  })
                              : entireSmslcDetails(ref, context),
                        const SizedBox(
                          height: 18,
                        ),
                        // gw || semc Details
                        userSelectedDeviceOrAssetName == firstDeviceLable
                            ? AnimatedBuilder(
                                animation: animationController,
                                builder: (context, child) {
                                  return entireGwOrSEMCDetails(ref, context);
                                })
                            : entireGwOrSEMCDetails(ref, context),
                        if (assetType == 'ccms' || firstDeviceType == 'GW')
                          const SizedBox(
                            height: 18,
                          ),
                        if (assetType == 'ccms' || firstDeviceType == 'GW')
                          entireEbMeterDetails(ref, context),
                        if ((assetType == 'ccms' || firstDeviceType == 'GW') ||
                            (assetType == 'smslc' || firstDeviceType == 'SEMC'))
                          const SizedBox(
                            height: 25,
                          ),
                        if ((assetType == 'ccms' || firstDeviceType == 'GW') ||
                            (assetType == 'smslc' || firstDeviceType == 'SEMC'))
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              tickets.isNotEmpty
                                  ? Material(
                                      elevation: 10,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 17, horizontal: 3.8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).canvasColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .unselectedWidgetColor
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: tickets.length,
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () async {
                                                if (tickets[index]
                                                            .ticketStatus !=
                                                        'Visited-Closed' &&
                                                    tickets[index]
                                                            .ticketStatus !=
                                                        'Closed' &&
                                                    tickets[index]
                                                            .ticketStatus !=
                                                        'Verified-Closed') {
                                                  if (doesDeviceTypeExist(
                                                      tickets[index]
                                                              .deviceType ??
                                                          '')) {
                                                    ref
                                                        .read(ticketController)
                                                        .resetFieldValues(
                                                            tickets[index]);
                                                    ref
                                                        .read(ticketController)
                                                        .updateSelectedTicket(
                                                            tickets[index]);

                                                    if (context.mounted) {
                                                      // showTicketDetailsDialog(
                                                      //     context, ref);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const TicketDetailsPage()),
                                                      );
                                                    }
                                                  }
                                                } else {
                                                  null;
                                                }
                                              },
                                              child: TicketDetailsCard(
                                                  tickets[index]),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  : Material(
                                      elevation: 10,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 15),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).canvasColor,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .unselectedWidgetColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: SizedBox(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              child: const Center(
                                                child: Text(
                                                  "No Tickets available",
                                                ),
                                              ))),
                                    ),

                              // Top-Right Positioned Container
                              Positioned(
                                top: -20, // Align to top
                                right: -4, // Align to right
                                child: GestureDetector(
                                  onTap: () async {
                                    await ref
                                        .read(ticketController)
                                        .isTicketsOfSpecificDeviceOrAsset(true);
                                    if (context.mounted) {
                                      ref
                                          .read(ticketController)
                                          .loadInitialDetailsOfEntities(
                                              ref, firstDeviceType);
                                    }
                                    if (context.mounted) {
                                      showMaintenanceTicketCreationDialog(
                                          context, ref);
                                    }
                                  },
                                  child: Container(
                                    height: 43,
                                    width: 43,
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Theme.of(context).canvasColor,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(
                          height: 22,
                        ),
                        if ((assetType == 'ccms' && firstDeviceType == 'GW') ||
                            (assetType == 'smslc' && firstDeviceType == 'SEMC'))
                          getLive,
                        if ((assetType == 'ccms' && firstDeviceType == 'GW') ||
                            (assetType == 'smslc' && firstDeviceType == 'SEMC'))
                          const SizedBox(
                            height: 16,
                          ),
                        if ((assetType == 'ccms' && firstDeviceType == 'GW') ||
                            (assetType == 'smslc' && firstDeviceType == 'SEMC'))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [mcbReset, mcbClear],
                          ),
                        if (assetType == 'ccms' || firstDeviceType == 'SEMC')
                          const SizedBox(
                            height: 16,
                          ),
                        if ((assetType == 'ccms' || firstDeviceType == 'GW') ||
                            (assetType == 'smslc' || firstDeviceType == 'SEMC'))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AbsorbPointer(
                                absorbing: isDisabled,
                                child: AnimatedToggleSwitch<bool>.dual(
                                  current: toggleButton,
                                  first: false,
                                  second: true,
                                  spacing: 50.0,
                                  animationDuration:
                                      const Duration(milliseconds: 600),
                                  style: ToggleStyle(
                                    borderColor: isDisabled
                                        ? Colors.grey
                                        : Colors.transparent,
                                    indicatorColor: Colors.white,
                                    indicatorBorderRadius:
                                        const BorderRadius.all(
                                            Radius.circular(100)),
                                    backgroundColor:
                                        isDisabled ? Colors.grey : Colors.amber,
                                  ),
                                  customStyleBuilder:
                                      (context, local, global) => ToggleStyle(
                                    backgroundGradient: isDisabled
                                        ? null // No gradient when disabled
                                        : LinearGradient(
                                            colors: [
                                              Colors.green,
                                              Colors.red[800]!
                                            ],
                                            stops: [
                                              global.position -
                                                  (1 -
                                                          2 *
                                                              max(
                                                                  0,
                                                                  global.position -
                                                                      0.5)) *
                                                      0.5,
                                              global.position +
                                                  max(
                                                          0,
                                                          2 *
                                                              (global.position -
                                                                  0.5)) *
                                                      0.5,
                                            ],
                                          ),
                                  ),
                                  borderWidth: 6.0,
                                  height: 50.0,
                                  loadingIconBuilder: (context, global) =>
                                      CupertinoActivityIndicator(
                                          color: Color.lerp(
                                              Colors.red,
                                              isDisabled
                                                  ? Colors.grey
                                                  : Colors.green,
                                              global.position)),
                                  onChanged: (value) async {
                                    dev.log('onchanged value $value');
                                    final controlType = value ? 'off' : 'on';
                                    dev.log(
                                        'control type onchanged value $controlType');

                                    String apiResponse = await ref
                                        .read(panelController)
                                        .panelControl(
                                            ref, context, controlType);

                                    if (apiResponse == 'success') {
                                      dev.log(apiResponse);
                                      ref
                                          .read(panelController)
                                          .toggleButtonValue(value);
                                      ref
                                          .read(panelController)
                                          .updateRelayStatusForPanel(
                                              controlType);
                                    } else {
                                      dev.log(
                                          'API call failed. Reverting toggle to its previous state.');
                                    }

                                    return Future<dynamic>.delayed(
                                        const Duration(seconds: 2));
                                  },
                                  iconBuilder: (value) => value
                                      ? Icon(Icons.power_outlined,
                                          color: isDisabled
                                              ? Colors.grey
                                              : Colors.green,
                                          size: 32.0)
                                      : Icon(Icons.power_settings_new_rounded,
                                          color: isDisabled
                                              ? Colors.grey
                                              : Colors.red,
                                          size: 32.0),
                                  textBuilder: (value) => Center(
                                    child: Text(
                                      value ? 'On' : 'Off',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 19.0,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 2.3,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: relayStatusForPanel == 'on'
                                        ? Theme.of(context).hintColor // Green
                                        : Theme.of(context)
                                            .tabBarTheme
                                            .indicatorColor!, // Red
                                  ),
                                ),
                                child: Center(
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Status : ',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .secondaryHeaderColor,
                                        fontSize: 14,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text:
                                              relayStatusForPanel.toUpperCase(),
                                          style: TextStyle(
                                            color: relayStatusForPanel == 'on'
                                                ? Theme.of(context)
                                                    .hintColor // Green
                                                : Theme.of(context)
                                                    .tabBarTheme
                                                    .indicatorColor, // Red
                                            fontSize: 17,
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
                        if (assetType == 'ccms' &&
                            !isWithInUserProximity &&
                            commStatusForPanel == 'online' &&
                            firstDeviceType == 'GW')
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 8, bottom: 48),
                            child: Text(
                              'You must be within $userProximityRadius m of the panel to control it.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .tabBarTheme
                                    .indicatorColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // ),
                      ],
                    ),
                  )),
            )),
      ),
    );
  }
}

Widget entireCcmsOrHubDetails(WidgetRef ref, BuildContext context) {
  String assetType = ref.watch(deviceController).assetType;
  String commStatusForPanel = ref.watch(panelController).commStatusForPanel;
  String ccmsInstallBy = ref.watch(deviceController).ccmsInstallBy;
  String hubInstallBy = ref.watch(deviceController).hubInstallBy;
  String ccmsAssetName = ref.watch(deviceController).ccmsAssetName;
  String hubName = ref.watch(deviceController).hubName;
  String hubLandmark = ref.watch(deviceController).hubLandmark;
  String ccmsLandmark = ref.watch(deviceController).ccmsLandmark;
  String ccmsregion = ref.watch(deviceController).ccmsregion;
  String ccmszone = ref.watch(deviceController).ccmszone;
  String ccmsward = ref.watch(deviceController).ccmsward;
  String hubregion = ref.watch(deviceController).hubregion;
  String hubward = ref.watch(deviceController).hubward;
  String hubzone = ref.watch(deviceController).hubzone;
  int firstDevicelastCommunicatedStatus =
      ref.watch(deviceController).firstDevicelastCommunicatedStatus;
  DateTime deviceformEndDate =
      DateTime.fromMillisecondsSinceEpoch(firstDevicelastCommunicatedStatus);
  String deviceLstdate =
      DateFormat('yyyy-MM-dd hh:mm:ss').format(deviceformEndDate);
  int ccmsInstalledOn = ref.watch(deviceController).ccmsInstalledOn;
  DateTime ccmsInstalledformDate =
      DateTime.fromMillisecondsSinceEpoch(ccmsInstalledOn);
  String ccmsInstalledOnDate =
      DateFormat('yyyy-MM-dd hh:mm:ss').format(ccmsInstalledformDate);
  int hubInstallTime = ref.watch(deviceController).hubInstalledOn;
  DateTime hubInstalledformDate =
      DateTime.fromMillisecondsSinceEpoch(hubInstallTime);
  String hubInstalledOnDate =
      DateFormat('yyyy-MM-dd hh:mm:ss').format(hubInstalledformDate);
  String userSelectedDeviceOrAssetName =
      ref.watch(deviceController).userSelectedDeviceOrAssetName;
  final animationController = ref.watch(animationControllerProvider);
  return Material(
    elevation: 10,
    borderRadius: BorderRadius.circular(12),
    child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: userSelectedDeviceOrAssetName == ccmsAssetName ||
                          userSelectedDeviceOrAssetName == hubName
                      ? Theme.of(context).disabledColor
                      : Theme.of(context)
                          .unselectedWidgetColor
                          .withValues(alpha: 0.3),
                  blurRadius: 5,
                  spreadRadius:
                      userSelectedDeviceOrAssetName == ccmsAssetName ||
                              userSelectedDeviceOrAssetName == hubName
                          ? animationController.value * 5
                          : 0)
            ]),
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(children: [
              ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(left: 1.0, top: 12),
                  child: Text(assetType == "hub" ? hubName : ccmsAssetName,
                      style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
                leading: assetType == "hub"
                    ? Image.file(height: 35, width: 35, Assets.hub)
                    : Image.file(height: 35, width: 35, Assets.ccmsPanel),
              ),
              ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(left: 55.0, top: 1),
                  child: UsableWidgets.selectedContextContainer(
                      context,
                      ref,
                      assetType == 'hub'
                          ? '$hubregion > $hubzone > $hubward'
                          : '$ccmsregion > $ccmszone > $ccmsward'),
                ),
                subtitle: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 55.0, top: 12),
                      child: assetType == "hub"
                          ? Text(
                              hubLandmark,
                              style: TextStyle(
                                color: Theme.of(context).cardColor,
                                fontSize: 14,
                              ),
                            )
                          : Text(
                              ccmsLandmark,
                              style: TextStyle(
                                color: Theme.of(context).cardColor,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
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
              Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: deviceLstdate != "1970-01-01 05:30:00"
                        ? RichText(
                            text: TextSpan(
                                text: 'Last Comm ',
                                style: TextStyle(
                                  color: Theme.of(context).secondaryHeaderColor,
                                  fontSize: 12,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: deviceLstdate.toString(),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .secondaryHeaderColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ]),
                          )
                        : Text(
                            "No Communication Yet",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).secondaryHeaderColor),
                          ),
                  ),
                  if (assetType == 'ccms' || assetType == 'smslc')
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 3,
                          right: 5,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(5.0),
                            border: Border.all(
                                color: commStatusForPanel == 'online'
                                    ? Theme.of(context).hintColor
                                    : Theme.of(context)
                                        .tabBarTheme
                                        .indicatorColor!,
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            // mainAxisAlignment: MainAxisAlignment.,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3.0),
                                decoration: BoxDecoration(
                                  color: commStatusForPanel == 'online'
                                      ? Theme.of(context).hintColor
                                      : Theme.of(context)
                                          .tabBarTheme
                                          .indicatorColor!,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              Text(
                                commStatusForPanel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: commStatusForPanel == 'online'
                                      ? Theme.of(context).hintColor
                                      : Theme.of(context)
                                          .tabBarTheme
                                          .indicatorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                        if ((hubInstallBy.isEmpty &&
                                ccmsInstallBy.isNotEmpty) ||
                            (hubInstallBy.isNotEmpty && ccmsInstallBy.isEmpty))
                          Container(
                            width: 170,
                            height: 25,
                            decoration: BoxDecoration(
                                color: Theme.of(context).canvasColor,
                                border: Border.all(
                                    color:
                                        Theme.of(context).secondaryHeaderColor),
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
                                      assetType == "hub"
                                          ? Text(
                                              hubInstallBy,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .secondaryHeaderColor),
                                            )
                                          : Text(
                                              ccmsInstallBy,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .secondaryHeaderColor),
                                            )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (hubInstallTime != 0 || ccmsInstalledOn != 0)
                          Row(children: [
                            Container(
                              width: 120,
                              height: 25,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).canvasColor,
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .secondaryHeaderColor),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 1,
                                  right: 2,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: assetType == "hub"
                                        ? Text(
                                            hubInstalledOnDate,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .secondaryHeaderColor,
                                                fontSize: 10),
                                          )
                                        : Text(
                                            ccmsInstalledOnDate,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .secondaryHeaderColor,
                                                fontSize: 10),
                                          ),
                                  ),
                                ),
                              ),
                            )
                          ]),
                      ]))
            ]))),
  );
}

Widget entireGwOrSEMCDetails(WidgetRef ref, BuildContext context) {
  String firstDeviceLable = ref.watch(deviceController).firstDeviceLable;
  String firstDeviceInstallBy =
      ref.watch(deviceController).firstDeviceInstallBy;
  int deviceInstalledOn = ref.watch(deviceController).deviceInstalledOn;
  DateTime deviceInstalledformDate =
      DateTime.fromMillisecondsSinceEpoch(deviceInstalledOn);
  String deviceDateInstalledOn =
      DateFormat('yyyy-MM-dd hh:mm:ss').format(deviceInstalledformDate);
  String userSelectedDeviceOrAssetName =
      ref.watch(deviceController).userSelectedDeviceOrAssetName;
  final animationController = ref.watch(animationControllerProvider);
  String assetType = ref.read(deviceController).assetType;
  String hubLat = ref.read(deviceController).hubLat;
  String hubLong = ref.read(deviceController).hubLong;
  String ccmsLat = ref.read(deviceController).ccmsLat;
  String ccmsLong = ref.read(deviceController).ccmsLong;
  String smslcLat = ref.read(deviceController).smslcLat;
  String smslcLong = ref.read(deviceController).smslcLong;
  String firstDeviceType = ref.read(deviceController).firstDeviceType;
  dev.log('firstDeviceType: $firstDeviceType');

  final replace = maintenanceActivityButton(
    context,
    onTap: () async {
      if (firstDeviceType == 'GW') {
        ref.read(deviceController).replaceInstallActivityOnTap(
            ref,
            context,
            2,
            "gwReplace",
            assetType == 'ccms' ? ccmsLat : hubLat,
            assetType == 'ccms' ? ccmsLong : hubLong);
      } else {
        ref.read(deviceController).replaceInstallActivityOnTap(
            ref, context, 2, "semcReplace", smslcLat, smslcLong);
      }
    },
    text: firstDeviceType == 'GW' ? "Replace\nGateway" : "Replace\nSEMC",
    bgcolor: darkYellow,
    iccolor: Theme.of(context).canvasColor,
    image: firstDeviceType == 'GW' ? Assets.gateway : Assets.ebMeter,
  );

  return Material(
    elevation: 10,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: userSelectedDeviceOrAssetName == firstDeviceLable
                    ? Theme.of(context).disabledColor
                    : Theme.of(context)
                        .unselectedWidgetColor
                        .withValues(alpha: 0.3),
                blurRadius: 5,
                spreadRadius: userSelectedDeviceOrAssetName == firstDeviceLable
                    ? animationController.value * 5
                    : 0)
          ]),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: firstDeviceLable != ""
            ? Column(
                children: [
                  ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Image.file(
                          height: 35,
                          width: 35,
                          firstDeviceType == 'GW'
                              ? Assets.gateway
                              : Assets.ebMeter),
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
                                    color:
                                        Theme.of(context).secondaryHeaderColor),
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
                                            color: Theme.of(context)
                                                .secondaryHeaderColor),
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
                                        color: Theme.of(context)
                                            .secondaryHeaderColor),
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
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [replace],
                  )
                ],
              )
            : Center(
                child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  (assetType == 'ccms' || assetType == 'hub')
                      ? "No Gateway is Found"
                      : "No SEMC Device is Found",
                ),
              )),
      ),
    ),
  );
}

Widget panelControlButton(BuildContext context,
    {VoidCallback? onTap,
    required String text,
    required width,
    Color? bgcolor,
    required Color borderColor}) {
  return GestureDetector(
    onTap: onTap,
    child: Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
        decoration: BoxDecoration(
          color: bgcolor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

Widget entireEbMeterDetails(WidgetRef ref, BuildContext context) {
  String ebMeterNo = ref.watch(deviceController).ebMeterNo;
  String ebMeterPhase = ref.watch(deviceController).ebMeterPhase;
  String ebMeterReplacedBy = ref.watch(deviceController).ebMeterReplacedBy;
  int ebMeterReplacedOn = ref.watch(deviceController).ebMeterReplacedOn;
  DateTime ebMeterInstalledformDate =
      DateTime.fromMillisecondsSinceEpoch(ebMeterReplacedOn);
  String ebMeterInstalledOnDate =
      DateFormat('yyyy-MM-dd hh:mm:ss').format(ebMeterInstalledformDate);
  String ebMeterReadingOffset =
      ref.watch(deviceController).ebMeterReadingOffset;
  String hubOrCcms = ref.read(deviceController).assetType;
  String hubLat = ref.read(deviceController).hubLat;
  String hubLong = ref.read(deviceController).hubLong;
  String ccmsLat = ref.read(deviceController).ccmsLat;
  String ccmsLong = ref.read(deviceController).ccmsLong;

  final ebMeterReplace = maintenanceActivityButton(
    context,
    onTap: () async {
      ref.read(deviceController).replaceInstallActivityOnTap(
          ref,
          context,
          2,
          "ebMeterReplace",
          hubOrCcms == 'ccms' ? ccmsLat : hubLat,
          hubOrCcms == 'ccms' ? ccmsLong : hubLong);
    },
    text: "Replace\nEB Meter",
    bgcolor: darkYellow,
    iccolor: Theme.of(context).canvasColor,
    image: Assets.ebMeter,
  );
  return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .unselectedWidgetColor
                    .withValues(alpha: 0.3),
                blurRadius: 5,
              )
            ]),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: ebMeterNo.isNotEmpty
              ? Column(
                  children: [
                    ListTile(
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.file(
                          Assets.ebMeter,
                          height: 34,
                          width: 34,
                        ),
                      ),
                      title: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          ebMeterNo,
                          style: TextStyle(
                              color: Theme.of(context).cardColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Divider(
                        color: Theme.of(context)
                            .unselectedWidgetColor
                            .withValues(alpha: 0.35),
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 70, top: 7.0),
                      child: Row(
                        children: [
                          Text(
                            '${ebMeterPhase[0].toUpperCase() + ebMeterPhase.substring(1)} phase',
                            style: TextStyle(
                                color: Theme.of(context).secondaryHeaderColor),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Row(
                            children: [
                              Image.file(
                                Assets.meterReading,
                                height: 20,
                                width: 30,
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              Text(
                                ebMeterReadingOffset.isNotEmpty
                                    ? '$ebMeterReadingOffset kWh'
                                    : '-',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).secondaryHeaderColor),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                          if (ebMeterReplacedBy != "" &&
                              ebMeterReplacedBy.runtimeType == String)
                            Container(
                              width: 170,
                              height: 25,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).canvasColor,
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .secondaryHeaderColor),
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
                                          ebMeterReplacedBy,
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
                          if (ebMeterInstalledOnDate != "1970-01-01 05:30:00")
                            Row(
                              children: [
                                Container(
                                  width: 120,
                                  height: 25,
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).canvasColor,
                                      border: Border.all(
                                          color: Theme.of(context)
                                              .secondaryHeaderColor),
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
                                          ebMeterInstalledOnDate,
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
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [ebMeterReplace],
                    ),
                  ],
                )
              : const Center(
                  child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "No EB Meter is Found",
                  ),
                )),
        ),
      ));
}

Widget entireSmslcDetails(WidgetRef ref, BuildContext context) {
  String assetType = ref.watch(deviceController).assetType;
  String commStatusForPanel = ref.watch(panelController).commStatusForPanel;
  String smslcInstallBy = ref.watch(deviceController).smslcInstallBy;
  String smslcAssetName = ref.watch(deviceController).smslcAssetName;
  String smslcLandmark = ref.watch(deviceController).smslcLandmark;
  String smslcregion = ref.watch(deviceController).smslcregion;
  String smslczone = ref.watch(deviceController).smslczone;
  String smslcward = ref.watch(deviceController).smslcward;
  int firstDevicelastCommunicatedStatus =
      ref.watch(deviceController).firstDevicelastCommunicatedStatus;
  DateTime deviceformEndDate =
      DateTime.fromMillisecondsSinceEpoch(firstDevicelastCommunicatedStatus);
  String deviceLstdate =
      DateFormat('yyyy-MM-dd hh:mm:ss').format(deviceformEndDate);
  int smslcInstalledOn = ref.watch(deviceController).smslcInstalledOn;
  DateTime smslcInstalledformDate =
      DateTime.fromMillisecondsSinceEpoch(smslcInstalledOn);
  String smslcInstalledOnDate =
      DateFormat('yyyy-MM-dd hh:mm:ss').format(smslcInstalledformDate);
  String userSelectedDeviceOrAssetName =
      ref.watch(deviceController).userSelectedDeviceOrAssetName;
  final animationController = ref.watch(animationControllerProvider);
  return Material(
    elevation: 10,
    borderRadius: BorderRadius.circular(12),
    child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: userSelectedDeviceOrAssetName == smslcAssetName
                      ? Theme.of(context).disabledColor
                      : Theme.of(context)
                          .unselectedWidgetColor
                          .withValues(alpha: 0.3),
                  blurRadius: 5,
                  spreadRadius: userSelectedDeviceOrAssetName == smslcAssetName
                      ? animationController.value * 5
                      : 0)
            ]),
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(children: [
              ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(left: 1.0, top: 12),
                  child: Text(smslcAssetName,
                      style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
                leading: Image.file(height: 35, width: 35, Assets.ccmsPanel),
              ),
              ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(left: 55.0, top: 1),
                  child: UsableWidgets.selectedContextContainer(
                      context, ref, '$smslcregion > $smslczone > $smslcward'),
                ),
                subtitle: Column(
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 55.0, top: 12),
                        child: Text(
                          smslcLandmark,
                          style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontSize: 14,
                          ),
                        )),
                  ],
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
              Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: deviceLstdate != "1970-01-01 05:30:00"
                        ? RichText(
                            text: TextSpan(
                                text: 'Last Comm ',
                                style: TextStyle(
                                  color: Theme.of(context).secondaryHeaderColor,
                                  fontSize: 12,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: deviceLstdate.toString(),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .secondaryHeaderColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ]),
                          )
                        : Text(
                            "No Communication Yet",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).secondaryHeaderColor),
                          ),
                  ),
                  if (assetType == 'ccms' || assetType == 'smslc')
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 3,
                          right: 5,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(5.0),
                            border: Border.all(
                                color: commStatusForPanel == 'online'
                                    ? Theme.of(context).hintColor
                                    : Theme.of(context)
                                        .tabBarTheme
                                        .indicatorColor!,
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            // mainAxisAlignment: MainAxisAlignment.,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3.0),
                                decoration: BoxDecoration(
                                  color: commStatusForPanel == 'online'
                                      ? Theme.of(context).hintColor
                                      : Theme.of(context)
                                          .tabBarTheme
                                          .indicatorColor!,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              Text(
                                commStatusForPanel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: commStatusForPanel == 'online'
                                      ? Theme.of(context).hintColor
                                      : Theme.of(context)
                                          .tabBarTheme
                                          .indicatorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                        if (smslcInstallBy.isNotEmpty)
                          Container(
                            width: 170,
                            height: 25,
                            decoration: BoxDecoration(
                                color: Theme.of(context).canvasColor,
                                border: Border.all(
                                    color:
                                        Theme.of(context).secondaryHeaderColor),
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
                                        smslcInstallBy,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .secondaryHeaderColor),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (smslcInstalledOn != 0)
                          Row(children: [
                            Container(
                              width: 120,
                              height: 25,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).canvasColor,
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .secondaryHeaderColor),
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
                                      smslcInstalledOnDate,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .secondaryHeaderColor,
                                          fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ]),
                      ]))
            ]))),
  );
}
