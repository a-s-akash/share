import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final userContextController =
    ChangeNotifierProvider<UserContextProvider>((ref) {
  return UserContextProvider();
});

class UserContextProvider extends ChangeNotifier {
  List<String> _customers = [];
  List<String> _regions = [];
  List<String> _zones = [];
  List<String> _wards = [];

  String _selectedCustomer = '';
  String _selectedCustomerId = '';
  String _selectedRegion = '';
  String _selectedZone = '';
  String _selectedWard = '';

  Map<String, dynamic> _data = {};

  UserContextProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (!Hive.isBoxOpen('project_context')) {
      await Hive.openBox('project_context');
    }
    if (!Hive.isBoxOpen('project_context_selection')) {
      await Hive.openBox('project_context_selection');
    }
    final box = Hive.box('project_context');
    box.listenable().addListener(_loadFromHive);
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = Hive.box('project_context');
    final userContext = box.get(userEmail);

    if (userContext == null) return;
    isDashboardPreparingNotifier.value = false;

    // Capture old state for comparison
    final oldSelectedCustomer = _selectedCustomer;
    final oldSelectedRegion = _selectedRegion;
    final oldSelectedZone = _selectedZone;
    final oldSelectedWard = _selectedWard;
    final oldRegions = List<String>.from(_regions);
    final oldZones = List<String>.from(_zones);
    final oldWards = List<String>.from(_wards);

    _data = Map<String, dynamic>.from(userContext as Map);
    _customers = _data.keys.cast<String>().toList()..sort();

    // Load saved selections from Hive
    if (_selectedCustomer.isEmpty && Hive.isBoxOpen('project_context_selection')) {
      final selectionBox = Hive.box('project_context_selection');
      final savedSelection = selectionBox.get(userEmail);
      if (savedSelection is Map) {
        final map = Map<String, dynamic>.from(savedSelection);
        final savedCustomer = map['customer'] ?? '';
        if (_customers.contains(savedCustomer)) {
          _selectedCustomer = savedCustomer;
          _selectedCustomerId = map['customer_id'] ?? '';
          _selectedRegion = map['region'] ?? '';
          _selectedZone = map['zone'] ?? '';
          _selectedWard = map['ward'] ?? '';
        }
      }
    }

    // Default Selection Logic
    if (_selectedCustomer.isNotEmpty &&
        !_customers.contains(_selectedCustomer)) {
      _selectedCustomer = '';
      _selectedCustomerId = '';
    }

    if (_selectedCustomer.isEmpty && _customers.isNotEmpty) {
      _selectedCustomer = _customers.first;
      _selectedCustomerId = _data[_selectedCustomer]['customer_id'];
      _updateRegions(selectFirst: true);
    } else {
      _updateRegions(selectFirst: _selectedRegion.isEmpty);
    }

    // Check for changes
    bool hasChanged = _selectedCustomer != oldSelectedCustomer ||
        _selectedRegion != oldSelectedRegion ||
        _selectedZone != oldSelectedZone ||
        _selectedWard != oldSelectedWard ||
        !listEquals(_regions, oldRegions) ||
        !listEquals(_zones, oldZones) ||
        !listEquals(_wards, oldWards);

    if (hasChanged) {
      notifyListeners();
    }
  }

  void selectCustomer(String? customer) {
    if (customer == null || customer == _selectedCustomer) return;
    _selectedCustomer = customer;
    _selectedCustomerId = _data[_selectedCustomer]['customer_id'];
    _resetRegion();
    _updateRegions(selectFirst: true);
    _saveSelectionToHive();
    notifyListeners();
  }

  void selectRegion(String? region) {
    if (region == _selectedRegion) {
      if (_selectedZone.isNotEmpty) {
        _selectedZone = '';
        _selectedWard = '';
        _saveSelectionToHive();
        notifyListeners();
      }
      return;
    }
    _selectedRegion = region ?? '';
    _resetZone();
    _updateZones();
    _saveSelectionToHive();
    notifyListeners();
  }

  void selectZone(String? zone) {
    if (zone == _selectedZone) {
      if (_selectedWard.isNotEmpty) {
        _selectedWard = '';
        _saveSelectionToHive();
        notifyListeners();
      }
      return;
    }
    _selectedZone = zone ?? '';
    _resetWard();
    _updateWards();
    _saveSelectionToHive();
    notifyListeners();
  }

  void selectWard(String? ward) {
    if (ward == _selectedWard) return;
    _selectedWard = ward ?? '';
    _saveSelectionToHive();
    notifyListeners();
  }

  void _saveSelectionToHive() {
    if (!Hive.isBoxOpen('project_context_selection')) return;
    final box = Hive.box('project_context_selection');
    box.put(userEmail, {
      'customer': _selectedCustomer,
      'customer_id': _selectedCustomerId,
      'region': _selectedRegion,
      'zone': _selectedZone,
      'ward': _selectedWard,
    });
  }

  void _updateRegions({bool selectFirst = false}) {
    if (_selectedCustomer.isEmpty || _data[_selectedCustomer] == null) {
      _regions = [];
      _resetRegion();
      return;
    }
    var regionsMap = _data[_selectedCustomer]['regions'] as Map?;
    if (regionsMap != null) {
      _regions = regionsMap.keys.cast<String>().toList()..sort();
    } else {
      _regions = [];
    }

    if (_selectedRegion.isNotEmpty && !_regions.contains(_selectedRegion)) {
      _selectedRegion = '';
      _resetZone();
    }

    if (selectFirst && _regions.isNotEmpty) {
      _selectedRegion = _regions.first;
      _updateZones();
    } else if (_selectedRegion.isNotEmpty) {
      _updateZones();
    } else {
      // Region is empty and not selecting first, so reset dependent
      _resetZone();
    }
  }

  void _updateZones() {
    if (_selectedRegion.isEmpty) {
      _zones = [];
      _resetZone();
      return;
    }
    var regionsMap = _data[_selectedCustomer]['regions'];
    var zonesMap = regionsMap[_selectedRegion]['zones'] as Map?;

    if (zonesMap != null) {
      _zones = zonesMap.keys.cast<String>().toList()..sort();
    } else {
      _zones = [];
    }

    if (_selectedZone.isNotEmpty && !_zones.contains(_selectedZone)) {
      _selectedZone = '';
      _resetWard();
    } else if (_selectedZone.isNotEmpty) {
      _updateWards();
    } else {
      _resetWard();
    }
  }

  void _updateWards() {
    if (_selectedZone.isEmpty) {
      _wards = [];
      _resetWard();
      return;
    }
    var regionsMap = _data[_selectedCustomer]['regions'];
    var zonesMap = regionsMap[_selectedRegion]['zones'];
    var wardsMap = zonesMap[_selectedZone]['wards'] as Map?;

    if (wardsMap != null) {
      _wards = wardsMap.keys.cast<String>().toList()..sort();
    } else {
      _wards = [];
    }

    if (_selectedWard.isNotEmpty && !_wards.contains(_selectedWard)) {
      _selectedWard = '';
    }
  }

  void _resetRegion() {
    _selectedRegion = '';
    _regions = [];
    _resetZone();
  }

  void _resetZone() {
    _selectedZone = '';
    _zones = [];
    _resetWard();
  }

  void _resetWard() {
    _selectedWard = '';
    _wards = [];
  }

  List<String> get customers => _customers;
  List<String> get regions => _regions;
  List<String> get zones => _zones;
  List<String> get wards => _wards;

  String get selectedCustomer => _selectedCustomer;
  String get selectedCustomerId => _selectedCustomerId;
  String get selectedRegion => _selectedRegion;
  String get selectedZone => _selectedZone;
  String get selectedWard => _selectedWard;
}
