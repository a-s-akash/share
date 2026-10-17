import 'dart:developer';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/location_selection/region_list.dart';
import 'package:schnell_luminator/login_page/login_controller.dart';
import 'package:schnell_luminator/survey/screens/survey_take_photo.dart';
import 'package:schnell_luminator/ticket_notification/ticket_controller.dart';
import '../location_selection/ward_list.dart';
import '../location_selection/zone_list.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../utils/app_theme.dart';
import '../utils/dropdown_options.dart';
import '../utils/utility.dart';

const priority = [
  'Priority',
  'Critical',
  'Major',
  'Minor',
  'Warning',
  'Indeterminate'
];

Future<void> showTicketCreationDialog(
  context,
  WidgetRef ref,
) async {
  await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24.0))),
            insetPadding: const EdgeInsets.all(8.0),
            backgroundColor: Theme.of(context).canvasColor,
            content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.80,
                width: MediaQuery.of(context).size.width * 0.80,
                child: const TicketCreation()));
      });
  ref.read(ticketController).clearTicketRelatedValues();
}

class TicketCreation extends ConsumerWidget {
  const TicketCreation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextEditingController locationTextController =
        ref.watch(ticketController).locController;
    TextEditingController autoCompletecontroller =
        ref.watch(ticketController).autoCompletecontroller;
    TextEditingController creationCommentsController =
        ref.watch(ticketController).creationCommentsController;

    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;
    String deviceZone = ref.watch(ticketController).deviceZone;
    String deviceRegion = ref.watch(ticketController).deviceRegion;
    String deviceWard = ref.watch(ticketController).deviceWard;
    String usermail = ref.watch(loginController).userMail;
    String selectedProblemType =
        ref.watch(ticketController).selectedProblemType;
    String enteredTicketCreationComments =
        ref.watch(ticketController).enteredTicketCreationComments;
    String deviceOrAssetType = ref.read(ticketController).deviceOrAssetType;
    bool isOnline = ref.watch(internetStatusProvider);
    String resolvedOfflineDeviceType = offlineDeviceTypeOptions
            .any((option) => option['value'] == deviceOrAssetType)
        ? deviceOrAssetType
        : 'others';
    //bool showAsterisk = ref.watch(ticketController).showAsterisk;

    bool isRegionChoosen = selectedRegion != '' || deviceRegion != '';

    bool validateMandatoryFields() {
      final bool isDeviceTypeValid = deviceOrAssetType != 'Device/Asset Type*';
      final bool isProblemTypeValid = selectedProblemType != 'Problem Type*';
      final bool isAutoCompleteValid = deviceOrAssetType != 'others'
          ? autoCompletecontroller.text.isNotEmpty
          : true;
      final bool isCommentValid =
          selectedProblemType != 'Others' && deviceOrAssetType != 'others'
              ? true
              : enteredTicketCreationComments.isNotEmpty;

      return isDeviceTypeValid &&
          isProblemTypeValid &&
          isAutoCompleteValid &&
          isCommentValid;
    }

    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;
    String username = usermail.split("@").first.toUpperCase();

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              children: [
                const SizedBox(width: 24),
                Expanded(
                  child: Center(
                    child: Text(
                      "Ticket Creation",
                      style: TextStyle(color: Theme.of(context).cardColor),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).tabBarTheme.indicatorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              color: Theme.of(context).dialogTheme.backgroundColor,
              thickness: 0.5),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    showRegionDialog(context, ref);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    height: 35,
                    width: deviceWidth * 0.25,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.5),
                        border: Border.all(
                            width: 2,
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.8))),
                    child: Center(
                      child: AutoSizeText(
                        deviceRegion.isEmpty
                            ? selectedRegion == ''
                                ? 'All Regions'
                                : selectedRegion
                            : deviceRegion,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).cardColor,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (selectedRegion != '') {
                      showZoneSelectDialog(context, ref);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    height: 35,
                    width: deviceWidth * 0.25,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: selectedRegion != ''
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.5)
                            : Theme.of(context).dialogTheme.backgroundColor,
                        border: Border.all(
                            width: 2,
                            color: selectedRegion != ''
                                ? Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.8)
                                : Theme.of(context)
                                    .dialogTheme
                                    .backgroundColor!
                                    .withValues(alpha: 0.8))),
                    child: Center(
                      child: AutoSizeText(
                        deviceZone.isEmpty
                            ? selectedZone == ''
                                ? 'All Zones'
                                : selectedZone
                            : deviceZone,
                        style: TextStyle(
                            fontSize: 12,
                            color: selectedRegion != ''
                                ? Theme.of(context).cardColor
                                : Theme.of(context).hoverColor,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (selectedZone != '') {
                      showWardSelectDialog(context, ref);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    height: 35,
                    width: deviceWidth * 0.25,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: selectedZone != ''
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.5)
                            : Theme.of(context).dialogTheme.backgroundColor,
                        border: Border.all(
                            width: 2,
                            color: selectedZone != ''
                                ? Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.8)
                                : Theme.of(context)
                                    .dialogTheme
                                    .backgroundColor!
                                    .withValues(alpha: 0.8))),
                    child: Center(
                      child: AutoSizeText(
                        deviceWard.isEmpty
                            ? selectedWard == ''
                                ? 'All Wards'
                                : selectedWard
                            : deviceWard,
                        style: TextStyle(
                            fontSize: 12,
                            color: selectedZone != ''
                                ? Theme.of(context).cardColor
                                : Theme.of(context).hoverColor,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: Divider(
                color: Theme.of(context).dialogTheme.backgroundColor,
                thickness: 0.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // selectedDeviceType != 'others' &&
              //         selectedDeviceType != 'Device/Asset Type*'
              Container(
                width: deviceWidth * 0.35,
                height: deviceHeight * 0.087,
                padding: const EdgeInsets.only(top: 7, bottom: 7),
                child: isOnline
                    ? TextField(
                        readOnly: true,
                        obscureText: false,
                        style: TextStyle(
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis,
                          color: Theme.of(context).hoverColor,
                        ),
                        onChanged: (value) => ref
                            .read(ticketController)
                            .updateSelectedFields(
                                context, ref, value, "deviceType", true),
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelStyle: TextStyle(
                              color: Theme.of(context).secondaryHeaderColor,
                            ),
                            labelText: 'Device/Asset Type',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).secondaryHeaderColor,
                            ),
                            hintText: deviceOrAssetType.toUpperCase(),
                            floatingLabelBehavior:
                                FloatingLabelBehavior.always),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton2(
                          isDense: true,
                          isExpanded: true,
                          value: resolvedOfflineDeviceType,
                          items: offlineDeviceTypeOptions.map((option) {
                            return DropdownMenuItem(
                              value: option['value'],
                              child: Text(
                                option['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).secondaryHeaderColor,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              ref.read(ticketController).updateSelectedFields(
                                  context, ref, newValue, "deviceType", true);
                            }
                          },
                          dropdownStyleData: DropdownStyleData(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Theme.of(context).canvasColor,
                            ),
                          ),
                          buttonStyleData: ButtonStyleData(
                            height: 45,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Theme.of(context).hoverColor),
                            ),
                          ),
                        ),
                      ),
              ),

              Container(
                // width: deviceWidth * 0.39,
                // height: deviceHeight * 0.09,
                width: deviceWidth * 0.41,
                height: deviceHeight * 0.087,

                padding: const EdgeInsets.only(top: 7, bottom: 7),
                child: TextField(
                  readOnly: true,
                  controller: autoCompletecontroller,
                  // focusNode: focusNode,
                  obscureText: false,
                  style: TextStyle(
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                      color: Theme.of(context).secondaryHeaderColor),
                  decoration: InputDecoration(
                    suffixIcon: InkWell(
                      child: Icon(Icons.qr_code,
                          size: 23,
                          color: Theme.of(context).secondaryHeaderColor),
                      onTap: () async {
                        ScanResult result = await BarcodeScanner.scan();
                        if (result.rawContent != '') {
                          log('Selected: $result.rawContent');
                          String entityName = result.rawContent;
                          await Utility.isConnected().then((value) async {
                            if (value) {
                              if (context.mounted) {
                                entityName = await ref
                                    .read(ticketController)
                                    .getEntityTypeForTicket(
                                        ref, context, result.rawContent);
                              }
                            }
                          });

                          if (context.mounted) {
                            ref.read(ticketController).updateSelectedFields(
                                context,
                                ref,
                                entityName,
                                "Device / Asset Id",
                                false);
                          }
                          autoCompletecontroller.text = ref
                              .read(ticketController)
                              .selectedDeviceOrAssetName;
                        }
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelText: 'Device/Asset Id',
                    labelStyle: TextStyle(
                        color: Theme.of(context).secondaryHeaderColor),
                    hintStyle: TextStyle(
                        fontSize: 8,
                        color: Theme.of(context).secondaryHeaderColor),
                    hintText: 'Device/Asset Id',
                  ),
                ),
              ),

              // SizedBox(
              //   width: deviceWidth * 0.39,
              //   height: deviceHeight * 0.052,
              //   child: Card(
              //       elevation: 3,
              //       shadowColor: const Color.fromARGB(255, 5, 5, 5),
              //       color: Colors.white,
              //       shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(4)),
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceAround,
              //         children: [
              //           Text(
              //             autoCompletecontroller.text,
              //             style:
              //                 TextStyle(color: Color.fromARGB(255, 97, 96, 96)),
              //           ),
              //           InkWell(
              //             child: const Icon(Icons.qr_code,
              //                 size: 23, color: Color.fromARGB(255, 97, 96, 96)),
              //             onTap: () async {
              //               ScanResult result = await BarcodeScanner.scan();
              //               if (result.rawContent != '') {
              //                 log('Selected: $result.rawContent');
              //                 await ref.read(ticketController).getDeviceType(
              //                     ref, context, result.rawContent);
              //                 if (context.mounted) {
              //                   ref.read(ticketController).updateSelectedFields(
              //                       context,
              //                       ref,
              //                       result.rawContent,
              //                       "Device / Asset Id",
              //                       false);
              //                 }
              //                 autoCompletecontroller.text = result.rawContent;
              //               }
              //             },
              //           ),
              //         ],
              //       )),
              // )
            ],
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 7.0),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Container(
                color: Theme.of(context).dialogTheme.backgroundColor,
                margin: const EdgeInsets.all(6.0),
                child: SizedBox(
                  width: deviceWidth * 0.66,
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      style: TextStyle(
                          color: Theme.of(context).secondaryHeaderColor),
                      maxLength: 250,
                      readOnly: (deviceOrAssetType == 'others') ? false : true,
                      controller: locationTextController,
                      onChanged: (value) => ref
                          .read(ticketController)
                          .updateSelectedFields(
                              context, ref, value, "location", false),
                      decoration: InputDecoration(
                          counterText: "",
                          hintText: 'Location',
                          hintStyle: TextStyle(
                            color: Theme.of(context).secondaryHeaderColor,
                            fontSize: 12,
                          )),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18.0, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: Icon(Icons.warning_amber,
                      size: 30, color: Theme.of(context).dividerColor),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    isDense: true,
                    isExpanded: false,
                    value: selectedProblemType,
                    // items: problemTypes[
                    //         deviceOrAssetType.toString().toUpperCase()]!
                    items: fetchProblemTypes(
                            deviceOrAssetType.toString().toUpperCase())
                        .map((String items) {
                      return DropdownMenuItem(
                        alignment: AlignmentDirectional.centerStart,
                        value: items,
                        child: Text(
                          items,
                          style: TextStyle(
                              color: Theme.of(context).secondaryHeaderColor,
                              fontSize: 10),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != "Problem Type*") {
                        ref.read(ticketController).updateSelectedFields(
                            context, ref, newValue, "problemType", false);
                      }
                    },
                    dropdownStyleData: DropdownStyleData(
                        padding: const EdgeInsets.only(left: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Theme.of(context).canvasColor,
                        )),
                    buttonStyleData: ButtonStyleData(
                      height: 45,
                      width: deviceWidth * 0.67,
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Theme.of(context).canvasColor,
                      ),
                      elevation: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.12,
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(left: 3, right: 3),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).hoverColor),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: creationCommentsController.text.isEmpty
                        ? RichText(
                            text: TextSpan(
                              text: 'Comments ',
                              style: TextStyle(
                                color: Theme.of(context).hoverColor,
                                fontSize: 14,
                              ),
                              children: deviceOrAssetType == 'others' ||
                                      selectedProblemType == 'Others'
                                  ? [
                                      TextSpan(
                                        text: '*',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .tabBarTheme
                                                .indicatorColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ]
                                  : [],
                            ),
                          )
                        : Container(),
                  ),
                ),
                TextField(
                  controller: creationCommentsController,
                  style:
                      TextStyle(color: Theme.of(context).secondaryHeaderColor),
                  onChanged: (value) {
                    ref.read(ticketController).updateSelectedFields(
                        context, ref, value, "comments", false);
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: deviceWidth * 0.78,
            decoration: BoxDecoration(
              color: Theme.of(context).hoverColor.withValues(alpha: 0.05),
              border:
                  Border.all(color: Theme.of(context).hoverColor, width: 0.6),
            ),
            margin: const EdgeInsets.only(top: 15),
            padding: const EdgeInsets.only(
              top: 14,
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  width: deviceWidth * 0.83,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 40,
                        width: deviceWidth * 0.34,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.2),
                                width: 1)),
                        padding: const EdgeInsets.only(
                            top: 3.0, bottom: 3.0, left: 10),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Text(
                                'Open',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        height: 40,
                        width: deviceWidth * 0.34,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.1),
                            border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.2),
                                width: 1)),
                        padding: const EdgeInsets.only(
                            top: 3.0, bottom: 3.0, left: 10),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Icon(Icons.circle,
                                    size: 12,
                                    color: Theme.of(context).dividerColor),
                              ),
                              Text(
                                'Major',
                                style: TextStyle(
                                    color: Theme.of(context).dividerColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: deviceWidth * 0.83,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 40,
                        width: deviceWidth * 0.34,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .hintColor
                                .withValues(alpha: 0.1),
                            border: Border.all(
                                color: Theme.of(context)
                                    .hintColor
                                    .withValues(alpha: 0.2),
                                width: 1)),
                        padding: const EdgeInsets.only(
                            top: 1.0, bottom: 1.0, left: 10),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Icon(Icons.person_2_outlined,
                                    size: 15,
                                    color: Theme.of(context).hintColor),
                              ),
                              Expanded(
                                child: Text(
                                  username,
                                  style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        height: 40,
                        width: deviceWidth * 0.34,
                        padding: const EdgeInsets.only(
                            top: 1.0, bottom: 1.0, left: 10),
                        decoration: BoxDecoration(
                            color: warningColor.withValues(alpha: 0.1),
                            border: Border.all(
                                color: warningColor.withValues(alpha: 0.2),
                                width: 1)),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 5.0),
                                child: Icon(Icons.person_2_outlined,
                                    size: 15, color: warningColor),
                              ),
                              Expanded(
                                child: Text(
                                  username,
                                  style: const TextStyle(
                                      color: warningColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 3,
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            height: 60,
            width: deviceWidth,
            child: GestureDetector(
              onTap: () async {
                // Connectivity is no longer checked here: TicketRepository
                // (via createTicketDetailsFB) decides online-vs-queue at
                // submit time, so the form stays usable offline.
                if (validateMandatoryFields()) {
                  if (!isRegionChoosen) {
                    final overlay = Overlay.of(context, rootOverlay: true);

                    late OverlayEntry entry;

                    entry = OverlayEntry(
                      builder: (_) => Positioned(
                        bottom: 50,
                        left: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            if (entry.mounted) entry.remove();
                          },
                          child: Material(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).tabBarTheme.indicatorColor,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                "Please select a Region to continue",
                                style: TextStyle(
                                    color: Theme.of(context).canvasColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    overlay.insert(entry);

                    // auto dismiss
                    Future.delayed(const Duration(seconds: 4), () {
                      if (entry.mounted) entry.remove();
                    });
                  } else {
                    final ticketCreated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CaptureThreeImagesScreen(
                          capturedImages:
                              ref.watch(ticketController).fetchedCapturedImages,
                          isForTicket: true,
                          usermail: usermail,
                          username: username,
                        ),
                      ),
                    );

                    if (ticketCreated == true && context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                }
              },
              child: Container(
                height: 40,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: validateMandatoryFields() && isRegionChoosen
                        ? Theme.of(context).hintColor
                        : Theme.of(context).hoverColor,
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(
                    'Proceed with Photo',
                    style: TextStyle(
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
