import 'package:flutter_svg/flutter_svg.dart';

import 'package:citizen_complaints_list_web/screens/Tickets_List/debounce_search_field.dart';
import 'package:citizen_complaints_list_web/screens/Ticket_Creation/new_ticket_controller.dart';
import 'package:citizen_complaints_list_web/screens/Ticket_Creation/new_ticket_screen.dart';
import 'package:citizen_complaints_list_web/screens/Ticket_Updation/ticket_update_controller.dart';
import 'package:citizen_complaints_list_web/screens/Ticket_Updation/ticket_update_screen.dart';
import 'package:citizen_complaints_list_web/screens/Ticket_Updation/public_ticket_migration_controller.dart';
import 'package:citizen_complaints_list_web/screens/Ticket_Updation/public_ticket_migration_screen.dart';
import 'package:citizen_complaints_list_web/screens/Tickets_List/audit_trail_dialog.dart';
import 'package:citizen_complaints_list_web/screens/Tickets_List/tickets_filter_dialog.dart';
import 'package:citizen_complaints_list_web/screens/Tickets_List/tickets_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:citizen_complaints_list_web/screens/Tickets_List/project_context_controller.dart';
import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:lottie/lottie.dart';

class TicketsListScreen extends ConsumerStatefulWidget {
  const TicketsListScreen({super.key});

  @override
  ConsumerState<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends ConsumerState<TicketsListScreen> {
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  final ScrollController _verticalBodyScrollController = ScrollController();
  late TextEditingController _pageTextController;
  final TextEditingController _pageSizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageTextController = TextEditingController();

    _headerScrollController.addListener(() {
      if (_headerScrollController.offset != _bodyScrollController.offset) {
        _bodyScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    _bodyScrollController.addListener(() {
      if (_bodyScrollController.offset != _headerScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    _verticalBodyScrollController.dispose();
    _pageTextController.dispose();
    _pageSizeController.dispose();
    super.dispose();
  }

  Widget _buildFixedWidthCell(
    context,
    String text, {
    double? width,
    bool isHeader = false,
    bool isComments = false,
    bool isPriority = false,
    String? tag,
  }) {
    Color colour = Theme.of(context).secondaryHeaderColor;
    if (isPriority) {
      colour = switch (text) {
        'Minor' => const Color.fromARGB(255, 255, 191, 0),
        'Major' => const Color.fromARGB(255, 255, 132, 0),
        'Warning' => const Color.fromARGB(255, 171, 171, 0),
        'Critical' => Colors.red,
        // 'Indeterminate' => const Color.fromARGB(255, 0, 125, 171),
        _ => Colors.grey,
      };
    }
    return SizedBox(
      width: isComments ? 200 : width ?? 125,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (tag != null && tag != '')
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: SizedBox(
                // width: 58,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (text.isNotEmpty)
            GestureDetector(
              onLongPress: () {
                if (isHeader) return;
                Clipboard.setData(ClipboardData(text: text));
                EasyLoading.show(
                  indicator: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy,
                        color: Theme.of(context).canvasColor,
                        size: 18,
                      ),
                      Text("  Copied",
                          style: TextStyle(
                            color: Theme.of(context).canvasColor,
                          )),
                    ],
                  ),
                  dismissOnTap: true,
                );

                Future.delayed(const Duration(milliseconds: 1500), () {
                  EasyLoading.dismiss();
                });
              },
              onDoubleTap: () {
                if (isHeader) return;
                Clipboard.setData(ClipboardData(text: text));
                EasyLoading.show(
                  indicator: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy,
                        color: Theme.of(context).canvasColor,
                        size: 18,
                      ),
                      Text("  Copied",
                          style: TextStyle(
                            color: Theme.of(context).canvasColor,
                          )),
                    ],
                  ),
                  dismissOnTap: true,
                );

                Future.delayed(const Duration(milliseconds: 1500), () {
                  EasyLoading.dismiss();
                });
              },
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: isHeader || isPriority
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: colour,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns(TicketsListProvider controller) {
    final isPublic = ref.read(ticketsListController).isPublic;

    return [
      DataColumn(
        label: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: _buildFixedWidthCell(
            context,
            'Ticket No',
            isHeader: true,
            width: 92,
          ),
        ),
        onSort: (idx, asc) => controller.onSort(idx, asc),
      ),
      DataColumn(
        label: _buildFixedWidthCell(context, 'Complainee',
            isHeader: true, width: 85),
        onSort: (idx, asc) => controller.onSort(idx, asc),
      ),
      DataColumn(
        label: _buildFixedWidthCell(context, 'Device/Asset',
            isHeader: true, width: 200),
        onSort: (idx, asc) => controller.onSort(idx, asc),
      ),
      DataColumn(
        label: _buildFixedWidthCell(context, 'Problem Type', isHeader: true),
        onSort: (idx, asc) => controller.onSort(idx, asc),
      ),
      DataColumn(
        label: _buildFixedWidthCell(
          context,
          'Priority',
          isHeader: true,
          width: 90,
        ),
        onSort: (idx, asc) => controller.onSort(idx, asc),
      ),
      DataColumn(
        label:
            _buildFixedWidthCell(context, 'Status', isHeader: true, width: 120),
        onSort: (idx, asc) => controller.onSort(idx, asc),
      ),
      DataColumn(
        label: _buildFixedWidthCell(
          context,
          'Created time',
          isHeader: true,
          width: 85,
        ),
        onSort: (idx, asc) => controller.onSort(idx, asc),
      ),
      if (isPublic)
        DataColumn(
          label: _buildFixedWidthCell(context, 'Complainee Contact No',
              isHeader: true),
          onSort: (idx, asc) => controller.onSort(idx, asc),
        ),
      if (!isPublic)
        DataColumn(
          label: _buildFixedWidthCell(context, 'Assignee', isHeader: true),
          onSort: (idx, asc) => controller.onSort(idx, asc),
        ),
      if (!isPublic)
        DataColumn(
          label: _buildFixedWidthCell(
            context,
            'Closed time',
            isHeader: true,
            width: 85,
          ),
          onSort: (idx, asc) => controller.onSort(idx, asc),
        ),
      DataColumn(
        label: _buildFixedWidthCell(
          context,
          'Duration\n(Days)',
          isHeader: true,
          width: 55,
        ),
        onSort: (idx, asc) => controller.onSort(idx, asc),
      ),
      DataColumn(
        label: _buildFixedWidthCell(
          context,
          'Comments',
          isHeader: true,
          isComments: true,
        ),
        onSort: (idx, asc) => controller.onSort(idx, asc),
      ),
      if (!isPublic)
        DataColumn(
          label: _buildFixedWidthCell(
            context,
            'Zone',
            isHeader: true,
            width: 100,
          ),
          onSort: (idx, asc) => controller.onSort(idx, asc),
        ),
      if (!isPublic)
        DataColumn(
          label: _buildFixedWidthCell(
            context,
            'Ward',
            isHeader: true,
            width: 100,
          ),
          onSort: (idx, asc) => controller.onSort(idx, asc),
        ),
    ];
  }

  Widget _buildSearchableFilterDropdown(
      BuildContext context,
      String label,
      String? value,
      List<String> items,
      double width,
      Function(String?) onChanged) {
    bool isDisabled = items.isEmpty;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: width,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownMenu<String>(
        key: ValueKey(value),
        width: width,
        menuHeight: 300,
        enableFilter: true,
        enabled: !isDisabled,
        requestFocusOnTap: true,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDisabled
                ? Theme.of(context).unselectedWidgetColor
                : Theme.of(context).secondaryHeaderColor,
          ),
        ),
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).secondaryHeaderColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).unselectedWidgetColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).unselectedWidgetColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          constraints: const BoxConstraints.tightFor(height: 40),
        ),
        initialSelection: value,
        onSelected: onChanged,
        filterCallback: (entries, filter) {
          final String term = filter.toUpperCase();
          final filteredEntries = entries
              .where((entry) => entry.label.toUpperCase().contains(term))
              .toList();

          if (filteredEntries.isEmpty) {
            return [
              DropdownMenuEntry<String>(
                value: '',
                label: 'Not Found',
                enabled: false,
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    TextStyle(
                      color: Theme.of(context).unselectedWidgetColor,
                    ),
                  ),
                ),
              ),
            ];
          }

          return filteredEntries;
        },
        dropdownMenuEntries: items.map((e) {
          return DropdownMenuEntry<String>(
            value: e,
            label: e,
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                TextStyle(
                  color: Theme.of(context).secondaryHeaderColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterTag(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
    VoidCallback? onRemove,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Open filter dialog when tag is clicked
          showDialog(
            context: context,
            builder: (context) {
              return TicketsFilterDialog(
                initialPriorities:
                    ref.read(ticketsListController).selectedPriorities,
                initialStatuses:
                    ref.read(ticketsListController).selectedStatuses,
                initialComplaineeTypes:
                    ref.read(ticketsListController).selectedComplaineeTypes,
                initialAssetTypes:
                    ref.read(ticketsListController).selectedAssetTypes,
                initialProblemTypes:
                    ref.read(ticketsListController).selectedProblemTypes,
                initialAssigneeIds:
                    ref.read(ticketsListController).selectedAssigneeIds,
                initialDateRange:
                    ref.read(ticketsListController).selectedDateRange,
                allComplainees: [...complaineeList, "Auto"],
                allAssetTypes: ref.read(ticketsListController).allAssetTypes,
                assetToProblemsMap:
                    ref.read(ticketsListController).assetToProblemsMap,
                allProblemTypes:
                    ref.read(ticketsListController).allProblemTypes,
                allAssignees: ref.read(ticketsListController).allAssigneesData,
                onFetchAssignees: () =>
                    ref.read(ticketsListController).fetchAssigneesForDialog(),
                onApply: (
                  priorities,
                  statuses,
                  complaineeTypes,
                  assetTypes,
                  problemTypes,
                  assigneeIds,
                  searchPhoneNumber,
                  dateRange,
                  assigneeNames,
                ) {
                  ref.read(ticketsListController).applyFilters(
                        priorities,
                        statuses,
                        complaineeTypes,
                        assetTypes,
                        problemTypes,
                        assigneeIds,
                        searchPhoneNumber,
                        dateRange,
                        assigneeNames: assigneeNames,
                      );
                },
                initialPhoneNumber:
                    ref.read(ticketsListController).selectedPhoneNumber,
                isPublic: ref.read(ticketsListController).isPublic,
                initialAssigneeNames: ref
                    .read(ticketsListController)
                    .filterProvider
                    .assigneeNames,
              );
            },
          );
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$label: ",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).secondaryHeaderColor,
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 6),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSummary(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(ticketsListController);
    List<Widget> tags = [];

    // Helper to format list: "Item" or "Item + N"
    String formatList(List<String> items) {
      if (items.isEmpty) return "";
      if (items.length == 1) return items.first;
      return "${items.first} + ${items.length - 1}";
    }

    if (controller.selectedStatuses.isNotEmpty) {
      tags.add(_buildFilterTag(
        context,
        ref,
        "Status",
        formatList(controller.selectedStatuses),
        () {
          ref.read(ticketsListController).applyFilters(
                controller.selectedPriorities,
                [], // Clear status filter to show all
                controller.selectedComplaineeTypes,
                controller.selectedAssetTypes,
                controller.selectedProblemTypes,
                controller.selectedAssigneeIds,
                controller.selectedPhoneNumber,
                controller.selectedDateRange,
                assigneeNames: controller.filterProvider.assigneeNames,
              );
        },
      ));
    }

    if (controller.selectedPriorities.isNotEmpty) {
      tags.add(_buildFilterTag(
        context,
        ref,
        "Priority",
        formatList(controller.selectedPriorities),
        () {
          ref.read(ticketsListController).applyFilters(
            [],
            controller.selectedStatuses,
            controller.selectedComplaineeTypes,
            controller.selectedAssetTypes,
            controller.selectedProblemTypes,
            controller.selectedAssigneeIds,
            controller.selectedPhoneNumber,
            controller.selectedDateRange,
            assigneeNames: controller.filterProvider.assigneeNames,
          );
        },
      ));
    }
    if (controller.selectedComplaineeTypes.isNotEmpty) {
      tags.add(_buildFilterTag(
        context,
        ref,
        "Complainee",
        formatList(controller.selectedComplaineeTypes),
        () {
          ref.read(ticketsListController).applyFilters(
                controller.selectedPriorities,
                controller.selectedStatuses,
                [],
                controller.selectedAssetTypes,
                controller.selectedProblemTypes,
                controller.selectedAssigneeIds,
                controller.selectedPhoneNumber,
                controller.selectedDateRange,
                assigneeNames: controller.filterProvider.assigneeNames,
              );
        },
      ));
    }
    if (controller.selectedAssetTypes.isNotEmpty) {
      tags.add(_buildFilterTag(
        context,
        ref,
        "Asset",
        formatList(controller.selectedAssetTypes
            .map((e) => getEntityLabel(e))
            .toList()),
        () {
          ref.read(ticketsListController).applyFilters(
                controller.selectedPriorities,
                controller.selectedStatuses,
                controller.selectedComplaineeTypes,
                [],
                controller.selectedProblemTypes,
                controller.selectedAssigneeIds,
                controller.selectedPhoneNumber,
                controller.selectedDateRange,
                assigneeNames: controller.filterProvider.assigneeNames,
              );
        },
      ));
    }
    if (controller.selectedProblemTypes.isNotEmpty) {
      tags.add(_buildFilterTag(
        context,
        ref,
        "Problem",
        formatList(controller.selectedProblemTypes),
        () {
          ref.read(ticketsListController).applyFilters(
                controller.selectedPriorities,
                controller.selectedStatuses,
                controller.selectedComplaineeTypes,
                controller.selectedAssetTypes,
                [],
                controller.selectedAssigneeIds,
                controller.selectedPhoneNumber,
                controller.selectedDateRange,
                assigneeNames: controller.filterProvider.assigneeNames,
              );
        },
      ));
    }
    if (controller.selectedAssigneeIds.isNotEmpty) {
      List<String> names = [];
      for (var id in controller.selectedAssigneeIds) {
        if (id == 'Unassigned') {
          names.add("Unassigned");
        } else {
          final assignee = controller.allAssigneesData.firstWhere(
            (e) => e['id'] == id,
            orElse: () => {
              'name': controller.filterProvider.assigneeNames[id] ?? 'Unknown'
            },
          );
          names.add(assignee['name'] ??
              controller.filterProvider.assigneeNames[id] ??
              'Unknown');
        }
      }
      tags.add(_buildFilterTag(
        context,
        ref,
        "Assignee",
        formatList(names),
        () {
          ref.read(ticketsListController).applyFilters(
                controller.selectedPriorities,
                controller.selectedStatuses,
                controller.selectedComplaineeTypes,
                controller.selectedAssetTypes,
                controller.selectedProblemTypes,
                [],
                controller.selectedPhoneNumber,
                controller.selectedDateRange,
                assigneeNames: controller.filterProvider.assigneeNames,
              );
        },
      ));
    }
    if (controller.selectedPhoneNumber.isNotEmpty) {
      tags.add(_buildFilterTag(
        context,
        ref,
        "Phone",
        controller.selectedPhoneNumber,
        () {
          ref.read(ticketsListController).applyFilters(
                controller.selectedPriorities,
                controller.selectedStatuses,
                controller.selectedComplaineeTypes,
                controller.selectedAssetTypes,
                controller.selectedProblemTypes,
                controller.selectedAssigneeIds,
                '', // Clear phone filter
                controller.selectedDateRange,
                assigneeNames: controller.filterProvider.assigneeNames,
              );
        },
      ));
    }
    if (controller.selectedDateRange != null) {
      final start = controller.selectedDateRange!.start;
      final end = controller.selectedDateRange!.end;
      final f =
          "${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}";
      tags.add(_buildFilterTag(
        context,
        ref,
        "Date",
        f,
        null,
      ));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 5.0, right: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          alignment: WrapAlignment.end,
          children: tags,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    final userContext = ref.watch(userContextController);
    final ticketsController = ref.watch(ticketsListController);
    final isPublic = ticketsController.isPublic;
    final publicCount = ticketsController.publicTicketCount;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            toolbarHeight: 50,
            actionsPadding: const EdgeInsets.only(top: 5, right: 15),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            title: Row(
              children: [
                if (width >= 900) ...[
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        return Row(
                          children: [
                            if (!isPublic) ...[
                              _buildSearchableFilterDropdown(
                                context,
                                "Customer",
                                userContext.selectedCustomer,
                                userContext.customers,
                                width * 0.17,
                                (val) => userContext.selectCustomer(val),
                              ),
                              const SizedBox(width: 5),
                              _buildSearchableFilterDropdown(
                                context,
                                "Region",
                                userContext.selectedRegion,
                                userContext.regions,
                                width * 0.17,
                                (val) => userContext.selectRegion(val),
                              ),
                              const SizedBox(width: 5),
                              _buildSearchableFilterDropdown(
                                context,
                                "Zone",
                                userContext.selectedZone,
                                userContext.zones,
                                width * 0.17,
                                (val) => userContext.selectZone(val),
                              ),
                              const SizedBox(width: 5),
                              _buildSearchableFilterDropdown(
                                  context,
                                  "Ward",
                                  userContext.selectedWard,
                                  userContext.wards,
                                  width * 0.17,
                                  (val) => userContext.selectWard(val)),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              // IconsButtonsWidget(
              //   msg: "Block",
              //   icon: Icons.block,
              //   onTap: () async {
              //     updateProblemTypes();
              //   },
              //   color: Theme.of(context).unselectedWidgetColor,
              // ),
              if (isPublic)
                Tooltip(
                    message: "Public Complaints",
                    child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            ticketsController.togglePublic();
                          },
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 10,
                              ),
                              height: 35,
                              width: width < 900 ? width / 1.7 : width / 1.36,
                              decoration: BoxDecoration(
                                color: isPublic
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30.0),
                                border: Border.all(
                                  color: !isPublic
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/public_tickets.svg',
                                        // width: 30,
                                        height: 20,
                                        colorFilter: ColorFilter.mode(
                                          !isPublic
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context).canvasColor,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      const Text(
                                        "Public Complaints",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Positioned(
                                    right: 0,
                                    child: Icon(Icons.close),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ))),
              if (publicCount != 0 && !isPublic)
                Tooltip(
                  message: "Public Complaints",
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        ticketsController.togglePublic();
                      },
                      child: (width > 1150 || width < 900)
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 10,
                                ),
                                height: 35,
                                decoration: BoxDecoration(
                                  color: isPublic
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30.0),
                                  border: Border.all(
                                    color: !isPublic
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/public_tickets.svg',
                                      // width: 30,
                                      height: 20,
                                      colorFilter: ColorFilter.mode(
                                        !isPublic
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(context).canvasColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "$publicCount",
                                      style: TextStyle(
                                          color: !isPublic
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context).canvasColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4.5),
                                    decoration: BoxDecoration(
                                      color: isPublic
                                          ? Theme.of(context).primaryColor
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: !isPublic
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                      ),
                                    ),
                                    width: 35,
                                    height: 35,
                                    child: SvgPicture.asset(
                                      'assets/icons/public_tickets.svg',
                                      width: 10,
                                      height: 10,
                                      colorFilter: ColorFilter.mode(
                                        !isPublic
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(context).canvasColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF3B30),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          publicCount > 99
                                              ? '99+'
                                              : '$publicCount',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).canvasColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              SizedBox(width: (width > 1150 || width < 900) ? 10 : 5),
              IconsButtonsWidget(
                  msg: "Refresh",
                  icon: Icons.refresh,
                  onTap: () async {
                    ref.read(ticketsListController).reload();
                  }),

              SizedBox(width: (width > 1150 || width < 900) ? 10 : 5),
              IconsButtonsWidget(
                  msg: "Export to CSV",
                  icon: Icons.file_download_outlined,
                  onTap: () async {
                    await ref.read(ticketsListController).exportToCsv();
                  }),
              SizedBox(width: (width > 1150 || width < 900) ? 10 : 5),

              PopupMenuButton(
                  tooltip: "search",
                  offset: const Offset(0, 45),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        enabled: false,
                        child: SizedBox(
                          width: 300,
                          child: DebounceSearchField(
                            initialValue:
                                ref.read(ticketsListController).searchQuery,
                            autofocus: true,
                            onChanged: (value) {
                              ref
                                  .read(ticketsListController)
                                  .setSearchQuery(value);
                            },
                            onClear: () {
                              Navigator.pop(context);
                              ref.read(ticketsListController).clearSearch();
                            },
                          ),
                        ),
                      ),
                    ];
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search,
                            size: 25,
                            color: Theme.of(context).canvasColor,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: ref
                                    .watch(ticketsListController)
                                    .searchQuery
                                    .isEmpty
                                ? Colors.transparent
                                : const Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  )),
              SizedBox(width: (width > 1150 || width < 900) ? 10 : 5),
              IconsButtonsWidget(
                  msg: "filter",
                  icon: Icons.filter_list,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return TicketsFilterDialog(
                          initialPriorities: ref
                              .read(ticketsListController)
                              .selectedPriorities,
                          initialStatuses:
                              ref.read(ticketsListController).selectedStatuses,
                          initialComplaineeTypes: ref
                              .read(ticketsListController)
                              .selectedComplaineeTypes,
                          initialAssetTypes: ref
                              .read(ticketsListController)
                              .selectedAssetTypes,
                          initialProblemTypes: ref
                              .read(ticketsListController)
                              .selectedProblemTypes,
                          initialAssigneeIds: ref
                              .read(ticketsListController)
                              .selectedAssigneeIds,
                          initialPhoneNumber: ref
                              .read(ticketsListController)
                              .selectedPhoneNumber,
                          initialDateRange:
                              ref.read(ticketsListController).selectedDateRange,
                          allComplainees: [...complaineeList, "Auto"],
                          allAssetTypes:
                              ref.read(ticketsListController).allAssetTypes,
                          assetToProblemsMap: ref
                              .read(ticketsListController)
                              .assetToProblemsMap,
                          allProblemTypes:
                              ref.read(ticketsListController).allProblemTypes,
                          allAssignees:
                              ref.read(ticketsListController).allAssigneesData,
                          onFetchAssignees: () => ref
                              .read(ticketsListController)
                              .fetchAssigneesForDialog(),
                          onApply: (
                            priorities,
                            statuses,
                            complaineeTypes,
                            assetTypes,
                            problemTypes,
                            assigneeIds,
                            searchPhoneNumber,
                            dateRange,
                            assigneeNames,
                          ) {
                            ref.read(ticketsListController).applyFilters(
                                  priorities,
                                  statuses,
                                  complaineeTypes,
                                  assetTypes,
                                  problemTypes,
                                  assigneeIds,
                                  searchPhoneNumber,
                                  dateRange,
                                  assigneeNames: assigneeNames,
                                );
                          },
                          isPublic: ref.read(ticketsListController).isPublic,
                          initialAssigneeNames: ref
                              .read(ticketsListController)
                              .filterProvider
                              .assigneeNames,
                        );
                      },
                    );
                  }),
              SizedBox(width: (width > 1150 || width < 900) ? 10 : 5),
              Tooltip(
                message: isPublic ? '' : "New Ticket",
                child: MouseRegion(
                  cursor: isPublic
                      ? SystemMouseCursors.forbidden
                      : SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () async {
                      if (!isPublic) {
                        await ref.read(newTicketController).prePopulateContext(
                              region: userContext.selectedRegion,
                              zone: userContext.selectedZone,
                              ward: userContext.selectedWard,
                            );
                        await ref
                            .read(newTicketController)
                            .valueUpdate('minimize', false);
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return Dialog(
                              insetPadding: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SizedBox(
                                width: 600,
                                height: 700,
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 16.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Create Tickets",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .canvasColor,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.remove,
                                                  color: Theme.of(context)
                                                      .canvasColor),
                                              onPressed: () {
                                                EasyLoading.dismiss();
                                                ref
                                                    .read(newTicketController)
                                                    .valueUpdate(
                                                        'minimize', true);
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: NewTicketScreen()),
                                  ],
                                ),
                              ),
                            );
                          },
                        ).then((_) {
                          ref.read(newTicketController).clearData();
                          ref.read(ticketsListController).reload();
                        });
                      } else {
                        return;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isPublic
                            ? Theme.of(context).disabledColor
                            : Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 25,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).canvasColor,
          body: Stack(
            children: [
              Builder(
                builder: (context) {
                  final isSmallScreen = width < 900;

                  Widget? smallScreenHeader;
                  if (isSmallScreen) {
                    smallScreenHeader = Consumer(
                      builder: (context, ref, _) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              if (!isPublic) ...[
                                _buildSearchableFilterDropdown(
                                  context,
                                  "Customer",
                                  userContext.selectedCustomer,
                                  userContext.customers,
                                  width - 16,
                                  (val) => userContext.selectCustomer(val),
                                ),
                                const SizedBox(height: 2),
                                _buildSearchableFilterDropdown(
                                  context,
                                  "Region",
                                  userContext.selectedRegion,
                                  userContext.regions,
                                  width - 16,
                                  (val) => userContext.selectRegion(val),
                                ),
                                if (!isPublic) ...[
                                  const SizedBox(height: 2),
                                  _buildSearchableFilterDropdown(
                                    context,
                                    "Zone",
                                    userContext.selectedZone,
                                    userContext.zones,
                                    width - 16,
                                    (val) => userContext.selectZone(val),
                                  ),
                                  const SizedBox(height: 2),
                                  _buildSearchableFilterDropdown(
                                    context,
                                    "Ward",
                                    userContext.selectedWard,
                                    userContext.wards,
                                    width - 16,
                                    (val) => userContext.selectWard(val),
                                  ),
                                ],
                              ]
                            ],
                          ),
                        );
                      },
                    );
                  }

                  return Consumer(
                    builder: (context, ref, _) {
                      final controller = ref.watch(ticketsListController);

                      if (controller.isLoading && controller.tickets.isEmpty) {
                        return Column(
                          children: [
                            if (smallScreenHeader != null) smallScreenHeader,
                            _buildFilterSummary(context, ref),
                            Expanded(
                              child: Center(
                                child: SpinKitThreeBounce(
                                    color: Theme.of(context).primaryColor),
                              ),
                            ),
                          ],
                        );
                      }

                      if (controller.tickets.isEmpty) {
                        return Column(
                          children: [
                            if (smallScreenHeader != null) smallScreenHeader,
                            _buildFilterSummary(context, ref),
                            const Expanded(
                                child: Center(child: Text('No tickets found'))),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  child: Text(
                                    "v $dashboardVersion",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .secondaryHeaderColor
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 20)
                          ],
                        );
                      }

                      final tickets = controller.tickets;
                      const double actionsColumnWidth = 120;

                      double measureTextHeight(String text, double maxWidth,
                          {bool isBold = false}) {
                        if (text.isEmpty) return 0;
                        final TextSpan textSpan = TextSpan(
                          text: text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isBold ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                        final TextPainter textPainter = TextPainter(
                          text: textSpan,
                          textDirection: TextDirection.ltr,
                        );
                        textPainter.layout(maxWidth: maxWidth);
                        return textPainter.height;
                      }

                      double calculateRowHeight(Map<String, dynamic> data) {
                        double maxHeight = 55.0;
                        const double verticalPadding = 10.0;

                        final entityName =
                            data['entity_name']?.toString() ?? '';
                        final entityType = getEntityLabel(
                            data['entity_type']?.toString() ?? '');

                        double deviceColHeight =
                            measureTextHeight(entityName, 150);
                        if (entityType.isNotEmpty) {
                          deviceColHeight +=
                              4 + measureTextHeight(entityType, 150 - 16) + 4;
                        }
                        if ((deviceColHeight + verticalPadding) > maxHeight) {
                          maxHeight = deviceColHeight + verticalPadding;
                        }
                        // // 2. Comments (Width: 200)
                        // final comments = data['comments']?.toString() ?? '';
                        // final commentsHeight = measureTextHeight(comments, 550);
                        // if ((commentsHeight + verticalPadding) > maxHeight) {
                        //   maxHeight = commentsHeight + verticalPadding;
                        // }

                        return maxHeight;
                      }

                      if (!controller.isSyncing &&
                          _pageTextController.text !=
                              controller.currentPage.toString()) {
                        _pageTextController.text =
                            controller.currentPage.toString();
                      }

                      return Column(
                        children: [
                          if (smallScreenHeader != null) smallScreenHeader,
                          _buildFilterSummary(context, ref),
                          Expanded(
                              child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 56.0,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Theme.of(context)
                                                    .dividerColor,
                                                width: 0.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SingleChildScrollView(
                                          controller: _headerScrollController,
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            headingRowHeight: 56.0,
                                            columnSpacing: 0,
                                            horizontalMargin: 10,
                                            dividerThickness: 0.01,
                                            showBottomBorder: true,
                                            sortColumnIndex:
                                                controller.sortColumnIndex,
                                            sortAscending:
                                                controller.isAscending,
                                            columns: _buildColumns(controller),
                                            rows: const [],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    child: DataTable(
                                      columnSpacing: 0,
                                      horizontalMargin: 0,
                                      dividerThickness: 0.01,
                                      showBottomBorder: true,
                                      columns: [
                                        DataColumn(
                                          label: Container(
                                            width: actionsColumnWidth,
                                            alignment: Alignment.center,
                                            child: const Text(''),
                                          ),
                                        ),
                                      ],
                                      rows: const [],
                                    ),
                                  ),
                                ],
                              ),

                              // Body Rows
                              Expanded(
                                child: controller.isSyncing
                                    ? Center(
                                        child: SpinKitThreeBounce(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      )
                                    : ScrollbarTheme(
                                        data: ScrollbarThemeData(
                                          thumbColor: WidgetStateProperty.all(
                                            Theme.of(context)
                                                .unselectedWidgetColor
                                                .withValues(alpha: 0.5),
                                          ),
                                          thickness:
                                              WidgetStateProperty.all(5.0),
                                          radius: const Radius.circular(20),
                                          thumbVisibility:
                                              WidgetStateProperty.all(true),
                                        ),
                                        child: Scrollbar(
                                          controller:
                                              _verticalBodyScrollController,
                                          thumbVisibility: true,
                                          trackVisibility: false,
                                          child: SingleChildScrollView(
                                            controller:
                                                _verticalBodyScrollController,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Stack(
                                                    children: [
                                                      IgnorePointer(
                                                        child: Column(
                                                          children: tickets
                                                              .map((doc) {
                                                            final data =
                                                                doc.data();
                                                            final h =
                                                                calculateRowHeight(
                                                                    data);
                                                            return Container(
                                                              height: h,
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border(
                                                                  bottom:
                                                                      BorderSide(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .dividerColor,
                                                                    width: 0.3,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                      Scrollbar(
                                                        controller:
                                                            _bodyScrollController,
                                                        thumbVisibility: true,
                                                        trackVisibility: false,
                                                        child:
                                                            SingleChildScrollView(
                                                          controller:
                                                              _bodyScrollController,
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          child: DataTable(
                                                            dataRowMinHeight:
                                                                0, // Allow variable min
                                                            dataRowMaxHeight: double
                                                                .infinity, // Allow expansion
                                                            headingRowHeight: 0,
                                                            columnSpacing: 0,
                                                            horizontalMargin:
                                                                10,
                                                            dividerThickness:
                                                                0.01,
                                                            showBottomBorder:
                                                                true,
                                                            columns:
                                                                _buildColumns(
                                                                    controller),
                                                            rows: tickets
                                                                .map((doc) {
                                                              final data =
                                                                  doc.data();
                                                              final closedOn = data[
                                                                  'ticket_closed_on'];
                                                              final h =
                                                                  calculateRowHeight(
                                                                      data);

                                                              return DataRow(
                                                                cells: [
                                                                  DataCell(
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            8),
                                                                    child: Container(
                                                                        height:
                                                                            h,
                                                                        alignment:
                                                                            Alignment
                                                                                .centerLeft,
                                                                        child: _buildFixedWidthCell(
                                                                            context,
                                                                            data['ticket_id']?.toString() ??
                                                                                '',
                                                                            width:
                                                                                92)),
                                                                  )),
                                                                  DataCell(Container(
                                                                      height: h,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: _buildFixedWidthCell(
                                                                          context,
                                                                          data['complainee']?.toString() ??
                                                                              '',
                                                                          width:
                                                                              85))),
                                                                  DataCell(Container(
                                                                      height: h,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: _buildFixedWidthCell(
                                                                          context,
                                                                          data['entity_name']?.toString() ??
                                                                              '',
                                                                          tag: getEntityLabel(data['entity_type']?.toString() ??
                                                                              ''),
                                                                          width:
                                                                              200))),
                                                                  DataCell(Container(
                                                                      height: h,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: _buildFixedWidthCell(
                                                                          context,
                                                                          data['problem_type']?.toString() ??
                                                                              ''))),
                                                                  DataCell(Container(
                                                                      height: h,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: _buildFixedWidthCell(
                                                                          context,
                                                                          data['priority']?.toString() ??
                                                                              '',
                                                                          width:
                                                                              90,
                                                                          isPriority:
                                                                              true))),
                                                                  DataCell(Container(
                                                                      height: h,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: _buildFixedWidthCell(
                                                                          context,
                                                                          data['status']?.toString() ??
                                                                              '',
                                                                          width:
                                                                              120))),
                                                                  DataCell(Container(
                                                                      height: h,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: _buildFixedWidthCell(
                                                                          context,
                                                                          data['ticket_opened_on']?.toString().replaceFirst(' ', '\n') ??
                                                                              '',
                                                                          width:
                                                                              85))),
                                                                  if (isPublic)
                                                                    DataCell(Container(
                                                                        height: h,
                                                                        alignment: Alignment.centerLeft,
                                                                        child: _buildFixedWidthCell(
                                                                          context,
                                                                          data['complainee_contact_no']?.toString() ??
                                                                              '',
                                                                        ))),
                                                                  if (!isPublic)
                                                                    DataCell(Container(
                                                                        height: h,
                                                                        alignment: Alignment.centerLeft,
                                                                        child: _buildFixedWidthCell(
                                                                          context,
                                                                          data['assignee']?.toString() ??
                                                                              '',
                                                                        ))),
                                                                  if (!isPublic)
                                                                    DataCell(Container(
                                                                        height:
                                                                            h,
                                                                        alignment:
                                                                            Alignment
                                                                                .centerLeft,
                                                                        child: _buildFixedWidthCell(
                                                                            context,
                                                                            (closedOn == null || closedOn.toString().trim().isEmpty)
                                                                                ? ''
                                                                                : closedOn.toString().replaceFirst(' ', '\n'),
                                                                            width: 85))),
                                                                  DataCell(Container(
                                                                      height: h,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: _buildFixedWidthCell(
                                                                          context,
                                                                          '${getDaysDifference(data['ticket_opened_on'], data['ticket_closed_on'])}',
                                                                          width:
                                                                              55))),
                                                                  DataCell(Container(
                                                                      height: h,
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: _buildFixedWidthCell(
                                                                          context,
                                                                          data['comments']?.toString().replaceAll('\n', ' ') ??
                                                                              '',
                                                                          isComments:
                                                                              true))),
                                                                  if (!isPublic)
                                                                    DataCell(Container(
                                                                        height:
                                                                            h,
                                                                        alignment:
                                                                            Alignment
                                                                                .centerLeft,
                                                                        child: _buildFixedWidthCell(
                                                                            context,
                                                                            data['zone']?.toString() ??
                                                                                '',
                                                                            width:
                                                                                100))),
                                                                  if (!isPublic)
                                                                    DataCell(Container(
                                                                        height:
                                                                            h,
                                                                        alignment:
                                                                            Alignment
                                                                                .centerLeft,
                                                                        child: _buildFixedWidthCell(
                                                                            context,
                                                                            data['ward']?.toString() ??
                                                                                '',
                                                                            width:
                                                                                100))),
                                                                ],
                                                              );
                                                            }).toList(),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DataTable(
                                                  dataRowMinHeight: 0,
                                                  dataRowMaxHeight:
                                                      double.infinity,
                                                  headingRowHeight: 0,
                                                  columnSpacing: 0,
                                                  horizontalMargin: 0,
                                                  dividerThickness: 0.3,
                                                  showBottomBorder: true,
                                                  columns: const [
                                                    DataColumn(
                                                      label: SizedBox(
                                                        width:
                                                            actionsColumnWidth,
                                                        child: Text(''),
                                                      ),
                                                    ),
                                                  ],
                                                  rows: tickets.map((doc) {
                                                    final data = doc.data();
                                                    final h =
                                                        calculateRowHeight(
                                                            data);
                                                    return DataRow(
                                                      cells: [
                                                        DataCell(
                                                          Container(
                                                            height: h,
                                                            alignment: Alignment
                                                                .center,
                                                            width:
                                                                actionsColumnWidth,
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Tooltip(
                                                                  message:
                                                                      'Edit',
                                                                  child:
                                                                      IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .edit,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .secondaryHeaderColor
                                                                          .withValues(
                                                                              alpha: 0.7),
                                                                    ),
                                                                    onPressed:
                                                                        () async {
                                                                      await ref
                                                                          .read(
                                                                              ticketUpdateController)
                                                                          .valueUpdate(
                                                                              'minimize',
                                                                              false);
                                                                      final bool
                                                                          isPublic =
                                                                          data['customer'] ==
                                                                              'Public';
                                                                      if (isPublic) {
                                                                        ref.read(publicTicketMigrationController).initialize(
                                                                            data,
                                                                            doc.id);
                                                                      } else {
                                                                        ref.read(ticketUpdateController).initialize(
                                                                            data,
                                                                            doc.id);
                                                                      }
                                                                      showDialog(
                                                                        context:
                                                                            context,
                                                                        barrierDismissible:
                                                                            false,
                                                                        builder:
                                                                            (context) {
                                                                          return Dialog(
                                                                            insetPadding:
                                                                                const EdgeInsets.all(
                                                                              20,
                                                                            ),
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(
                                                                                16,
                                                                              ),
                                                                            ),
                                                                            child:
                                                                                SizedBox(
                                                                              width: 600,
                                                                              height: 700,
                                                                              child: Column(
                                                                                children: [
                                                                                  Container(
                                                                                    decoration: BoxDecoration(
                                                                                      borderRadius: const BorderRadius.only(
                                                                                        topLeft: Radius.circular(
                                                                                          16,
                                                                                        ),
                                                                                        topRight: Radius.circular(
                                                                                          16,
                                                                                        ),
                                                                                      ),
                                                                                      color: Theme.of(
                                                                                        context,
                                                                                      ).primaryColor,
                                                                                    ),
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsets.symmetric(
                                                                                        horizontal: 16.0,
                                                                                        vertical: 16.0,
                                                                                      ),
                                                                                      child: Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                        children: [
                                                                                          Text(
                                                                                            isPublic ? "Assign Ticket - ${doc['ticket_id']}" : "Update Ticket - ${doc['ticket_id']}",
                                                                                            style: TextStyle(
                                                                                              fontSize: 20,
                                                                                              fontWeight: FontWeight.bold,
                                                                                              color: Theme.of(
                                                                                                context,
                                                                                              ).canvasColor,
                                                                                            ),
                                                                                          ),
                                                                                          IconButton(
                                                                                            onPressed: () {
                                                                                              EasyLoading.dismiss();
                                                                                              ref.read(ticketUpdateController).valueUpdate('minimize', true);
                                                                                              Navigator.of(context).pop();
                                                                                            },
                                                                                            icon: Icon(
                                                                                              Icons.remove,
                                                                                              color: Theme.of(
                                                                                                context,
                                                                                              ).canvasColor,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const Divider(
                                                                                    height: 1,
                                                                                  ),
                                                                                  Expanded(
                                                                                    child: ClipRRect(
                                                                                      borderRadius: const BorderRadius.only(
                                                                                        bottomLeft: Radius.circular(
                                                                                          16,
                                                                                        ),
                                                                                        bottomRight: Radius.circular(
                                                                                          16,
                                                                                        ),
                                                                                      ),
                                                                                      child: isPublic ? const PublicTicketMigrationScreen() : const TicketEditScreen(),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                      ).then(
                                                                          (_) {
                                                                        ref
                                                                            .read(ticketUpdateController)
                                                                            .clearData();
                                                                        ref
                                                                            .read(publicTicketMigrationController)
                                                                            .clearData();
                                                                        ref
                                                                            .read(ticketsListController)
                                                                            .reload();
                                                                      });
                                                                    },
                                                                  ),
                                                                ),
                                                                Tooltip(
                                                                  message:
                                                                      'Audit Trail',
                                                                  child:
                                                                      IconButton(
                                                                    icon: Icon(
                                                                      Icons
                                                                          .history,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .secondaryHeaderColor
                                                                          .withValues(
                                                                              alpha: 0.7),
                                                                    ),
                                                                    onPressed:
                                                                        () {
                                                                      showDialog(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (context) =>
                                                                                AuditTrailDialog(
                                                                          ticketId:
                                                                              data['ticket_id'] ?? '',
                                                                          auditTrail:
                                                                              data['audit_trail'] ?? [],
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          )),

                          // Pagination Footer
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8.0, right: 8.0),
                            child: Row(
                              children: [
                                const SizedBox(width: 15),
                                Text(
                                  "v $dashboardVersion",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .secondaryHeaderColor
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                const Spacer(),
                                Row(children: [
                                  const Text("Tickets per page: "),
                                  const SizedBox(width: 3),
                                  // DropdownMenu with custom input support
                                  SizedBox(
                                    width: 80,
                                    height: 40,
                                    child: TextField(
                                      controller: _pageSizeController
                                        ..text = controller.pageSize.toString(),
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 0,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        suffixIcon: PopupMenuButton<int>(
                                          icon:
                                              const Icon(Icons.arrow_drop_down),
                                          padding: EdgeInsets.zero,
                                          onSelected: (val) {
                                            controller.setPageSize(val);
                                            _pageSizeController.text =
                                                val.toString();
                                          },
                                          itemBuilder: (context) => [10, 20, 30]
                                              .map(
                                                (e) => PopupMenuItem(
                                                  value: e,
                                                  child: Text(e.toString()),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onSubmitted: (val) {
                                        final size = int.tryParse(val);
                                        if (size != null && size > 0) {
                                          controller.setPageSize(size);
                                        } else {
                                          // Revert
                                          _pageSizeController.text =
                                              controller.pageSize.toString();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    "${(controller.currentPage - 1) * controller.pageSize + 1} - ${(controller.currentPage * controller.pageSize).clamp(0, controller.totalCount)} of ${controller.totalCount}",
                                  ),
                                  const SizedBox(width: 15),

                                  const Text("Page  "),
                                  SizedBox(
                                    width: 50,
                                    child: TextField(
                                      controller: _pageTextController
                                        ..text =
                                            controller.currentPage.toString(),
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 8,
                                        ),
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onSubmitted: (val) {
                                        final page = int.tryParse(val);
                                        if (page != null) {
                                          controller.jumpToPage(page);
                                        } else {
                                          _pageTextController.text =
                                              controller.currentPage.toString();
                                        }
                                      },
                                    ),
                                  ),
                                  Text("  of  ${controller.totalPages}"),
                                  const SizedBox(width: 5),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: controller.currentPage > 1
                                        ? () {
                                            controller.previousPage();
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: (controller.currentPage <
                                                controller.totalPages) ||
                                            (controller.hasMore &&
                                                controller.totalPages == 0)
                                        ? () {
                                            controller.nextPage();
                                          }
                                        : null,
                                  ),
                                ])
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: isDashboardPreparingNotifier,
            builder: (ctx, isPreparing, _) {
              if (!isPreparing) {
                return const SizedBox.shrink();
              }
              return AbsorbPointer(
                child: Container(
                  color: Theme.of(context).canvasColor,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            width: 150.0,
                            height: 150.0,
                            child: Lottie.asset(
                              "assets/animation/preparing.json",
                              fit: BoxFit.fill,
                            )),
                        Text(
                          'Preparing Dashboard',
                          style: TextStyle(
                            color: Theme.of(context).secondaryHeaderColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class IconsButtonsWidget extends StatelessWidget {
  const IconsButtonsWidget(
      {super.key,
      required this.msg,
      required this.icon,
      required this.onTap,
      this.color});

  final String msg;
  final IconData icon;
  final Function onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          onTap();
        },
        child: Tooltip(
          message: msg,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color ?? Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 25,
              color: Theme.of(context).canvasColor,
            ),
          ),
        ),
      ),
    );
  }
}
