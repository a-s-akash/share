import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/attendence_tracking.dart/user_tracking_controller.dart';
import 'package:schnell_luminator/home_page/map_controller.dart';
import 'package:schnell_luminator/home_page/map_page.dart';
import 'package:schnell_luminator/home_page/webview.dart';
import 'package:schnell_luminator/login_page/login_controller.dart';
import 'package:schnell_luminator/qr_scan_online.dart';
import 'package:schnell_luminator/survey/background_connectivity_monitoring.dart';
import 'package:schnell_luminator/ticket_notification/ticket_controller.dart';
import 'package:schnell_luminator/utils/asset_folder.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:schnell_luminator/utils/session.dart';
import 'package:schnell_luminator/utils/utility.dart';
import '../device_page/device_controller.dart';
import '../device_page/device_search.dart';
import '../location_selection/location_controller.dart';
import '../pole_install.dart/pole_installtion_history.dart';
import '../ticket_notification/ticket_list_page.dart';
import '../utils/dialog_box.dart';
import '../utils/session_context_controller.dart';
import 'session_context_sheet.dart';

final bottomMenuStateProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerWidget {
  HomePage({Key? key}) : super(key: key);
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Set only when navigating here right after completing Project
  /// Context selection (Customer > Region > Zone > Ward) — the one
  /// transition that should auto-open the session setup bottom sheet.

  // final List<Widget> body = [
  //   Dashboard(),
  //   const MapPage(),
  // ];
  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return const Dashboard();
      case 1:
        return const MapPage();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var currentPageIndex = ref.watch(bottomMenuStateProvider.state).state;
    String usermail = ref.watch(loginController).userMail;
    String usernmae = usermail.split("@").first.toUpperCase();
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    int selectedBottomNavIndex = ref.watch(bottomMenuStateProvider.state).state;
    String selectedContextId = ref.watch(ticketController).selectedContextId;
    String selectedRegionId = ref.watch(deviceController).selectedRegionId;
    String userMail = ref.read(loginController).userMail;

    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          return showExitPopup(context);
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: currentPageIndex == 1
              ? null
              : AppBar(
                  leading: Builder(builder: (BuildContext context) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: Theme.of(context).cardColor,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    );
                  }),
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.19),
                  elevation: 0.0,
                  centerTitle: true,
                  titleTextStyle: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall!.color,
                    fontSize: 18.0,
                  ),
                  title: Text(
                    selectedBottomNavIndex == 0 ? "HOME" : "MAP",
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  actions: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'search',
                              icon: Icon(Icons.search,
                                  color: Theme.of(context).cardColor),
                              onPressed: () {
                                // if (selectedWard != '') {
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //       builder: (context) => const DeviceSearch()),
                                // );
                                ref
                                    .read(deviceController)
                                    .emptyDeviceSearchList();
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const DeviceSearch()));
                                // } else {
                                //   wardRequiredAlert(context, ref,
                                //       ErrorMessages.wardRequiredAlertMessage);
                                // }
                              },
                            ),
                          ],
                        ),
                      ),
                    ]),
          drawer: customHomeDrawer(
            usernmae,
            usermail,
            context,
            ref,
          ),
          body: ConnectivityBanner(child: _getBody(currentPageIndex)),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
            type: BottomNavigationBarType.fixed,
            currentIndex: ref.read(bottomMenuStateProvider.state).state,
            selectedItemColor: Theme.of(context).cardColor,
            unselectedItemColor: Theme.of(context).unselectedWidgetColor,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (v) async {
              if (ref.watch(internetStatusProvider)) {
                bool isLocationTrackingRequi =
                    await isLocationTrackingRequired();
                if (isLocationTrackingRequi) {
                  //auto logout after 24 hrs
                  bool didAutoLogout = await ref
                      .read(userTrackingController)
                      .autoLogout(context, ref);
                  if (didAutoLogout) return;
                }

                if (v == 1) {
                  if (selectedRegion.isEmpty) {
                    wardRequiredAlert(
                        context, ref, ErrorMessages.regionRequiredAlertMessage);
                    return;
                  }
                  EasyLoading.show(
                    status: '',
                    dismissOnTap: false,
                  );
                  await ref.read(locationController).fetchCurrentLocation();
                  if (context.mounted) {
                    await ref
                        .read(mapController)
                        .getLatLongBasedonWard(ref, context, selectedContextId);
                  }
                  EasyLoading.dismiss();
                  ref.read(mapController).getGeofence(
                      ref, context, userMail, 'region', selectedRegionId);
                  ref.read(mapController).updateChoosenAsset('');
                  ref.read(bottomMenuStateProvider.state).state = v;
                } else {
                  ref.read(bottomMenuStateProvider.state).state = v;
                }
              } else {
                if (context.mounted) {
                  await snackBar(
                    context,
                    ErrorMessages.offlineErrorTitle,
                    ErrorMessages.offlineErrorMessage,
                  );
                }
              }
            },
            items: const [
              BottomNavigationBarItem(
                label: 'Home',
                icon: Icon(Icons.home),
              ),
              BottomNavigationBarItem(label: 'Map', icon: Icon(Icons.map)),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                tooltip: 'qr code',
                heroTag: 'qr_fab',
                backgroundColor: Theme.of(context).cardColor,
                onPressed: () {
                  Utility.isConnected().then((value) async {
                    if (value) {
                      try {
                        bool isLocationTrackingRequi =
                            await isLocationTrackingRequired();
                        if (isLocationTrackingRequi) {
                          //auto logout after 24 hrs
                          bool didAutoLogout = await ref
                              .read(userTrackingController)
                              .autoLogout(context, ref);
                          if (didAutoLogout) return;
                        }
                        final isLocationServiceOn =
                            await Utility.ensureLocationServiceEnabled();
                        if (!isLocationServiceOn) {
                          return;
                        } //check if location is on

                        if (context.mounted) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScanQRWithCustomScreen(
                                    firstOrSecond: 1, clickEventIsFor: "1"),
                              ));
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
                child: const Icon(
                  Icons.qr_code,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> showExitPopup(context) async {
    var bg = Theme.of(context).dialogTheme.backgroundColor;
    return await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: bg,
            content: Container(
              height: 100,
              color: bg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Are you sure you want to exit?",
                    style: TextStyle(
                        color: Theme.of(context).secondaryHeaderColor),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (kDebugMode) {
                              log('yes selected');
                            }
                            exit(0);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).tabBarTheme.indicatorColor),
                          child: Text("Yes",
                              style: TextStyle(
                                  color: Theme.of(context).canvasColor)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                          child: ElevatedButton(
                              onPressed: () {
                                if (kDebugMode) {
                                  log('no selected');
                                }
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .color,
                              ),
                              child: Text("No",
                                  style: TextStyle(
                                    color: Theme.of(context).canvasColor,
                                  ))))
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }
}

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  // Future<void> _initializeBackgroundSync() async {
  //   try {
  //     BackgroundSyncWorkManager.triggerPeriodicSyncTasks();
  //     log('Background sync manager initialized for base survey');
  //   } catch (e) {
  //     log('Failed to initialize background sync manager: $e');
  //   }
  // }

  @override
  void initState() {
    super.initState();

    ref.read(ticketController).loadLocalTicketsCount();
    Utility.isConnected().then((value) async {
      if (value) {
        if (context.mounted) {
          // ref
          //     .read(ticketController)
          //     .getTicketsCountBasedOnStatus(context, ref, 'Pending');
          ref
              .read(ticketController)
              .getTicketsCountBasedOnStatusFB(context, ref, 'Pending');
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String selectedCustomer = ref.watch(deviceController).selectedCustomer;
    String selectedCustomerId = ref.watch(deviceController).selectedCustomerId;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedRegionId = ref.watch(deviceController).selectedRegionId;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedZoneId = ref.watch(deviceController).selectedZoneId;
    String selectedWard = ref.watch(deviceController).selectedWard;
    String selectedWardId = ref.watch(deviceController).selectedWardId;
    String usermail = ref.watch(loginController).userMail;
    String wardId = ref.watch(deviceController).userSelectedWardid;
    int totalTicketsCount = ref.watch(ticketController).totalTicketsCount;
    final sessionContext = ref.watch(sessionContextController);

    return Container(
      color: const Color.fromARGB(255, 238, 238, 238),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2),
            child: SelectedLocationData(
              selectedCustomer: selectedCustomer,
              selectedRegion: selectedRegion,
              selectedZone: selectedZone,
              selectedWard: selectedWard,
            ),
          ),
          Column(children: [
            if (sessionContext.mode != null)
              Padding(
                padding: const EdgeInsets.only(
                    top: 8.0, left: 12, right: 12, bottom: 4),
                child: _SessionContextChip(
                  mode: sessionContext.mode!,
                  vehicleType: sessionContext.vehicleType,
                  vehicleNumber: sessionContext.vehicleNumber,
                  onTap: () =>
                      showSessionContextSheet(context, ref, dismissible: true),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: GestureDetector(
                onTap: () async {
                  bool isLocationTrackingRequi =
                      await isLocationTrackingRequired();
                  if (isLocationTrackingRequi) {
                    bool didAutoLogout = await ref
                        .read(userTrackingController)
                        .autoLogout(context, ref);
                    if (didAutoLogout) return;

                    final isLocationServiceOn =
                        await Utility.ensureLocationServiceEnabled();
                    if (!isLocationServiceOn) {
                      return; //check if location is on
                    }
                  }

                  EasyLoading.show(status: 'loading...', dismissOnTap: false);
                  ref.read(ticketController).updateSearchText('');
                  await ref
                      .read(ticketController)
                      .isTicketsOfSpecificDeviceOrAsset(false);

                  // Offline: skip the server fetch and open the list with
                  // whatever was last loaded — the list/creation screens are
                  // already offline-capable (queue + export), so there's no
                  // reason to block entry the way the old snackbar-block did.
                  if (await Utility.isConnected()) {
                    if (context.mounted) {
                      await ref
                          .read(ticketController)
                          .getTicketsBasedOnStatusFB(context, ref, 'Pending');
                    }
                  }

                  EasyLoading.dismiss();
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TicketListPage()),
                    );
                  }
                },
                child: Card(
                    elevation: 4,
                    shadowColor: Theme.of(context).secondaryHeaderColor,
                    color: Theme.of(context).canvasColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height / 15,
                      width: MediaQuery.of(context).size.width / 1.28,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning,
                                    size: 25, color: Colors.yellow),
                                const SizedBox(width: 15),
                                Text('Tickets',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Theme.of(context).cardColor)),
                                const Spacer(),
                                Text(totalTicketsCount.toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Theme.of(context).cardColor)),
                              ]),
                        ),
                      ),
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (selectedWard != '') {
                        if (context.mounted) {
                          ref.read(deviceController).openOtherApp(
                                ref,
                                context,
                                "com.schnelliot.polevault",
                                selectedCustomerId,
                                selectedRegion,
                                selectedZone,
                                selectedWard,
                                wardId,
                                usermail,
                              );
                        }
                      } else {
                        wardRequiredAlert(context, ref,
                            ErrorMessages.wardRequiredAlertMessage);
                      }
                    },
                    child: Card(
                        elevation: 4,
                        shadowColor: Theme.of(context).secondaryHeaderColor,
                        color: Theme.of(context).canvasColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height / 6,
                          width: MediaQuery.of(context).size.width / 3,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Pole installation',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: Theme.of(context).cardColor)),
                                  Container(
                                    padding: const EdgeInsets.only(top: 10),
                                    height: 90,
                                    width: 90,
                                    child: Image.file(
                                      Assets.poleInstalltransparent,
                                      height: 25,
                                    ),
                                  ),
                                ]),
                          ),
                        )),
                  ),
                  GestureDetector(
                    onTap: () async {
                      Utility.isConnected().then((value) async {
                        if (value) {
                          if (selectedWard != '') {
                            if (context.mounted) {
                              await ref
                                  .read(deviceController)
                                  .lampCount(ref, context, wardId, usermail);
                            }
                          } else {
                            if (context.mounted) {
                              wardRequiredAlert(context, ref,
                                  ErrorMessages.wardRequiredAlertMessage);
                            }
                          }
                        } else {
                          if (context.mounted) {
                            await snackBar(
                                context,
                                ErrorMessages.offlineErrorTitle,
                                ErrorMessages.offlineErrorMessage);
                          }
                        }
                      });
                    },
                    child: Card(
                        elevation: 4,
                        shadowColor: Theme.of(context).secondaryHeaderColor,
                        color: Theme.of(context).canvasColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height / 6,
                          width: MediaQuery.of(context).size.width / 3,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Lamp installation',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: Theme.of(context).cardColor,
                                      )),
                                  Container(
                                    padding: const EdgeInsets.only(top: 10),
                                    height: 90,
                                    width: 90,
                                    child: Image.file(
                                      Assets.lampInstallation,
                                      height: 25,
                                    ),
                                  ),
                                ]),
                          ),
                        )),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (selectedWard != '') {
                        /// Initialize periodic background sync
                        // _initializeBackgroundSync();

                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PoleInstalltionHistoryInfo(),
                            ),
                            (route) => false);

                        // if (context.mounted) {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //         builder: (context) =>
                        //             const BaseSurveyInformation()),
                        //   );
                        // }
                      } else {
                        wardRequiredAlert(context, ref,
                            ErrorMessages.wardRequiredAlertMessage);
                      }
                    },
                    child: Card(
                        elevation: 4,
                        shadowColor: Theme.of(context).secondaryHeaderColor,
                        color: Theme.of(context).canvasColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height / 6,
                          width: MediaQuery.of(context).size.width / 3,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text('Survey',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: Theme.of(context).cardColor)),
                                  Container(
                                    // color: Colors.yellow,
                                    padding: const EdgeInsets.only(top: 0),
                                    height: 55,
                                    width: 80,
                                    child: Image.asset(
                                      'assets/images/survey.png',
                                    ),
                                  ),
                                ]),
                          ),
                        )),
                  ),
                  GestureDetector(
                    onTap: () async {
                      Utility.isConnected().then((value) async {
                        if (value) {
                          if (selectedCustomer != '' &&
                              selectedRegion == '' &&
                              selectedZone == '' &&
                              selectedWard == '') {
                            await ref
                                .read(loginController)
                                .paramsForTheWebViewCustomer(
                                    ref, selectedCustomerId, selectedCustomer);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const WebviewDashboard()),
                              );
                            }
                          } else if (selectedCustomer != '' &&
                              selectedRegion != '' &&
                              selectedZone == '' &&
                              selectedWard == '') {
                            await ref
                                .read(loginController)
                                .paramsForTheWebViewWard(
                                  ref,
                                  selectedRegionId,
                                  selectedRegion,
                                  selectedRegion,
                                );
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const WebviewDashboard()),
                              );
                            }
                          } else if (selectedCustomer != '' &&
                              selectedRegion != '' &&
                              selectedZone != '' &&
                              selectedWard == '') {
                            await ref
                                .read(loginController)
                                .paramsForTheWebViewWard(
                                    ref,
                                    selectedZoneId,
                                    selectedZone,
                                    '$selectedRegion > $selectedZone');
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const WebviewDashboard()),
                              );
                            }
                          } else if (selectedCustomer != '' &&
                              selectedRegion != '' &&
                              selectedZone != '' &&
                              selectedWard != '') {
                            await ref
                                .read(loginController)
                                .paramsForTheWebViewWard(
                                  ref,
                                  selectedWardId,
                                  selectedWard,
                                  '$selectedRegion > $selectedZone > $selectedWard',
                                );
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const WebviewDashboard()),
                              );
                            }
                          }
                        } else {
                          if (context.mounted) {
                            await snackBar(
                                context,
                                ErrorMessages.offlineErrorTitle,
                                ErrorMessages.offlineErrorMessage);
                          }
                        }
                      });
                    },
                    child: Card(
                        elevation: 4,
                        shadowColor: Theme.of(context).secondaryHeaderColor,
                        color: Theme.of(context).canvasColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height / 6,
                          width: MediaQuery.of(context).size.width / 3,
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Dashboard',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: Theme.of(context).cardColor,
                                      )),
                                  Container(
                                    padding: const EdgeInsets.only(top: 0),
                                    height: 90,
                                    width: 70,
                                    child: Image.asset(
                                      'assets/images/dashboard.png',
                                      // height: 25,
                                    ),
                                  ),
                                ]),
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Always-visible two-segment status bar showing the current Operation
/// Mode and Vehicle. Tapping reopens the session setup bottom sheet so
/// the user can review or update their selections.
class _SessionContextChip extends StatelessWidget {
  const _SessionContextChip({
    required this.mode,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.onTap,
  });

  final AppMode mode;
  final String? vehicleType;
  final String? vehicleNumber;
  final VoidCallback onTap;

  Color get _modeColor => mode == AppMode.installation
      ? const Color(0xFF1565C0) // installation — blue
      : const Color(0xFFE65100); // maintenance — orange

  IconData get _modeIcon => mode == AppMode.installation
      ? Icons.build_circle_outlined
      : Icons.handyman_outlined;

  IconData get _vehicleIcon => vehicleType == '4 Wheeler'
      ? Icons.directions_car_outlined
      : Icons.two_wheeler_outlined;

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        Theme.of(context).unselectedWidgetColor.withValues(alpha: 0.25);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Material(
        key: ValueKey('${mode.name}-$vehicleType-$vehicleNumber'),
        color: Theme.of(context).canvasColor,
        elevation: 2,
        shadowColor: Theme.of(context).secondaryHeaderColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _Segment(
                      icon: _modeIcon,
                      color: _modeColor,
                      label: 'MODE',
                      value: mode.label,
                    ),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: dividerColor),
                  Expanded(
                    child: _Segment(
                      icon: _vehicleIcon,
                      color: Theme.of(context).primaryColor,
                      label: 'VEHICLE',
                      value:
                          (vehicleNumber != null && vehicleNumber!.isNotEmpty)
                              ? vehicleNumber!
                              : (vehicleType ?? '-'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Theme.of(context).unselectedWidgetColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Theme.of(context)
                        .secondaryHeaderColor
                        .withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).secondaryHeaderColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
