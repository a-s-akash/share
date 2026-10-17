import 'package:citizen_complaints_list_web/screens/Ticket_Updation/public_ticket_migration_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/foundation.dart';

class PublicTicketMigrationScreen extends ConsumerStatefulWidget {
  const PublicTicketMigrationScreen({super.key});

  @override
  ConsumerState<PublicTicketMigrationScreen> createState() =>
      _PublicTicketMigrationScreenState();
}

class _PublicTicketMigrationScreenState
    extends ConsumerState<PublicTicketMigrationScreen> {
  bool _isLoaded = false;

  final FocusNode _customerFocus = FocusNode();
  final FocusNode _regionFocus = FocusNode();
  final FocusNode _zoneFocus = FocusNode();
  final FocusNode _wardFocus = FocusNode();

  final SearchController _customerSearch = SearchController();
  final SearchController _regionSearch = SearchController();
  final SearchController _zoneSearch = SearchController();
  final SearchController _wardSearch = SearchController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _customerFocus.dispose();
    _regionFocus.dispose();
    _zoneFocus.dispose();
    _wardFocus.dispose();
    _customerSearch.dispose();
    _regionSearch.dispose();
    _zoneSearch.dispose();
    _wardSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return Center(
        child: SpinKitDualRing(color: Theme.of(context).primaryColor),
      );
    }

    final controller = ref.watch(publicTicketMigrationController);
    Uint8List? pickedImageBytes = controller.pickedImageBytes;

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
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.08),
                                            child: Icon(
                                              Icons.business_outlined,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Text(
                                            controller.originalRegion,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .secondaryHeaderColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.08),
                                            child: Icon(
                                              Icons.call_outlined,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Text(
                                            controller.originalPhone,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .secondaryHeaderColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.05),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 18,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                controller.originalLocation,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                      .secondaryHeaderColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.05),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Problem",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .secondaryHeaderColor
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              controller.originalProblemType,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .secondaryHeaderColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.05),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Device ID",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .secondaryHeaderColor
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              controller
                                                      .originalDeviceId.isEmpty
                                                  ? "N/A"
                                                  : controller.originalDeviceId,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .secondaryHeaderColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Row(
                        //   children: [
                        //     _buildReadOnlyField(
                        //         "Reported Region", controller.originalRegion),
                        //     const SizedBox(width: 16),
                        //     _buildReadOnlyField(
                        //         "Device ID", controller.originalDeviceId),
                        //   ],
                        // ),
                        // const SizedBox(height: 12),
                        // Row(
                        //   children: [
                        //     _buildReadOnlyField(
                        //         "Location", controller.originalLocation),
                        //   ],
                        // ),
                        // const SizedBox(height: 12),
                        // Row(
                        //   children: [
                        //     _buildReadOnlyField(
                        //         "Problem Type", controller.originalProblemType),
                        //     const SizedBox(width: 16),
                        //     _buildReadOnlyField(
                        //         "Phone Number", controller.originalPhone),
                        //   ],
                        // ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            _buildSearchableDropdown(
                              label: "Customer*",
                              items: controller.customerList,
                              selectedValue: controller.targetCustomer,
                              focusNode: _customerFocus,
                              searchController: _customerSearch,
                              onChanged: (val) {
                                ref
                                    .read(publicTicketMigrationController)
                                    .targetValueUpdate('customer', val!);
                                _regionSearch.text = '';
                                _zoneSearch.text = '';
                                _wardSearch.text = '';
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildSearchableDropdown(
                              label: "Region*",
                              items: controller.targetRegionList,
                              selectedValue: controller.targetRegion,
                              focusNode: _regionFocus,
                              searchController: _regionSearch,
                              onChanged: (val) {
                                ref
                                    .read(publicTicketMigrationController)
                                    .targetValueUpdate('region', val!);
                                _zoneSearch.text = '';
                                _wardSearch.text = '';
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildSearchableDropdown(
                              label: "Zone",
                              items: controller.targetZoneList,
                              selectedValue: controller.targetZone,
                              focusNode: _zoneFocus,
                              searchController: _zoneSearch,
                              onChanged: (val) {
                                ref
                                    .read(publicTicketMigrationController)
                                    .targetValueUpdate('zone', val!);
                                _wardSearch.text = '';
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildSearchableDropdown(
                              label: "Ward",
                              items: controller.targetWardList,
                              selectedValue: controller.targetWard,
                              focusNode: _wardFocus,
                              searchController: _wardSearch,
                              onChanged: (val) => ref
                                  .read(publicTicketMigrationController)
                                  .targetValueUpdate('ward', val!),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            _buildTextField(
                              label: 'Call Details*',
                              controller: controller.commentsController,
                              maxLines: 4,
                              onChanged: (val) {
                                setState(
                                    () {}); // Trigger rebuild to update canMigrate
                              },
                              commentsWarning:
                                  controller.commentsController.text.isEmpty,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // --- IMAGE UPLOAD ---
                        if (pickedImageBytes == null)
                          InkWell(
                            onTap: () async {
                              ref
                                  .read(publicTicketMigrationController)
                                  .imagePicker();
                            },
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context).unselectedWidgetColor,
                                border: Border.all(
                                  color:
                                      Theme.of(context).unselectedWidgetColor,
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
                                height: 300,
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
                                        .read(publicTicketMigrationController)
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
                                            color:
                                                Theme.of(context).canvasColor,
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
                                        .read(publicTicketMigrationController)
                                        .removeImage();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .unselectedWidgetColor,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                  cursor: controller.canMigrate
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.forbidden,
                  child: GestureDetector(
                    onTap: controller.canMigrate
                        ? () {
                            EasyLoading.show(
                                status: 'Migrating...',
                                maskType: EasyLoadingMaskType.black);
                            controller.migrateTicket(context);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: controller.canMigrate
                            ? Theme.of(context).primaryColor
                            : Theme.of(
                                context,
                              ).unselectedWidgetColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Assign Ticket",
                        style: TextStyle(
                          color: controller.canMigrate
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
          ],
        ),
      ),
    );
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
  }) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Listener(
              onPointerDown: (_) {
                if (enabled && focusNode != null && !focusNode.hasFocus) {
                  focusNode.requestFocus();
                }
              },
              child: DropdownMenu<String>(
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
                  style: borderColor != null
                      ? TextStyle(color: borderColor)
                      : null,
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
                        return DropdownMenuEntry<String>(value: e, label: e);
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
              ));
        },
      ),
    );
  }

  // Widget _buildReadOnlyField(String label, String value) {
  //   return Expanded(
  //     child: TextFormField(
  //       initialValue: value.isEmpty ? "N/A" : value,
  //       enabled: false,
  //       decoration: InputDecoration(
  //         labelText: label,
  //         labelStyle: TextStyle(color: Theme.of(context).secondaryHeaderColor),
  //         border: const OutlineInputBorder(),
  //         disabledBorder: OutlineInputBorder(
  //           borderSide: BorderSide(
  //               color:
  //                   Theme.of(context).unselectedWidgetColor.withValues(alpha: 0.3)),
  //         ),
  //         contentPadding:
  //             const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //       ),
  //       style: TextStyle(
  //           color: Theme.of(context).secondaryHeaderColor.withValues(alpha: 0.5)),
  //     ),
  //   );
  // }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    bool enabled = true,
    bool isError = false,
    bool commentsWarning = false,
  }) {
    return Expanded(
      child: TextFormField(
        enabled: enabled,
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        style: TextStyle(
          color: !enabled
              ? Theme.of(context).unselectedWidgetColor
              : isError
                  ? Theme.of(context).tabBarTheme.indicatorColor
                  : Theme.of(context).secondaryHeaderColor,
        ),
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
                  borderSide:
                      BorderSide(color: Theme.of(context).tabBarTheme.indicatorColor!))
              : null,
          focusedBorder: isError
              ? OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Theme.of(context).tabBarTheme.indicatorColor!, width: 2))
              : null,
          contentPadding: EdgeInsets.all(maxLines > 1 ? 16.0 : 12.0),
        ),
      ),
    );
  }
}
