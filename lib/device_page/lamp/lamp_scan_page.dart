import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/home_page/dashboard.dart';
import 'package:schnell_luminator/survey/background_connectivity_monitoring.dart';
import 'package:schnell_luminator/utils/constants.dart';
import '../../pole_install.dart/pole_controller.dart';
import '../../qr_scan_online.dart';
import '../../survey/survey_controller.dart';
import '../../utils/asset_folder.dart';
import '../../utils/dialog_box.dart';
import '../../utils/error_messages.dart';
import '../../utils/utility.dart';
import '../../utils/widgets.dart';
import 'lamp_controller.dart';

class PoleScanPage extends ConsumerStatefulWidget {
  const PoleScanPage({super.key});
  @override
  ConsumerState<PoleScanPage> createState() => PoleScanPageState();
}

class PoleScanPageState extends ConsumerState<PoleScanPage> {
  late TextEditingController surveyPoleNumberController;
  late FocusNode surveyFocusNode;

  @override
  void initState() {
    super.initState();
    surveyPoleNumberController = TextEditingController();
    surveyFocusNode = FocusNode();
  }

  @override
  void dispose() {
    surveyPoleNumberController.dispose();
    surveyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;
    int newLampCount = ref.watch(deviceController).newLampCount;
    List lmpHistoryData = ref.watch(deviceController).lmpHistoryData;
    int lampSpecificUserCount =
        ref.watch(deviceController).lampSpecificUserCount;
    var todaysDate =
        '${DateTime.now().day.toString().length == 1 ? '0${DateTime.now().day.toString()}' : DateTime.now().day.toString()}-${DateTime.now().month.toString().length == 1 ? '0${DateTime.now().month.toString()}' : DateTime.now().month.toString()}-${DateTime.now().year.toString()}';
    final polePrefix = ref.watch(surveyController).surveyPolePrefix;
    log(polePrefix);
    List searchResult = ref.watch(deviceController).deviceSearchList;
    List filteredList =
        searchResult.where((item) => item['type'] == "pole").toList();
    filteredList.sort((a, b) => a["name"].compareTo(b["name"]));
    String selectedWardDesc = ref.watch(deviceController).selectedWardDesc;
    bool showSearchLoading = ref.watch(poleController).showSearchLoading;

    return SafeArea(
        child: WillPopScope(
            onWillPop: () async {
              // Navigator.pop(context);

              ref.read(bottomMenuStateProvider.state).state = 0;
              await Navigator.of(context).pushNamedAndRemoveUntil(
                  homeRoute, (Route<dynamic> route) => false);
              return true;
            },
            child: Scaffold(
                resizeToAvoidBottomInset: true,
                appBar: AppBar(
                  leading: Builder(builder: (BuildContext context) {
                    return IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).cardColor,
                      ),
                      onPressed: () async {
                        ref.read(bottomMenuStateProvider.state).state = 0;
                        await Navigator.of(context).pushNamedAndRemoveUntil(
                            homeRoute, (Route<dynamic> route) => false);
                      },
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
                    "Lamp Summary".toUpperCase(),
                    style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontWeight: FontWeight.w500),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () async {
                        try {
                          log('Hive boxes refreshed before Excel export');
                        } catch (e) {
                          log('Error refreshing Hive boxes before export: $e');
                        }
                        await ref
                            .read(lampController)
                            .showLampExportDialog(context);
                      },
                      tooltip: 'export',
                      icon: const Icon(
                        Icons.file_download,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: ConnectivityBanner(
                  child: SingleChildScrollView(
                      child: Column(children: [
                    const SizedBox(
                      height: 8,
                    ),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          UsableWidgets.projContextContainerInHistory(
                              context,
                              selectedRegion,
                              selectedZone,
                              selectedWard,
                              selectedWardDesc),
                          // Container(
                          //   width: 235,
                          //   margin: const EdgeInsets.only(
                          //       left: 10, right: 5, top: 5, bottom: 5),
                          //   height: 50,
                          //   decoration: BoxDecoration(
                          //       color: Theme.of(context)
                          //           .primaryColor
                          //           .withValues(alpha: 0.5),
                          //       borderRadius: BorderRadius.circular(18)),
                          //   child: Center(
                          //     child: Padding(
                          //       padding: const EdgeInsets.all(6.0),
                          //       child: Align(
                          //         alignment: Alignment.centerLeft,
                          //         child: FittedBox(
                          //           fit: BoxFit.contain,
                          //           child: Row(
                          //               mainAxisAlignment:
                          //                   MainAxisAlignment.start,
                          //               children: [
                          //                 Icon(Icons.location_on_outlined,
                          //                     color:
                          //                         Theme.of(context).cardColor),
                          //                 const SizedBox(
                          //                   width: 5,
                          //                 ),
                          //                 Text(
                          //                   selectedRegion,
                          //                   style: TextStyle(
                          //                       color:
                          //                           Theme.of(context).cardColor,
                          //                       fontWeight: FontWeight.bold),
                          //                 ),
                          //                 Icon(Icons.chevron_right_outlined,
                          //                     color:
                          //                         Theme.of(context).cardColor),
                          //                 Text(
                          //                   selectedZone,
                          //                   style: TextStyle(
                          //                       color:
                          //                           Theme.of(context).cardColor,
                          //                       fontWeight: FontWeight.bold),
                          //                 ),
                          //                 Icon(Icons.chevron_right_outlined,
                          //                     color:
                          //                         Theme.of(context).cardColor),
                          //                 Text(
                          //                   selectedWard,
                          //                   style: TextStyle(
                          //                       color:
                          //                           Theme.of(context).cardColor,
                          //                       fontWeight: FontWeight.bold),
                          //                 )
                          //               ]),
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          Container(
                            width: 60,
                            margin: const EdgeInsets.only(
                                left: 0, right: 5, top: 5, bottom: 5),
                            height: 45,
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.business,
                                      color: Theme.of(context).cardColor,
                                      size: 21,
                                    ),
                                    const SizedBox(
                                      width: 3,
                                    ),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          newLampCount.toString(),
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Theme.of(context).cardColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  ]),
                            ),
                          ),
                          Container(
                            width: 60,
                            margin: const EdgeInsets.only(
                                left: 0, right: 5, top: 5, bottom: 5),
                            height: 45,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_2_outlined,
                                      size: 21,
                                      color: Theme.of(context).cardColor,
                                    ),
                                    const SizedBox(
                                      width: 3,
                                    ),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          lampSpecificUserCount.toString(),
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Theme.of(context).cardColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ),
                    // const SizedBox(
                    //   height: 50,
                    // ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.start,
                    //   children: [
                    //     SizedBox(
                    //       width: MediaQuery.of(context).size.width * 0.11,
                    //     ),
                    //     Text(
                    //       'Lamp Installation History for this user',
                    //       style: TextStyle(
                    //           fontSize: 16,
                    //           color: Theme.of(context).cardColor,
                    //           fontWeight: FontWeight.bold),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(
                      height: 40,
                    ),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width / 1.1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.8),
                          border: Border.all(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.8),
                            width: 1,
                          ),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10)),
                        ),
                        child: Table(
                          border: TableBorder.symmetric(
                            inside: BorderSide(
                              width: 1,
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.19),
                            ),
                          ),
                          children: [
                            TableRow(children: [
                              TableCell(
                                  child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  "Date",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Theme.of(context).cardColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              )),
                              TableCell(
                                  child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  "Lamps",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Theme.of(context).cardColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              )),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width / 1.1,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lmpHistoryData.length,
                        itemBuilder: (context, index) {
                          final myObject = lmpHistoryData[index];
                          final keys = myObject.keys.toList();
                          final values = myObject.values.toList();
                          return Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.19),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .dialogTheme
                                      .backgroundColor!,
                                  width: 0.5,
                                ),
                                borderRadius: index == lmpHistoryData.length - 1
                                    ? const BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10))
                                    : const BorderRadius.only(
                                        bottomLeft: Radius.circular(0),
                                        bottomRight: Radius.circular(0))),
                            child: Table(
                              border: TableBorder.symmetric(
                                  inside: BorderSide(
                                width: 1,
                                color: Theme.of(context)
                                    .dialogTheme
                                    .backgroundColor!,
                              )),
                              children: List<TableRow>.generate(keys.length,
                                  (rowIndex) {
                                final key = keys[rowIndex];
                                final value = values[rowIndex];
                                return TableRow(children: [
                                  TableCell(
                                      child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          key == todaysDate ? "Today" : key,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .secondaryHeaderColor,
                                          ),
                                        )
                                      ],
                                    ),
                                  )),
                                  TableCell(
                                      child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      value.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .secondaryHeaderColor,
                                      ),
                                    ),
                                  )),
                                ]);
                              }),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 57,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: TextField(
                        focusNode: surveyFocusNode,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        controller: surveyPoleNumberController,
                        cursorColor: Theme.of(context).primaryColor,
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          counterText: '',
                          filled: true,
                          fillColor: Colors.transparent,
                          // Theme.of(context).primaryColor.withOpacity(0.3),
                          hintText: ' Search a Pole',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).unselectedWidgetColor,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  polePrefix,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).secondaryHeaderColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'search',
                                icon: Icon(Icons.search,
                                    color: Theme.of(context).primaryColor),
                                onPressed: () async {
                                  FocusScope.of(context).unfocus();
                                  final isConnected =
                                      await Utility.isConnected();
                                  if (isConnected) {
                                    if (surveyPoleNumberController
                                        .text.isEmpty) {
                                      showSnackBar(ref, context,
                                          "Please provide min. 3 characters to search.");
                                      return;
                                    }
                                    ref
                                        .read(poleController)
                                        .toggleSearchLoader(true);
                                    await ref
                                        .read(deviceController)
                                        .clickEventIsFor("poleSearch");
                                    await ref
                                        .read(deviceController)
                                        .deviceListSearch(ref, context,
                                            surveyPoleNumberController.text,
                                            prefixText: polePrefix);
                                    surveyPoleNumberController.text = '';
                                  } else {
                                    await snackBar(
                                      context,
                                      ErrorMessages.offlineErrorTitle,
                                      ErrorMessages.offlineErrorMessage,
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'qr scan',
                                icon: Icon(Icons.qr_code,
                                    color: Theme.of(context).primaryColor),
                                onPressed: () async {
                                  final isConnected =
                                      await Utility.isConnected();

                                  if (isConnected) {
                                    await Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (context) =>
                                          ScanQRWithCustomScreen(
                                        firstOrSecond: 1,
                                        clickEventIsFor: "ScanAPole",
                                      ),
                                    ));
                                  } else {
                                    await snackBar(
                                      context,
                                      ErrorMessages.offlineErrorTitle,
                                      ErrorMessages.offlineErrorMessage,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    searchResult.isNotEmpty
                        ? Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .canvasColor, // subtle background
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredList.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.2),
                              ),
                              itemBuilder: (context, index) {
                                final item = filteredList[index];
                                return InkWell(
                                  onTap: () async {
                                    EasyLoading.dismiss();
                                    await ref
                                        .read(deviceController)
                                        .showSelectedDevice(ref, context,
                                            item['name'], item['type'], '1');
                                    ref
                                        .read(deviceController)
                                        .emptyDeviceSearchList();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    color: Colors.transparent,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 25,
                                          // margin: const EdgeInsets.all(2),
                                          child: Image.file(
                                            Assets.pole,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item['name'] ?? "Unknown",
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : showSearchLoading
                            ? Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: SpinKitRing(
                                  size: 30,
                                  lineWidth: 4,
                                  color: Theme.of(context).primaryColor,
                                ),
                              )
                            : const SizedBox.shrink(),
                  ])),
                ))));
  }
}
