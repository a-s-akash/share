import 'dart:async';
import 'package:citizen_complaints_list_web/screens/Ticket_Updation/abnormal_data_dialog.dart';
import 'package:citizen_complaints_list_web/screens/Ticket_Updation/ticket_update_controller.dart';
import 'package:citizen_complaints_list_web/screens/Tickets_List/tickets_list_controller.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class TicketEditScreen extends ConsumerStatefulWidget {
  const TicketEditScreen({super.key});

  @override
  ConsumerState<TicketEditScreen> createState() => _TicketEditScreenState();
}

class _TicketEditScreenState extends ConsumerState<TicketEditScreen> {
  bool _isLoaded = false;
  final FocusNode _assigneeFocusNode = FocusNode();
  final FocusNode _deviceFocusNode = FocusNode();
  final SearchController _deviceSearchController = SearchController();
  final SearchController _assigneeSearchController = SearchController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    initLoad();
  }

  void initLoad() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        final controller = ref.read(ticketUpdateController);
        if (controller.selectedDevice.isNotEmpty) {
          _deviceSearchController.text = controller.selectedDevice;
        }
        if (controller.selectedAssignee.isNotEmpty) {
          _assigneeSearchController.text = controller.selectedAssignee;
        }
        if (controller.isTicketEditable) {
          controller.fetchAssignees();
          controller.fetchDevices();
        }
        setState(() {
          _isLoaded = true;
        });
      }
    });

    _assigneeFocusNode.addListener(() {
      if (_assigneeFocusNode.hasFocus &&
          ref.read(ticketUpdateController).isTicketEditable) {
        final controller = ref.read(ticketUpdateController);
        if (controller.assigneeList.length <= 1) {
          controller.fetchAssignees();
        }
      }
    });

    _deviceFocusNode.addListener(() {
      if (_deviceFocusNode.hasFocus &&
          ref.read(ticketUpdateController).isTicketEditable) {
        final controller = ref.read(ticketUpdateController);
        if (controller.devicesList.isEmpty) {
          controller.fetchDevices();
        }
      }
    });
    _deviceSearchController.addListener(_onDeviceSearchChanged);
  }

  @override
  void dispose() {
    _deviceSearchController.removeListener(_onDeviceSearchChanged);
    _deviceSearchController.dispose();
    _assigneeSearchController.dispose();
    _assigneeFocusNode.dispose();
    _deviceFocusNode.dispose();
    _debounce?.cancel();

    super.dispose();
  }

  void _onDeviceSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref
            .read(ticketUpdateController)
            .fetchDevices(_deviceSearchController.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return Center(
        child: SpinKitDualRing(color: Theme.of(context).primaryColor),
      );
    }

    final controller = ref.watch(ticketUpdateController);
    ref.listen(ticketUpdateController, (previous, next) {
      if (previous?.selectedDevice != next.selectedDevice) {
        if (_deviceSearchController.text != next.selectedDevice) {
          _deviceSearchController.text = next.selectedDevice;
        }
      }
    });
    ref.listen(ticketUpdateController, (previous, next) {
      if (previous?.selectedAssignee != next.selectedAssignee) {
        if (_assigneeSearchController.text != next.selectedAssignee) {
          _assigneeSearchController.text = next.selectedAssignee;
        }
      }
    });

    ref.listen<TicketUpdateProvider>(ticketUpdateController, (previous, next) {
      if (previous != null &&
          !previous.isTicketEditable &&
          next.isTicketEditable) {
        next.fetchAssignees();
        next.fetchDevices();
      }
    });

    String selectedPriority = controller.selectedPriority;
    String selectedStatus = controller.selectedStatus;
    String selectedAssignee = controller.selectedAssignee;
    bool selectedComponentChanged = controller.selectedComponentChanged;
    String selectedIssueIdentified = controller.selectedIssueIdentified;
    Uint8List? pickedImageBytes = controller.pickedImageBytes;
    bool canUpdate = controller.canUpdate;
    String duplicateTicketId = controller.duplicateOf != ''
        ? controller.duplicateOf
        : controller.previousDuplicatedTo;
    bool isDuplicated =
        selectedStatus == 'Verified-Duplicate' && duplicateTicketId != '';
    bool isAbnormalReading =
        controller.selectedProblemType == "Abnormal Reading";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildTextField(
                              label: 'Region',
                              controller: TextEditingController(
                                text: controller.selectedRegion,
                              ),
                              enabled: false,
                              onChanged: (_) {},
                            ),
                            const SizedBox(width: 16),
                            controller.isZoneEditable
                                ? _buildSearchableDropdown(
                                    key: ValueKey(controller.selectedZone),
                                    items: controller.zoneList,
                                    selectedValue: controller.selectedZone,
                                    label: 'Zone',
                                    enabled: controller.isTicketEditable,
                                    onChanged: (value) {
                                      if (value != controller.selectedZone) {
                                        _deviceSearchController.clear();
                                      }
                                      controller.valueUpdate('zone', value);
                                    },
                                  )
                                : _buildTextField(
                                    label: 'Zone',
                                    controller: TextEditingController(
                                      text: controller.selectedZone,
                                    ),
                                    enabled: false,
                                    onChanged: (_) {},
                                  ),
                            const SizedBox(width: 16),
                            controller.isWardEditable
                                ? _buildSearchableDropdown(
                                    key: ValueKey(controller.selectedWard),
                                    items: controller.wardList,
                                    selectedValue: controller.selectedWard,
                                    label: 'Ward',
                                    enabled: controller.isTicketEditable,
                                    onChanged: (value) {
                                      if (value != controller.selectedWard) {
                                        _deviceSearchController.clear();
                                      }
                                      controller.valueUpdate('ward', value);
                                    },
                                  )
                                : _buildTextField(
                                    label: 'Ward',
                                    controller: TextEditingController(
                                      text: controller.selectedWard,
                                    ),
                                    enabled: false,
                                    onChanged: (_) {},
                                  ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            controller.isDeviceTypeEditable
                                ? _buildSearchableDropdown(
                                    key:
                                        ValueKey(controller.selectedDeviceType),
                                    items: deviceTypeList,
                                    selectedValue:
                                        controller.selectedDeviceType,
                                    label: 'Device/Asset Type',
                                    enabled: controller.isTicketEditable,
                                    labelMapper: getEntityLabel,
                                    onChanged: (value) {
                                      if (value !=
                                          controller.selectedDeviceType) {
                                        _deviceSearchController.clear();
                                        _debounce?.cancel();
                                      }
                                      controller.valueUpdate(
                                          'deviceType', value);
                                    })
                                : _buildTextField(
                                    label: 'Device/Asset Type',
                                    controller: TextEditingController(
                                      text: getEntityLabel(
                                          controller.selectedDeviceType),
                                    ),
                                    enabled: false,
                                    onChanged: (_) {},
                                  ),
                            const SizedBox(width: 16),
                            controller.isDeviceEditable
                                ? _buildSearchableDropdown(
                                    key: ValueKey(
                                        "dev_${controller.selectedDeviceType}_${controller.selectedDevice}"),
                                    items: controller.devicesList,
                                    searchController: _deviceSearchController,
                                    focusNode: _deviceFocusNode,
                                    selectedValue: controller.selectedDevice,
                                    label: 'Device/Asset ID',
                                    enabled: controller.isTicketEditable,
                                    onChanged: (value) =>
                                        controller.valueUpdate('device', value),
                                    isLoading: controller.isLoadingDevices,
                                  )
                                : _buildTextField(
                                    label: 'Device/Asset ID',
                                    controller: TextEditingController(
                                      text: controller.selectedDevice,
                                    ),
                                    enabled: false,
                                    onChanged: (_) {},
                                  ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildTextField(
                              label: 'Location',
                              controller: controller.locationController,
                              enabled: controller.selectedDeviceId.isEmpty &&
                                  controller.previousLocation.isEmpty &&
                                  controller.isTicketEditable,
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildSearchableDropdown(
                              label: 'Priority',
                              items: controller.priorityList,
                              selectedValue: selectedPriority,
                              enabled: controller.isTicketEditable,
                              onChanged: (val) {
                                ref
                                    .read(ticketUpdateController)
                                    .valueUpdate('priority', val);
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Stack(
                                children: [
                                  _buildTextField(
                                    label: 'Problem Type',
                                    controller: TextEditingController(
                                      text: controller.selectedProblemType,
                                    ),
                                    enabled: false,
                                    onChanged: (_) {},
                                    expand: false,
                                  ),
                                  if (isAbnormalReading)
                                    Positioned(
                                      right: 0,
                                      top: 5,
                                      child: Tooltip(
                                        message: 'View Data',
                                        child: IconButton(
                                            icon: Icon(Icons.more_vert_rounded,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AbnormalDataDialog(
                                                        ticketId: controller
                                                            .ticketId),
                                              );
                                            }),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildSearchableDropdown(
                              label: 'Status',
                              items: controller.statusList,
                              selectedValue: selectedStatus,
                              // enabled: controller.isTicketEditable,
                              onChanged: (val) {
                                ref
                                    .read(ticketUpdateController)
                                    .valueUpdate('status', val, context);
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildSearchableDropdown(
                              label: selectedStatus == 'Assigned'
                                  ? 'Assignee*'
                                  : 'Assignee',
                              items: controller.assigneeList,
                              searchController: _assigneeSearchController,
                              focusNode: _assigneeFocusNode,
                              selectedValue: selectedAssignee,
                              enabled: controller.isTicketEditable,
                              onChanged: (val) {
                                ref
                                    .read(ticketUpdateController)
                                    .valueUpdate('assignee', val);
                              },
                              borderColor: (selectedStatus == 'Assigned' &&
                                      selectedAssignee == 'Unassigned')
                                  ? Theme.of(context).tabBarTheme.indicatorColor
                                  : null,
                              isLoading: controller.isLoadingAssignees,
                            ),
                          ],
                        ),
                        if (isDuplicated) const SizedBox(height: 5),
                        if (isDuplicated)
                          Row(
                            children: [
                              const Padding(
                                  padding: EdgeInsetsGeometry.only(left: 5)),
                              const Text("of"),
                              Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        duplicateTicketId,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            controller.previousComplainee.isNotEmpty
                                ? _buildTextField(
                                    enabled: false,
                                    label: 'Complainee',
                                    controller: TextEditingController(
                                      text: controller.previousComplainee,
                                    ),
                                    onChanged: (_) {},
                                  )
                                : _buildSearchableDropdown(
                                    label: 'Complainee',
                                    items: complaineeList,
                                    selectedValue:
                                        controller.previousComplainee.isEmpty
                                            ? null
                                            : controller.previousComplainee,
                                    enabled: controller.isTicketEditable,
                                    onChanged: (val) {
                                      ref
                                          .read(ticketUpdateController)
                                          .valueUpdate('complainee', val);
                                    },
                                  ),
                            const SizedBox(width: 16),
                            _buildTextField(
                              label: 'Complainee Phone Number',
                              controller: controller.phoneController,
                              enabled: controller.isTicketEditable &&
                                  controller
                                      .previousComplaineePhoneNumber.isEmpty,
                              isError: controller
                                      .previousComplaineePhoneNumber.isEmpty &&
                                  controller.phoneController.text.length < 10 &&
                                  controller.phoneController.text.isNotEmpty,
                              onChanged: (val) {
                                ref
                                    .read(ticketUpdateController)
                                    .valueUpdate('phone', val);
                              },
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildSearchableDropdown(
                              label: 'Issues Identified',
                              items: controller.issueIdentifiedList,
                              selectedValue: selectedIssueIdentified,
                              enabled: controller.isTicketEditable,
                              onChanged: (val) {
                                ref
                                    .read(ticketUpdateController)
                                    .valueUpdate('issueIdentified', val);
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: controller.isTicketEditable &&
                                              controller
                                                  .isComponentChangeEnabled
                                          ? Theme.of(context)
                                              .unselectedWidgetColor
                                          : Theme.of(context)
                                              .unselectedWidgetColor
                                              .withValues(alpha: 0.5)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Components Changed",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: controller.isTicketEditable &&
                                                controller
                                                    .isComponentChangeEnabled
                                            ? Theme.of(context)
                                                .secondaryHeaderColor
                                            : Theme.of(context)
                                                .unselectedWidgetColor,
                                      ),
                                    ),
                                    Checkbox(
                                      value: selectedComponentChanged,
                                      onChanged: controller.isTicketEditable &&
                                              controller
                                                  .isComponentChangeEnabled
                                          ? (val) {
                                              ref
                                                  .read(ticketUpdateController)
                                                  .valueUpdate(
                                                    'componentChanged',
                                                    val ?? false,
                                                  );
                                            }
                                          : null,
                                      activeColor:
                                          Theme.of(context).primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // if (controller.shouldShowReplacedNameField)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 16.0),
                        //     child: Row(
                        //       children: [
                        //         _buildTextField(
                        //           label:
                        //               "Replaced ${controller.selectedIssueIdentified} Name",
                        //           controller:
                        //               controller.replacedEntityNameController,
                        //           enabled: controller.isTicketEditable,
                        //           onChanged: (val) {
                        //             setState(() {});
                        //           },
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildTextField(
                              label: 'Comments*',
                              controller: controller.commentsController,
                              maxLines: 4,
                              onChanged: (val) {
                                ref
                                    .read(ticketUpdateController)
                                    .valueUpdate('comments', val);
                              },
                              commentsWarning:
                                  controller.commentsController.text.isEmpty,
                            ),
                          ],
                        ),
                        if (controller.isTicketEditable)
                          const SizedBox(height: 16),
                        if (pickedImageBytes == null &&
                            controller.isTicketEditable)
                          InkWell(
                            onTap: () async {
                              ref.read(ticketUpdateController).imagePicker();
                            },
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context).unselectedWidgetColor,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).unselectedWidgetColor,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload,
                                    size: 50,
                                    color: Theme.of(context).canvasColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Upload Image",
                                    style: TextStyle(
                                      color: Theme.of(context).canvasColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (pickedImageBytes != null &&
                            controller.isTicketEditable)
                          Stack(
                            children: [
                              SizedBox(
                                height: 500,
                                width: double.infinity,
                                child: Image.memory(
                                  pickedImageBytes,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () async {
                                    ref
                                        .read(ticketUpdateController)
                                        .imagePicker();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.replay,
                                          color: Theme.of(context).canvasColor,
                                          size: 20,
                                        ),
                                        Text(
                                          "ReUpload",
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).canvasColor,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: InkWell(
                                  onTap: () async {
                                    ref
                                        .read(ticketUpdateController)
                                        .removeImage();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).unselectedWidgetColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.clear,
                                      color: Theme.of(context).canvasColor,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () async {
                      if (canUpdate) {
                        EasyLoading.show(
                          status: 'Updating Ticket...',
                          // maskType: EasyLoadingMaskType.black,
                        );
                        await Future.delayed(Duration.zero);
                        ref.read(ticketUpdateController).updateTicket(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: canUpdate
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).unselectedWidgetColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Update",
                        style: TextStyle(
                          color: Theme.of(context).canvasColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    bool enabled = true,
    bool isError = false,
    bool commentsWarning = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    bool expand = true,
  }) {
    final textField = TextFormField(
      enabled: enabled,
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        color: !enabled
            ? Theme.of(context).unselectedWidgetColor
            : isError
                ? Theme.of(context).tabBarTheme.indicatorColor
                : Theme.of(context).secondaryHeaderColor,
      ),
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isError || commentsWarning
              ? Theme.of(context).tabBarTheme.indicatorColor
              : null,
        ),
        border: const OutlineInputBorder(),
        enabledBorder: isError
            ? OutlineInputBorder(
                borderSide: BorderSide(
                    color: Theme.of(context).tabBarTheme.indicatorColor!))
            : null,
        focusedBorder: isError
            ? OutlineInputBorder(
                borderSide: BorderSide(
                    color: Theme.of(context).tabBarTheme.indicatorColor!,
                    width: 2))
            : null,
        contentPadding: EdgeInsets.all(maxLines > 1 ? 16.0 : 12.0),
        suffixIcon: suffixIcon,
      ),
    );
    return expand ? Expanded(child: textField) : textField;
  }

  Widget _buildSearchableDropdown({
    Key? key,
    required String label,
    required List<String> items,
    required String? selectedValue,
    Color? borderColor,
    required ValueChanged<String?> onChanged,
    FocusNode? focusNode,
    bool isLoading = false,
    SearchController? searchController,
    bool enabled = true,
    String Function(String)? labelMapper,
  }) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return DropdownMenu<String>(
            key: key ?? ValueKey(selectedValue),
            enabled: enabled,
            controller: searchController,
            width: constraints.maxWidth,
            menuHeight: 300,
            enableFilter: true,
            requestFocusOnTap: true,
            focusNode: focusNode,
            label: Text(
              label,
              style: borderColor != null ? TextStyle(color: borderColor) : null,
            ),
            initialSelection: selectedValue,
            textStyle:
                borderColor != null ? TextStyle(color: borderColor) : null,
            trailingIcon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_drop_down),
            inputDecorationTheme: InputDecorationTheme(
              border: const OutlineInputBorder(),
              enabledBorder: borderColor != null
                  ? OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor),
                    )
                  : null,
              focusedBorder: borderColor != null
                  ? OutlineInputBorder(
                      borderSide: BorderSide(color: borderColor),
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownMenuEntries: items.isEmpty
                ? [
                    DropdownMenuEntry<String>(
                      value: '__no_data__',
                      label: isLoading
                          ? 'Fetching...'
                          : 'No ${label.replaceAll('*', '')}s Found',
                      enabled: false,
                    ),
                  ]
                : items.map((e) {
                    return DropdownMenuEntry<String>(
                        value: e,
                        label: labelMapper != null ? labelMapper(e) : e);
                  }).toList(),
            filterCallback: (entries, filter) {
              if (items.isEmpty) return entries;
              final String term = filter.toUpperCase();
              final filteredEntries = entries
                  .where((entry) => entry.label.toUpperCase().contains(term))
                  .toList();

              if (filteredEntries.isEmpty) {
                return [
                  const DropdownMenuEntry<String>(
                    value: '__no_data__',
                    label: 'No Data Found',
                    enabled: false,
                  ),
                ];
              }

              return filteredEntries;
            },
            onSelected: (value) {
              if (value != null && value.isNotEmpty) {
                onChanged(value);
              }
            },
          );
        },
      ),
    );
  }
}
