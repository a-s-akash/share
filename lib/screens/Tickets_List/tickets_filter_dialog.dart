import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:citizen_complaints_list_web/screens/Tickets_List/tickets_list_controller.dart';

class TicketsFilterDialog extends StatefulWidget {
  final List<String> initialPriorities;
  final List<String> initialStatuses;
  final List<String> initialComplaineeTypes;
  final List<String> initialAssetTypes;
  final List<String> initialProblemTypes;
  final List<String> initialAssigneeIds;

  final List<String> allComplainees;
  final List<String> allAssetTypes;
  final List<String> allProblemTypes;
  final Map<String, List<String>> assetToProblemsMap;
  final List<Map<String, String>> allAssignees;

  final Function(
    List<String> priorities,
    List<String> statuses,
    List<String> complaineeTypes,
    List<String> assetTypes,
    List<String> problemTypes,
    List<String> assigneeIds,
    String searchPhoneNumber,
    DateTimeRange? dateRange,
    Map<String, String>? assigneeNames,
  ) onApply;

  final Future<List<Map<String, String>>> Function()? onFetchAssignees;

  const TicketsFilterDialog({
    super.key,
    required this.initialPriorities,
    required this.initialStatuses,
    required this.initialComplaineeTypes,
    required this.initialAssetTypes,
    required this.initialProblemTypes,
    required this.initialAssigneeIds,
    required this.allComplainees,
    required this.allAssetTypes,
    required this.allProblemTypes,
    required this.assetToProblemsMap,
    required this.allAssignees,
    required this.onApply,
    required this.isPublic,
    required this.initialPhoneNumber,
    this.initialDateRange,
    this.onFetchAssignees,
    this.initialAssigneeNames,
  });

  final Map<String, String>? initialAssigneeNames;

  final bool isPublic;
  final String initialPhoneNumber;

  final DateTimeRange? initialDateRange;

  @override
  State<TicketsFilterDialog> createState() => _TicketsFilterDialogState();
}

class _TicketsFilterDialogState extends State<TicketsFilterDialog> {
  late List<String> _selectedPriorities;
  late List<String> _selectedStatuses;
  late List<String> _selectedComplaineeTypes;
  late List<String> _selectedAssetTypes;
  late List<String> _selectedProblemTypes;
  late List<String> _selectedAssigneeIds;
  final TextEditingController _searchController = TextEditingController();
  late final TextEditingController _phoneNumberController;

  List<Map<String, String>> _assignees = [];
  bool _isLoadingAssignees = false;
  final FocusNode _assigneeFocusNode = FocusNode();
  DateTimeRange? _selectedDateRange;

  final List<String> _allPriorities = [
    'Critical',
    'Major',
    'Minor',
    'Warning',
    // 'Indeterminate',
  ];
  final List<String> _allStatuses = [
    'Open',
    'Assigned',
    'Visited-Closed',
    'Visited-Not Closed',
    'Verified-Opened',
    'Verified-Closed',
    'Closed',
    'Verified-Duplicate',
    'Waiting-For-Support'
  ];

  @override
  void initState() {
    super.initState();
    _selectedPriorities = List.from(widget.initialPriorities);
    _selectedStatuses = List.from(widget.initialStatuses);
    _selectedComplaineeTypes = List.from(widget.initialComplaineeTypes);
    _selectedAssetTypes = List.from(widget.initialAssetTypes);
    _selectedProblemTypes = List.from(widget.initialProblemTypes);
    _selectedAssigneeIds = List.from(widget.initialAssigneeIds);
    _assignees = List.from(widget.allAssignees);
    _selectedDateRange = widget.initialDateRange;
    _phoneNumberController =
        TextEditingController(text: widget.initialPhoneNumber);

    _assigneeFocusNode.addListener(_onAssigneeFocusChange);
  }

  void _onAssigneeFocusChange() {
    if (_assigneeFocusNode.hasFocus &&
        _assignees.isEmpty &&
        widget.onFetchAssignees != null &&
        !_isLoadingAssignees) {
      _fetchAssignees();
    }
  }

  Future<void> _fetchAssignees() async {
    setState(() {
      _isLoadingAssignees = true;
    });
    try {
      final fetched = await widget.onFetchAssignees!();
      if (mounted) {
        setState(() {
          _assignees = fetched;
          _isLoadingAssignees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAssignees = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _phoneNumberController.dispose();
    _assigneeFocusNode.dispose();
    super.dispose();
  }

  void _toggleSelection(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Widget _buildFilterSection(
      String title, List<String> options, List<String> selected,
      {Function(String)? onSelectionChanged,
      String Function(String)? labelMapper,
      List<String> alarmOptions = const []}) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Theme.of(context).unselectedWidgetColor,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  (title == 'Problem Types' && alarmOptions.isNotEmpty)
                      ? "Manual $title"
                      : title,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((option) {
                    final isSelected = selected.contains(option);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(
                        labelMapper != null ? labelMapper(option) : option,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).canvasColor
                              : Theme.of(context).secondaryHeaderColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      selectedColor: Theme.of(context).primaryColor,
                      checkmarkColor: Theme.of(context).canvasColor,
                      onSelected: (_) {
                        _toggleSelection(selected, option);
                        if (onSelectionChanged != null) {
                          onSelectionChanged(option);
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).unselectedWidgetColor,
                        ),
                      ),
                      showCheckmark: true,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          if (title == 'Problem Types' && alarmOptions.isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        "Alarm $title",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: alarmOptions!.map((option) {
                          final isSelected = selected.contains(option);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(
                              labelMapper != null
                                  ? labelMapper(option)
                                  : option,
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).canvasColor
                                    : Theme.of(context).secondaryHeaderColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            backgroundColor: Colors.transparent,
                            selectedColor: Theme.of(context).primaryColor,
                            checkmarkColor: Theme.of(context).canvasColor,
                            onSelected: (_) {
                              _toggleSelection(selected, option);
                              if (onSelectionChanged != null) {
                                onSelectionChanged(option);
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).unselectedWidgetColor,
                              ),
                            ),
                            showCheckmark: true,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAssigneeFilterSection() {
    final List<Map<String, String>> availableAssignees = _assignees
        .where((e) => !_selectedAssigneeIds.contains(e['id']))
        .toList();

    final List<DropdownMenuEntry<String>> entries = [];

    final Set<String> addedIds = {};
    for (final assignee in availableAssignees) {
      final id = assignee['id'] ?? '';
      final name = assignee['name'] ?? '';
      if (id.isNotEmpty && !addedIds.contains(id)) {
        entries.add(
          DropdownMenuEntry<String>(
            value: id,
            label: name.isNotEmpty ? name : id,
          ),
        );
        addedIds.add(id);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Theme.of(context).unselectedWidgetColor,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 120,
            child: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "Assignee",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Listener(
                    onPointerDown: (_) {
                      if (!_assigneeFocusNode.hasFocus) {
                        _assigneeFocusNode.requestFocus();
                      }
                    },
                    child: DropdownMenu<String>(
                      controller: _searchController,
                      width: 250,
                      menuHeight: 300,
                      hintText: "Search",
                      enableFilter: true,
                      requestFocusOnTap: true,
                      focusNode: _assigneeFocusNode,
                      trailingIcon: _isLoadingAssignees
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_drop_down),
                      dropdownMenuEntries: entries.isEmpty
                          ? [
                              DropdownMenuEntry<String>(
                                value: '',
                                label: _isLoadingAssignees
                                    ? 'Fetching...'
                                    : 'No Assignees Found',
                                enabled: false,
                              ),
                            ]
                          : entries,
                      inputDecorationTheme: const InputDecorationTheme(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      filterCallback: (entries, filter) {
                        final String term = filter.toUpperCase();
                        final filteredEntries = entries
                            .where((entry) =>
                                entry.label.toUpperCase().contains(term))
                            .toList();

                        if (filteredEntries.isEmpty) {
                          return [
                            DropdownMenuEntry<String>(
                              value: '',
                              label: _isLoadingAssignees
                                  ? 'Fetching...'
                                  : 'Not Found',
                              enabled: false,
                            ),
                          ];
                        }

                        return filteredEntries;
                      },
                      onSelected: (String? value) {
                        if (value != null && value.isNotEmpty) {
                          setState(() {
                            _toggleSelection(_selectedAssigneeIds, value);
                            _searchController.clear();
                          });
                        }
                      },
                    )),
                ..._selectedAssigneeIds.map((id) {
                  String label = id;
                  if (id == 'Unassigned') {
                    label = 'Unassigned';
                  } else {
                    // 1. Check persistent names from provider (Immediate resolution)
                    // 2. Check locally fetched names
                    // 3. Check parent provided names
                    final combined = [..._assignees, ...widget.allAssignees];
                    final assignee = combined.firstWhere(
                      (element) => element['id'] == id,
                      orElse: () =>
                          {'name': widget.initialAssigneeNames?[id] ?? id},
                    );
                    label = assignee['name'] ??
                        widget.initialAssigneeNames?[id] ??
                        id;
                  }

                  return Chip(
                    label: Text(
                      label,
                      style: TextStyle(
                        color: Theme.of(context).canvasColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    deleteIcon: Icon(Icons.close,
                        size: 18, color: Theme.of(context).canvasColor),
                    onDeleted: () {
                      setState(() {
                        _toggleSelection(_selectedAssigneeIds, id);
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSingleDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_selectedDateRange?.start ?? DateTime.now())
        : (_selectedDateRange?.end ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (_selectedDateRange == null) {
          _selectedDateRange = DateTimeRange(start: picked, end: picked);
        } else {
          if (isStart) {
            if (picked.isAfter(_selectedDateRange!.end)) {
              _selectedDateRange = DateTimeRange(start: picked, end: picked);
            } else {
              _selectedDateRange =
                  DateTimeRange(start: picked, end: _selectedDateRange!.end);
            }
          } else {
            if (picked.isBefore(_selectedDateRange!.start)) {
              _selectedDateRange = DateTimeRange(start: picked, end: picked);
            } else {
              _selectedDateRange =
                  DateTimeRange(start: _selectedDateRange!.start, end: picked);
            }
          }
        }
      });
    }
  }

  Widget _buildDateInputBox(String hint, DateTime? date, VoidCallback onTap) {
    String text = "";
    if (date != null) {
      text = "${date.day}/${date.month}/${date.year}";
    }
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).unselectedWidgetColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text.isEmpty ? hint : text,
          style: TextStyle(
            color: text.isEmpty
                ? Theme.of(context).disabledColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeFilterSection() {
    int diff = 0;
    String diffText = "";
    if (_selectedDateRange != null) {
      diff =
          _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays;
      diff = diff + 1;
      diffText = diff < 31
          ? "d"
          : diff < 365
              ? "m"
              : "y";
      switch (diffText) {
        case "d":
          diffText = diff == 1 ? "day" : "days";
          break;
        case "m":
          diff = (diff / 30).round();
          diffText = diff == 1 ? "month" : "months";
          break;
        case "y":
          diff = (diff / 365).round();
          diffText = diff == 1 ? "year" : "years";
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Theme.of(context).unselectedWidgetColor,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 120,
            child: Text(
              "Date Range",
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _buildDateInputBox("Start Date", _selectedDateRange?.start,
                    () => _pickSingleDate(context, true)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(" - ",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                _buildDateInputBox("End Date", _selectedDateRange?.end,
                    () => _pickSingleDate(context, false)),
                const SizedBox(width: 15),
                if (_selectedDateRange != null)
                  Text(
                    '$diff $diffText',
                    style: TextStyle(
                        color: Theme.of(context).unselectedWidgetColor),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberFilterSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Theme.of(context).unselectedWidgetColor,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 120,
            child: Text(
              "Complainee Phone Number",
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                hintText: "Enter phone number",
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.66,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Filter Tickets",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (!widget.isPublic) ...[
                      _buildFilterSection(
                          "Priority", _allPriorities, _selectedPriorities),
                      _buildFilterSection(
                          "Status", _allStatuses, _selectedStatuses),
                      _buildFilterSection("Complainee", widget.allComplainees,
                          _selectedComplaineeTypes),
                      _buildPhoneNumberFilterSection(),
                      _buildAssigneeFilterSection(),
                      _buildFilterSection(
                        "Asset Type",
                        widget.allAssetTypes,
                        _selectedAssetTypes,
                        labelMapper: getEntityLabel,
                        onSelectionChanged: (value) {
                          setState(() {
                            _selectedProblemTypes.clear();
                          });
                        },
                      ),
                    ],
                    if (widget.isPublic) _buildPhoneNumberFilterSection(),
                    Builder(
                      builder: (context) {
                        List<String> availableProblems = [];
                        List<String> availableAlarmProblems = [];
                        if (_selectedAssetTypes.isNotEmpty) {
                          for (var asset in _selectedAssetTypes) {
                            if (widget.assetToProblemsMap[asset] != null) {
                              availableProblems
                                  .addAll(widget.assetToProblemsMap[asset]!);
                              availableAlarmProblems.addAll(
                                  widget.assetToProblemsMap['auto_$asset']!);
                            }
                          }
                          availableProblems = availableProblems.toSet().toList()
                            ..sort();
                          availableAlarmProblems =
                              availableAlarmProblems.toSet().toList()..sort();
                        } else {
                          availableProblems = List.from(widget.allProblemTypes);
                        }
                        if (availableProblems.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _buildFilterSection("Problem Types",
                            availableProblems, _selectedProblemTypes,
                            alarmOptions: availableAlarmProblems);
                      },
                    ),
                    if (!widget.isPublic) _buildDateRangeFilterSection(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: Theme.of(context)
                            .unselectedWidgetColor
                            .withValues(alpha: 0.5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedPriorities.clear();
                        _selectedStatuses.clear();
                        if (!widget.isPublic) {
                          _selectedStatuses.addAll(['Open', 'Assigned']);
                          _selectedDateRange = DateTimeRange(
                            start:
                                DateTime.now().subtract(const Duration(days: 6)),
                            end: DateTime.now(),
                          );
                        } else {
                          _selectedDateRange = null;
                        }
                        _selectedComplaineeTypes.clear();
                        _selectedAssetTypes.clear();
                        _selectedProblemTypes.clear();
                        _selectedAssigneeIds.clear();
                        _phoneNumberController.clear();
                      });
                    },
                    child: Text(
                      "Reset",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Theme.of(context).secondaryHeaderColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final Map<String, String> assigneeNames = {};
                          for (var id in _selectedAssigneeIds) {
                            if (id == 'Unassigned') {
                              assigneeNames[id] = 'Unassigned';
                            } else {
                              final combined = [
                                ..._assignees,
                                ...widget.allAssignees
                              ];
                              final assignee = combined.firstWhere(
                                (element) => element['id'] == id,
                                orElse: () => {'name': id},
                              );
                              assigneeNames[id] = assignee['name'] ?? id;
                            }
                          }

                          widget.onApply(
                            _selectedPriorities,
                            _selectedStatuses,
                            _selectedComplaineeTypes,
                            _selectedAssetTypes,
                            _selectedProblemTypes,
                            _selectedAssigneeIds,
                            _phoneNumberController.text,
                            _selectedDateRange,
                            assigneeNames,
                          );
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Theme.of(context).canvasColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Update"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
