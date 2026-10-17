import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:citizen_complaints_list_web/s3_bucket/s3_config.dart';
import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:citizen_complaints_list_web/screens/Ticket_Creation/new_ticket_service.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:citizen_complaints_list_web/screens/Tickets_List/project_context_controller.dart';

import 'package:citizen_complaints_list_web/screens/Tickets_List/tickets_filter_controller.dart';
import 'package:citizen_complaints_list_web/utils/export_csv.dart';
import 'package:citizen_complaints_list_web/ticket_live_listener.dart';

final ticketsListController =
    ChangeNotifierProvider<TicketsListProvider>((ref) {
  // Only rebuild when customerId or region changes — zone/ward are filtered
  // in-memory inside fetchTickets(), so they don't need a new SSE watcher.
  final customerId = ref.watch(
    userContextController.select((u) => u.selectedCustomerId),
  );
  final customer = ref.watch(
    userContextController.select((u) => u.selectedCustomer),
  );
  final region = ref.watch(
    userContextController.select((u) => u.selectedRegion),
  );

  // Zone & ward are read (not watched) so they don't trigger a rebuild.
  final userContext = ref.read(userContextController);
  final filterProvider = ref.read(ticketsFilterProvider);

  return TicketsListProvider(
    customerId: customerId,
    customer: customer,
    region: region,
    zone: userContext.selectedZone,
    ward: userContext.selectedWard,
    filterProvider: filterProvider,
    userContextProvider: userContext,
  );
});

final List<String> complaineeList = [
  'O&M (CMS)',
  'Public',
  'Councillor',
  'Officials',
  'Serviceman',
];

Map<String, dynamic> entityList = {
  "lamp": {
    'label': "Lamp",
    "device": ["lamp"],
    "type": "asset",
    // "problem_type": [
    //   "Not burning",
    //   "Flickering",
    //   "Day time burning",
    //   "No Load",
    //   "Meter Comm. Failure",
    //   "Relay Failure",
    //   "Not communicating",
    //   "Input Power unavailable",
    //   "RF Signal Rank Poor",
    //   "4G network poor",
    //   "Others"
    // ]
  },
  "slc": {
    'label': "SLC Panel",
    "device": ["ccms", "smslc"],
    "type": "asset",
    // "problem_type": [
    //   "Low Voltage",
    //   "High Voltage",
    //   "High Current / Power Theft",
    //   "MCB Trip",
    //   "Power Failure",
    //   "Relay Failure",
    //   "Meter Comm. Failure",
    //   "Lamps not burning",
    //   "Day time burning",
    //   "Timing issue",
    //   "No Communication / Offline",
    //   "Preventive Maintenance",
    //   "RF Signal Rank Poor",
    //   "4G network poor",
    //   "Input Cable Damaged",
    //   "Load always ON",
    //   "Bypass",
    //   "Others"
    // ]
  },
  'gw': {
    'label': "Controller (GW/SEMC)",
    "device": ["gw", "semc"],
    "type": "device",
    // "problem_type": [
    //   "Not communicating",
    //   "Input Power unavailable / Power  Failure",
    //   "RF Signal Rank Poor",
    //   "4G network poor",
    //   "Others"
    // ]
  },
  'ilm': {
    'label': "ILM",
    "device": ["ilm", "ilm-4g"],
    "type": "device",
    // "problem_type": [
    //   "Not burning",
    //   "Flickering",
    //   "Day time burning",
    //   "No Load",
    //   "Meter Comm. Failure",
    //   "Relay Failure",
    //   "Not communicating",
    //   "Input Power unavailable",
    //   "RF Signal Rank Poor",
    //   "4G network poor",
    //   "Others"
    // ]
  },
  "pole": {
    'label': "Pole",
    "device": ["pole"],
    "type": "asset",
    // "problem_type": ["Pole damaged", "Others"]
  },
  "others": {
    'label': "Others",
    "device": ["others"],
    "type": "Others",
    // "problem_type": ["Others"]
  }
};

String getEntityLabel(String? key) {
  if (key == null || key.isEmpty) return '';
  return entityList[key]?['label'] ?? key;
}

List<String> deviceTypeList = entityList.keys.toList()..sort();

class TicketsListProvider extends ChangeNotifier {
  int _sortColumnIndex = 6;
  bool _isAscending = false;
  bool _disposed = false;

  int _pageSize = 10;
  List<DocumentSnapshotProxy> _tickets = [];
  List<Map<String, dynamic>> _allFilteredDocs = [];
  bool _isLoading = true;
  bool _hasMore = true;

  int _currentPageIndex = 0;
  int _targetPageIndex = 0;
  bool _isFetchingQueue = false;
  int _totalTickets = 0;
  int get totalCount => _totalTickets;

  final String customer;
  final String customerId;
  final String region;
  String
      zone; // mutable — updated when user changes zone without rebuilding provider
  String
      ward; // mutable — updated when user changes ward without rebuilding provider
  final TicketsFilterProvider filterProvider;
  final UserContextProvider userContextProvider;

  static List<Map<String, dynamic>> _cachedPublicDocs = [];
  static int _cachedPublicCount = 0;

  PeriodicTicketWatcher? _ticketWatcher;
  StreamSubscription<List<Ticket>>? _liveSubscription;
  List<Map<String, dynamic>> _firestoreDocs = [];
  List<Map<String, dynamic>> _publicDocs = List.from(_cachedPublicDocs);
  List<Map<String, dynamic>> _customerDocs = [];
  DateTimeRange? _lastSubscriptionDateRange;

  int get publicTicketCount =>
      _publicDocs.isNotEmpty ? _publicDocs.length : _cachedPublicCount;

  TicketsListProvider({
    required this.customer,
    required this.customerId,
    required this.region,
    required this.zone,
    required this.ward,
    required this.filterProvider,
    required this.userContextProvider,
  }) {
    // Call setContext synchronously so the date range is already correct
    // when _setupFirestoreListener() runs below — avoids a double-setup race.
    filterProvider.setContext(customer: customer, region: region);
    _initializeStaticData(); // intentionally unawaited; fills async, safe to proceed
    filterProvider.addListener(_onFilterChanged);
    userContextProvider.addListener(_onUserContextChanged);

    if ((customer.isNotEmpty && region.isNotEmpty) || isPublic) {
      _setupFirestoreListener();
      if (!isPublic) _fetchAssignees();
    } else {
      _isLoading = false;
    }
  }

  bool _showPublicOnly = false;
  bool get isPublic => _showPublicOnly;
  bool _isTogglingPublic = false;

  bool _isSameDateRange(DateTimeRange? a, DateTimeRange? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.start.year == b.start.year &&
        a.start.month == b.start.month &&
        a.start.day == b.start.day &&
        a.end.year == b.end.year &&
        a.end.month == b.end.month &&
        a.end.day == b.end.day;
  }

  void togglePublic() {
    _targetPageIndex = 0;
    _showPublicOnly = !_showPublicOnly;
    _firestoreDocs = isPublic ? _publicDocs : _customerDocs;
    _isAscending = false;
    _sortColumnIndex = 6;
    _searchQuery = '';

    _isTogglingPublic = true;
    try {
      if (isPublic) {
        filterProvider.resetForPublic();
      } else {
        filterProvider.resetForProject(
            defaultDateRange: _lastSubscriptionDateRange);
      }
    } finally {
      _isTogglingPublic = false;
    }

    fetchTickets(notify: true);
  }

  void _onUserContextChanged() {
    if (_disposed) return;
    final newZone = userContextProvider.selectedZone;
    final newWard = userContextProvider.selectedWard;
    if (newZone != zone || newWard != ward) {
      zone = newZone;
      ward = newWard;
      _targetPageIndex = 0;
      _currentPageIndex = 0;
      fetchTickets(notify: true);
    }
  }

  void _onFilterChanged() {
    if (_disposed || _isTogglingPublic) return;
    if (!isPublic &&
        !_isSameDateRange(
            _lastSubscriptionDateRange, filterProvider.selectedDateRange)) {
      _setupFirestoreListener();
    } else {
      fetchTickets(notify: true);
    }
  }

  void _setupFirestoreListener() {
    _liveSubscription?.cancel();
    _ticketWatcher?.dispose();
    _ticketWatcher = null;
    _lastSubscriptionDateRange = filterProvider.selectedDateRange;
    _isLoading = true;
    _firestoreDocs = [];
    _publicDocs = List.from(_cachedPublicDocs);
    _customerDocs = [];
    Future.microtask(() => notifyListeners());

    if (filterProvider.selectedDateRange == null) {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return;
    }

    final start = filterProvider.selectedDateRange!.start;
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} 00:00:00';

    final end = filterProvider.selectedDateRange!.end;
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')} 23:59:59';

    _ticketWatcher = PeriodicTicketWatcher(
        customerId: customerId, region: region, start: startStr, end: endStr);

    _liveSubscription = _ticketWatcher!.stream.listen((tickets) {
      if (_disposed) return;
      final docs = tickets.map((t) => t.data).toList();
      _publicDocs = docs.where((doc) => doc['customer'] == 'Public').toList();
      _cachedPublicDocs = List.from(_publicDocs);
      _cachedPublicCount = _publicDocs.length;
      _customerDocs = docs.where((doc) => doc['customer'] != 'Public').toList();
      _firestoreDocs = isPublic ? _publicDocs : _customerDocs;
      fetchTickets(notify: true, showLoading: false);
    }, onError: (error) {
      debugPrint("Live Listener Error: $error");
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void onSort(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _isAscending = ascending;
    fetchTickets();
  }

  Future<void> setPageSize(int size) async {
    if (size < 1) {
      size = 1;
    } else if (size > 30) {
      // size = 30;
    }
    _pageSize = size;

    _pageSize = size;

    _currentPageIndex = 0;
    _targetPageIndex = 0;
    _tickets = [];
    _isLoading = true;
    if (!_disposed) notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));

    await fetchTickets(notify: false);
    if (!_disposed) notifyListeners();
  }

  Future<void> applyFilters(
    List<String> priorities,
    List<String> statuses,
    List<String> complaineeTypes,
    List<String> assetTypes,
    List<String> problemTypes,
    List<String> assigneeIds,
    String searchPhoneNumber,
    DateTimeRange? dateRange, {
    Map<String, String>? assigneeNames,
  }) async {
    // Check for changes against the persistent provider
    if (listEquals(List.from(filterProvider.selectedPriorities)..sort(),
            List.from(priorities)..sort()) &&
        listEquals(List.from(filterProvider.selectedStatuses)..sort(),
            List.from(statuses)..sort()) &&
        listEquals(List.from(filterProvider.selectedComplaineeTypes)..sort(),
            List.from(complaineeTypes)..sort()) &&
        listEquals(List.from(filterProvider.selectedAssetTypes)..sort(),
            List.from(assetTypes)..sort()) &&
        listEquals(List.from(filterProvider.selectedProblemTypes)..sort(),
            List.from(problemTypes)..sort()) &&
        listEquals(List.from(filterProvider.selectedAssigneeIds)..sort(),
            List.from(assigneeIds)..sort()) &&
        filterProvider.searchPhoneNumber == searchPhoneNumber &&
        filterProvider.selectedDateRange == dateRange &&
        (assigneeNames == null ||
            mapEquals(filterProvider.assigneeNames, assigneeNames))) {
      return;
    }
    _currentPageIndex = 0;
    _targetPageIndex = 0;
    fetchTickets();

    // Update persistent state.
    // This will notify listeners of ticketsFilterProvider.
    // ticketsListController watches ticketsFilterProvider, so it will rebuild.
    // The new instance of TicketsListProvider will call fetchTickets() in its constructor.
    filterProvider.updateFilters(
      priorities: priorities,
      statuses: statuses,
      complaineeTypes: complaineeTypes,
      assetTypes: assetTypes,
      problemTypes: problemTypes,
      assigneeIds: assigneeIds,
      searchPhoneNumber: searchPhoneNumber,
      dateRange: dateRange,
      assigneeNames: assigneeNames,
    );
  }

  Future<void> fetchTickets(
      {bool notify = true, bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
    }
    if (!isPublic && region.isEmpty) {
      _isLoading = false;
      if (notify && !_disposed) notifyListeners();
      return;
    }

    try {
      List<Map<String, dynamic>> fetchedDocs = [];

      for (var doc in _firestoreDocs) {
        // App-level filtering based on UserContext selections (region, zone, ward) - bypassed for public tickets
        if (isPublic ||
            // ((region.isEmpty || doc['region'] == region) &&
            ((zone.isEmpty || doc['zone'] == zone) &&
                (ward.isEmpty || doc['ward'] == ward))) {
          fetchedDocs.add(doc);
        }
      }

      // 1. STATUS
      if (filterProvider.selectedStatuses.isNotEmpty) {
        fetchedDocs = fetchedDocs
            .where((doc) =>
                filterProvider.selectedStatuses.contains(doc['status']))
            .toList();
      }

      // 2. PRIORITY
      if (filterProvider.selectedPriorities.isNotEmpty) {
        fetchedDocs = fetchedDocs
            .where((doc) =>
                filterProvider.selectedPriorities.contains(doc['priority']))
            .toList();
      }

      // 3. COMPLAINEE TYPE
      if (filterProvider.selectedComplaineeTypes.isNotEmpty) {
        fetchedDocs = fetchedDocs
            .where((doc) => filterProvider.selectedComplaineeTypes
                .contains(doc['complainee']))
            .toList();
      }

      // 3.5. PHONE NUMBER SEARCH
      if (filterProvider.searchPhoneNumber.isNotEmpty) {
        final phoneQuery = filterProvider.searchPhoneNumber.toLowerCase();
        fetchedDocs = fetchedDocs.where((doc) {
          final contactNo =
              (doc['complainee_contact_no'] ?? '').toString().toLowerCase();
          return contactNo.contains(phoneQuery);
        }).toList();
      }

      // 4. ASSET TYPE
      if (filterProvider.selectedAssetTypes.isNotEmpty) {
        fetchedDocs = fetchedDocs
            .where((doc) =>
                filterProvider.selectedAssetTypes.contains(doc['entity_type']))
            .toList();
      }

      // 5. PROBLEM TYPE
      if (filterProvider.selectedProblemTypes.isNotEmpty) {
        fetchedDocs = fetchedDocs
            .where((doc) => filterProvider.selectedProblemTypes
                .contains(doc['problem_type']))
            .toList();
      }

      // 6. ASSIGNEE
      if (filterProvider.selectedAssigneeIds.isNotEmpty) {
        fetchedDocs = fetchedDocs.where((doc) {
          final docAssigneeId = doc['assignee_id'] as String? ?? '';
          if (filterProvider.selectedAssigneeIds.contains("Unassigned") &&
              (docAssigneeId.isEmpty || doc['assignee'] == 'Unassigned')) {
            return true;
          }
          return filterProvider.selectedAssigneeIds.contains(docAssigneeId);
        }).toList();
      }

      // 7. DATE RANGE
      if (filterProvider.selectedDateRange != null) {
        final start = filterProvider.selectedDateRange!.start;
        final startStr = '${start.year}-'
            '${start.month.toString().padLeft(2, '0')}-'
            '${start.day.toString().padLeft(2, '0')} '
            '00:00:00';

        final end = filterProvider.selectedDateRange!.end;
        final endStr = '${end.year}-'
            '${end.month.toString().padLeft(2, '0')}-'
            '${end.day.toString().padLeft(2, '0')} '
            '23:59:59';

        fetchedDocs = fetchedDocs.where((doc) {
          final t = doc['ticket_opened_on'] as String? ?? '';
          return t.compareTo(startStr) >= 0 && t.compareTo(endStr) <= 0;
        }).toList();
      }

      // 8. SEARCH — applied last so it narrows the already-filtered set.
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        // fetchedDocs = fetchedDocs.where((doc) {
        //   final Map<String, dynamic> filteredData = Map.from(doc);
        //   filteredData.remove('audit_trail');
        //   final jsonString = filteredData.values.join(' ').toLowerCase();
        //   return jsonString.contains(query);
        // }).toList();
        if (isPublic) {
          fetchedDocs = fetchedDocs
              .where((doc) =>
                  '${doc['ticket_id']} ${doc['customer']} ${doc['region']} ${doc['entity_name']} ${doc['complainee']} ${doc['problem_type']} ${doc['ticket_opened_by']} ${doc['comments']} ${doc['status']} ${doc['complainee_contact_no']}'
                      .toLowerCase()
                      .contains(query))
              .toList();
        } else {
          fetchedDocs = fetchedDocs
              .where((doc) =>
                  '${doc['ticket_id']} ${doc['customer']} ${doc['region']} ${doc['zone']} ${doc['ward']} ${doc['entity_name']} ${doc['entity_type']} ${doc['complainee']} ${doc['problem_type']} ${doc['ticket_opened_by']} ${doc['ticket_closed_by']} ${doc['comments']} ${doc['priority']} ${doc['status']} ${doc['assignee']} ${doc['issue_identified']}'
                      .toLowerCase()
                      .contains(query))
              .toList();
        }
      }

      // Update total count after all filtering
      _totalTickets = fetchedDocs.length;

      // Global sorting
      fetchedDocs.sort((aMap, bMap) {
        int result = 0;

        String getField(Map<String, dynamic> map, int index) {
          switch (index) {
            case 0:
              return (map['ticket_id'] ?? '').toString();
            case 1:
              return (map['complainee'] ?? '').toString();
            case 2:
              return (map['entity_name'] ?? '').toString();
            case 3:
              return (map['problem_type'] ?? '').toString();
            case 4:
              return (map['priority'] ?? '').toString();
            case 5:
              return (map['status'] ?? '').toString();
            case 6:
              return (map['ticket_opened_on'] ?? '').toString();
            case 7:
              return isPublic
                  ? (map['complainee_contact_no'] ?? '').toString()
                  : (map['assignee'] ?? '').toString();
            case 8:
              return isPublic
                  ? (map['duration'] ?? '').toString()
                  : (map['ticket_closed_on'] ?? '').toString();
            case 9:
              return isPublic
                  ? (map['comments'] ?? '').toString()
                  : (map['duration'] ?? '').toString();
            case 10:
              return (map['comments'] ?? '').toString();
            case 11:
              return (map['zone'] ?? '').toString();
            case 12:
              return (map['ward'] ?? '').toString();
            default:
              return '';
          }
        }

        String aValue = getField(aMap, _sortColumnIndex);
        String bValue = getField(bMap, _sortColumnIndex);
        result = aValue.compareTo(bValue);

        return _isAscending ? result : -result;
      });

      // Pagination
      int start = _targetPageIndex * _pageSize;
      int end = start + _pageSize;

      List<Map<String, dynamic>> pageDocs = [];
      if (start < fetchedDocs.length) {
        pageDocs = fetchedDocs.sublist(
            start, end > fetchedDocs.length ? fetchedDocs.length : end);
      }

      _allFilteredDocs = fetchedDocs;

      _hasMore = end < fetchedDocs.length;

      // Convert to our Proxy object for UI compatibility
      _tickets = pageDocs
          .map((doc) => DocumentSnapshotProxy(
              doc['_firestore_id'] ?? doc['id'] ?? '', doc))
          .toList();
      _currentPageIndex = _targetPageIndex;

      // We already sorted all documents above, no need for _sortLocalTickets()
    } catch (e) {
      debugPrint("Error fetching tickets locally: $e");
      _hasMore = false;
    }

    _isLoading = false;
    if (notify && !_disposed) notifyListeners();
  }

  void nextPage() {
    if (_targetPageIndex < totalPages - 1 || (_hasMore && totalPages == 0)) {
      _targetPageIndex++;
      if (!_disposed) notifyListeners();
      _processPageQueue();
    }
  }

  Future<void> exportToCsv() async {
    if (_allFilteredDocs.isEmpty) return;

    List<List<dynamic>> rows = [
      [
        "Ticket No",
        "Region",
        "Zone",
        "Ward",
        "Complainee",
        "Device/Asset Type",
        "Device/Asset Name",
        "Problem Type",
        "Status",
        "Priority",
        "Assignee",
        "Opened Time",
        "Closed Time",
        "Duration (Days)",
        "Location",
        "Latest Comments",
        "Complainee Phone Number",
      ]
    ];

    for (var doc in _allFilteredDocs) {
      rows.add([
        doc['ticket_id'] ?? '',
        doc['region'] ?? '',
        doc['zone'] ?? '',
        doc['ward'] ?? '',
        doc['complainee'] ?? '',
        getEntityLabel(doc['entity_type']?.toString()),
        doc['entity_name'] ?? '',
        doc['problem_type'] ?? '',
        doc['status'] ?? '',
        doc['priority'] ?? '',
        doc['assignee'] ?? '',
        doc['ticket_opened_on'] ?? '',
        doc['ticket_closed_on'] ?? '',
        '${getDaysDifference(doc['ticket_opened_on'], doc['ticket_closed_on'])}',
        doc['location'] ?? '',
        doc['comments'] ?? '',
        doc['complainee_contact_no'] ?? '',
      ]);
    }

    String name = '';
    if (isPublic) {
      name = "Public";
    } else {
      name = ward.isNotEmpty ? ward : (zone.isNotEmpty ? zone : region);
      if (name.isEmpty) {
        name = "Tickets";
      }
    }
    String fileName =
        '${name}_${getCurrentFormattedDateTime().replaceAll(":", "").replaceAll(" ", "_").replaceAll("-", "")}.csv';

    await exportCsv(rows, fileName);
  }

  void previousPage() {
    if (_targetPageIndex > 0) {
      _targetPageIndex--;
      if (!_disposed) notifyListeners();
      _processPageQueue();
    }
  }

  void jumpToPage(int page) {
    if (page < 1) page = 1;
    if (totalPages > 0 && page > totalPages) page = totalPages;

    // Convert to 0-index
    final newIndex = page - 1;

    if (newIndex != _targetPageIndex) {
      _targetPageIndex = newIndex;
      if (!_disposed) notifyListeners();
      _processPageQueue();
    }
  }

  Future<void> _processPageQueue() async {
    if (_isFetchingQueue) return;
    _isFetchingQueue = true;
    if (!_disposed) notifyListeners();

    try {
      while (_currentPageIndex != _targetPageIndex) {
        if (_targetPageIndex > _currentPageIndex) {
          if (_hasMore) {
            _currentPageIndex++;
            await fetchTickets(notify: false);
          } else {
            _targetPageIndex = _currentPageIndex;
            break;
          }
        } else {
          if (_currentPageIndex > 0) {
            _currentPageIndex--;
            await fetchTickets(notify: false);
          } else {
            _targetPageIndex = _currentPageIndex;
            break;
          }
        }
      }
    } finally {
      _isFetchingQueue = false;
      if (!_disposed) notifyListeners();
    }
  }

  void refresh() {
    // Preserves existing categorical filters, but clears the date range
    // matching the previous behavior of refresh().
    filterProvider.updateFilters(
      priorities: filterProvider.selectedPriorities,
      statuses: filterProvider.selectedStatuses,
      complaineeTypes: filterProvider.selectedComplaineeTypes,
      assetTypes: filterProvider.selectedAssetTypes,
      problemTypes: filterProvider.selectedProblemTypes,
      assigneeIds: filterProvider.selectedAssigneeIds,
      searchPhoneNumber: '',
      dateRange: null,
    );
  }

  void reload() {
    fetchTickets();
  }

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _targetPageIndex = 0;
    _currentPageIndex = 0;
    fetchTickets();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    _targetPageIndex = 0;
    _currentPageIndex = 0;
    fetchTickets();
  }

  // Removed _sortLocalTickets as sorting is now handled within fetchTickets

  List<String> get _selectedStatuses => filterProvider.selectedStatuses;
  List<String> get _selectedPriorities => filterProvider.selectedPriorities;
  List<String> get _selectedComplaineeTypes =>
      filterProvider.selectedComplaineeTypes;
  List<String> get _selectedAssetTypes => filterProvider.selectedAssetTypes;
  List<String> get _selectedProblemTypes => filterProvider.selectedProblemTypes;
  List<String> get _selectedAssigneeIds => filterProvider.selectedAssigneeIds;
  String get _selectedSearchPhoneNumber => filterProvider.searchPhoneNumber;
  DateTimeRange? get _selectedDateRange => filterProvider.selectedDateRange;

  // Options
  List<Map<String, String>> _allAssigneesData = [];

  List<String> _allAssetTypes = [];
  List<String> _allProblemTypes = [];
  Map<String, List<String>> _assetToProblemsMap = {};

  int get sortColumnIndex => _sortColumnIndex;
  bool get isAscending => _isAscending;
  int get pageSize => _pageSize;

  List<DocumentSnapshotProxy> get tickets => _tickets;

  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  // UI usage: shows Target (Optimistic)
  int get currentPage => _targetPageIndex + 1;
  int get totalPages => (_totalTickets / _pageSize).ceil();
  // Helper to know if UI is ahead of Data
  bool get isSyncing => _targetPageIndex != _currentPageIndex;

  List<String> get selectedStatuses => _selectedStatuses;
  List<String> get selectedPriorities => _selectedPriorities;
  List<String> get selectedComplaineeTypes => _selectedComplaineeTypes;
  List<String> get selectedAssetTypes => _selectedAssetTypes;
  List<String> get selectedProblemTypes => _selectedProblemTypes;
  List<String> get selectedAssigneeIds => _selectedAssigneeIds;
  String get selectedPhoneNumber => _selectedSearchPhoneNumber;
  DateTimeRange? get selectedDateRange => _selectedDateRange;

  List<String> get allAssignees =>
      _allAssigneesData.map((e) => e['name']!).toList();
  List<Map<String, String>> get allAssigneesData => _allAssigneesData;
  List<String> get allAssetTypes => _allAssetTypes;
  List<String> get allProblemTypes => _allProblemTypes;
  Map<String, List<String>> get assetToProblemsMap => _assetToProblemsMap;

  @override
  void dispose() {
    _disposed = true;
    filterProvider.removeListener(_onFilterChanged);
    userContextProvider.removeListener(_onUserContextChanged);
    _liveSubscription?.cancel();
    _ticketWatcher?.dispose();
    _ticketWatcher = null;
    super.dispose();
  }

  Future<void> _initializeStaticData() async {
    try {
      if (!Hive.isBoxOpen('problemTypesAndIssuesIdentified')) {
        await Hive.openBox('problemTypesAndIssuesIdentified');
      }
      final probIssueBox = Hive.box('problemTypesAndIssuesIdentified');

      _allAssetTypes = entityList.keys.toList()..sort();
      _assetToProblemsMap = {};
      entityList.forEach((key, _) {
        _assetToProblemsMap[key] = List<String>.from(
          probIssueBox.get('problem_types')?[key] ?? [],
        );
        _assetToProblemsMap['auto_$key'] = List<String>.from(
          probIssueBox.get('problem_types')?['auto_$key'] ?? [],
        );
      });
      List<String> generalProblemTypes = List<String>.from(
        probIssueBox.get('problem_types')?['general'] ?? [],
      );
      _allProblemTypes = generalProblemTypes;
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('Error initializing static data: $e');
    }
  }

  Future<void> _fetchAssignees() async {
    if (region.isEmpty) {
      _allAssigneesData = [];
      if (!_disposed) notifyListeners();
      return;
    }
    try {
      final regionId = await _getRegionId();
      if (_disposed) return;

      if (regionId.isNotEmpty) {
        _allAssigneesData = await fetchAssigneesByRegionService(regionId);
      }
    } catch (e) {
      debugPrint('Error fetching assignees: $e');
      _allAssigneesData = [];
    }
    if (!_disposed) notifyListeners();
  }

  Future<List<Map<String, String>>> fetchAssigneesForDialog() async {
    String regionId = await _getRegionId();
    if (regionId.isNotEmpty) {
      return await fetchAssigneesByRegionService(regionId);
    }
    return [];
  }

  Future<String> _getRegionId() async {
    try {
      if (!Hive.isBoxOpen('project_context')) {
        await Hive.openBox('project_context');
      }
      final box = Hive.box('project_context');

      final userContextMap = box.get(userEmail);
      final data = userContextMap?[customer];
      if (data != null && data['regions'][region] != null) {
        return data['regions'][region]['region_id'] ?? '';
      }
    } catch (e) {
      return '';
    }
    return '';
  }
}

class DocumentSnapshotProxy {
  final String id;
  final Map<String, dynamic> _data;
  DocumentSnapshotProxy(this.id, this._data);

  Map<String, dynamic> data() => _data;
  dynamic operator [](String key) => _data[key];
}

int getDaysDifference(dynamic openedOn, dynamic closedOn) {
  if (openedOn == null || openedOn.toString().trim().isEmpty) {
    return 0;
  }
  if (closedOn == null || closedOn.toString().trim().isEmpty) {
    closedOn = DateTime.now();
  }

  try {
    final opened = DateTime.parse(openedOn.toString());
    final closed = DateTime.parse(closedOn.toString());
    return closed.difference(opened).inDays;
  } catch (_) {
    return 0;
  }
}

Future<void> launchAttachment(String fileName) async {
  if (fileName.isEmpty) return;
  try {
    final url = '${S3Config.s3Endpoint}/$fileName';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $url');
    }
  } catch (e) {
    debugPrint('Error launching URL: $e');
  }
}

// final List<String> generalProblemTypes = [
//   'Day time burning',
//   'Lamps not burning',
//   'Flickering',
//   'Panel damaged',
//   'Panel door opened',
//   'Pole damaged',
//   'Web Application Down',
//   'Others'
// ];
