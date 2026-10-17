import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:schnell_luminator/home_page/map_controller.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../qr_scan_online.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../survey/survey_controller.dart';
import '../utils/constants.dart';
import '../utils/dialog_box.dart';
import 'device_controller.dart';
import 'gw_semc_take_photo.dart';

class SwitchPointScreen extends ConsumerStatefulWidget {
  final String scannedDeviceOrAssetName;
  const SwitchPointScreen({super.key, required this.scannedDeviceOrAssetName});

  @override
  ConsumerState<SwitchPointScreen> createState() => _SwitchPointScreenState();
}

class _SwitchPointScreenState extends ConsumerState<SwitchPointScreen> {
  List<String> _allSelectedSwitchPoints = [];
  List<String> _customSwitchPoints = [];
  bool _isEarthingAvailable = true;
  final TextEditingController _earthingReasonController =
      TextEditingController();

  @override
  void dispose() {
    _earthingReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wardNumber = ref.watch(
      surveyController.select((state) => state.wardNumberForPolePrefix),
    );
    final deviceType = ref.watch(deviceController).firstDeviceType;
    final assetName = deviceType == 'GW'
        ? ref.watch(deviceController).ccmsAssetName
        : ref.watch(deviceController).smslcAssetName;
    final spNoPrefixText = '$wardNumber-SP';
    final selectedWardId = ref.watch(
      deviceController.select((state) => state.selectedWardId),
    );
    var qrViewController = ref
        .watch(ref.watch(isSecondTime) ? qrController2 : qrController)
        .qrViewController;
    String clickeventIsFor = ref.watch(deviceController).clickeventIsFor;
    bool isSwitchPointRequiredForPanel =
        ref.watch(mapController).isSwitchPointRequiredForPanel;

    return SafeArea(
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop && qrViewController != null) {
            qrViewController.resumeCamera();
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.primaryColor.withValues(alpha: 0.19),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.primaryColor),
              onPressed: () {
                Navigator.pop(context);
                if (qrViewController != null) {
                  qrViewController.resumeCamera();
                }
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ASSOCIATE SWITCH POINT",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${widget.scannedDeviceOrAssetName.toUpperCase()} scanned",
                  style: TextStyle(
                    color: theme.secondaryHeaderColor.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          body: ConnectivityBanner(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("SLC", theme),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: theme.unselectedWidgetColor
                                          .withValues(alpha: 0.6)),
                                ),
                                child: Text(
                                  assetName.toUpperCase(),
                                  style: TextStyle(
                                    color: theme.secondaryHeaderColor
                                        .withValues(alpha: 0.8),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Type", theme),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: theme.unselectedWidgetColor
                                          .withValues(alpha: 0.6)),
                                ),
                                child: Text(
                                  deviceType.toUpperCase() == "GW"
                                      ? "CCMS"
                                      : "SMSLC",
                                  style: TextStyle(
                                    color: theme.secondaryHeaderColor
                                        .withValues(alpha: 0.8),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Switch Point Dropdown
                    _buildLabel("Switch Point No", theme),
                    const SizedBox(height: 4),
                    ValueListenableBuilder(
                      valueListenable: Hive.box(assetNameBox).listenable(),
                      builder: (context, Box box, _) {
                        final wardData = box.get('ward_$selectedWardId');
                        log('wardData: $wardData');
                        final switchPointNames = wardData == null
                            ? <String>[]
                            : List<String>.from(wardData['switchPoints'] ?? []);

                        return AnimatedEditableInlineMultiSelect(
                          items: switchPointNames,
                          hint: 'Type or select...',
                          prefixText: spNoPrefixText,
                          theme: theme,
                          onChanged: (selectedItems, customItems) {
                            _allSelectedSwitchPoints = selectedItems;
                            _customSwitchPoints = customItems;
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Earthing toggle
                    _buildLabel("Earthing", theme),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ToggleSwitch(
                        minWidth: 80,
                        cornerRadius: 12,
                        activeBgColors: [
                          [theme.primaryColor.withValues(alpha: 0.8)],
                          [theme.primaryColor.withValues(alpha: 0.8)],
                        ],
                        activeFgColor: Colors.white,
                        inactiveBgColor: Colors.grey[300],
                        inactiveFgColor: Colors.black,
                        totalSwitches: 2,
                        labels: const ['Yes', 'No'],
                        initialLabelIndex: _isEarthingAvailable ? 0 : 1,
                        onToggle: (index) {
                          setState(() {
                            _isEarthingAvailable = index == 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLabel(
                      _isEarthingAvailable
                          ? "Reason (optional)"
                          : "Reason for Earthing not available*",
                      theme,
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _earthingReasonController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Concrete around the poles, No space under the pole',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color:
                              theme.secondaryHeaderColor.withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.unselectedWidgetColor
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!_isEarthingAvailable &&
                                  _earthingReasonController.text
                                      .trim()
                                      .isEmpty) {
                                showSnackBar(ref, context,
                                    "Please provide reason for Earthing not available");
                                return;
                              }
                              ref
                                  .read(surveyController)
                                  .updateSwitchPointSurveyFieldValues(
                                    context,
                                    ref,
                                    _isEarthingAvailable,
                                    'spEarthingAvailable',
                                  );
                              ref
                                  .read(surveyController)
                                  .updateSwitchPointSurveyFieldValues(
                                    context,
                                    ref,
                                    _earthingReasonController.text.trim(),
                                    'spEarthingReason',
                                  );

                              // switch Point no check

                              if (isSwitchPointRequiredForPanel &&
                                  _allSelectedSwitchPoints.isNotEmpty) {
                                showSnackBar(ref, context,
                                    "Please select or provide Switch Point Number");
                                return;
                              }

                              await ref
                                  .read(surveyController)
                                  .updateSwitchPointSurveyFieldValues(
                                    context,
                                    ref,
                                    _customSwitchPoints,
                                    'customSwitchPointNo',
                                  );
                              if (!context.mounted) return;
                              ref
                                  .read(surveyController)
                                  .updateSwitchPointSurveyFieldValues(
                                    context,
                                    ref,
                                    _allSelectedSwitchPoints,
                                    'multiSwitchPointNo',
                                  );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GwSemcCaptureThreeImagesScreen(
                                          clickeventIsFor: clickeventIsFor,
                                          requiredImageCount: 3),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  theme.primaryColor.withValues(alpha: 0.8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Proceed",
                              style: TextStyle(
                                color: theme.canvasColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: theme.primaryColor.withValues(alpha: 0.8),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// Searchable multi-select dropdown — floating overlay card, editable + prefix

class AnimatedEditableInlineMultiSelect extends ConsumerStatefulWidget {
  final List<String> items;
  final String hint;
  final String prefixText;
  final ThemeData theme;
  final int maxLength;
  final void Function(List<String> selectedItems, List<String> customItems)?
      onChanged;

  const AnimatedEditableInlineMultiSelect({
    super.key,
    required this.items,
    required this.hint,
    required this.prefixText,
    required this.theme,
    this.maxLength = 4,
    this.onChanged,
  });

  @override
  ConsumerState<AnimatedEditableInlineMultiSelect> createState() =>
      _AnimatedEditableInlineMultiSelectState();
}

class _AnimatedEditableInlineMultiSelectState
    extends ConsumerState<AnimatedEditableInlineMultiSelect> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _selected = [];
  final List<String> _customItems = [];
  bool _isExpanded = false;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.items;
    return widget.items
        .where((e) => e.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void _addTyped() {
    final raw = _searchCtrl.text.trim();
    if (raw.isEmpty) return;
    final isValidSwitchPoint =
        ref.read(surveyController).isValidSwitchPointNo(raw);
    if (!isValidSwitchPoint) {
      alertPopUp1(
        context,
        'Invalid Switch Point Number format. Please enter a valid format (SP999)',
        'assets/animation/warn.json',
      );
      return;
    }

    final paddedRaw = ref.read(surveyController).padNumber(raw, 4);
    final value = '${widget.prefixText}$paddedRaw';
    if (!_selected.contains(value)) {
      setState(() {
        _selected.add(value);
        _customItems.add(value);
      });
      widget.onChanged?.call(List.from(_selected), List.from(_customItems));
    }
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded
              ? theme.primaryColor
              : _selected.isNotEmpty
                  ? theme.primaryColor.withAlpha(150)
                  : theme.unselectedWidgetColor.withAlpha(150),
        ),
        // color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  widget.prefixText,
                  style: TextStyle(
                    color: theme.secondaryHeaderColor.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _focusNode,
                  maxLength: widget.maxLength,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  textInputAction: TextInputAction.done,
                  onChanged: (val) {
                    setState(() {
                      _query = val;
                      _isExpanded = true; // Auto open on typing
                    });
                  },
                  // onSubmitted: (_) => _addTyped(),
                  onTap: () {
                    // Open dropdown if it was closed
                    if (!_isExpanded) {
                      setState(() => _isExpanded = true);
                    }
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                        fontSize: 13,
                        color:
                            theme.secondaryHeaderColor.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              // if (_searchCtrl.text.trim().length == widget.maxLength)
              //   IconButton(
              //     icon: Icon(
              //       Icons.add_circle_outline,
              //       color: theme.primaryColor,
              //     ),
              //     onPressed: _addTyped,
              //     tooltip: 'Create Custom Text',
              //   ),
              InkWell(
                onTap: () {
                  if (_isExpanded) _focusNode.unfocus();
                  setState(() => _isExpanded = !_isExpanded);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: _isExpanded ? theme.primaryColor : Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),

          // ── Chips row ─────────────
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _selected.map((sp) {
                  return Chip(
                    label: Text(
                      sp,
                      style: TextStyle(fontSize: 11, color: theme.primaryColor),
                    ),
                    backgroundColor: theme.primaryColor.withAlpha(25),
                    side: BorderSide(color: theme.primaryColor.withAlpha(70)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    deleteIcon: Icon(
                      Icons.close,
                      size: 13,
                      color: theme.primaryColor,
                    ),
                    onDeleted: () {
                      setState(() {
                        _selected.remove(sp);
                        _customItems.remove(sp);
                      });
                      widget.onChanged
                          ?.call(List.from(_selected), List.from(_customItems));
                    },
                  );
                }).toList(),
              ),
            ),

          // ── Animated Expandable Body ──────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: !_isExpanded
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      Divider(
                          height: 1, color: theme.primaryColor.withAlpha(100)),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: _filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No results',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) {
                                  final item = _filtered[index];
                                  final isChecked = _selected.contains(item);
                                  return CheckboxListTile(
                                    dense: true,
                                    title: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                      ),
                                    ),
                                    value: isChecked,
                                    activeColor: theme.primaryColor,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selected.add(item);
                                        } else {
                                          _selected.remove(item);
                                          _customItems.remove(item);
                                        }
                                      });
                                      widget.onChanged?.call(
                                        List.from(_selected),
                                        List.from(_customItems),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                      // Small text to show editable action
                      if (_query.trim().isNotEmpty &&
                          !_filtered.contains(
                            '${widget.prefixText}${_query.trim()}',
                          ))
                        InkWell(
                          onTap: _addTyped,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                            color: theme.primaryColor.withAlpha(15),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add: ${widget.prefixText}${_query.trim()}',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
