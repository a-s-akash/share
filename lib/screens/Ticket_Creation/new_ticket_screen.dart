import 'dart:async';
import 'package:citizen_complaints_list_web/screens/Ticket_Creation/new_ticket_controller.dart';
import 'package:citizen_complaints_list_web/screens/Tickets_List/tickets_list_controller.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  bool _isLoaded = false;
  Timer? _debounce;
  final SearchController _deviceSearchController = SearchController();
  final FocusNode _assigneeFocusNode = FocusNode();
  final FocusNode _deviceFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    ref.read(newTicketController).init();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });

    _deviceSearchController.addListener(_onDeviceSearchChanged);

    _assigneeFocusNode.addListener(() {
      if (_assigneeFocusNode.hasFocus) {
        ref.read(newTicketController).fetchAssignees();
      }
    });

    _deviceFocusNode.addListener(() {
      if (_deviceFocusNode.hasFocus) {
        ref.read(newTicketController).fetchDevices();
      }
    });
  }

  @override
  void dispose() {
    _deviceSearchController.removeListener(_onDeviceSearchChanged);
    _deviceSearchController.dispose();
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
            .read(newTicketController)
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
    final controller = ref.watch(newTicketController);

    String selectedRegion = controller.selectedRegion;
    String selectedZone = controller.selectedZone;
    String selectedWard = controller.selectedWard;
    String selectedDeviceType = controller.selectedDeviceType;
    String selectedDevice = controller.selectedDevice;
    String selectedPriority = controller.selectedPriority;
    String selectedProblemType = controller.selectedProblemType;
    String selectedStatus = controller.selectedStatus;
    String selectedAssignee = controller.selectedAssignee;
    String selectedComplainee = controller.selectedComplainee;
    Uint8List? pickedImageBytes = controller.pickedImageBytes;
    bool canCreateTicket = controller.canCreateTicket;

    return ValueListenableBuilder(
      valueListenable: Hive.box('project_context').listenable(),
      builder: (context, box, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(
                        scrollbars: false,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildSearchableDropdown(
                                  label: 'Region*',
                                  items: controller.regionList,
                                  selectedValue: selectedRegion,
                                  onChanged: (val) {
                                    if (val != selectedRegion) {
                                      _deviceSearchController.clear();
                                    }
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('region', val);
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildSearchableDropdown(
                                  label: 'Zone',
                                  items: controller.zoneList,
                                  selectedValue: selectedZone,
                                  onChanged: (val) {
                                    if (val != selectedZone) {
                                      _deviceSearchController.clear();
                                    }
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('zone', val);
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildSearchableDropdown(
                                  label: 'Ward',
                                  items: controller.wardList,
                                  selectedValue: selectedWard,
                                  onChanged: (val) {
                                    if (val != selectedWard) {
                                      _deviceSearchController.clear();
                                    }
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('ward', val);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildSearchableDropdown(
                                  label: 'Device/Asset Type',
                                  items: deviceTypeList,
                                  selectedValue: selectedDeviceType.isEmpty
                                      ? null
                                      : selectedDeviceType,
                                  labelMapper: getEntityLabel,
                                  onChanged: (val) {
                                    if (val != selectedDeviceType) {
                                      _deviceSearchController.clear();
                                      _debounce?.cancel();
                                    }
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('deviceType', val);
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildSearchableDropdown(
                                  label: 'Device/Asset ID',
                                  items: controller.devicesList,
                                  selectedValue: selectedDevice.isEmpty
                                      ? null
                                      : selectedDevice,
                                  onChanged: (val) {
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('device', val);
                                  },
                                  searchController: _deviceSearchController,
                                  customKey: ValueKey(
                                      "dev_${selectedDeviceType}_$selectedDevice"),
                                  focusNode: _deviceFocusNode,
                                  isLoading: controller.isLoadingDevices,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildTextField(
                                  label: 'Location',
                                  controller: controller.locationController,
                                  enabled: controller.selectedDeviceId.isEmpty,
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
                                  onChanged: (val) {
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('priority', val);
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildSearchableDropdown(
                                  label: 'Problem Type*',
                                  items: controller.problemTypeList,
                                  selectedValue: selectedProblemType.isEmpty
                                      ? null
                                      : selectedProblemType,
                                  onChanged: (val) {
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('problemType', val);
                                  },
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
                                  onChanged: (val) {
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('status', val);
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildSearchableDropdown(
                                  label: selectedStatus == 'Assigned'
                                      ? 'Assignee*'
                                      : 'Assignee',
                                  items: controller.assigneeList,
                                  selectedValue: selectedAssignee,
                                  onChanged: (val) {
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('assignee', val);
                                  },
                                  borderColor: (selectedStatus == 'Assigned' &&
                                          selectedAssignee == 'Unassigned')
                                      ? Theme.of(context)
                                          .tabBarTheme
                                          .indicatorColor
                                      : null,
                                  focusNode: _assigneeFocusNode,
                                  isLoading: controller.isLoadingAssignees,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildSearchableDropdown(
                                  label: 'Complainee',
                                  items: complaineeList,
                                  selectedValue: selectedComplainee.isEmpty
                                      ? null
                                      : selectedComplainee,
                                  onChanged: (val) {
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('complainee', val);
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildTextField(
                                  label: 'Complainee Phone Number',
                                  controller: controller.phoneController,
                                  onChanged: (val) {
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('phone', val);
                                  },
                                  maxLength: 10,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  borderColor: (controller.phoneController.text
                                              .isNotEmpty &&
                                          controller
                                                  .phoneController.text.length <
                                              10)
                                      ? Theme.of(context)
                                          .tabBarTheme
                                          .indicatorColor
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildTextField(
                                  label: (selectedProblemType == "" ||
                                          selectedProblemType == "Others")
                                      ? 'Comments*'
                                      : 'Comments',
                                  controller: controller.commentsController,
                                  maxLines: 4,
                                  onChanged: (val) {
                                    ref
                                        .read(newTicketController)
                                        .valueUpdate('comments', val);
                                  },
                                  borderColor: selectedProblemType == "Others"
                                      ? controller
                                              .commentsController.text.isEmpty
                                          ? Theme.of(context)
                                              .tabBarTheme
                                              .indicatorColor
                                          : null
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (pickedImageBytes == null)
                              InkWell(
                                onTap: () async {
                                  ref.read(newTicketController).imagePicker();
                                },
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).unselectedWidgetColor,
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
                            else
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
                                            .read(newTicketController)
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
                                              color: Theme.of(
                                                context,
                                              ).canvasColor,
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
                                            .read(newTicketController)
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
                const SizedBox(height: 10),
                const SizedBox(height: 10),
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
                      cursor: canCreateTicket
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.forbidden,
                      child: GestureDetector(
                        onTap: () async {
                          if (canCreateTicket) {
                            EasyLoading.show(
                              status: 'Creating Ticket...',
                              // maskType: EasyLoadingMaskType.black,
                            );
                            await Future.delayed(Duration.zero);
                            ref.read(newTicketController).createTicket(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: canCreateTicket
                                ? Theme.of(context).primaryColor
                                : Theme.of(
                                    context,
                                  )
                                    .unselectedWidgetColor
                                    .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Create",
                            style: TextStyle(
                              color: canCreateTicket
                                  ? Theme.of(context).canvasColor
                                  : Theme.of(context).unselectedWidgetColor,
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
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    Color? borderColor,
  }) {
    return Expanded(
      child: TextFormField(
        maxLength: maxLength,
        enabled: enabled,
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: borderColor != null ? TextStyle(color: borderColor) : null,
        cursorColor: borderColor,
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          labelStyle:
              borderColor != null ? TextStyle(color: borderColor) : null,
          border: const OutlineInputBorder(),
          enabledBorder: borderColor != null
              ? OutlineInputBorder(borderSide: BorderSide(color: borderColor))
              : null,
          focusedBorder: borderColor != null
              ? OutlineInputBorder(borderSide: BorderSide(color: borderColor))
              : null,
          contentPadding: EdgeInsets.all(maxLines > 1 ? 16.0 : 12.0),
        ),
      ),
    );
  }

  Widget _buildSearchableDropdown({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    Color? borderColor,
    SearchController? searchController,
    Key? customKey,
    FocusNode? focusNode,
    bool isLoading = false,
    String Function(String)? labelMapper,
  }) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Listener(
              onPointerDown: (_) {
                if (focusNode != null && !focusNode.hasFocus) {
                  focusNode.requestFocus();
                }
              },
              child: DropdownMenu<String>(
                controller: searchController,
                focusNode: focusNode,
                key: customKey ?? ValueKey(selectedValue),
                width: constraints.maxWidth,
                menuHeight: 300,
                enableFilter: true,
                requestFocusOnTap: true,
                trailingIcon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_drop_down),
                label: Text(
                  label,
                  style: borderColor != null
                      ? TextStyle(color: borderColor)
                      : null,
                ),
                initialSelection: selectedValue,
                textStyle:
                    borderColor != null ? TextStyle(color: borderColor) : null,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                      .where(
                          (entry) => entry.label.toUpperCase().contains(term))
                      .toList();

                  if (filteredEntries.isEmpty) {
                    return [
                      const DropdownMenuEntry<String>(
                        value: '',
                        label: 'Not Found',
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
              ));
        },
      ),
    );
  }
}
