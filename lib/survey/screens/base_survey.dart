import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../device_page/device_controller.dart';
import '../../pole_install.dart/pole_installtion_history.dart';
import '../../utils/dialog_box.dart';
import '../background_connectivity_monitoring.dart';
import '../survey_controller.dart';
import 'pole_survey.dart';
import 'switch_point_survey.dart';
import 'transformer_survey.dart';

class BaseSurveyInformation extends ConsumerStatefulWidget {
  const BaseSurveyInformation({super.key});
  @override
  ConsumerState<BaseSurveyInformation> createState() => _BaseSurveyState();
}

class _BaseSurveyState extends ConsumerState<BaseSurveyInformation>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(surveyController).fetchNetworkDetails();
      // BackgroundSyncWorkManager.registerInternetCheckTask();
      // _initializeBackgroundSync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final polePrefix = ref.watch(surveyController).surveyPolePrefix;
    final selectedCustomer = ref.watch(
      deviceController.select((state) => state.selectedCustomer),
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

    String selectedAssetType = ref.watch(
      surveyController.select((state) => state.selectedAssetType),
    );
    final poleNumberController = ref.watch(
      surveyController.select((state) => state.poleNumberController),
    );
    final switchPointController = ref.watch(
      surveyController.select((state) => state.switchPointController),
    );
    final switchPointNumberController = ref.watch(
      surveyController.select((state) => state.switchPointNumberController),
    );
    final wardNumber = ref.watch(
      surveyController.select((state) => state.wardNumberForPolePrefix),
    );
    final TextEditingController transNoController =
        ref.read(surveyController).transNoController;
    final spNoPrefixText = '$wardNumber-SP';
    String transformerNoPrefixText = '$wardNumber-TFR';

    return WillPopScope(
        onWillPop: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PoleInstalltionHistoryInfo(),
            ),
          );
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
              "ASSET SURVEY",
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
          body: ConnectivityBanner(
            child: SafeArea(
                child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: FocusScope(
                        node: FocusScopeNode(),
                        child: ListView(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SelectedLocationData(
                              selectedCustomer: selectedCustomer,
                              selectedRegion: selectedRegion,
                              selectedZone: selectedZone,
                              selectedWard: selectedWard,
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          buildPoleCompositeInput(
                            context: context,
                            iconAsset: "assets/images/poleAsset.png",
                            poleController: poleNumberController,
                            spController: switchPointController,
                            hintText: 'Enter Pole No',
                            prefixText: polePrefix,
                            onProceed: () async {
                              EasyLoading.show(
                                status: '',
                                dismissOnTap: false,
                              );
                              selectedAssetType = 'Pole';
                              ref
                                  .read(surveyController)
                                  .updateBaseSurveyFieldValues(context, ref,
                                      selectedAssetType, 'assetType');
                              ref
                                  .read(surveyController)
                                  .updatePoleSurveyFieldValues(context, ref,
                                      poleNumberController.text, 'poleNumber');
                              ref
                                  .read(surveyController)
                                  .updatePoleSurveyFieldValues(
                                      context,
                                      ref,
                                      '$spNoPrefixText${switchPointController.text}',
                                      'switchPointNo');
                              final fullPoleNo =
                                  '$polePrefix${poleNumberController.text}-SP${switchPointController.text}';
                              await ref
                                  .read(surveyController)
                                  .fetchSurveyDetails(ref, fullPoleNo);
                              // ref
                              //     .read(surveyController)
                              //     .updatePoleHeightCascade(
                              //         selectedRoadType);
                              EasyLoading.dismiss();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PoleSurveyInformation()),
                              );
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          assetInputButton(
                            context: context,
                            assetType: 'sp',
                            iconAsset: "assets/images/spAsset.png",
                            controller: switchPointNumberController,
                            hintText: 'Enter Pole No',
                            prefixText: spNoPrefixText,
                            onProceed: () async {
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
                                    '$spNoPrefixText${switchPointNumberController.text}',
                                    'switchPointNumber',
                                  );
                              final fullSpNo =
                                  '$spNoPrefixText${switchPointNumberController.text}';
                              await ref
                                  .read(surveyController)
                                  .fetchSurveyDetails(ref, fullSpNo);

                              EasyLoading.dismiss();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SwitchPointSurvey()),
                              );
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          assetInputButton(
                            context: context,
                            assetType: 'trans',
                            iconAsset: "assets/images/transAsset.png",
                            controller: transNoController,
                            hintText: 'Enter Pole No',
                            prefixText: transformerNoPrefixText,
                            onProceed: () async {
                              EasyLoading.show(
                                status: '',
                                dismissOnTap: false,
                              );
                              selectedAssetType = 'Transformer';
                              ref
                                  .read(surveyController)
                                  .updateBaseSurveyFieldValues(context, ref,
                                      selectedAssetType, 'assetType');
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
                              final fulltransNo =
                                  '$transformerNoPrefixText${transNoController.text.trim()}';
                              await ref
                                  .read(surveyController)
                                  .fetchSurveyDetails(ref, fulltransNo);

                              EasyLoading.dismiss();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const TransformerSurvey()),
                              );
                            },
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                        ])))),
          ),
        ));
  }
}

Widget buildPoleCompositeInput({
  required BuildContext context,
  required String iconAsset,
  required String prefixText,
  required String hintText,
  required TextEditingController poleController,
  required TextEditingController spController,
  required VoidCallback onProceed,
}) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColorLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Image.asset(iconAsset, height: 32, width: 32),
          const SizedBox(width: 8),

          Text(
            prefixText,
            style: TextStyle(
              color: theme.secondaryHeaderColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 4),

          _numberSlot(
            context: context,
            controller: poleController,
            hint: '0000',
            width: 56,
            maxLength: 4,
          ),

          /// -SP
          Text(
            '-SP',
            style: TextStyle(
              color: theme.secondaryHeaderColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 4),

          /// SP NUMBER INPUT
          _numberSlot(
            context: context,
            controller: spController,
            hint: '000',
            width: 46,
            maxLength: 3,
          ),

          const Spacer(),

          GestureDetector(
            onTap: onProceed,
            child: Container(
              width: 40,
              height: 35,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_forward_ios_outlined,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          )
        ],
      ),
    ),
  );
}

Widget _numberSlot({
  required BuildContext context,
  required TextEditingController controller,
  required String hint,
  required double width,
  required int maxLength,
}) {
  final theme = Theme.of(context);

  return Container(
    width: width,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    padding: const EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(6),
      border: Border(
        bottom: BorderSide(
          color: theme.primaryColor.withValues(alpha: 0.6),
          width: 1.4,
        ),
      ),
    ),
    child: TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.primaryColor,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.primaryColor.withValues(alpha: 0.35),
          letterSpacing: 1.5,
        ),
        border: InputBorder.none,
      ),
    ),
  );
}

Widget assetInputButton({
  required BuildContext context,
  required String assetType,
  required String iconAsset,
  required String prefixText,
  required String hintText,
  required TextEditingController controller,
  required VoidCallback onProceed,
}) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColorLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Image.asset(iconAsset, height: 32, width: 32),
          const SizedBox(width: 15),
          Text(
            prefixText,
            style: TextStyle(
              color: theme.secondaryHeaderColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          _numberSlot(
            context: context,
            controller: controller,
            hint: assetType == 'sp' ? '000' : '',
            width: assetType == 'sp' ? 56 : 150,
            maxLength: assetType == 'sp' ? 3 : 15,
          ),
          const Spacer(),
          GestureDetector(
            onTap: onProceed,
            child: Container(
              width: 40,
              height: 35,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_forward_ios_outlined,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          )
        ],
      ),
    ),
  );
}

// Widget _buildAssetTile({
//   required BuildContext context,
//   required String image,
//   required String label,
//   required Function() onTap,
// }) {
//   return Expanded(
//     child: GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 6),
//         padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
//         decoration: BoxDecoration(
//           // boxShadow: [
//           //   BoxShadow(
//           //     color: Colors.black.withOpacity(0.2),
//           //     blurRadius: 4,
//           //     offset: const Offset(0, 2),
//           //   ),
//           // ],
//           color: Theme.of(context).primaryColorLight.withValues(alpha: 0.4),
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
//             width: 0,
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               image,
//               height: 50,
//             ),
//             const SizedBox(height: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }
