import 'dart:async';
import 'dart:developer';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/survey/background_connectivity_monitoring.dart';
import 'package:schnell_luminator/utils/constants.dart';
import 'package:schnell_luminator/utils/widgets.dart';
import '../../utils/app_theme.dart';
import '../../utils/dialog_box.dart';
import '../../utils/dropdown_options.dart';
import '../survey_controller.dart';
import 'survey_take_photo.dart';

class PoleSurveyInformation extends ConsumerStatefulWidget {
  const PoleSurveyInformation({super.key});
  @override
  ConsumerState<PoleSurveyInformation> createState() => _PoleSurveyState();
}

class _PoleSurveyState extends ConsumerState<PoleSurveyInformation>
    with WidgetsBindingObserver {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(surveyController).fetchNetworkDetails();

      // ref.read(surveyController).fetchLocationForSurvey();
      // BackgroundSyncWorkManager.registerInternetCheckTask();
    });
  }

  // @override
  // Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
  //   super.didChangeAppLifecycleState(state);
  //   if (state == AppLifecycleState.resumed) {
  //     log('App resumed - checking connectivity status');
  //     // BackgroundSyncWorkManager.registerInternetCheckTask();
  //     // await ref.read(internetStatusProvider.notifier).syncFromPrefs();
  //   }
  // }

  bool isNumeric(String newValue) {
    if (newValue.isEmpty) {
      return false;
    }
    return int.tryParse(newValue) != null;
  }

  // Get initial wattage for a given lamp type
  String getInitialLampWattage(String type) {
    return lampWattages[type]?.first ?? '40 W';
  }

  void debounceUpdate(String value, String fieldName, String whichField) {
    // Cancel previous timer
    _debounce?.cancel();

    // Wait 500ms after last keystroke
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (whichField == 'default') {
        ref
            .read(surveyController)
            .updatePoleSurveyFieldValues(context, ref, value, fieldName);
      } else if (whichField == 'pole') {
        ref
            .read(surveyController)
            .updatePoleSurveyFieldPoleValues(context, ref, value, fieldName);
      } else if (whichField == 'light') {
        ref
            .read(surveyController)
            .updatePoleSurveyFieldLightValues(context, ref, value, fieldName);
      } else if (whichField == 'arm') {
        ref
            .read(surveyController)
            .updatePoleSurveyFieldArmValues(context, ref, value, fieldName);
      } else if (whichField == 'motor') {
        ref
            .read(surveyController)
            .updatePoleSurveyFieldMotorValues(context, ref, value, fieldName);
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
    bool isResurvey = ref.watch(surveyController).isResurvey;
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
    final clampTypeWidthController = ref.watch(
      surveyController.select((state) => state.clampTypeWidthController),
    );
    final surveyManualLocationController = ref.watch(
      surveyController.select((state) => state.surveyManualLocationEntry),
    );
    final clampTypeLengthController = ref.watch(
      surveyController.select((state) => state.clampTypeLengthController),
    );
    final goodArmTextController = ref.watch(
      surveyController.select((state) => state.goodArmTextController),
    );
    final badArmTextController = ref.watch(
      surveyController.select((state) => state.badArmTextController),
    );
    final missingArmTextController = ref.watch(
      surveyController.select((state) => state.missingArmTextController),
    );
    final workingTextController =
        ref.watch(surveyController).workingTextController;
    final commentsController = ref.watch(
      surveyController.select((state) => state.commentsController),
    );
    final poleNumberController = ref.watch(
      surveyController.select((state) => state.poleNumberController),
    );
    final exCorpPoleNoController = ref.watch(
      surveyController.select((state) => state.exCorpPoleNoController),
    );
    final ebPoleNoController = ref.watch(
      surveyController.select((state) => state.ebPoleNoController),
    );
    final switchPointController = ref.watch(
      surveyController.select((state) => state.switchPointController),
    );
    final notWorkingTextController =
        ref.watch(surveyController).notWorkingTextController;
    final missingTextController =
        ref.watch(surveyController).missingTextController;
    final poleMotorRatingController = ref.watch(
      surveyController.select((state) => state.poleMotorRatingController),
    );
    final poleMotorMakeController = ref.watch(
      surveyController.select((state) => state.poleMotorMakeController),
    );
    final poleMotorModelController = ref.watch(
      surveyController.select((state) => state.poleMotorModelController),
    );
    final poleTransformerNoController = ref.watch(
      surveyController.select((state) => state.poleTransformerNoController),
    );

    // Device and pole data
    final poleNoTemplate = ref.watch(
      deviceController.select((state) => state.selectedRegionPoleSchema),
    );
    final wardNumber = ref.watch(
      surveyController.select((state) => state.wardNumberForPolePrefix),
    );

    final selectedRegion = ref.watch(
      deviceController.select((state) => state.selectedRegion),
    );
    final selectedZone = ref.watch(
      deviceController.select((state) => state.selectedZone),
    );
    final selectedWard = ref.watch(
      deviceController.select((state) => state.selectedWard),
    );

    ref.watch(hiveSyncProvider);
    final selectedClampUnits = ref.watch(
      surveyController.select((state) => state.selectedClampUnits),
    );
    final selectedClampWidth = ref.watch(
      surveyController.select((state) => state.selectedClampWidth),
    );
    final selectedClampLength = ref.watch(
      surveyController.select((state) => state.selectedClampLength),
    );
    final selectedClampType = ref.watch(
      surveyController.select((state) => state.selectedClampType),
    );
    final selectedBracketMountingHeight = ref.watch(
      surveyController.select((state) => state.selectedBracketMountingHeight),
    );
    final selectedCustomBracketHeight = ref.watch(
      surveyController.select((state) => state.selectedCustomBracketHeight),
    );
    final isEarthingRequired = ref.watch(
      surveyController.select((state) => state.isEarthingRequired),
    );
    final selectedManualSwitchCtrl = ref.watch(
      surveyController.select((state) => state.selectedManualSwitchCtrl),
    );
    final selectedPoleCondition = ref.watch(
      surveyController.select((state) => state.selectedPoleCondition),
    );
    final selectedArmCount = ref.watch(
      surveyController.select((state) => state.selectedArmCount),
    );
    final selectedArmLength = ref.watch(
      surveyController.select((state) => state.selectedArmLength),
    );
    final selectedPoleHeight = ref.watch(
      surveyController.select((state) => state.selectedPoleHeight),
    );
    final selectedPoleSpan = ref.watch(
      surveyController.select((state) => state.selectedPoleSpan),
    );
    final selectedPoleType = ref.watch(
      surveyController.select((state) => state.selectedPoleType),
    );

    final selectedWardId = ref.watch(
      deviceController.select((state) => state.selectedWardId),
    );
    final selectedLamps = ref.watch(surveyController).selectedLamps;

    log('$selectedLamps');
    final selectedPoleMotorCondition = ref.watch(
      surveyController.select((state) => state.selectedPoleMotorCondition),
    );
    final selectedIncomingTransLine = ref.watch(
      surveyController.select((state) => state.selectedIncomingTransLine),
    );
    final selectedIncomingTransType = ref.watch(
      surveyController.select((state) => state.selectedIncomingTransType),
    );
    final selectedPoleWinchCondition = ref.watch(
      surveyController.select((state) => state.selectedPoleWinchCondition),
    );
    final selectedPoleRopeCondition = ref.watch(
      surveyController.select((state) => state.selectedPoleRopeCondition),
    );
    final selectedPoleRatingUnits = ref.watch(
      surveyController.select((state) => state.selectedPoleRatingUnits),
    );

    final isSurveyLocationFetched = ref.watch(
      surveyController.select((state) => state.isSurveyLocationFetched),
    );
    final fetchedLandMark = ref.watch(surveyController).fetchedLandMark;

    final fetchedLat = ref.watch(
      surveyController.select((state) => state.fetchedLat),
    );
    final fetchedLong = ref.watch(
      surveyController.select((state) => state.fetchedLong),
    );
    final fetchedAltitude = ref.watch(
      surveyController.select((state) => state.fetchedAltitude),
    );
    final isBracketMountingEditable = ref.watch(
      surveyController.select((state) => state.isBracketMountingEditable),
    );

    final polePrefix = ref
        .read(surveyController)
        .extractPolePrefix(poleNoTemplate, wardNumber);

    log(polePrefix);

    final transformerNoPrefixText = '$wardNumber-TFR';
    final spNoPrefixText = '$wardNumber-SP';

    return SafeArea(
        child: Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.19),
        elevation: 0.0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 18.0,
        ),
        title: Text(
          'Pole Asset Survey',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      body: ConnectivityBanner(
        child: WillPopScope(
          onWillPop: () async {
            ref.read(surveyController).clearAllUpdatedSelectedFields();
            return true;
          },
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(5),
            children: [
              UsableWidgets.projContextContainerInMaintenace(context, ref,
                  selectedRegion, selectedZone, selectedWard, null),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextField(
                          readOnly: isResurvey ? true : false,
                          maxLength: 4,
                          controller: poleNumberController,
                          obscureText: false,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            overflow: TextOverflow.ellipsis,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          onChanged: (newValue) async {
                            // log('pole name $newValue');
                            debounceUpdate(newValue, 'poleNumber', 'default');
                            // ref
                            //     .read(surveyController)
                            //     .updatePoleSurveyFieldValues(
                            //         context, ref, newValue, 'poleNumber');
                          },
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            counterText: '',
                            prefixText: polePrefix,
                            prefixStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            suffixIcon: InkWell(
                                child: Icon(Icons.qr_code,
                                    size: 23, color: darkBlue),
                                onTap: () async {
                                  ScanResult result =
                                      await BarcodeScanner.scan();
                                  if (result.rawContent != '') {
                                    // bool isValidPole = await ref
                                    //     .read(surveyController)
                                    //     .isValidPoleNumber(result.rawContent);
                                    // if (isValidPole) {
                                    final regex = RegExp(r'^\d{4}$');
                                    if (!regex
                                        .hasMatch(result.rawContent.trim())) {
                                      if (context.mounted) {
                                        FocusScope.of(context).unfocus();
                                      }
                                      if (context.mounted) {
                                        showSnackBar(
                                          ref,
                                          context,
                                          "Invalid pole number. It must contain only 4 digits.",
                                        );
                                      }
                                      return;
                                    }
                                    log('pole name $result.rawContent');
                                    await ref
                                        .read(surveyController)
                                        .updatePoleSurveyFieldValues(
                                          context,
                                          ref,
                                          result.rawContent,
                                          "poleNumber",
                                        );
                                    // } else {
                                    //   alertPopUp1(
                                    //       context,
                                    //       'Invalid Pole Number format. Please enter a valid Pole Number format (BBMPSNLW99P9999)',
                                    //       'assets/animation/warn.json');
                                    // }
                                  }
                                }),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelText: 'Pole Number *',
                            labelStyle: TextStyle(
                                fontSize: 17,
                                color: darkBlue,
                                fontWeight: FontWeight.bold),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
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
              const SizedBox(
                height: 10,
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
                        ref.read(surveyController).updateVehicleAccess(value);
                      }
                    },
                  )),
                ],
              ),
              const SizedBox(
                height: 10,
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

                      ref.read(surveyController).updateBaseSurveyFieldValues(
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

                      ref.read(surveyController).updateBaseSurveyFieldValues(
                          context, ref, value, 'trafficSpeed');
                    },
                  )),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ebPoleNoController,
                        obscureText: false,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onChanged: (newValue) {
                          debounceUpdate(
                              newValue, 'escomPoleNumber', 'default');
                        },
                        maxLength: 25,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          counterText: '',
                          labelText: 'EB Pole No',
                          labelStyle: TextStyle(
                              fontSize: 17,
                              color: darkBlue,
                              fontWeight: FontWeight.bold),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      child: TextField(
                        // readOnly: false,
                        controller: exCorpPoleNoController,
                        keyboardType: TextInputType.number,
                        obscureText: false,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onChanged: (newValue) {
                          // log('exCorpPoleNo $newValue');
                          debounceUpdate(newValue, 'exCorpPoleNo', 'default');
                          // ref
                          //     .read(surveyController)
                          //     .updatePoleSurveyFieldValues(
                          //         context, ref, newValue, 'exCorpPoleNo');
                        },
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          counterText: '',
                          labelText: 'Ex Corp Pole No',
                          labelStyle: TextStyle(
                              fontSize: 17,
                              color: darkBlue,
                              fontWeight: FontWeight.bold),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: Hive.box(assetNameBox).listenable(),
                        builder: (context, Box box, _) {
                          final wardData = box.get('ward_$selectedWardId');
                          log('wardData: $wardData');
                          final transformerNames = wardData == null
                              ? <String>[]
                              : List<String>.from(
                                  wardData['transformers'] ?? []);

                          return editableDropdownField(context, ref,
                              assetType: 'transformer',
                              dropdownItems: transformerNames,
                              controller: poleTransformerNoController,
                              label: 'Transformer No',
                              prefixText: transformerNoPrefixText);
                        },
                      ),
                      // child: TextField(
                      //   // readOnly: false,
                      //   controller: poleTransformerNoController,
                      //   obscureText: false,
                      //   style: const TextStyle(
                      //     color: Colors.black,
                      //     fontSize: 14,
                      //     overflow: TextOverflow.ellipsis,
                      //   ),
                      //   onChanged: (newValue) {
                      //     // log('poleTransFormerNo $newValue');
                      //     debounceUpdate(newValue.toUpperCase(),
                      //         'poleTransFormerNo', 'default');
                      //     // ref
                      //     //     .read(surveyController)
                      //     //     .updatePoleSurveyFieldValues(
                      //     //         context,
                      //     //         ref,
                      //     //         newValue.toUpperCase(),
                      //     //         'poleTransFormerNo');
                      //   },
                      //   maxLength: 15,

                      //   decoration: InputDecoration(
                      //     prefixText: transformerNoPrefixText,
                      //     prefixStyle: TextStyle(
                      //       color: Colors.grey[600],
                      //       fontSize: 14,
                      //       fontWeight: FontWeight.w500,
                      //     ),
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(8),
                      //     ),
                      //     counterText: '',
                      //     labelText: 'Transformer No',
                      //     labelStyle: TextStyle(
                      //         fontSize: 17,
                      //         color: darkBlue,
                      //         fontWeight: FontWeight.bold),
                      //     floatingLabelBehavior: FloatingLabelBehavior.always,
                      //   ),
                      // ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: Hive.box(assetNameBox).listenable(),
                        builder: (context, Box box, _) {
                          final wardData = box.get('ward_$selectedWardId');
                          log('wardData: $wardData');
                          final switchPointNames = wardData == null
                              ? <String>[]
                              : List<String>.from(
                                  wardData['switchPoints'] ?? []);

                          return editableDropdownField(context, ref,
                              assetType: 'switchPoint',
                              dropdownItems: switchPointNames,
                              controller: switchPointController,
                              label: 'Switch Point No',
                              prefixText: spNoPrefixText);
                        },
                      ),
                    ),

                    // Expanded(
                    //   child: TextField(
                    //     keyboardType: TextInputType.number,
                    //     // readOnly: false,
                    //     controller: switchPointController,
                    //     obscureText: false,
                    //     inputFormatters: [
                    //       FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    //     ],
                    //     style: const TextStyle(
                    //       color: Colors.black,
                    //       fontSize: 14,
                    //       overflow: TextOverflow.ellipsis,
                    //     ),
                    //     onChanged: (newValue) {
                    //       // log('switchPointNo $newValue');
                    //       debounceUpdate(newValue.toUpperCase(),
                    //           'switchPointNo', 'default');
                    //       // ref
                    //       //     .read(surveyController)
                    //       //     .updatePoleSurveyFieldValues(context, ref,
                    //       //         newValue.toUpperCase(), 'switchPointNo');
                    //     },
                    //     maxLength: 3,
                    //     decoration: InputDecoration(
                    //       prefixText: spNoPrefixText,
                    //       prefixStyle: TextStyle(
                    //         color: Colors.grey[600],
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w500,
                    //       ),
                    //       border: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //       counterText: '',
                    //       // hintText: 'eg : SP999',
                    //       labelText: 'Switch Point No',
                    //       labelStyle: TextStyle(
                    //           fontSize: 17,
                    //           color: darkBlue,
                    //           fontWeight: FontWeight.bold),
                    //       floatingLabelBehavior: FloatingLabelBehavior.always,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
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
                          TextField(
                            // animationType: Animationtype.typer,
                            keyboardType: TextInputType
                                .visiblePassword, // to remove emoji from the keyboard
                            maxLength: 100,

                            controller: surveyManualLocationController,

                            style: const TextStyle(color: Colors.black),

                            onChanged: (value) {
                              ref
                                  .read(surveyController)
                                  .updateSurveyFieldValues(context, ref, value,
                                      'manualEnteredLocation');
                            },

                            decoration: InputDecoration(
                                hintStyle: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Theme.of(context).secondaryHeaderColor),
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
                                      color: Color.fromARGB(248, 64, 124, 161),
                                      width: 1.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color.fromARGB(248, 64, 124, 161),
                                      width: 1.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                )),
                          ),
                          const SizedBox(height: 20),
                          isSurveyLocationFetched == true
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    fetchedLandMark != ''
                                        ? Text(
                                            fetchedLandMark,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.bold),
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
                                      color: Theme.of(context).primaryColor),
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
                      value: selectedPoleCondition,
                      label: "Pole Condition",
                      items: poleConditions,
                      onChanged: (newValue) {
                        // log('selected value $newValue');
                        debounceUpdate(
                            newValue.toString(), 'poleCondition', 'pole');
                        // ref
                        //     .read(surveyController)
                        //     .updatePoleSurveyFieldPoleValues(
                        //         context, ref, newValue, 'poleCondition');
                      },
                    ),
                  ),
                  if (selectedPoleCondition != 'Missing')
                    Expanded(
                        child: UsableWidgets.buildDropdown(
                      context,
                      value: selectedPoleType,
                      label: "Pole Type",
                      items: poleTypes,
                      onChanged: (newValue) {
                        // log('selected value $newValue');
                        debounceUpdate(newValue.toString(), 'poleType', 'pole');
                        // ref
                        //     .read(surveyController)
                        //     .updatePoleSurveyFieldPoleValues(
                        //         context, ref, newValue, 'poleType');
                        // ref
                        //     .read(surveyController)
                        //     .updatePoleTypeCascade(context, ref, newValue!);
                      },
                    )),
                ],
              ),
              if (selectedPoleCondition != 'Missing')
                Row(
                  children: [
                    if (selectedPoleType != 'High Mast(HM)' &&
                        selectedPoleType != 'Mini Mast(MM)')
                      Expanded(
                        child: UsableWidgets.buildDropdown(
                          context,
                          value: selectedPoleSpan,
                          label: "Pole Span *",
                          items: poleSpan,
                          onChanged: (newValue) {
                            // log('selected value $newValue');
                            debounceUpdate(
                                newValue.toString(), 'poleSpan', 'pole');
                            // ref
                            //     .read(surveyController)
                            //     .updatePoleSurveyFieldPoleValues(
                            //         context, ref, newValue, 'poleSpan');
                          },
                        ),
                      ),
                    Expanded(
                        child: UsableWidgets.buildDropdown(
                      context,
                      value: selectedPoleHeight,
                      label: "Pole Height",
                      items: poleHeightOptions,
                      onChanged: (newValue) {
                        // log('selected value $newValue');
                        debounceUpdate(
                            newValue.toString(), 'poleHeight', 'pole');
                        // ref
                        //     .read(surveyController)
                        //     .updatePoleSurveyFieldPoleValues(
                        //         context, ref, newValue, 'poleHeight');
                      },
                    )),
                  ],
                ),
              if (selectedPoleType == 'High Mast(HM)')
                Row(
                  children: [
                    Expanded(
                      child: UsableWidgets.buildDropdown(
                        context,
                        value: selectedPoleMotorCondition,
                        label: "Motor Condition",
                        items: motorConditionOptions,
                        onChanged: (newValue) {
                          // log('selected value $newValue');
                          debounceUpdate(
                              newValue.toString(), 'motorCondition', 'motor');
                          // ref
                          //     .read(surveyController)
                          //     .updatePoleSurveyFieldMotorValues(
                          //         context, ref, newValue, 'motorCondition');
                        },
                      ),
                    ),
                  ],
                ),
              if (selectedPoleType == 'High Mast(HM)' &&
                  selectedPoleMotorCondition != 'Missing')
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
                          "Motor Details",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 6.0),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  controller: poleMotorRatingController,
                                  obscureText: false,
                                  maxLength: 4,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onChanged: (newValue) {
                                    // log('Motor Rating $newValue');
                                    debounceUpdate(newValue.toString(),
                                        'motorRating', 'motor');
                                    // ref
                                    //     .read(surveyController)
                                    //     .updatePoleSurveyFieldMotorValues(
                                    //         context,
                                    //         ref,
                                    //         newValue,
                                    //         'motorRating');
                                  },
                                  decoration: InputDecoration(
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    labelText: 'Rating',
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
                              value: selectedPoleRatingUnits,
                              label: "Rating Units",
                              items: poleMotorRatingUnitsOptions,
                              onChanged: (newValue) {
                                // log('motor rating units $newValue');
                                debounceUpdate(newValue.toString(),
                                    'ratingUnits', 'motor');

                                // ref
                                //     .read(surveyController)
                                //     .updatePoleSurveyFieldMotorValues(
                                //         context,
                                //         ref,
                                //         newValue,
                                //         'ratingUnits');
                              },
                            )),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 6.0),
                                child: TextField(
                                  controller: poleMotorMakeController,
                                  obscureText: false,
                                  maxLength: 15,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onChanged: (newValue) {
                                    // log('Motor Make $newValue');
                                    debounceUpdate(newValue.toString(),
                                        'motorMake', 'motor');
                                    // ref
                                    //     .read(surveyController)
                                    //     .updatePoleSurveyFieldMotorValues(
                                    //         context,
                                    //         ref,
                                    //         newValue,
                                    //         'motorMake');
                                  },
                                  decoration: InputDecoration(
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 6.0),
                                child: TextField(
                                  maxLength: 15,
                                  controller: poleMotorModelController,
                                  obscureText: false,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onChanged: (newValue) {
                                    // log('Motor Model $newValue');
                                    debounceUpdate(newValue.toString(),
                                        'motorModel', 'motor');

                                    // ref
                                    //     .read(surveyController)
                                    //     .updatePoleSurveyFieldMotorValues(
                                    //         context,
                                    //         ref,
                                    //         newValue,
                                    //         'motorModel');
                                  },
                                  decoration: InputDecoration(
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    labelText: 'Model',
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
                      ],
                    ),
                  ),
                ),
              if (selectedPoleType == 'High Mast(HM)')
                Row(
                  children: [
                    Expanded(
                        child: UsableWidgets.buildDropdown(
                      context,
                      value: selectedPoleWinchCondition,
                      label: "Winch Condition",
                      items: poleWinchConditionOptions,
                      onChanged: (newValue) {
                        // log('winch condition $newValue');
                        debounceUpdate(
                            newValue.toString(), 'winchCondition', 'motor');

                        // ref
                        //     .read(surveyController)
                        //     .updatePoleSurveyFieldMotorValues(
                        //         context, ref, newValue, 'winchCondition');
                      },
                    )),
                    Expanded(
                        child: UsableWidgets.buildDropdown(
                      context,
                      value: selectedPoleRopeCondition,
                      label: "Rope Condition",
                      items: poleRopeConditionOptions,
                      onChanged: (newValue) {
                        // log('rope condition $newValue');
                        debounceUpdate(
                            newValue.toString(), 'ropeCondition', 'motor');

                        // ref
                        //     .read(surveyController)
                        //     .updatePoleSurveyFieldMotorValues(
                        //         context, ref, newValue, 'ropeCondition');
                      },
                    )),
                  ],
                ),
              if (selectedPoleCondition != 'Missing')
                Row(
                  children: [
                    Expanded(
                      child: UsableWidgets.buildDropdown(
                        context,
                        value: selectedIncomingTransLine,
                        label: "Incoming\nTransmission Line",
                        items: incomingTransLineOptions,
                        onChanged: (newValue) {
                          // log('selected value $newValue');
                          debounceUpdate(
                              newValue.toString(), 'incomingTransLine', 'pole');

                          // ref
                          //     .read(surveyController)
                          //     .updatePoleSurveyFieldPoleValues(context, ref,
                          //         newValue, 'incomingTransLine');
                        },
                      ),
                    ),
                    Expanded(
                      child: UsableWidgets.buildDropdown(
                        context,
                        value: selectedIncomingTransType,
                        label: "Incoming\nTransmission Type",
                        items: incomingTransTypeOptions,
                        onChanged: (newValue) {
                          // log('selected value $newValue');
                          debounceUpdate(
                              newValue.toString(), 'incomingTransType', 'pole');

                          // ref
                          //     .read(surveyController)
                          //     .updatePoleSurveyFieldPoleValues(context, ref,
                          //         newValue, 'incomingTransType');
                        },
                      ),
                    ),
                  ],
                ),
              if (selectedPoleCondition != 'Missing' &&
                  (selectedPoleType != 'High Mast(HM)' &&
                      selectedPoleType != 'Mini Mast(MM)'))
                UsableWidgets.buildDropdown(
                  context,
                  value: selectedClampType,
                  label: "Clamp Dimension",
                  items: clampTypeOptions,
                  onChanged: (newValue) {
                    // log('selected value $newValue');
                    debounceUpdate(newValue.toString(), 'clampType', 'pole');

                    // ref
                    //     .read(surveyController)
                    //     .updatePoleSurveyFieldPoleValues(
                    //         context, ref, newValue, 'clampType');
                  },
                ),
              if (selectedPoleCondition != 'Missing')
                if (selectedClampType == 'Others')
                  const SizedBox(
                    height: 10,
                  ),
              if (selectedPoleCondition != 'Missing')
                if (selectedClampType == 'Others')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 47,
                        width: 54,
                        child: TextField(
                          controller: clampTypeLengthController,
                          style: const TextStyle(color: Colors.black),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          cursorColor: Theme.of(context).primaryColor,
                          decoration: InputDecoration(
                              errorStyle: const TextStyle(fontSize: 4),
                              border: const OutlineInputBorder(),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              counterText: '',
                              labelText: '<L>',
                              labelStyle: TextStyle(
                                  color: darkBlue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          onChanged: (newValue) {
                            if (newValue.length == 1 || newValue.length == 2) {
                              // FocusScope.of(context).nextFocus();
                              debounceUpdate(clampTypeLengthController.text,
                                  'customInputLength', 'pole');
                              // ref
                              //     .read(surveyController)
                              //     .updatePoleSurveyFieldPoleValues(
                              //         context,
                              //         ref,
                              //         clampTypeLengthController.text,
                              //         'customInputLength');
                            }
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      const Text('x', style: TextStyle(fontSize: 21)),
                      const SizedBox(
                        width: 14,
                      ),
                      SizedBox(
                        height: 47,
                        width: 54,
                        child: TextField(
                          controller: clampTypeWidthController,
                          style: const TextStyle(color: Colors.black),
                          // autofocus: autoFocus,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          // controller: controller,
                          maxLength: 2,
                          cursorColor: Theme.of(context).primaryColor,
                          decoration: InputDecoration(
                              errorStyle: const TextStyle(fontSize: 4),
                              border: const OutlineInputBorder(),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              counterText: '',
                              labelText: '<W>',
                              labelStyle: TextStyle(
                                  color: darkBlue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          onChanged: (newValue) {
                            if (newValue.length == 1 || newValue.length == 2) {
                              // FocusScope.of(context).nextFocus();
                              debounceUpdate(clampTypeWidthController.text,
                                  'customInputWidth', 'pole');
                              // ref
                              // .read(surveyController)
                              // .updatePoleSurveyFieldPoleValues(
                              //     context,
                              //     ref,
                              //     clampTypeWidthController.text,
                              //     'customInputWidth');
                            }
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 21,
                      ),
                      SizedBox(
                        height: 56,
                        width: 130,
                        child: InputDecorator(
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              label: RichText(
                                  text: TextSpan(
                                text: 'Units',
                                style: TextStyle(
                                    color: darkBlue,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ))),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton2(
                            value: units.contains(selectedClampUnits)
                                ? selectedClampUnits
                                : null,
                            items: units.map((String items) {
                              return DropdownMenuItem(
                                alignment: AlignmentDirectional.centerStart,
                                value: items,
                                child: Text(
                                  items,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              debounceUpdate(newValue.toString(),
                                  'customInputUnits', 'pole');
                              // ref
                              //     .read(surveyController)
                              //     .updatePoleSurveyFieldPoleValues(context,
                              //         ref, newValue, 'customInputUnits');
                            },
                            dropdownStyleData: DropdownStyleData(
                                padding: const EdgeInsets.only(left: 15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.white,
                                )),
                            buttonStyleData: const ButtonStyleData(
                              padding: EdgeInsets.only(),
                              height: 60,
                            ),
                          )),
                        ),
                      ),
                    ],
                  ),
              if (selectedClampType == 'Others')
                const SizedBox(
                  height: 10,
                ),
              if (selectedPoleCondition != 'Missing')
                Row(
                  children: [
                    if (selectedPoleType != 'High Mast(HM)' &&
                        selectedPoleType != 'Mini Mast(MM)')
                      Expanded(
                        child: UsableWidgets.buildDropdown(context,
                            value: selectedBracketMountingHeight,
                            label: "Bracket\nMounting Height",
                            items: bracketMountingHeightOptions,
                            onChanged: (newValue) {
                          // log('selected value $newValue');
                          debounceUpdate(newValue.toString(),
                              'bracketMountingHeight', 'pole');

                          // ref
                          //     .read(surveyController)
                          //     .updatePoleSurveyFieldPoleValues(context,
                          //         ref, newValue, 'bracketMountingHeight');
                        }, isEditable: isBracketMountingEditable),
                      ),
                    if (selectedPoleCondition != 'Missing')
                      if (selectedPoleType != 'High Mast(HM)' &&
                          selectedPoleType != 'Mini Mast(MM)')
                        if (selectedBracketMountingHeight == 'Others')
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              height: 47,
                              width: 54,
                              child: TextField(
                                style: const TextStyle(color: Colors.black),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                cursorColor: Theme.of(context).primaryColor,
                                decoration: InputDecoration(
                                    errorStyle: const TextStyle(fontSize: 4),
                                    border: const OutlineInputBorder(),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    counterText: '',
                                    labelText: '<M>',
                                    labelStyle: TextStyle(
                                        color: darkBlue,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                onChanged: (newValue) {
                                  if (newValue.length == 1 ||
                                      newValue.length == 2) {
                                    debounceUpdate(newValue.toString(),
                                        'customBracketHeight', 'pole');
                                    // ref
                                    //     .read(surveyController)
                                    //     .updatePoleSurveyFieldPoleValues(
                                    //         context,
                                    //         ref,
                                    //         newValue,
                                    //         'customBracketHeight');
                                  }
                                },
                              ),
                            ),
                          ),
                  ],
                ),
              if (selectedPoleCondition != 'Missing')
                Row(
                  children: [
                    UsableWidgets.yesNoToggle(
                        ref,
                        context,
                        'Earthing',
                        isEarthingRequired,
                        selectedPoleType != "RCC" &&
                            selectedPoleType != "Tubular"),
                    // yesNoToggle(
                    //     ref, context, 'Bracket Required', isBracketRequired),
                  ],
                ),
              if (selectedPoleCondition != 'Missing')
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
                          "Arm Details",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        UsableWidgets.buildDropdown(
                          context,
                          value: selectedArmCount,
                          label: "Count",
                          items: armCountOptions,
                          onChanged: (value) {
                            debounceUpdate(value.toString(), 'armCount', 'arm');
                            // ref
                            //     .read(surveyController)
                            //     .updatePoleSurveyFieldArmValues(
                            //         context, ref, value, 'armCount');
                          },
                        ),
                        if (selectedArmCount != '0')
                          UsableWidgets.buildDropdown(
                            context,
                            value: selectedArmLength,
                            label: "Length",
                            items: ['Normal', 'Small', 'Missing'],
                            onChanged: (value) {
                              debounceUpdate(
                                  value.toString(), 'armLength', 'arm');
                              // ref
                              //     .read(surveyController)
                              //     .updatePoleSurveyFieldArmValues(
                              //         context, ref, value, 'armLength');
                            },
                          ),
                        if (selectedArmCount != '0')
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            color: Colors.grey[100],
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Condition",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 10),
                                  buildNumberInputRow(ref, context, "Good",
                                      goodArmTextController, "arm"),
                                  buildNumberInputRow(ref, context, "Bad",
                                      badArmTextController, "arm"),
                                  buildNumberInputRow(ref, context, "Missing",
                                      missingArmTextController, "arm",
                                      enabled: false),
                                ],
                              ),
                            ),
                          ),
                        // if (selectedArmCount != '0')
                        //   buildDropdown(
                        //     context,
                        //     value: selectedArmCondition,
                        //     label: "Condition",
                        //     items: ['Good', 'Bad', 'Missing'],
                        //     onChanged: (value) {
                        //       ref
                        //           .read(surveyController)
                        //           .updatePoleSurveyFieldValues(
                        //               context, ref, value, 'armCondition');
                        //     },
                        //   ),
                      ],
                    ),
                  ),
                ),
              if (selectedPoleCondition != 'Missing')
                if (selectedArmCount != '0')
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
                            "Light Details",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),

                          /// Nested Card: Status and Count
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            color: Colors.grey[100],
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Status and Count",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 10),
                                  buildNumberInputRow(ref, context, "Working",
                                      workingTextController, "light"),
                                  buildNumberInputRow(
                                      ref,
                                      context,
                                      "Not Working",
                                      notWorkingTextController,
                                      "light"),
                                  buildNumberInputRow(ref, context, "Missing",
                                      missingTextController, "light",
                                      enabled: false),
                                ],
                              ),
                            ),
                          ),
                          if ((workingTextController.text != '0' &&
                                  workingTextController.text != '') ||
                              (notWorkingTextController.text != '0' &&
                                  notWorkingTextController.text != ''))
                            // Multiple Lamp Selection
                            ListView.builder(
                              // reverse: true,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: selectedLamps.length,
                              itemBuilder: (context, index) {
                                final lamp = selectedLamps[index];
                                return Row(
                                  children: [
                                    // Lamp Type Dropdown
                                    Expanded(
                                      child: lampTypesDropDown(
                                        context,
                                        selectedValue:
                                            lamp['type'] ?? 'Tube light',
                                        items: lampWattageOptions.keys.toList(),
                                        onChanged: (newType) {
                                          if (newType != null) {
                                            ref
                                                .read(surveyController)
                                                .updateLampType(index, newType);
                                          }
                                        },
                                        isExpanded: true,
                                      ),
                                    ),
                                    const SizedBox(width: 0),
                                    // Lamp Wattage Dropdown
                                    Expanded(
                                      child: lampTypesDropDown(
                                        context,
                                        selectedValue: lamp['watts'] ?? '40 W',
                                        items:
                                            lampWattageOptions[lamp['type']] ??
                                                [],
                                        onChanged: (newWatts) {
                                          if (newWatts != null) {
                                            ref
                                                .read(surveyController)
                                                .updateLampWatts(
                                                    index, newWatts);
                                          }
                                        },
                                        isExpanded: true,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 48,
                                      child: (index ==
                                                  selectedLamps.length - 1 &&
                                              (int.parse(selectedArmCount) !=
                                                  0))
                                          ? IconButton(
                                              tooltip: 'add',
                                              onPressed: selectedLamps.length <
                                                      int.parse(
                                                          selectedArmCount)
                                                  ? () {
                                                      ref
                                                          .read(
                                                              surveyController)
                                                          .addLamp();
                                                    }
                                                  : null,
                                              icon: Icon(
                                                Icons.add_circle,
                                                color: selectedLamps.length <
                                                        int.parse(
                                                            selectedArmCount)
                                                    ? const Color.fromARGB(
                                                            248, 64, 124, 161)
                                                        .withValues(alpha: 0.8)
                                                    : Colors.grey,
                                                size: 30,
                                              ),
                                            )
                                          : null, // Empty space for non-last rows
                                    ),
                                  ],
                                );
                              },
                            ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Expanded(
                                  child: UsableWidgets.buildDropdown(
                                context,
                                value: selectedManualSwitchCtrl,
                                label: "Manual Switch Control",
                                items: manualSwitchControlOptions,
                                onChanged: (value) {
                                  debounceUpdate(value.toString(),
                                      'manualSwitchCtrl', 'light');
                                  // ref
                                  //     .read(surveyController)
                                  //     .updatePoleSurveyFieldLightValues(
                                  //         context,
                                  //         ref,
                                  //         value,
                                  //         'manualSwitchCtrl');
                                },
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                child: Container(
                  height: MediaQuery.sizeOf(context).height * 0.12,
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(left: 3, right: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).primaryColor),
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
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                        onChanged: (value) {
                          debounceUpdate(value, 'comments', 'comments');

                          // ref.read(surveyController).updateSurveyFieldValues(
                          //     context, ref, value, "comments");
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
                height: 20,
              ),
              GestureDetector(
                  child: Center(
                    child: Container(
                      height: 50,
                      width: deviceWidth * 0.8,
                      // padding: const EdgeInsets.all(12),
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
                    ref.read(surveyController).onClickEventIsFor('poleSurvey');
                    // Check if location is available
                    if (fetchedLat == '' || fetchedLong == '') {
                      alertPopUp(context, 'Collecting Data Please Wait',
                          'assets/animation/userAlert.json');
                      return;
                    }

                    // Clamp Type validation
                    if (selectedClampType == 'Others') {
                      if (selectedClampWidth.isEmpty ||
                          selectedClampLength.isEmpty) {
                        FocusScope.of(context).unfocus();
                        showSnackBar(ref, context,
                            "Please provide the length and width");
                        return;
                      }
                      if (!isNumeric(selectedClampLength) ||
                          !isNumeric(selectedClampWidth)) {
                        FocusScope.of(context).unfocus();
                        showSnackBar(
                            ref, context, "Length and width must be numeric");
                        return;
                      }
                    }

                    if ((selectedPoleCondition != 'Missing') &&
                        selectedPoleType != 'High Mast(HM)' &&
                        selectedPoleType != 'Mini Mast(MM)') {
                      if (selectedPoleSpan.isEmpty) {
                        showSnackBar(ref, context, "Please provide Pole Span");
                        return;
                      }

                      // Bracket Mounting Height validation
                      if (selectedBracketMountingHeight == 'Others') {
                        if (selectedCustomBracketHeight.isEmpty) {
                          FocusScope.of(context).unfocus();
                          showSnackBar(ref, context,
                              "Please provide the Meter for bracket mounting height");
                          return;
                        }
                        if (!isNumeric(selectedCustomBracketHeight)) {
                          FocusScope.of(context).unfocus();
                          showSnackBar(ref, context, "Meter must be numeric");
                          return;
                        }
                      }
                    }

                    // Pole number check
                    final formattedPoleNo = ref
                        .read(surveyController)
                        .padNumber(poleNumberController.text.trim(),
                            4); //zero padded for 4 digits
                    if (formattedPoleNo.isEmpty) {
                      showSnackBar(ref, context, "Please provide Pole Number");
                      return;
                    }

                    if (exCorpPoleNoController.text.isNotEmpty) {
                      final regex = RegExp(r'^\d{4}$');
                      if (!regex.hasMatch(exCorpPoleNoController.text)) {
                        FocusScope.of(context).unfocus();
                        showSnackBar(
                          ref,
                          context,
                          "Invalid Ex Corp Pole No. It must contain only 4 digits.",
                        );
                        return;
                      }
                    }

                    // if (switchPointNumber.isEmpty) {
                    //   showToastMessage(
                    //       context, "Please provide Switch Point Number");
                    //   return;
                    // }

                    // switch Point no check
                    // Dropdown selections are already in the stored format
                    // and must be kept as-is; only manually typed values
                    // get zero-padded to 4 digits.
                    final formattedSPNumber = ref
                            .read(surveyController)
                            .isSwitchPointFromDropdown
                        ? switchPointController.text.trim()
                        : ref
                            .read(surveyController)
                            .padNumber(switchPointController.text.trim(), 4);
                    if (switchPointController.text.isNotEmpty) {
                      final isValidSwitchPoint = ref
                          .read(surveyController)
                          .isValidSwitchPointNo(formattedSPNumber);
                      if (!isValidSwitchPoint) {
                        alertPopUp1(
                          context,
                          'Invalid Switch Point Number format. Please enter a valid format (SP999)',
                          'assets/animation/warn.json',
                        );
                        return;
                      } else {
                        ref.read(surveyController).updatePoleSurveyFieldValues(
                              context,
                              ref,
                              '$spNoPrefixText$formattedSPNumber',
                              'switchPointNo',
                            );
                      }
                    }

                    if (poleTransformerNoController.text.isNotEmpty) {
                      ref.read(surveyController).updatePoleSurveyFieldValues(
                            context,
                            ref,
                            '$transformerNoPrefixText${poleTransformerNoController.text.trim()}',
                            'poleTransFormerNo',
                          );
                    }
                    final concatMotorRatingValue = poleMotorRatingController
                            .text.isEmpty
                        ? '0 $selectedPoleRatingUnits'
                        : '${poleMotorRatingController.text} $selectedPoleRatingUnits';
                    ref.read(surveyController).updatePoleSurveyFieldMotorValues(
                          context,
                          ref,
                          concatMotorRatingValue,
                          'motorRating',
                        );
                    final generatedPoleName =
                        ref.read(surveyController).generatePoleName(
                              template: poleNoTemplate,
                              wardNo: wardNumber,
                              poleNo: 'P$formattedPoleNo',
                              switchPointNo: 'SP$formattedSPNumber',
                            );
                    // log('Formatted Pole Number: $generatedPoleName');
                    ref.read(surveyController).updatePoleSurveyFieldValues(
                          context,
                          ref,
                          generatedPoleName,
                          'poleNumber',
                        );

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
            ],
          ),
        ),
      ),
    ));
  }
}

Widget buildNumberInputRow(
  WidgetRef ref,
  BuildContext context,
  String label,
  TextEditingController controller,
  String fieldType, {
  bool enabled = true,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(
          width: 55,
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            onChanged: enabled
                ? (val) {
                    if (fieldType == 'arm') {
                      ref.read(surveyController).updatePoleSurveyFieldArmValues(
                          context, ref, val, label);
                    } else if (fieldType == 'light') {
                      ref
                          .read(surveyController)
                          .updatePoleSurveyFieldLightValues(
                              context, ref, val, label);
                    } else {
                      ref
                          .read(surveyController)
                          .updateSurveyFieldValues(context, ref, val, label);
                    }
                  }
                : null,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget lampTypesDropDown(
  BuildContext context, {
  required String selectedValue,
  required List<String> items,
  required ValueChanged<String?> onChanged,
  required bool isExpanded,
}) {
  double deviceWidth = MediaQuery.sizeOf(context).width;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
    child: DropdownButtonHideUnderline(
      child: DropdownButton2(
        isDense: true,
        isExpanded: isExpanded,
        value: items.contains(selectedValue) ? selectedValue : null,
        items: items.map((String item) {
          return DropdownMenuItem(
            alignment: AlignmentDirectional.centerStart,
            value: item,
            child: Text(
              item,
              style: const TextStyle(color: Colors.black, fontSize: 12),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownStyleData: DropdownStyleData(
          padding: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Theme.of(context).canvasColor,
          ),
        ),
        buttonStyleData: ButtonStyleData(
          height: 45,
          width: deviceWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Theme.of(context).canvasColor,
          ),
          elevation: 1,
        ),
      ),
    ),
  );
}

Widget editableDropdownField(
  BuildContext context,
  WidgetRef ref, {
  required final String assetType,
  required final String prefixText,
  required final TextEditingController controller,
  required final List<String> dropdownItems,
  required final String label,
  bool useFloatingLabel = true,
}) {
  return TextField(
    controller: controller,
    maxLength: assetType == 'switchPoint' ? 4 : 15,
    keyboardType:
        assetType == 'switchPoint' ? TextInputType.number : TextInputType.text,
    onChanged: (value) {
      if (assetType == 'switchPoint') {
        ref.read(surveyController).isSwitchPointFromDropdown = false;
        ref.read(surveyController).updatePoleSurveyFieldValues(
              context,
              ref,
              value.toUpperCase(),
              'switchPointNo',
            );
      } else if (assetType == 'transformer') {
        ref.read(surveyController).updatePoleSurveyFieldValues(
              context,
              ref,
              value.toUpperCase(),
              'poleTransFormerNo',
            );
        //  debounceUpdate(newValue.toUpperCase(),
        //                       'poleTransFormerNo', 'default');
      }
    },
    style: const TextStyle(color: Colors.black),
    decoration: InputDecoration(
      counterText: '',
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              prefixText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 0,
        minHeight: 0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 18,
      ),
      suffixIcon: PopupMenuButton<String>(
        position: PopupMenuPosition.under,
        icon: const Icon(Icons.arrow_drop_down),
        color: Colors.white,
        constraints: const BoxConstraints(
          maxHeight: 200,
        ),
        onSelected: (String value) {
          if (assetType == 'switchPoint') {
            final match = RegExp(r'SP(\d+)$').firstMatch(value);
            final numericValue = match != null ? match.group(1)! : value;

            controller.text = numericValue;
            ref.read(surveyController).isSwitchPointFromDropdown = true;

            ref.read(surveyController).updatePoleSurveyFieldValues(
                  context,
                  ref,
                  numericValue,
                  'switchPointNo',
                );
          } else if (assetType == 'transformer') {
            final match = RegExp(r'TFR(.+)$').firstMatch(value);
            final numericValue = match != null ? match.group(1)! : value;

            controller.text = numericValue;

            ref.read(surveyController).updatePoleSurveyFieldValues(
                  context,
                  ref,
                  numericValue,
                  'poleTransFormerNo',
                );
          }

          // log('Selected SP value: $numericValue');
        },
        itemBuilder: (BuildContext context) {
          return dropdownItems.map((String item) {
            return PopupMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList();
        },
      ),
      labelText: useFloatingLabel ? label : null,
      // hintText: useFloatingLabel ? null : label,
      hintStyle: useFloatingLabel
          ? null
          : TextStyle(fontSize: 14, color: Colors.grey[500]),
      labelStyle:
          TextStyle(fontSize: 17, color: darkBlue, fontWeight: FontWeight.bold),
      floatingLabelBehavior: useFloatingLabel
          ? FloatingLabelBehavior.always
          : FloatingLabelBehavior.never,
    ),
  );
}

// Widget editableDropdown({
//   required List<String> items,
//   required TextEditingController controller,
//   required String label,
//   String? prefixText,
//   int maxLength = 15,
// }) {
//   final focusNode = FocusNode();

//   return LayoutBuilder(
//     builder: (context, constraints) {
//       return RawAutocomplete<String>(
//           textEditingController: controller,
//           focusNode: focusNode,

//           // Always show all items
//           optionsBuilder: (text) => items,
//           onSelected: (value) {
//             controller.text = value.toUpperCase();
//           },
//           fieldViewBuilder: (context, textController, focusNode, _) {
//             return TextField(
//               controller: textController,
//               focusNode: focusNode,
//               maxLength: maxLength,
//               style: const TextStyle(fontSize: 14),
//               decoration: InputDecoration(
//                 prefixText: prefixText,
//                 counterText: '',
//                 labelText: label,
//                 floatingLabelBehavior: FloatingLabelBehavior.always,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.arrow_drop_down),
//                   onPressed: () {
//                     focusNode.requestFocus();

//                     final currentText = textController.text;
//                     textController.text = '$currentText ';
//                     textController.text = currentText;
//                   },
//                 ),
//               ),
//             );
//           },
//           optionsViewBuilder: (context, onSelected, options) {
//             if (options.isEmpty) return const SizedBox.shrink();

//             return Align(
//               alignment: Alignment.topLeft,
//               child: Material(
//                 elevation: 4,
//                 borderRadius: BorderRadius.circular(8),
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(
//                     maxHeight: 250, // controls dropdown height
//                   ),
//                   child: SizedBox(
//                     width: constraints.maxWidth,
//                     child: Scrollbar(
//                       thumbVisibility: true,
//                       child: ListView.builder(
//                         padding: EdgeInsets.zero,
//                         itemCount: options.length,
//                         itemBuilder: (context, index) {
//                           final option = options.elementAt(index);
//                           return ListTile(
//                             dense: true,
//                             title: Text(option),
//                             onTap: () => onSelected(option),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           });
//     },
//   );
// }

Widget editableDropdown(
  context, {
  required List<String> items,
  required TextEditingController controller,
  required String label,
  String? prefixText,
  int maxLength = 15,
}) {
  return DropdownMenu<String>(
    controller: controller,
    enableSearch: false,
    enableFilter: false, // Keeps all items visible always
    requestFocusOnTap: true,
    expandedInsets: EdgeInsets.zero,
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(Colors.white),
      surfaceTintColor: WidgetStateProperty.all(Colors.white),
      elevation: WidgetStateProperty.all(6),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),

    menuHeight: 200,

    // leadingIcon: Image.asset(
    //   "assets/images/poleAsset.png",
    //   height: 12,
    // ),
    inputDecorationTheme: InputDecorationTheme(
      prefixStyle: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle:
          TextStyle(fontSize: 17, color: darkBlue, fontWeight: FontWeight.bold),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    ),

    label: Text(label),
    dropdownMenuEntries: items.map((String name) {
      return DropdownMenuEntry<String>(
        value: name,
        label: name,
      );
    }).toList(),
    textStyle: const TextStyle(
      color: Colors.black,
      fontSize: 14,
      overflow: TextOverflow.ellipsis,
    ),
    onSelected: (String? newValue) {
      if (newValue != null) {
        controller.text = newValue;
        // Trigger your update logic here
        // debounceUpdate(newValue.toUpperCase(), 'switchPointNo', 'default');
      }
    },
  );
}
