import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/device_page/gw_semc_take_photo.dart';
import 'package:schnell_luminator/qr_scan_online.dart';
import 'package:schnell_luminator/survey/background_connectivity_monitoring.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';
import 'package:schnell_luminator/utils/widgets.dart';
import '../../utils/asset_folder.dart';

class LampDetailsPage extends ConsumerWidget {
  const LampDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String finalNewLmpName = ref.watch(deviceController).finalNewLmpName;
    List<dynamic> recommendedWattage =
        ref.watch(deviceController).recommendedWattage;
    String newManufacturer = ref.watch(deviceController).newManufacturer;
    String manufacturerDesc = '';
    if (newManufacturer == 'HA') {
      manufacturerDesc = "Havells";
    } else if (newManufacturer == 'SI') {
      manufacturerDesc = 'Signify';
    } else if (newManufacturer == 'OR') {
      manufacturerDesc = 'Orient';
    } else if (newManufacturer == 'BA') {
      manufacturerDesc = 'Bajaj';
    } else if (newManufacturer == 'HI') {
      manufacturerDesc = 'Hitro';
    } else {
      manufacturerDesc = '-';
    }
    String newLmpType = ref.watch(deviceController).newLmpType;
    String newLmpWattage = ref.watch(deviceController).newLmpWattage;
    String intNewLmpWattage = int.tryParse(newLmpWattage).toString();
    String poleLocation = ref.watch(deviceController).poleLocation;
    String clickeventIsFor = ref.watch(deviceController).clickeventIsFor;
    var qrViewController = ref
        .watch(ref.watch(isSecondTime) ? qrController2 : qrController)
        .qrViewController;
    List lampProfiles = ref.watch(deviceController).lampProfiles;

    String? selectedLamp;
    if (lampProfiles.length == 1 && clickeventIsFor == 'recordExistingLamp') {
      newLmpType = lampProfiles[0]['type'];
      newLmpWattage = lampProfiles[0]['watts'].toString();
    }

    log('values: $newLmpType and $newLmpWattage');

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          if (qrViewController != null) {
            qrViewController.resumeCamera();
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: Builder(builder: (BuildContext context) {
              return IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).cardColor,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  if (qrViewController != null) {
                    qrViewController.resumeCamera();
                  }
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
              "LAMP DETAILS",
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
          body: ConnectivityBanner(
            child: Column(
              children: [
                const SizedBox(
                  height: 40,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                    // height: MediaQuery.of(context).size.height / 2.27, //1.12
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                        color: Theme.of(context).canvasColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: Theme.of(context).unselectedWidgetColor,
                              blurRadius: 5,
                              spreadRadius: 5)
                        ]),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        children: [
                          ListTile(
                            title: Padding(
                              padding:
                                  const EdgeInsets.only(left: 1.0, top: 12),
                              child: Text(
                                finalNewLmpName,
                                style: TextStyle(
                                    color: Theme.of(context).cardColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            subtitle: Padding(
                              padding:
                                  const EdgeInsets.only(left: 1.0, top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (clickeventIsFor != 'recordExistingLamp')
                                    Text(
                                      '$manufacturerDesc, $intNewLmpWattage W',
                                      style: TextStyle(
                                          color: Theme.of(context).cardColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  if (lampProfiles.length == 1 &&
                                      clickeventIsFor == 'recordExistingLamp')
                                    Text(
                                      '${lampProfiles[0]['type']} - ${lampProfiles[0]['watts']} W',
                                      style: TextStyle(
                                          color: Theme.of(context).cardColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  if (clickeventIsFor != 'recordExistingLamp')
                                    const SizedBox(
                                      height: 8,
                                    ),
                                  Text(
                                    poleLocation,
                                    style: TextStyle(
                                      color: Theme.of(context).cardColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            leading:
                                Image.file(height: 30, width: 60, Assets.lamp),
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
                          if (recommendedWattage.isNotEmpty)
                            Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              // height: 25,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).canvasColor,
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .secondaryHeaderColor),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(left: 8.0, top: 8.0),
                                    child: Text("Recommended Wattage"),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Wrap(
                                      runSpacing: 6,
                                      spacing: 3,
                                      alignment: WrapAlignment.start,
                                      direction: Axis.horizontal,
                                      children: List.generate(
                                          recommendedWattage.length, (index) {
                                        String recommLampType = '';
                                        int recommLampWatt = 0;
                                        if (index < recommendedWattage.length) {
                                          recommLampType =
                                              recommendedWattage[index]['type']
                                                  .toString();
                                          recommLampWatt =
                                              recommendedWattage[index]
                                                      ['recommended_wattage'] ??
                                                  0;
                                        }
                                        return SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              25,
                                          width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2 -
                                              100,
                                          child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                color: Theme.of(context)
                                                    .dialogTheme
                                                    .backgroundColor,
                                              ),
                                              child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Center(
                                                      child: Text(
                                                    "$recommLampType-$recommLampWatt W",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 13),
                                                  )))),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(
                            height: 10,
                          ),
                          if (lampProfiles.length > 1 &&
                              clickeventIsFor == 'recordExistingLamp')
                            UsableWidgets.buildDropdown(
                              context,
                              value: selectedLamp,
                              label: "Lamp Type & Wattage",
                              items: lampProfiles.map((lamp) {
                                final type = lamp['type'];
                                final watts = lamp['watts'];
                                return '$type - $watts W';
                              }).toList(),
                              onChanged: (newValue) {
                                log('selected value $newValue');
                                if (newValue != null) {
                                  final parts = newValue.split('-');
                                  newLmpType = parts[0].trim();
                                  newLmpWattage =
                                      parts[1].replaceAll('W', '').trim();

                                  log('Selected type: $newLmpType');
                                  log('Selected watts: $newLmpWattage');
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                    height: 50,
                    width: 300,
                    child: Material(
                      elevation: 5,
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20.0),
                      child: MaterialButton(
                        height: 60,
                        onPressed: () async {
                          if (clickeventIsFor == 'recordExistingLamp') {
                            if (lampProfiles.isNotEmpty) {
                              if (newLmpType.isNotEmpty &&
                                  newLmpWattage.isNotEmpty) {
                                ref
                                    .read(deviceController)
                                    .setLampDetailsForRecordExistingLamp(
                                        newLmpType, newLmpWattage);
                              } else {
                                showSnackBar(ref, context,
                                    "Please provide the lamp type and wattage");
                                return;
                              }
                            }
                          }
                          log('values: $newLmpType and $newLmpWattage');

                          if (context.mounted) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GwSemcCaptureThreeImagesScreen(
                                        clickeventIsFor: clickeventIsFor,
                                        requiredImageCount: 3),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Save and Take Photo',
                          style: TextStyle(
                              color: Theme.of(context).canvasColor,
                              fontSize: 16),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
