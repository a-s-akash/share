import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/pole_install.dart/pole_installtion_history.dart';
import 'package:schnell_luminator/ticket_notification/ticket_controller.dart';
import 'package:schnell_luminator/ticket_notification/ticket_list_page.dart';
import 'package:schnell_luminator/utils/asset_folder.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:schnell_luminator/utils/utility.dart';
import '../../home_page/map_controller.dart';
import '../../qr_scan_online.dart';
import '../../survey/background_connectivity_monitoring.dart';
import '../../utils/scroll_indicator.dart';
import '../../utils/widgets.dart';
import '../gw/panel_actions_controller.dart';

class PoleDetails extends ConsumerStatefulWidget {
  final String? navigationPath;
  final bool isFromTickets;
  final bool isFromTicketsList;

  const PoleDetails(
      {super.key,
      this.navigationPath,
      this.isFromTickets = false,
      this.isFromTicketsList = false});
  @override
  ConsumerState<PoleDetails> createState() => _PoleDetailsState();
}

class _PoleDetailsState extends ConsumerState<PoleDetails> {
  final ScrollController scrollViewController = ScrollController();

  @override
  Widget build(BuildContext context) {
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;
    String poleLocation = ref.watch(deviceController).poleLocation;
    int armCount = ref.watch(deviceController).armCount;
    List lampProfiles = ref.watch(deviceController).lampProfiles;
    bool isLedTypeInstallAllowed =
        ref.watch(mapController).isLedTypeInstallAllowed;
    int armCountIndex = 0;
    if (armCount >= 2) {
      armCountIndex = armCount;
    } else {
      armCountIndex = 2;
    }

    // Count LEDs
    final int ledCount = lampProfiles
        .where((e) => (e['type'] ?? '').toString().toUpperCase() == 'LED')
        .length;

// Total profiles count
    final int totalCount = lampProfiles.length;

// Case checks
    final bool isOnlyLED = ledCount == totalCount && totalCount > 0;

    String newRoadCategory = ref.watch(deviceController).newRoadCategory;
    String poleSpNo = ref.watch(deviceController).poleSpNo;
    bool isValidSp = ref.watch(deviceController).isValidSp;

    String poleTransformerNo = ref.watch(deviceController).poleTransformerNo;
    String poleLat = ref.watch(deviceController).poleLat;
    String poleLong = ref.watch(deviceController).poleLong;
    String poleName = ref.watch(deviceController).poleName;
    String poleRegion = ref.watch(deviceController).poleRegion;
    String poleWardName = ref.watch(deviceController).poleWardName;
    String poleZoneName = ref.watch(deviceController).poleZoneName;
    String userProximityRadius =
        ref.read(mapController).userProximityRadius.toString();
    List lampNamesInRelation = ref.watch(deviceController).lampNamesInRelation;
    log('lampNamesInRelation :$lampNamesInRelation');
    List ilmNamesInRelation = ref.watch(deviceController).ilmNamesInRelation;
    List lampLightPointIdInRelation =
        ref.watch(deviceController).lampLightPointIdInRelation;
    List<dynamic> recommendedWattage =
        ref.watch(deviceController).recommendedWattage;
    log('recommendedWattage :$recommendedWattage');
    var qrViewController = ref
        .watch(ref.watch(isSecondTime) ? qrController2 : qrController)
        .qrViewController;
    // installedDataIndex consumed by armDataList pre-computation above
    // Pre-compute arm data indexed by arm position (0..armCountIndex-1).
    // Used by the mixed-pole layout to render arms in a custom order without
    // re-running the sequential installedDataIndex logic inside each loop.
    final List<Map<String, dynamic>> armDataList = [];
    {
      int tempIdx = 0;
      for (int i = 0; i < armCountIndex; i++) {
        String ll = '', il = '', lp = '', br = '';
        int wt = 0;
        String my = '';
        if (tempIdx < lampNamesInRelation.length) {
          ll = lampNamesInRelation[tempIdx].toString();
          il = ilmNamesInRelation[tempIdx].toString();
          lp = lampLightPointIdInRelation[tempIdx].toString();
          tempIdx++;
          if (!ll.contains(poleName) && ll.isNotEmpty && ll.length < 32) {
            final parts = ll.split('-');
            br = {
                  'HA': 'Havells',
                  'SI': 'Signify',
                  'OR': 'Orient',
                  'BA': 'Bajaj',
                  'HI': 'Hitro'
                }[parts[0]] ??
                parts[0];
            wt = int.tryParse(parts[1]) ?? 0;
            my = parts.length > 4 ? parts[4] : '';
          }
        }
        armDataList.add({
          'lampLabel': ll,
          'ilmLabel': il,
          'lampLightPointId': lp,
          'brand': br,
          'wattage': wt,
          'mfgYear': my,
        });
      }
    }

    bool isRecommendedWattageMissing = recommendedWattage.isEmpty ||
        recommendedWattage.any((e) =>
            e['recommended_wattage'] == null || e['recommended_wattage'] == 0);

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (qrViewController != null) {
            qrViewController.resumeCamera();
          }
          // Navigator.of(context).pop();
          if (widget.isFromTickets && widget.isFromTicketsList) {
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
            automaticallyImplyLeading: false,
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.19),
            elevation: 0.0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall!.color,
              fontSize: 18.0,
            ),
            title: Text(
              "POLE MAINTENANCE",
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton:
              ScrollIndicator(controller: scrollViewController),
          body: ConnectivityBanner(
            child: SingleChildScrollView(
              controller: scrollViewController,
              child: Column(children: [
                const SizedBox(
                  height: 3,
                ),
                // if (selectedWard != '')
                UsableWidgets.projContextContainerInMaintenace(
                    context,
                    ref,
                    selectedWard != '' ? selectedRegion : poleRegion,
                    selectedWard != '' ? selectedZone : poleZoneName,
                    selectedWard != '' ? selectedWard : poleWardName,
                    null),

                const SizedBox(
                  height: 18,
                ),
                Column(
                  children: [
                    Center(
                        child: RichText(
                      text: TextSpan(
                        text: 'Pole # ',
                        style: TextStyle(
                          color: Theme.of(context).secondaryHeaderColor,
                          fontSize: 18,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: poleName.toString(),
                            style: TextStyle(
                                color: Theme.of(context).secondaryHeaderColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: InputDecorator(
                        decoration: InputDecoration(
                            label: RichText(
                                text: TextSpan(
                              text: 'Location',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).cardColor,
                                  fontWeight: FontWeight.bold),
                            )),
                            border: const OutlineInputBorder()),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            selectedWard != poleWardName
                                ? FittedBox(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.8),
                                          borderRadius:
                                              BorderRadius.circular(18)),
                                      child: Center(
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 7.5,
                                            ),
                                            Icon(Icons.location_on_outlined,
                                                color: Theme.of(context)
                                                    .canvasColor),
                                            const SizedBox(
                                              width: 7.5,
                                            ),
                                            Text(
                                              '$poleRegion > $poleZoneName > $poleWardName',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .canvasColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(
                                              width: 15,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(),
                            selectedWard != poleWardName
                                ? const SizedBox(
                                    height: 2,
                                  )
                                : Container(),
                            poleLocation != ''
                                ? Text(
                                    poleLocation,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .secondaryHeaderColor,
                                        fontSize: 14),
                                  )
                                : Container(),
                            poleLocation != ''
                                ? const SizedBox(
                                    height: 2,
                                  )
                                : Container(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text(
                                  'Latitude : ',
                                  // textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    poleLat,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text(
                                  'Longitude : ',
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    poleLong,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (newRoadCategory.isNotEmpty)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: Row(
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                    label: RichText(
                                        text: TextSpan(
                                      text: 'Road Category',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context).cardColor,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    border: const OutlineInputBorder()),
                                child: Text(
                                  newRoadCategory,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .secondaryHeaderColor,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                            if (newRoadCategory.isNotEmpty)
                              const SizedBox(
                                width: 10,
                              ),
                            Expanded(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                    label: RichText(
                                        text: TextSpan(
                                      text: 'Arm Count',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context).cardColor,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    border: const OutlineInputBorder()),
                                child: Text(
                                  armCount.toString(),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .secondaryHeaderColor,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // if (newRoadCategory.isNotEmpty)
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Row(
                        children: [
                          if (poleSpNo.isNotEmpty)
                            Expanded(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                    label: RichText(
                                        text: TextSpan(
                                      text: 'Switch Point No',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context).cardColor,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    border: const OutlineInputBorder()),
                                child: Text(
                                  poleSpNo,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .secondaryHeaderColor,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                          const SizedBox(
                            width: 10,
                          ),
                          if (poleTransformerNo.isNotEmpty)
                            Expanded(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                    label: RichText(
                                        text: TextSpan(
                                      text: 'Transformer No',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context).cardColor,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    border: const OutlineInputBorder()),
                                child: Text(
                                  poleTransformerNo,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .secondaryHeaderColor,
                                      fontSize: 14),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (armCount != 0 && lampProfiles.isNotEmpty)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: InputDecorator(
                          decoration: InputDecoration(
                              label: RichText(
                                  text: TextSpan(
                                text: 'Existing Lamp Type',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context).cardColor,
                                    fontWeight: FontWeight.bold),
                              )),
                              border: const OutlineInputBorder()),
                          child: Wrap(
                            runSpacing: 6,
                            spacing: 3,
                            alignment: WrapAlignment.start,
                            direction: Axis.horizontal,
                            children:
                                List.generate(lampProfiles.length, (index) {
                              String lampType = '';
                              String lampWatt = '';
                              if (index < lampProfiles.length) {
                                lampType =
                                    lampProfiles[index]['type'].toString();
                                lampWatt =
                                    lampProfiles[index]['watts'].toString();
                              }
                              return _buildBubble(
                                  context, "$lampType-$lampWatt W");
                            }),
                          ),
                        ),
                      ),
                    if (armCount != 0 && lampProfiles.isNotEmpty)
                      const SizedBox(
                        height: 20,
                      ),
                    if (armCount != 0 && isRecommendedWattageMissing)
                      const Padding(
                        padding:
                            EdgeInsets.only(left: 20, right: 20, bottom: 10),
                        child: Text(
                          "No recommended wattage has been configured for the Pole with the existing lamp.",
                          style: TextStyle(
                              fontSize: 11.0,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    Builder(builder: (context) {
                      final filteredRecommended = armCount != 0
                          ? recommendedWattage.where((e) {
                              final watt = e['recommended_wattage'];
                              return watt != null && watt != 0;
                            }).fold<List<Map<String, dynamic>>>(
                              [],
                              (unique, e) {
                                final key =
                                    '${e['type']}_${e['recommended_wattage']}';
                                if (!unique.any((u) =>
                                    '${u['type']}_${u['recommended_wattage']}' ==
                                    key)) {
                                  unique
                                      .add(Map<String, dynamic>.from(e as Map));
                                }
                                return unique;
                              },
                            ).toList()
                          : <Map<String, dynamic>>[];

                      if (filteredRecommended.isEmpty) return const SizedBox();

                      return SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: InputDecorator(
                          decoration: InputDecoration(
                              label: RichText(
                                  text: TextSpan(
                                text: 'Recommended Lamp Type',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context).cardColor,
                                    fontWeight: FontWeight.bold),
                              )),
                              border: const OutlineInputBorder()),
                          child: Wrap(
                            runSpacing: 6,
                            spacing: 3,
                            alignment: WrapAlignment.start,
                            direction: Axis.horizontal,
                            children: filteredRecommended.map((e) {
                              final recommLampType =
                                  e['type']?.toString() ?? '';
                              final recommLampWatt =
                                  (e['recommended_wattage'] as int?) ?? 0;
                              return _buildBubble(
                                  context, "$recommLampType-$recommLampWatt W");
                            }).toList(),
                          ),
                        ),
                      );
                    }),
                    if (selectedWard == poleWardName)
                      const SizedBox(
                        height: 20,
                      ),
                    if (selectedWard != poleWardName)
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          margin: const EdgeInsets.only(bottom: 20, top: 20),
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.red,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Colors.red,
                                size: 24.0,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedWard != ''
                                      ? 'The selected project and location of the pole are different. Please select the correct project and try again.'
                                      : "Please select the project /Region to proceed.",
                                  style: const TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    isValidSp
                        ? (ledCount > 0 && !isLedTypeInstallAllowed
                            ? _buildMixedPoleArmSection(
                                context: context,
                                armDataList: armDataList,
                                armCountIndex: armCountIndex,
                                ledCount: ledCount,
                                isOnlyLED: isOnlyLED,
                                poleLat: poleLat,
                                poleLong: poleLong,
                                selectedWard: selectedWard,
                                poleWardName: poleWardName,
                                userProximityRadius: userProximityRadius,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: List.generate(armCountIndex, (index) {
                                  return _buildArmCard(
                                    context: context,
                                    disableForThisIndex: false,
                                    data: armDataList[index],
                                    selectedWard: selectedWard,
                                    poleWardName: poleWardName,
                                    poleLat: poleLat,
                                    poleLong: poleLong,
                                    userProximityRadius: userProximityRadius,
                                  );
                                }),
                              ))
                        : Column(children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              margin:
                                  const EdgeInsets.only(bottom: 30, top: 20),
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.warning,
                                    color: Colors.red,
                                    size: 24.0,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                        text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 15.0,
                                              color: Colors.black,
                                            ),
                                            children: [
                                          const TextSpan(text: "SP No. "),
                                          TextSpan(
                                              text: poleSpNo,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const TextSpan(text: " not surveyed"),
                                          const TextSpan(
                                              text:
                                                  "\nComplete survey before lamp installation."),
                                        ])),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const PoleInstalltionHistoryInfo()));
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width / 1.15,
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(248, 75, 129, 163),
                                    borderRadius: BorderRadius.circular(50.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .unselectedWidgetColor,
                                        offset: const Offset(3.0, 4.0),
                                        blurRadius: 6.0,
                                      ),
                                    ]),
                                child: Center(
                                  child: Text(
                                    'Re-Survey',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).canvasColor),
                                  ),
                                ),
                              ),
                            )
                          ]),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ─── arm card (shared by both regular and mixed-pole layouts) ───────────────
  Widget _buildArmCard({
    required BuildContext context,
    required bool disableForThisIndex,
    required Map<String, dynamic> data,
    required String selectedWard,
    required String poleWardName,
    required String poleLat,
    required String poleLong,
    required String userProximityRadius,
  }) {
    final String lampLabel = data['lampLabel'].toString();
    final String ilmLabel = data['ilmLabel'].toString();
    final String lampLightPointId = data['lampLightPointId'].toString();
    final String brand = data['brand'].toString();
    final int wattage = data['wattage'] as int;
    final String mfgYear = data['mfgYear'].toString();

    return Container(
      padding: const EdgeInsets.all(7.0),
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border.all(color: Theme.of(context).primaryColor, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lampLabel.isNotEmpty)
            Text(
              'Installed Lamp',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          lampLabel.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    selectedWard == poleWardName
                        ? Utility.isConnected().then((value) async {
                            if (value) {
                              ref
                                  .read(deviceController)
                                  .userSelectedDeviceOrAsset(lampLabel);
                              if (context.mounted) {
                                await ref
                                    .read(deviceController)
                                    .installedLampNavigation(
                                        ref, context, lampLabel, 1, '1');
                              }
                            } else {
                              if (context.mounted) {
                                await snackBar(
                                    context,
                                    ErrorMessages.offlineErrorTitle,
                                    ErrorMessages.offlineErrorMessage);
                              }
                            }
                          })
                        : null;
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 1.15,
                    margin: const EdgeInsets.only(top: 5, bottom: 15.0),
                    padding: const EdgeInsets.only(
                        top: 5.0, bottom: 5.0, left: 3, right: 0),
                    decoration: BoxDecoration(
                      color: selectedWard == poleWardName
                          ? Theme.of(context).canvasColor
                          : Theme.of(context).unselectedWidgetColor,
                      borderRadius: BorderRadius.circular(5.0),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).unselectedWidgetColor,
                          offset: const Offset(3.0, 4.0),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(height: 42, width: 42, Assets.lamp),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRichText('Lamp ID:', ' $lampLabel'),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  if (wattage != 0)
                                    _buildRichText('Wattage:', ' ${wattage}W'),
                                  if (brand.isNotEmpty)
                                    const SizedBox(width: 14),
                                  if (mfgYear.isNotEmpty)
                                    _buildRichText('Mfg Year:', ' $mfgYear'),
                                ],
                              ),
                              const SizedBox(height: 5),
                              if (brand.isNotEmpty)
                                _buildRichText('Brand:', ' $brand'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: disableForThisIndex
                      ? null
                      : () {
                          selectedWard == poleWardName
                              ? Utility.isConnected().then((value) async {
                                  if (value) {
                                    EasyLoading.show(status: '');
                                    try {
                                      final isLocationServiceOn = await Utility
                                          .ensureLocationServiceEnabled();
                                      if (!isLocationServiceOn) return;
                                      bool isUserWithInProximity = await ref
                                          .read(panelController)
                                          .checkUserProximity(
                                              ref, poleLat, poleLong);
                                      EasyLoading.dismiss();
                                      if (!isUserWithInProximity) {
                                        wardRequiredAlert(context, ref,
                                            'You must be within $userProximityRadius m of the device/asset to control it.');
                                        return;
                                      }
                                      await ref
                                          .read(deviceController)
                                          .clickEventIsFor('addLamp');
                                      ref
                                          .read(deviceController)
                                          .setLampLightPointId(
                                              lampLightPointId);
                                      if (context.mounted) {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ScanQRWithCustomScreen(
                                                    firstOrSecond: 1,
                                                    clickEventIsFor: 'addLamp'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      log(e.toString());
                                    }
                                  } else {
                                    EasyLoading.dismiss();
                                    if (context.mounted) {
                                      await snackBar(
                                          context,
                                          ErrorMessages.offlineErrorTitle,
                                          ErrorMessages.offlineErrorMessage);
                                    }
                                  }
                                })
                              : null;
                        },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 1.15,
                    margin: const EdgeInsets.only(top: 4, bottom: 15.0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: disableForThisIndex
                          ? Theme.of(context).unselectedWidgetColor
                          : selectedWard == poleWardName
                              ? const Color.fromARGB(248, 75, 129, 163)
                              : Theme.of(context).unselectedWidgetColor,
                      borderRadius: BorderRadius.circular(50.0),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).unselectedWidgetColor,
                          offset: const Offset(3.0, 4.0),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Image.file(height: 28, width: 28, Assets.lamp),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Add Lamp',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).canvasColor),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Icon(Icons.qr_code_outlined,
                              size: 25, color: Theme.of(context).canvasColor),
                        ),
                      ],
                    ),
                  ),
                ),
          if (ilmLabel.isNotEmpty)
            Text(
              'Installed ILM',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ilmLabel.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    selectedWard == poleWardName
                        ? Utility.isConnected().then((value) async {
                            if (value) {
                              ref
                                  .read(deviceController)
                                  .userSelectedDeviceOrAsset(ilmLabel);
                              if (context.mounted) {
                                await ref
                                    .read(deviceController)
                                    .installedLampNavigation(
                                        ref, context, ilmLabel, 1, '1');
                              }
                            } else {
                              if (context.mounted) {
                                await snackBar(
                                    context,
                                    ErrorMessages.offlineErrorTitle,
                                    ErrorMessages.offlineErrorMessage);
                              }
                            }
                          })
                        : null;
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 1.0,
                    padding: const EdgeInsets.all(5.0),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: selectedWard == poleWardName
                          ? Theme.of(context).canvasColor
                          : Theme.of(context).unselectedWidgetColor,
                      borderRadius: BorderRadius.circular(5.0),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).unselectedWidgetColor,
                          offset: const Offset(3.0, 4.0),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                              height: 42, width: 42, Assets.ilmDeviceWithoutBg),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRichText('ILM Installed:', ' Yes'),
                              const SizedBox(height: 5),
                              _buildRichText('ILM ID:', ' $ilmLabel'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: disableForThisIndex
                      ? null
                      : () {
                          selectedWard == poleWardName
                              ? Utility.isConnected().then((value) async {
                                  if (value) {
                                    ref
                                        .read(deviceController)
                                        .setLampLightPointId(lampLightPointId);
                                    if (lampLabel.isNotEmpty) {
                                      await ref
                                          .read(deviceController)
                                          .clickEventIsFor('addILMViaPole');
                                      if (context.mounted) {
                                        await ref
                                            .read(deviceController)
                                            .scanDevice(ref, context, 1,
                                                'addILMViaPole');
                                        if (context.mounted) {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ScanQRWithCustomScreen(
                                                      firstOrSecond: 1,
                                                      clickEventIsFor:
                                                          'addILMViaPole'),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      EasyLoading.show(status: '');
                                      final isLocationServiceOn = await Utility
                                          .ensureLocationServiceEnabled();
                                      if (!isLocationServiceOn) return;
                                      bool isUserWithInProximity = await ref
                                          .read(panelController)
                                          .checkUserProximity(
                                              ref, poleLat, poleLong);
                                      EasyLoading.dismiss();
                                      if (!isUserWithInProximity) {
                                        wardRequiredAlert(context, ref,
                                            'You must be within $userProximityRadius m of the device/asset to control it.');
                                        return;
                                      }
                                      if (context.mounted) {
                                        await addIlmWarningPopup(
                                            ref,
                                            context,
                                            ErrorMessages
                                                .lampIdGenerationWarning);
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
                                })
                              : null;
                        },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 1.15,
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: disableForThisIndex
                          ? Theme.of(context).unselectedWidgetColor
                          : selectedWard == poleWardName
                              ? const Color.fromARGB(248, 75, 129, 163)
                              : Theme.of(context).unselectedWidgetColor,
                      borderRadius: BorderRadius.circular(50.0),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).unselectedWidgetColor,
                          offset: const Offset(3.0, 4.0),
                          blurRadius: 6.0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Image.file(
                              height: 28, width: 28, Assets.ilmDeviceWithoutBg),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Add ILM',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).canvasColor),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Icon(Icons.qr_code_outlined,
                              size: 25, color: Theme.of(context).canvasColor),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ─── mixed-pole layout ────────────────────────────────────────────────────
  Widget _buildMixedPoleArmSection({
    required BuildContext context,
    required List<Map<String, dynamic>> armDataList,
    required int armCountIndex,
    required int ledCount,
    required bool isOnlyLED,
    required String poleLat,
    required String poleLong,
    required String selectedWard,
    required String poleWardName,
    required String userProximityRadius,
  }) {
    // For only-LED poles the non-LED section is empty; all arm slots are LED.
    // For mixed poles, indices ledCount..armCountIndex-1 are non-LED/extra arms.
    final nonLedWidgets = <Widget>[
      if (!isOnlyLED)
        for (int i = ledCount; i < armCountIndex; i++)
          _buildArmCard(
            context: context,
            disableForThisIndex: false,
            data: armDataList[i],
            selectedWard: selectedWard,
            poleWardName: poleWardName,
            poleLat: poleLat,
            poleLong: poleLong,
            userProximityRadius: userProximityRadius,
          ),
    ];

    // Only-LED: show a slot for every arm (armCountIndex).
    // Mixed: show one slot per LED profile (ledCount).
    final int ledSlotCount = isOnlyLED ? armCountIndex : ledCount;

    final ledWidgets = <Widget>[
      for (int i = 0; i < ledSlotCount; i++)
        armDataList[i]['lampLabel'].toString().isEmpty
            ? _buildReplaceLampButton(context, poleLat, poleLong)
            : _buildArmCard(
                context: context,
                disableForThisIndex: false,
                data: armDataList[i],
                selectedWard: selectedWard,
                poleWardName: poleWardName,
                poleLat: poleLat,
                poleLong: poleLong,
                userProximityRadius: userProximityRadius,
              ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...nonLedWidgets,
        if (nonLedWidgets.isNotEmpty) const SizedBox(height: 4),
        _buildMixedLedWarning(context, poleLat, poleLong),
        ...ledWidgets,
      ],
    );
  }

  Widget _buildMixedLedWarning(
      BuildContext context, String poleLat, String poleLong) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.only(bottom: 16, top: 12),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24.0),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Conversion Blocked: Already Flagged as LED',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Lamps on this pole/arm do not require conversion.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          _bulletRow('To fix an incorrect survey:', 'Tap "Re-Survey"'),
          const SizedBox(height: 4),
          _bulletRow(
              'To perform standard maintenance:', 'Tap "Replace Lamp" below'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PoleInstalltionHistoryInfo()),
            ),
            child: Center(
              child: Container(
                width: 130,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(248, 75, 129, 163),
                  borderRadius: BorderRadius.circular(50.0),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).unselectedWidgetColor,
                      offset: const Offset(3.0, 4.0),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Re-Survey',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplaceLampButton(
      BuildContext context, String poleLat, String poleLong) {
    return Container(
      padding: const EdgeInsets.all(7.0),
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: Border.all(color: Theme.of(context).primaryColor, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: GestureDetector(
        onTap: () => ref.read(deviceController).replaceInstallActivityOnTap(
            ref, context, 1, 'addLamp', poleLat, poleLong),
        child: Container(
          width: MediaQuery.of(context).size.width / 1.15,
          margin: const EdgeInsets.only(top: 4, bottom: 15.0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(248, 75, 129, 163),
            borderRadius: BorderRadius.circular(50.0),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).unselectedWidgetColor,
                offset: const Offset(3.0, 4.0),
                blurRadius: 6.0,
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Image.file(height: 28, width: 28, Assets.lamp),
              ),
              const SizedBox(width: 10),
              Text(
                'Replace Lamp',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).canvasColor,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Icon(Icons.qr_code_outlined,
                    size: 25, color: Theme.of(context).canvasColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulletRow(String label, String action) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 14)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: action),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildBubble(BuildContext context, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
    decoration: BoxDecoration(
      color: Theme.of(context).dialogTheme.backgroundColor,
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(
          color: const Color.fromARGB(248, 75, 129, 163).withValues(alpha: 0.5),
          width: 1),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).secondaryHeaderColor,
      ),
    ),
  );
}

Widget _buildRichText(String label, String value) {
  return RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
        TextSpan(
          text: value,
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: label == 'Lamp ID:' ? 14 : 13,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}
