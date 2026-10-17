import 'dart:async';
import 'dart:developer';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:schnell_luminator/survey/screens/pole_survey.dart';
import 'package:schnell_luminator/utils/widgets.dart';
import '../../device_page/device_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/dialog_box.dart';
import '../../utils/dropdown_options.dart';
import '../background_connectivity_monitoring.dart';
import '../survey_controller.dart';
import 'survey_take_photo.dart';

class SwitchPointSurvey extends ConsumerStatefulWidget {
  const SwitchPointSurvey({super.key});
  @override
  ConsumerState<SwitchPointSurvey> createState() => _SwitchPointSurveyState();
}

class _SwitchPointSurveyState extends ConsumerState<SwitchPointSurvey>
    with WidgetsBindingObserver {
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read(surveyController).fetchLocationForSurvey();
      // BackgroundSyncWorkManager.registerInternetCheckTask();
    });
  }

  void debounceUpdate(String value, String fieldName, String whichField) {
    // Cancel previous timer
    _debounce?.cancel();

    // Wait 500ms after last keystroke
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (whichField == 'sp') {
        ref
            .read(surveyController)
            .updateSwitchPointSurveyFieldValues(context, ref, value, fieldName);
      } else if (whichField == 'comments') {
        ref
            .read(surveyController)
            .updateSurveyFieldValues(context, ref, value, fieldName);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.sizeOf(context).width;
    ref.watch(hiveSyncProvider);
    final switchPointNumberController = ref.watch(
      surveyController.select((state) => state.switchPointNumberController),
    );
    final spMeterNoController = ref.watch(
      surveyController.select((state) => state.spMeterNoController),
    );
    final spMakeController = ref.watch(
      surveyController.select((state) => state.spMakeController),
    );
    final rrNumberController = ref.watch(
      surveyController.select((state) => state.rrNumberController),
    );
    final spTransformerNoController = ref.watch(
      surveyController.select((state) => state.spTransformerNoController),
    );
    final selectedWardId = ref.watch(
      deviceController.select((state) => state.selectedWardId),
    );
    final switchPointIdController = ref.watch(
      surveyController.select((state) => state.switchPointIdController),
    );
    final surveyManualLocationController = ref.watch(
      surveyController.select((state) => state.surveyManualLocationEntry),
    );
    final spConnectedLoadController = ref.watch(
      surveyController.select((state) => state.spConnectedLoadController),
    );
    final commentsController = ref.watch(
      surveyController.select((state) => state.commentsController),
    );
    final selectedSwitchPointType = ref.watch(
      surveyController.select((state) => state.selectedSwitchPointType),
    );
    final selectedSPMeter = ref.watch(
      surveyController.select((state) => state.selectedSPMeter),
    );
    final selectedSpEarthingCondition = ref.watch(
      surveyController.select((state) => state.selectedSpEarthingCondition),
    );
    final selectedSpCondition = ref.watch(
      surveyController.select((state) => state.selectedSpCondition),
    );
    final selectedSpMeterType = ref.watch(
      surveyController.select((state) => state.selectedSpMeterType),
    );
    final selectedSpPhase = ref.watch(
      surveyController.select((state) => state.selectedSpPhase),
    );
    final isSurveyLocationFetched = ref.watch(
      surveyController.select((state) => state.isSurveyLocationFetched),
    );
    final fetchedLandMark = ref.watch(
      surveyController.select((state) => state.fetchedLandMark),
    );
    final fetchedLat = ref.watch(
      surveyController.select((state) => state.fetchedLat),
    );
    final fetchedLong = ref.watch(
      surveyController.select((state) => state.fetchedLong),
    );
    final fetchedAltitude = ref.watch(
      surveyController.select((state) => state.fetchedAltitude),
    );
    final wardNumber = ref.read(surveyController).wardNumberForPolePrefix;
    final spNoPrefixText = '$wardNumber-SP';
    final transformerNoPrefixText = '$wardNumber-TFR';
    final selectedRegion = ref.watch(
      deviceController.select((state) => state.selectedRegion),
    );
    final selectedZone = ref.watch(
      deviceController.select((state) => state.selectedZone),
    );
    final selectedWard = ref.watch(
      deviceController.select((state) => state.selectedWard),
    );

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
          resizeToAvoidBottomInset: true,
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
              "SWITCH POINT ASSET SURVEY",
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
          body: ConnectivityBanner(
            child: WillPopScope(
                onWillPop: () async {
                  ref.read(surveyController).clearAllUpdatedSelectedFields();
                  // Navigator.of(context).pop(true);
                  return true;
                },
                child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(5),
                    children: [
                      UsableWidgets.projContextContainerInMaintenace(
                          context,
                          ref,
                          selectedRegion,
                          selectedZone,
                          selectedWard,
                          null),
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 0.0),
                                child: TextField(
                                  readOnly: isResurvey ? true : false,
                                  controller: switchPointNumberController,
                                  obscureText: false,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
                                  ],
                                  onChanged: (newValue) {
                                    log('switch point number $newValue');
                                    debounceUpdate(newValue.toUpperCase(),
                                        'escomPoleNumber', 'sp');
                                    // ref
                                    //     .read(surveyController)
                                    //     .updateSwitchPointSurveyFieldValues(
                                    //         context,
                                    //         ref,
                                    //         newValue.toUpperCase(),
                                    //         'switchPointNumber');
                                  },
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  decoration: InputDecoration(
                                    prefixText: spNoPrefixText,
                                    prefixStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    labelText: 'Switch Point Number *',
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
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: UsableWidgets.buildDropdown(
                            context,
                            value: selectedSwitchPointType,
                            label: "Switch Point Type",
                            items: switchPointTypeOptions,
                            onChanged: (value) async {
                              ref
                                  .read(surveyController)
                                  .updateSwitchPointSurveyFieldValues(
                                      context, ref, value, 'spType');
                            },
                          )),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 6.0),
                              child: TextField(
                                controller: rrNumberController,
                                obscureText: false,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onChanged: (newValue) {
                                  log('rrNumber $newValue');
                                  debounceUpdate(newValue, 'rrNumber', 'sp');
                                  // ref
                                  //     .read(surveyController)
                                  //     .updateSwitchPointSurveyFieldValues(
                                  //         context, ref, newValue, 'rrNumber');
                                },
                                maxLength: 25,
                                // keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  labelText: 'RR Number',
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ValueListenableBuilder(
                                valueListenable:
                                    Hive.box(assetNameBox).listenable(),
                                builder: (context, Box box, _) {
                                  final wardData =
                                      box.get('ward_$selectedWardId');
                                  log('wardData: $wardData');
                                  final transformerNames = wardData == null
                                      ? <String>[]
                                      : List<String>.from(
                                          wardData['transformers'] ?? []);

                                  return editableDropdownField(context, ref,
                                      assetType: 'transformer',
                                      dropdownItems: transformerNames,
                                      controller: spTransformerNoController,
                                      label: 'Transformer No',
                                      prefixText: transformerNoPrefixText);
                                },
                              ),
                            ),
                            // Expanded(
                            //   child: TextField(
                            //     // readOnly: false,
                            //     controller: spTransformerNoController,
                            //     obscureText: false,
                            //     style: const TextStyle(
                            //       color: Colors.black,
                            //       fontSize: 14,
                            //       overflow: TextOverflow.ellipsis,
                            //     ),
                            //     onChanged: (newValue) {
                            //       log('poleTransFormerNo $newValue');
                            //       debounceUpdate(newValue.toUpperCase(),
                            //           'spTransFormerNo', 'sp');
                            //       // ref
                            //       //     .read(surveyController)
                            //       //     .updateSwitchPointSurveyFieldValues(
                            //       //         context,
                            //       //         ref,
                            //       //         newValue.toUpperCase(),
                            //       //         'spTransFormerNo');
                            //     },
                            //     maxLength: 15,

                            //     decoration: InputDecoration(
                            //       prefixText: transformerNoPrefixText,
                            //       prefixStyle: TextStyle(
                            //         color: Colors.grey[600],
                            //         fontSize: 14,
                            //         fontWeight: FontWeight.w500,
                            //       ),
                            //       border: OutlineInputBorder(
                            //         borderRadius: BorderRadius.circular(8),
                            //       ),
                            //       counterText: '',
                            //       labelText: 'Transformer No',
                            //       labelStyle: TextStyle(
                            //           fontSize: 17,
                            //           color: darkBlue,
                            //           fontWeight: FontWeight.bold),
                            //       floatingLabelBehavior:
                            //           FloatingLabelBehavior.always,
                            //     ),
                            //   ),
                            // ),
                            const SizedBox(
                              width: 15,
                            ),
                            Expanded(
                              child: TextField(
                                controller: switchPointIdController,
                                obscureText: false,
                                maxLength: 13,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onChanged: (newValue) {
                                  log('SP Id $newValue');
                                  debounceUpdate(newValue, 'spId', 'sp');
                                  // ref
                                  //     .read(surveyController)
                                  //     .updateSwitchPointSurveyFieldValues(
                                  //         context, ref, newValue, 'spId');
                                },
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  labelText: 'Panel ID',
                                  labelStyle: TextStyle(
                                      fontSize: 17,
                                      color: darkBlue,
                                      fontWeight: FontWeight.bold),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                  .updateRoadCategoryCascade(
                                      context, ref, value!);
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
                            items:
                                (vehicleAccessOptions[selectedRoadWidth] ?? [])
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
                                        prefixIcon: const Icon(
                                            Icons.location_on_outlined),
                                        contentPadding:
                                            const EdgeInsets.all(16.0),
                                        filled: true,
                                        fillColor: const Color.fromARGB(
                                                248, 64, 124, 161)
                                            .withValues(alpha: 0.20),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Color.fromARGB(
                                                  248, 64, 124, 161),
                                              width: 1.0),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Color.fromARGB(
                                                  248, 64, 124, 161),
                                              width: 1.0),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
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
                                                      fontWeight:
                                                          FontWeight.bold),
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
                                                      fontWeight:
                                                          FontWeight.bold),
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
                                                      fontWeight:
                                                          FontWeight.bold),
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
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ))
                                ],
                              )),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: UsableWidgets.buildDropdown(
                              context,
                              value: selectedSPMeter,
                              label: "Meter Status",
                              items: sPMeterOptions,
                              onChanged: (newValue) {
                                log('selected value $newValue');

                                ref
                                    .read(surveyController)
                                    .updateSwitchPointSurveyFieldValues(
                                        context, ref, newValue, 'spMeter');
                              },
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 6.0),
                              child: TextField(
                                controller: spConnectedLoadController,
                                obscureText: false,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onChanged: (newValue) {
                                  log('SP Connected Load $newValue');
                                  debounceUpdate(
                                      newValue, 'spConnectedLoad', 'sp');
                                  // ref
                                  //     .read(surveyController)
                                  //     .updateSwitchPointSurveyFieldValues(context,
                                  //         ref, newValue, 'spConnectedLoad');
                                },
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  TextInputFormatter.withFunction(
                                      (oldValue, newValue) {
                                    final text = newValue.text;

                                    if (text.isEmpty) {
                                      return newValue;
                                    }

                                    final value = double.tryParse(text);

                                    // Not a valid number
                                    if (value == null) {
                                      return oldValue;
                                    }

                                    // Allow only values between 0 and 45
                                    if (value < 0 || value > 45) {
                                      return oldValue;
                                    }

                                    // Optional: Allow up to 2 decimal places
                                    final parts = text.split('.');
                                    if (parts.length > 1 &&
                                        parts[1].length > 2) {
                                      return oldValue;
                                    }

                                    return newValue;
                                  }),
                                ],
                                decoration: InputDecoration(
                                  suffixText: 'kW',
                                  suffixStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  labelText: 'Connected Load',
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
                      // if (selectedSpMeterType != 'DP/Manual')
                      if (selectedSPMeter != 'Missing')
                        Card(
                          color: Theme.of(context).canvasColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          margin: const EdgeInsets.all(10),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Meter Details",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 6.0),
                                        child: TextField(
                                          controller: spMeterNoController,
                                          obscureText: false,
                                          maxLength: 12,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onChanged: (newValue) {
                                            log('SP Meter no $newValue');
                                            debounceUpdate(
                                                newValue, 'spMeterNo', 'sp');
                                            // ref
                                            //     .read(surveyController)
                                            //     .updateSwitchPointSurveyFieldValues(
                                            //         context,
                                            //         ref,
                                            //         newValue,
                                            //         'spMeterNo');
                                          },
                                          decoration: InputDecoration(
                                            counterText: '',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            labelText: 'S No',
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
                                      child: UsableWidgets.buildDropdown(
                                        context,
                                        value: selectedSpMeterType,
                                        label: "Meter Type",
                                        items: spMeterTypeOptions,
                                        onChanged: (newValue) {
                                          log('selected value $newValue');

                                          ref
                                              .read(surveyController)
                                              .updateSwitchPointSurveyFieldValues(
                                                  context,
                                                  ref,
                                                  newValue,
                                                  'spMeterType');
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 6.0),
                                        child: TextField(
                                          controller: spMakeController,
                                          obscureText: false,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onChanged: (newValue) {
                                            log('selected value $newValue');
                                            debounceUpdate(
                                                newValue, 'spMake', 'sp');
                                            // ref
                                            //     .read(surveyController)
                                            //     .updateSwitchPointSurveyFieldValues(
                                            //         context,
                                            //         ref,
                                            //         newValue,
                                            //         'spMake');
                                          },
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            labelText: 'Make',
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
                                        child: UsableWidgets.buildDropdown(
                                      context,
                                      value: selectedSpPhase,
                                      label: "Phase",
                                      items: spPhaseOptions,
                                      onChanged: (newValue) {
                                        log('selected value $newValue');

                                        ref
                                            .read(surveyController)
                                            .updateSwitchPointSurveyFieldValues(
                                                context,
                                                ref,
                                                newValue,
                                                'spPhase');
                                      },
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          // Expanded(
                          //   child: Padding(
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 10.0, vertical: 8.0),
                          //     child: Column(
                          //       crossAxisAlignment: CrossAxisAlignment.start,
                          //       children: [
                          //         const Text(
                          //           'Working',
                          //           style: const TextStyle(
                          //               fontSize: 13, fontWeight: FontWeight.w500),
                          //         ),
                          //         const SizedBox(height: 6),
                          //         ToggleSwitch(
                          //           minWidth: 80,
                          //           cornerRadius: 12,
                          //           activeBgColors: [
                          //             [
                          //               const Color.fromARGB(248, 64, 124, 161)
                          //                   .withOpacity(0.8)
                          //             ],
                          //             [
                          //               const Color.fromARGB(248, 64, 124, 161)
                          //                   .withOpacity(0.8)
                          //             ]
                          //           ],
                          //           activeFgColor: Colors.white,
                          //           inactiveBgColor: Colors.grey[300],
                          //           inactiveFgColor: Colors.black,
                          //           totalSwitches: 2,
                          //           labels: const ['Yes', 'No'],
                          //           initialLabelIndex:
                          //               selectedSpConditionWorking ? 0 : 1,
                          //           onToggle: (index) {
                          //             final isYes = index == 0;
                          //             ref
                          //                 .read(surveyController)
                          //                 .updateSurveyFieldValues(
                          //                     context, ref, isYes, 'spMeterWorking');
                          //           },
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),

                          Expanded(
                            child: UsableWidgets.buildDropdown(
                              context,
                              value: selectedSpCondition,
                              label: "Switch Point Condition",
                              items: spConditionOptions,
                              onChanged: (newValue) {
                                log('selected value $newValue');

                                ref
                                    .read(surveyController)
                                    .updateSwitchPointSurveyFieldValues(
                                        context, ref, newValue, 'spCondition');
                              },
                            ),
                          ),
                          Expanded(
                              child: UsableWidgets.buildDropdown(
                            context,
                            value: selectedSpEarthingCondition,
                            label: "Earthing Condition",
                            items: spEarthingConditionOptions,
                            onChanged: (newValue) {
                              log('selected value $newValue');

                              ref
                                  .read(surveyController)
                                  .updateSwitchPointSurveyFieldValues(context,
                                      ref, newValue, 'spEarthingCondition');
                            },
                          )),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 10),
                        child: Container(
                          height: MediaQuery.sizeOf(context).height * 0.12,
                          padding: const EdgeInsets.all(8.0),
                          margin: const EdgeInsets.only(left: 3, right: 3),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).primaryColor),
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
                                  debounceUpdate(value, 'comments', 'comments');
                                  // ref
                                  //     .read(surveyController)
                                  //     .updateSurveyFieldValues(
                                  //         context, ref, value, "comments");
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
                                .onClickEventIsFor('spSurvey');
                            // Check if location is available
                            if (fetchedLat == '' || fetchedLong == '') {
                              alertPopUp(context, 'Collecting Data Please Wait',
                                  'assets/animation/userAlert.json');
                              return;
                            }
                            if (switchPointNumberController.text.isEmpty) {
                              FocusScope.of(context).unfocus();
                              showSnackBar(ref, context,
                                  "Please provide the switch point number");
                              return;
                            }
                            final switchPointNumber = ref
                                .read(surveyController)
                                .padNumber(
                                    switchPointNumberController.text.trim(), 4);

                            final spFormatRegex = RegExp(r'^\d{1,4}$');

                            if (!spFormatRegex.hasMatch(switchPointNumber)) {
                              FocusScope.of(context).unfocus();
                              alertPopUp1(
                                context,
                                'Invalid Switch Point Number format. Please enter a valid format (e.g.,SP456,SP001234)',
                                'assets/animation/warn.json',
                              );

                              return;
                            }

                            final rrNumberRegex = RegExp(r'^[a-zA-Z0-9/]+$');

                            if (rrNumberController.text.isNotEmpty) {
                              if (!rrNumberRegex
                                  .hasMatch(rrNumberController.text)) {
                                FocusScope.of(context).unfocus();
                                showSnackBar(
                                  ref,
                                  context,
                                  "Invalid RR Number. Provide a proper format",
                                );
                                return;
                              }
                            }

                            if (switchPointIdController.text.isNotEmpty) {
                              // Regex: exactly 13 alphanumeric characters
                              final panelIdRegex = RegExp(r'^[a-zA-Z0-9]{13}$');

                              if (!panelIdRegex
                                  .hasMatch(switchPointIdController.text)) {
                                FocusScope.of(context).unfocus();
                                showSnackBar(
                                  ref,
                                  context,
                                  "Invalid Panel ID. It must contain exactly 13 digits.",
                                );
                                return;
                              }
                            }
                            if (spTransformerNoController.text.isNotEmpty) {
                              ref
                                  .read(surveyController)
                                  .updateSwitchPointSurveyFieldValues(
                                    context,
                                    ref,
                                    '$transformerNoPrefixText${spTransformerNoController.text.trim()}',
                                    'spTransFormerNo',
                                  );
                            }
                            if (switchPointNumber.isNotEmpty) {
                              ref
                                  .read(surveyController)
                                  .updateSwitchPointSurveyFieldValues(
                                    context,
                                    ref,
                                    '$spNoPrefixText$switchPointNumber',
                                    'switchPointNumber',
                                  );
                            }

                            // All validations passed
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CaptureThreeImagesScreen(
                                          capturedImages: ref
                                              .watch(surveyController)
                                              .fetchedCapturedImages)),
                            );
                          }),
                      const SizedBox(
                        height: 10,
                      ),
                    ])),
          )),
    );
  }
}
