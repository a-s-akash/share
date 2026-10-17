import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ticketsFilterProvider =
    ChangeNotifierProvider<TicketsFilterProvider>((ref) {
  return TicketsFilterProvider();
});

class TicketsFilterProvider extends ChangeNotifier {
  List<String> _selectedStatuses = ['Open', 'Assigned'];
  List<String> _selectedPriorities = []; // Empty means 'All'
  List<String> _selectedComplaineeTypes = [];
  List<String> _selectedAssetTypes = [];
  List<String> _selectedProblemTypes = [];
  List<String> _selectedAssigneeIds = [];
  String _searchPhoneNumber = '';
  DateTimeRange? _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  String? _lastCustomerContext;
  String? _lastRegionContext;
  Map<String, String> _assigneeNames = {};

  List<String> get selectedStatuses => _selectedStatuses;
  List<String> get selectedPriorities => _selectedPriorities;
  List<String> get selectedComplaineeTypes => _selectedComplaineeTypes;
  List<String> get selectedAssetTypes => _selectedAssetTypes;
  List<String> get selectedProblemTypes => _selectedProblemTypes;
  List<String> get selectedAssigneeIds => _selectedAssigneeIds;
  String get searchPhoneNumber => _searchPhoneNumber;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  Map<String, String> get assigneeNames => _assigneeNames;

  void setContext({required String customer, required String region}) {
    bool isPublic = customer == 'Public';
    bool wasPublic = _lastCustomerContext == 'Public';

    bool customerChanged =
        _lastCustomerContext != null && customer != _lastCustomerContext;
    bool regionChanged =
        _lastRegionContext != null && region != _lastRegionContext;

    bool hasChanged = false;

    // Reset Assignee filtering if customer or region changed
    if (customerChanged || regionChanged) {
      _selectedAssigneeIds = [];
      _assigneeNames = {};
      hasChanged = true;
    }

    // Reset date range to 7 days when customer changes
    if (customerChanged) {
      _selectedDateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 6)),
        end: DateTime.now(),
      );
      hasChanged = true;
    }

    // If it's the first time, or if we cross the boundary between Public and Project
    if (_lastCustomerContext == null || isPublic != wasPublic) {
      hasChanged = true;
      if (isPublic) {
        // Reset ALL for Public Context (Full reset for clarity)
        _selectedStatuses = [];
        _selectedPriorities = [];
        _selectedComplaineeTypes = [];
        _selectedAssetTypes = [];
        _selectedProblemTypes = [];
        _selectedAssigneeIds = [];
        _searchPhoneNumber = '';
        _assigneeNames = {};
        _selectedDateRange = null;
      } else {
        // Reset for Project Context
        _selectedStatuses = ['Open', 'Assigned'];
        _selectedPriorities = [];
        _selectedComplaineeTypes = [];
        _selectedAssetTypes = [];
        _selectedProblemTypes = [];
        _selectedAssigneeIds = [];
        _searchPhoneNumber = '';
        _assigneeNames = {};
        _selectedDateRange = DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 6)),
          end: DateTime.now(),
        );
      }
    }

    _lastCustomerContext = customer;
    _lastRegionContext = region;

    if (hasChanged) {
      notifyListeners();
    }
  }

  void resetForPublic() {
    _selectedStatuses = [];
    _selectedPriorities = [];
    _selectedComplaineeTypes = [];
    _selectedAssetTypes = [];
    _selectedProblemTypes = [];
    _selectedAssigneeIds = [];
    _searchPhoneNumber = '';
    _assigneeNames = {};
    _selectedDateRange = null;
    notifyListeners();
  }

  void resetForProject({DateTimeRange? defaultDateRange}) {
    _selectedStatuses = ['Open', 'Assigned'];
    _selectedPriorities = [];
    _selectedComplaineeTypes = [];
    _selectedAssetTypes = [];
    _selectedProblemTypes = [];
    _selectedAssigneeIds = [];
    _searchPhoneNumber = '';
    _assigneeNames = {};
    _selectedDateRange = defaultDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 6)),
          end: DateTime.now(),
        );
    notifyListeners();
  }

  void updateFilters({
    required List<String> priorities,
    required List<String> statuses,
    required List<String> complaineeTypes,
    required List<String> assetTypes,
    required List<String> problemTypes,
    required List<String> assigneeIds,
    required String searchPhoneNumber,
    required DateTimeRange? dateRange,
    Map<String, String>? assigneeNames,
  }) {
    _selectedPriorities = priorities;
    _selectedStatuses = statuses;
    _selectedComplaineeTypes = complaineeTypes;
    _selectedAssetTypes = assetTypes;
    _selectedProblemTypes = problemTypes;
    _selectedAssigneeIds = assigneeIds;
    _searchPhoneNumber = searchPhoneNumber;
    _selectedDateRange = dateRange;
    if (assigneeNames != null) {
      _assigneeNames = assigneeNames;
    }
    notifyListeners();
  }
}
