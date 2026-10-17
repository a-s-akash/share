import 'dart:async';
import 'dart:developer';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../device_page/device_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/dialog_box.dart';
import '../../utils/dropdown_options.dart';
import '../../utils/widgets.dart';
import '../background_connectivity_monitoring.dart';
import '../survey_controller.dart';
import 'survey_take_photo.dart';

class TransformerSurvey extends ConsumerStatefulWidget {
  const TransformerSurvey({super.key});
  @override
  ConsumerState<TransformerSurvey> createState() => _TransformerSurvey();
}

class _TransformerSurvey extends ConsumerState<TransformerSurvey>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read(surveyController).fetchLocationForSurvey();
      // BackgroundSyncWorkManager.registerInternetCheckTask();
    });
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      log('App resumed - checking connectivity status');
      // BackgroundSyncWorkManager.registerInternetCheckTask();
      // await ref.read(internetStatusProvider.notifier).syncFromPrefs();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.sizeOf(context).width;
    final TextEditingController surveyManualLocationController =
        ref.read(surveyController).surveyManualLocationEntry;
    bool isSurveyLocationFetched =
        ref.watch(surveyController).isSurveyLocationFetched;
    final TextEditingController commentsController =
        ref.read(surveyController).commentsController;
    String fetchedLandMark = ref.watch(surveyController).fetchedLandMark;
    String fetchedLat = ref.watch(surveyController).fetchedLat;
    String fetchedLong = ref.watch(surveyController).fetchedLong;
    String fetchedAltitude = ref.watch(surveyController).fetchedAltitude;
    String wardNumber = ref.read(surveyController).wardNumberForPolePrefix;
    String transformerNoPrefixText = '$wardNumber-TFR';
    final TextEditingController transNoController =
        ref.read(surveyController).transNoController;
    final TextEditingController transCapacityController =
        ref.read(surveyController).transCapacityController;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;
    final selectedRoadCategory = ref.watch(
      surveyController.select((state) => state.selectedRoadCategory),
    );

    final selectedRoadWidth = ref.watch(
      surveyController.select((state) => state.selectedRoadWidth),
    );

    final selectedVehicleAccess = ref.watch(
      surveyController.select((state) => state.selectedVehicleAccess),
    );

    final selectedRoadType = ref.watch(
      surveyController.select((state) => state.selectedRoadType),
    );
    final selectedTrafficSpeed = ref.watch(
      surveyController.select((state) => state.selectedTrafficSpeed),
    );
    final selectedTrafficDensity = ref.watch(
      surveyController.select((state) => state.selectedTrafficDensity),
    );

    bool isResurvey = ref.watch(surveyController).isResurvey;

    return SafeArea(
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
              "TRANSFORMER ASSET SURVEY",
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
          body: ConnectivityBanner(
            child: WillPopScope(
                onWillPop: () async {
                  ref.read(surveyController).clearAllUpdatedSelectedFields();
                  return true;
                },
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  UsableWidgets.projContextContainerInMaintenace(context, ref,
                      selectedRegion, selectedZone, selectedWard, null),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 6.0),
                          child: TextField(
                            readOnly: isResurvey ? true : false,
                            maxLength: 15,
                            controller: transNoController,
                            obscureText: false,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onChanged: (newValue) {
                              log('trans No $newValue');
                              ref
                                  .read(surveyController)
                                  .updateTransformerSurveyFieldValues(context,
                                      ref, newValue.toUpperCase(), 'transNo');
                            },
                            decoration: InputDecoration(
                              prefixText: transformerNoPrefixText,
                              prefixStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelText: 'Transformer Number *',
                              labelStyle: TextStyle(
                                  fontSize: 17,
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 6.0),
                          child: TextField(
                            controller: transCapacityController,
                            obscureText: false,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onChanged: (newValue) {
                              log('trans Capacity $newValue');
                              ref
                                  .read(surveyController)
                                  .updateTransformerSurveyFieldValues(
                                      context, ref, newValue, 'transCapacity');
                            },
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              counterText: '',
                              suffixText: 'kW',
                              suffixStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelText: 'Transformer Capacity',
                              labelStyle: TextStyle(
                                  fontSize: 17,
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: UsableWidgets.buildDropdown(
                        context,
                        value: selectedRoadCategory,
                        label: "Existing Road Category",
                        items: roadTypeOptions.keys.toList(),
                        onChanged: (value) async {
                          ref
                              .read(surveyController)
                              .updateRoadCategoryCascade(context, ref, value!);
                        },
                      )),
                      Expanded(
                          child: UsableWidgets.buildDropdown(
                        context,
                        value: selectedRoadType,
                        label: "Road Type",
                        items: (roadTypeOptions[selectedRoadCategory] ?? [])
                            .cast<String>(),
                        onChanged: (value) async {
                          ref
                              .read(surveyController)
                              .updateRoadTypeCascade(context, ref, value!);
                        },
                      )),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: UsableWidgets.buildDropdown(
                        context,
                        value: selectedRoadWidth,
                        label: "Road Width",
                        items: (roadWidthOptions[selectedRoadType] ?? [])
                            .cast<String>(),
                        onChanged: (value) async {
                          ref
                              .read(surveyController)
                              .updateRoadWidthCascade(context, ref, value!);
                        },
                      )),
                      Expanded(
                          child: UsableWidgets.buildDropdown(
                        context,
                        value: selectedVehicleAccess,
                        label: "Vehicle Access",
                        items: (vehicleAccessOptions[selectedRoadWidth] ?? [])
                            .cast<String>(),
                        onChanged: (value) async {
                          if (value != null) {
                            ref
                                .read(surveyController)
                                .updateVehicleAccess(value);
                          }
                        },
                      )),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: UsableWidgets.buildDropdown(
                        context,
                        value: selectedTrafficDensity,
                        label: "Traffic Density",
                        items: trafficDensityOptions,
                        onChanged: (value) async {
                          log('selected value $value');

                          ref
                              .read(surveyController)
                              .updateBaseSurveyFieldValues(
                                  context, ref, value, 'trafficDensity');
                        },
                      )),
                      Expanded(
                          child: UsableWidgets.buildDropdown(
                        context,
                        value: selectedTrafficSpeed,
                        label: "Traffic Speed",
                        items: trafficSpeedOptions,
                        onChanged: (value) async {
                          log('selected value $value');

                          ref
                              .read(surveyController)
                              .updateBaseSurveyFieldValues(
                                  context, ref, value, 'trafficSpeed');
                        },
                      )),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 8.0),
                    child: SizedBox(
                      width: deviceWidth,
                      child: InputDecorator(
                          decoration: InputDecoration(
                            label: RichText(
                                text: TextSpan(
                              text: 'Location',
                              style: TextStyle(
                                  fontSize: 17,
                                  color: darkBlue,
                                  fontWeight: FontWeight.bold),
                            )),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Column(
                            children: [
                              AnimatedTextField(
                                animationType: Animationtype.typer,
                                keyboardType: TextInputType
                                    .visiblePassword, // to remove emoji from the keyboard
                                maxLength: 100,

                                controller: surveyManualLocationController,

                                style: const TextStyle(color: Colors.black),

                                onChanged: (value) {
                                  ref
                                      .read(surveyController)
                                      .updateSurveyFieldValues(context, ref,
                                          value, 'manualEnteredLocation');
                                },

                                decoration: InputDecoration(
                                    hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .secondaryHeaderColor),
                                    hintText:
                                        'Provide additional landmark information if any',
                                    counterText: '',
                                    prefixIcon:
                                        const Icon(Icons.location_on_outlined),
                                    contentPadding: const EdgeInsets.all(16.0),
                                    filled: true,
                                    fillColor:
                                        const Color.fromARGB(248, 64, 124, 161)
                                            .withValues(alpha: 0.20),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color:
                                              Color.fromARGB(248, 64, 124, 161),
                                          width: 1.0),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color:
                                              Color.fromARGB(248, 64, 124, 161),
                                          width: 1.0),
                                      borderRadius: BorderRadius.circular(8.0),
                                    )),
                              ),
                              const SizedBox(height: 20),
                              isSurveyLocationFetched == true
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        fetchedLandMark != ''
                                            ? Text(
                                                fetchedLandMark,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            : Container(),
                                        const SizedBox(
                                          height: 2,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            const Text(
                                              'Latitude : ',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              fetchedLat,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const Text(
                                              'Longitude : ',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              fetchedLong,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 2,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Altitude : ',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              fetchedAltitude,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Text(
                                      'Fetching Location...',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ))
                            ],
                          )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 10),
                    child: Container(
                      height: MediaQuery.sizeOf(context).height * 0.12,
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(left: 3, right: 3),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Remarks / Comments ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                )),
                          ),
                          TextField(
                            maxLength: 250,
                            controller: commentsController,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 12),
                            onChanged: (value) {
                              ref
                                  .read(surveyController)
                                  .updateSurveyFieldValues(
                                      context, ref, value, "comments");
                            },
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 29,
                  ),
                  GestureDetector(
                      child: Center(
                        child: Container(
                          height: 50,
                          width: deviceWidth * 0.8,
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(248, 64, 124, 161)
                                  .withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Center(
                            child: Text(
                              'Proceed to Photo',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      onTap: () async {
                        ref
                            .read(surveyController)
                            .onClickEventIsFor('transSurvey');
                        // Check if location is available
                        if (fetchedLat == '' || fetchedLong == '') {
                          alertPopUp(context, 'Collecting Data Please Wait',
                              'assets/animation/userAlert.json');
                          return;
                        }
                        if (transCapacityController.text.contains('.')) {
                          FocusScope.of(context).unfocus();
                          showSnackBar(
                            ref,
                            context,
                            "Transformer Capacity must not contain a decimal value.",
                          );
                          return;
                        }
                        if (transNoController.text.isEmpty) {
                          FocusScope.of(context).unfocus();
                          showSnackBar(ref, context,
                              "Please provide the Transformer number");
                          return;
                        } else {
                          ref
                              .read(surveyController)
                              .updateTransformerSurveyFieldValues(
                                context,
                                ref,
                                '$transformerNoPrefixText${transNoController.text.trim()}',
                                'transNo',
                              );
                        }

                        // All validations passed
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CaptureThreeImagesScreen(
                                  capturedImages: ref
                                      .watch(surveyController)
                                      .fetchedCapturedImages)),
                        );
                      }),
                  const SizedBox(
                    height: 10,
                  ),
                ]))),
          )),
    );
  }
}
