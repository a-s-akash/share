import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:schnell_luminator/home_page/dashboard.dart';
import 'package:schnell_luminator/utils/widgets.dart';
import '../device_page/device_controller.dart';
import '../login_page/login_controller.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../survey/background_sync_manager.dart';
import '../survey/excel_export.dart';
import '../survey/screens/pole_survey.dart';
import '../survey/screens/switch_point_survey.dart';
import '../survey/screens/transformer_survey.dart';
import '../survey/survey_controller.dart';
import '../utils/asset_folder.dart';
import '../utils/dialog_box.dart';
import '../utils/error_messages.dart';
import '../utils/utility.dart';
import 'pole_controller.dart';
import 'pole_history_model.dart';

class PoleInstalltionHistoryInfo extends ConsumerStatefulWidget {
  const PoleInstalltionHistoryInfo({super.key});
  @override
  ConsumerState<PoleInstalltionHistoryInfo> createState() =>
      _PoleInstalltionHistoryInfoState();
}

class _PoleInstalltionHistoryInfoState
    extends ConsumerState<PoleInstalltionHistoryInfo>
    with WidgetsBindingObserver {
  late Box<InstallationHistory> historyBox;
  bool isBoxReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await openBox();
      Future.microtask(() async {
        final controller = ref.read(poleController);
        await controller.loadCombinedHistory(ref);
        controller.loadWardCounts(ref);
      });
    });
  }

  Future<void> openBox() async {
    historyBox = await Utility.openInstallationHistoryBox();
    setState(() {
      isBoxReady = true;
    });
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      log('App resumed - checking connectivity status');
      // BackgroundSyncWorkManager.registerInternetCheckTask();
      // Refresh UI from SharedPreferences immediately
      // await ref.read(internetStatusProvider.notifier).syncFromPrefs();
      BackgroundSyncWorkManager.triggerImmediateSync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;
    String selectedWardId = ref.watch(deviceController).selectedWardId;
    final usermail = ref.read(loginController).userMail;
    final hasInternet = ref.watch(internetStatusProvider);
    int totalAssetUserCount = ref.watch(poleController).totalAssetUserCount;
    int totalAssetWardCount = ref.watch(poleController).totalAssetWardCount;
    String selectedWardDesc = ref.watch(deviceController).selectedWardDesc;
    String selectedAssetType = ref.watch(
      surveyController.select((state) => state.selectedAssetType),
    );
    final selectedRoadType = ref.watch(
      surveyController.select((state) => state.selectedRoadType),
    );
    String wardNumber = ref.watch(
      surveyController.select((state) => state.wardNumberForPolePrefix),
    );
    String polePrefix = ref.watch(surveyController).surveyPolePrefix;
    String spNoPrefixText = '$wardNumber-SP';
    String transformerNoPrefixText = '$wardNumber-TFR';
    List poleSearchList = ref.watch(deviceController).poleSearchList;
    List poleFilteredList =
        poleSearchList.where((item) => item['type'] == "pole").toList();
    poleFilteredList.sort((a, b) => a["name"].compareTo(b["name"]));
    List spSearchList = ref.watch(deviceController).spSearchList;
    List spFilteredList =
        spSearchList.where((item) => item['type'] == "switchPoint").toList();
    spFilteredList.sort((a, b) => a["name"].compareTo(b["name"]));
    List transSearchList = ref.watch(deviceController).transSearchList;
    List transFilteredList =
        transSearchList.where((item) => item['type'] == "transformer").toList();
    transFilteredList.sort((a, b) => a["name"].compareTo(b["name"]));

    return WillPopScope(
        onWillPop: () async {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false);

          return false;
        },
        child: SafeArea(
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
              "SURVEY SUMMARY",
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
                  await showExportDialog(context);
                },
                icon: const Icon(
                  Icons.file_download,
                  color: Colors.green,
                ),
                tooltip: 'Export to Excel',
              ),
              IconButton(
                onPressed: () async {
                  await ref.read(surveyController).performManualSync();
                },
                icon: const Icon(
                  Icons.sync,
                  color: Colors.blue,
                ),
              ),
              // IconButton(
              //   onPressed: () async {},
              //   icon: Icon(
              //     hasInternet ? Icons.cloud : Icons.cloud_off,
              //     color: hasInternet ? Colors.green : Colors.red,
              //   ),
              // ),
              // const UploadProgressIndicator(),
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
                      const SizedBox(
                        width: 10,
                      ),
                      Row(
                        mainAxisAlignment: hasInternet == true
                            ? MainAxisAlignment.spaceEvenly
                            : MainAxisAlignment.center,
                        children: [
                          UsableWidgets.projContextContainerInHistory(
                              context,
                              selectedRegion,
                              selectedZone,
                              selectedWard,
                              selectedWardDesc),
                          const SizedBox(
                            height: 30,
                          ),
                          hasInternet == true
                              ? UsableWidgets.assetCountContainer(
                                  context, totalAssetWardCount, Icons.business)
                              : Container(),
                          const SizedBox(
                            width: 10,
                          ),
                          hasInternet == true
                              ? UsableWidgets.assetCountContainer(context,
                                  totalAssetUserCount, Icons.person_2_outlined)
                              : Container(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                isBoxReady
                    ? ValueListenableBuilder(
                        valueListenable: historyBox.listenable(),
                        builder: (context, Box<InstallationHistory> b, _) {
                          final list = b.values
                              .where((e) =>
                                  e.wardId == selectedWardId &&
                                  e.usermail == usermail)
                              .toList()
                            ..sort((a, b) => DateTime.parse(
                                        b.date.split('-').reversed.join('-'))
                                    .compareTo(
                                  DateTime.parse(
                                      a.date.split('-').reversed.join('-')),
                                ));

                          if (list.isEmpty) {
                            return const Center(
                                child: Text('No history available'));
                          }

                          return SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Table(
                                  border: TableBorder.all(
                                    width: 0.5,
                                    color: Theme.of(context).primaryColorLight,
                                  ),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1.5),
                                    1: FlexColumnWidth(1),
                                    2: FlexColumnWidth(1),
                                    3: FlexColumnWidth(1),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.6)),
                                      children: const [
                                        Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Center(
                                                child: Text('Date',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)))),
                                        Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Center(
                                                child: Text('Pole',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)))),
                                        Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Center(
                                                child: Text('SwitchPoint',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)))),
                                        Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Center(
                                                child: Text('Transformer',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)))),
                                      ],
                                    ),
                                    ...list.map((e) {
                                      final isToday = e.date ==
                                          '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}';
                                      return TableRow(
                                          decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColorLight
                                                  .withValues(alpha: 0.3)),
                                          children: [
                                            Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Center(
                                                    child: Text(isToday
                                                        ? 'Today'
                                                        : e.date))),
                                            Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Center(
                                                    child: Text('${e.pole}'))),
                                            Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Center(
                                                    child: Text(
                                                        '${e.switchPoint}'))),
                                            Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Center(
                                                    child: Text(
                                                        '${e.transformer}'))),
                                          ]);
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 40),
                SurveySearchButton(
                  label: 'Pole Survey',
                  assetType: 'pole',
                  prefix: polePrefix,
                  assetIcon: "assets/images/poleAsset.png",
                  onAdd: () {
                    EasyLoading.show(
                      status: '',
                      dismissOnTap: false,
                    );
                    selectedAssetType = 'Pole';
                    ref.read(surveyController).updateBaseSurveyFieldValues(
                        context, ref, selectedAssetType, 'assetType');
                    ref
                        .read(surveyController)
                        .poleFormValidation(context, ref, 'init', 'RCC');
                    ref
                        .read(surveyController)
                        .updatePoleHeightCascade(selectedRoadType);
                    EasyLoading.dismiss();
                    ref.read(surveyController).fetchLocationForSurvey();
                    ref.read(surveyController).setIsResurvey(false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PoleSurveyInformation()),
                    );
                  },
                  onSearch: (value) async {
                    log(value);

                    FocusScope.of(context).unfocus();
                    ref.read(poleController).toggleSearchLoader(true);
                    await ref
                        .read(deviceController)
                        .clickEventIsFor("poleSurveySearch");
                    final isConnected = await Utility.isConnected();
                    if (isConnected) {
                      await ref.read(deviceController).deviceListSearch(
                          ref, context, value,
                          prefixText: polePrefix);
                    } else {
                      await snackBar(
                        context,
                        ErrorMessages.offlineErrorTitle,
                        ErrorMessages.offlineErrorMessage,
                      );
                    }
                  },
                ),
                const SizedBox(height: 2),
                if (poleSearchList.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
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
                      itemCount: poleFilteredList.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.2),
                      ),
                      itemBuilder: (context, index) {
                        final item = poleFilteredList[index];
                        return InkWell(
                          onTap: () async {
                            EasyLoading.show(
                              status: '',
                              dismissOnTap: false,
                            );
                            selectedAssetType = 'Pole';
                            ref
                                .read(surveyController)
                                .updateBaseSurveyFieldValues(context, ref,
                                    selectedAssetType, 'assetType');
                            await ref
                                .read(surveyController)
                                .fetchSurveyDetails(ref, item['name']);

                            ref.read(deviceController).emptyDeviceSearchList();
                            EasyLoading.dismiss();
                            ref.read(surveyController).setIsResurvey(true);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PoleSurveyInformation()),
                            );
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
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                SurveySearchButton(
                  label: 'Switch Point Survey',
                  assetType: 'switchPoint',
                  prefix: spNoPrefixText,
                  assetIcon: "assets/images/spAsset.png",
                  onAdd: () {
                    selectedAssetType = 'Switch Point';
                    ref.read(surveyController).updateBaseSurveyFieldValues(
                        context, ref, selectedAssetType, 'assetType');
                    ref.read(surveyController).fetchLocationForSurvey();
                    ref.read(surveyController).setIsResurvey(false);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SwitchPointSurvey()),
                    );
                  },
                  onSearch: (value) async {
                    log(value);

                    FocusScope.of(context).unfocus();
                    ref.read(poleController).toggleSearchLoader(true);
                    await ref
                        .read(deviceController)
                        .clickEventIsFor("spSurveySearch");
                    final isConnected = await Utility.isConnected();
                    if (isConnected) {
                      await ref.read(deviceController).deviceListSearch(
                          ref, context, value,
                          prefixText: spNoPrefixText);
                    } else {
                      await snackBar(
                        context,
                        ErrorMessages.offlineErrorTitle,
                        ErrorMessages.offlineErrorMessage,
                      );
                    }
                  },
                ),
                const SizedBox(height: 2),
                if (spSearchList.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor, // subtle background
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
                      itemCount: spFilteredList.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.2),
                      ),
                      itemBuilder: (context, index) {
                        final item = spFilteredList[index];
                        return InkWell(
                          onTap: () async {
                            EasyLoading.show(
                              status: '',
                              dismissOnTap: false,
                            );
                            selectedAssetType = 'Switch Point';
                            ref
                                .read(surveyController)
                                .updateBaseSurveyFieldValues(context, ref,
                                    selectedAssetType, 'assetType');
                            ref
                                .read(surveyController)
                                .updateSwitchPointSurveyFieldValues(
                                  context,
                                  ref,
                                  '$spNoPrefixText${item['name']}',
                                  'switchPointNumber',
                                );
                            await ref
                                .read(surveyController)
                                .fetchSurveyDetails(ref, item['name']);
                            ref.read(deviceController).emptyDeviceSearchList();
                            EasyLoading.dismiss();
                            ref.read(surveyController).setIsResurvey(true);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SwitchPointSurvey()),
                            );
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
                                  child: Image.asset(
                                    "assets/images/spAsset.png",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item['name'] ?? "Unknown",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                SurveySearchButton(
                  label: 'Transformer Survey',
                  assetType: 'transformer',
                  prefix: transformerNoPrefixText,
                  assetIcon: "assets/images/transAsset.png",
                  onAdd: () {
                    selectedAssetType = 'Transformer';
                    ref.read(surveyController).updateBaseSurveyFieldValues(
                        context, ref, selectedAssetType, 'assetType');
                    ref.read(surveyController).fetchLocationForSurvey();
                    ref.read(surveyController).setIsResurvey(false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TransformerSurvey()),
                    );
                  },
                  onSearch: (value) async {
                    log(value);
                    FocusScope.of(context).unfocus();
                    ref.read(poleController).toggleSearchLoader(true);
                    await ref
                        .read(deviceController)
                        .clickEventIsFor("transSurveySearch");
                    final isConnected = await Utility.isConnected();
                    if (isConnected) {
                      await ref.read(deviceController).deviceListSearch(
                          ref, context, value,
                          prefixText: transformerNoPrefixText);
                    } else {
                      await snackBar(
                        context,
                        ErrorMessages.offlineErrorTitle,
                        ErrorMessages.offlineErrorMessage,
                      );
                    }
                  },
                ),
                const SizedBox(height: 2),
                if (transSearchList.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor, // subtle background
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
                      itemCount: transFilteredList.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.2),
                      ),
                      itemBuilder: (context, index) {
                        final item = transFilteredList[index];
                        return InkWell(
                          onTap: () async {
                            EasyLoading.show(
                              status: '',
                              dismissOnTap: false,
                            );
                            selectedAssetType = 'Transformer';
                            ref
                                .read(surveyController)
                                .updateBaseSurveyFieldValues(context, ref,
                                    selectedAssetType, 'assetType');

                            ref
                                .read(surveyController)
                                .updateTransformerSurveyFieldValues(
                                  context,
                                  ref,
                                  '$transformerNoPrefixText${item['name'].trim()}',
                                  'transNo',
                                );

                            await ref
                                .read(surveyController)
                                .fetchSurveyDetails(ref, item['name']);
                            ref.read(deviceController).emptyDeviceSearchList();
                            EasyLoading.dismiss();
                            ref.read(surveyController).setIsResurvey(true);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const TransformerSurvey()),
                            );
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
                                  child: Image.asset(
                                    "assets/images/transAsset.png",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item['name'] ?? "Unknown",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Theme.of(context).primaryColor,
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
              ]),
            ),
          ),
        )));
  }
}

class SurveySearchButton extends ConsumerStatefulWidget {
  final String label;
  final String assetType;
  final String prefix;
  final String assetIcon;
  final VoidCallback onAdd;
  final void Function(String value) onSearch;

  const SurveySearchButton({
    super.key,
    required this.label,
    required this.assetType,
    required this.prefix,
    required this.onAdd,
    required this.onSearch,
    required this.assetIcon,
  });

  @override
  ConsumerState<SurveySearchButton> createState() => _SurveySearchButtonState();
}

class _SurveySearchButtonState extends ConsumerState<SurveySearchButton> {
  bool showSearch = false;
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  static const buttonColor = Color.fromARGB(248, 64, 124, 161);
  final maxLengthMap = {
    'switchPoint': 4,
    'pole': 4,
    'transformer': 15,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: buttonColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: showSearch ? _searchBar(context) : _labelView(),
                  ),
                ),
                IconButton(
                  tooltip: 'search survey',
                  icon: Icon(
                    showSearch ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => showSearch = !showSearch);
                    if (showSearch) {
                      // search icon on tap
                      Future.delayed(const Duration(milliseconds: 200),
                          () => focusNode.requestFocus());
                    } else {
                      // close icon on tap
                      controller.clear();
                      focusNode.unfocus();
                      ref.read(deviceController).emptyDeviceSearchList();
                    }
                  },
                ),
                IconButton(
                  tooltip: 'new survey',
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: widget.onAdd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelView() {
    return Center(
      child: Text(
        widget.label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Container(
      key: const ValueKey('search'),
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        maxLength: maxLengthMap[widget.assetType] ?? 6,
        keyboardType: widget.assetType == 'transformer'
            ? TextInputType.text
            : TextInputType.number,
        cursorColor: Colors.black,
        style: const TextStyle(fontSize: 16, color: Colors.black),
        inputFormatters: widget.assetType == 'transformer'
            ? null
            : [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          hintText: 'Search',
          hintStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.prefix,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, size: 18, color: Colors.black),
            onPressed: () {
              if (widget.assetType == 'switchPoint') {
                if (controller.text.length < 3) {
                  showSnackBar(
                      ref, context, "Please provide 3 characters to search.");
                  return;
                }
              } else if (widget.assetType == 'pole') {
                if (controller.text.length < 4) {
                  showSnackBar(
                      ref, context, "Please provide 4 characters to search.");
                  return;
                }
              }
              widget.onSearch(
                controller.text,
              );
              controller.clear();
            },
          ),
        ),
      ),
    );
  }
}
