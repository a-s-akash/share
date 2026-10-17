import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/pole_install.dart/pole_service.dart';
import '../device_page/device_controller.dart';
import '../login_page/login_controller.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../utils/utility.dart';
import 'pole_history_model.dart';

final poleController =
    ChangeNotifierProvider<PoleProvider>((ref) => PoleProvider());

class PoleProvider extends ChangeNotifier {
  final PoleService _service = PoleService();
  int _totalAssetUserCount = 0;
  int _totalAssetWardCount = 0;
  List<InstallationHistory> _combined = [];
  bool _loading = false;
  bool _showSearchLoading = false;

  void loadWardCounts(WidgetRef ref) async {
    final wardId = ref.read(deviceController).selectedWardId;

    final results = await Future.wait<Map<String, dynamic>?>([
      _service.assetWardCountService(wardId, 'pole'),
      _service.assetWardCountService(wardId, 'switchPoint'),
      _service.assetWardCountService(wardId, 'transformer'),
    ]);
    final poleMap = results[0] ?? {};
    final spMap = results[1] ?? {};
    final trMap = results[2] ?? {};
    int poleSpecificWardCount = poleMap['pole_count'] ?? 0;
    int spSpecificWardCount = spMap['switch_point_count'] ?? 0;
    int transformerSpecificWardCount = trMap['transformer_count'] ?? 0;
    _totalAssetWardCount = poleSpecificWardCount +
        spSpecificWardCount +
        transformerSpecificWardCount;
    notifyListeners();
  }

  ///to trigger the full flow (online fetch + sync + load local)
  Future<void> loadCombinedHistory(
    WidgetRef ref, {
    bool forceRefresh = false,
  }) async {
    _loading = true;

    final hasInternet = ref.read(internetStatusProvider);
    final wardId = ref.read(deviceController).selectedWardId;
    final usermail = ref.read(loginController).userMail;

    if (hasInternet || forceRefresh) {
// fetch all three in parallel
      final results = await Future.wait<Map<String, dynamic>?>([
        _service.poleInstallationHistoryService(wardId, usermail, 'pole'),
        _service.poleInstallationHistoryService(
            wardId, usermail, 'switchPoint'),
        _service.poleInstallationHistoryService(
            wardId, usermail, 'transformer'),
      ]);

      final poleMap =
          results[0] != null && results[0]!.containsKey('User_history')
              ? Map<String, dynamic>.from(results[0]!['User_history'] as Map)
              : <String, dynamic>{};
      final spMap =
          results[1] != null && results[1]!.containsKey('User_history')
              ? Map<String, dynamic>.from(results[1]!['User_history'] as Map)
              : <String, dynamic>{};
      final trMap =
          results[2] != null && results[2]!.containsKey('User_history')
              ? Map<String, dynamic>.from(results[2]!['User_history'] as Map)
              : <String, dynamic>{};

      /// Extract Total_count for each asset type
      int poleUserCount =
          results[0]?['Total_count'] != null ? results[0]!['Total_count'] : 0;

      int spUserCount =
          results[1]?['Total_count'] != null ? results[1]!['Total_count'] : 0;

      int transUserCount =
          results[2]?['Total_count'] != null ? results[2]!['Total_count'] : 0;

      _totalAssetUserCount = poleUserCount + spUserCount + transUserCount;

      final merged = _mergeHistoryMaps(poleMap, spMap, trMap);
      log('Merged installation history: $merged');
      await _syncMergedToHive(
          wardId: wardId, usermail: usermail, merged: merged);
    }

// load from local
    _combined = await _loadOffline(wardId: wardId, usermail: usermail);

    _loading = false;
    notifyListeners();
  }

  /// Merge three maps into date -> {pole, switchPoint, transformer}
  Map<String, Map<String, int>> _mergeHistoryMaps(
    Map<String, dynamic> pole,
    Map<String, dynamic> sp,
    Map<String, dynamic> tr,
  ) {
    final allDates = <String>{};
    allDates.addAll(pole.keys.map((k) => k.toString()));
    allDates.addAll(sp.keys.map((k) => k.toString()));
    allDates.addAll(tr.keys.map((k) => k.toString()));
    log('All dates of installation history: $allDates');

    final merged = <String, Map<String, int>>{};

    for (final d in allDates) {
      merged[d] = {
        'pole': pole.containsKey(d) ? (pole[d] as num).toInt() : 0,
        'switchPoint': sp.containsKey(d) ? (sp[d] as num).toInt() : 0,
        'transformer': tr.containsKey(d) ? (tr[d] as num).toInt() : 0,
      };
    }

    return merged;
  }

  /// Sync merged map to Hive, keep ONLY latest 5 dates for this ward+user
  Future<void> _syncMergedToHive({
    required String wardId,
    required String usermail,
    required Map<String, Map<String, int>> merged,
  }) async {
    final box = await Utility.openInstallationHistoryBox();

// sort dates descending
    final sortedDates = merged.keys.toList()
      ..sort((a, b) {
        final dA = DateTime.parse(
            a.split('-').reversed.join('-')); // dd-mm-yyyy -> yyyy-mm-dd
        final dB = DateTime.parse(b.split('-').reversed.join('-'));
        return dB.compareTo(dA);
      });

    final latest5 = sortedDates.take(5).toSet();

// delete older keys for this ward+user
    final keysToDelete = box.keys.where((key) {
      final k = key.toString();
      return k.startsWith('${wardId}_${usermail}_') &&
          !latest5.contains(k.split('_').last);
    }).toList();

    if (keysToDelete.isNotEmpty) await box.deleteAll(keysToDelete);

// insert/update latest five
    for (final date in latest5) {
      final key = '${wardId}_${usermail}_$date';
      final d = merged[date]!;

      final item = InstallationHistory(
        date: date,
        pole: d['pole']!,
        switchPoint: d['switchPoint']!,
        transformer: d['transformer']!,
        wardId: wardId,
        usermail: usermail,
      );

      await box.put(key, item);
    }
  }

  Future<List<InstallationHistory>> _loadOffline({
    required String wardId,
    required String usermail,
  }) async {
    final box = await Utility.openInstallationHistoryBox();

    final list = box.values
        .where((e) => e.wardId == wardId && e.usermail == usermail)
        .toList()
      ..sort((a, b) {
        final A = DateTime.parse(a.date.split('-').reversed.join('-'));
        final B = DateTime.parse(b.date.split('-').reversed.join('-'));
        return B.compareTo(A);
      });

    if (list.length > 5) return list.take(5).toList();
    return list;
  }

  void toggleSearchLoader(value) {
    _showSearchLoading = value;
    notifyListeners();
  }

  int get totalAssetWardCount => _totalAssetWardCount;
  int get totalAssetUserCount => _totalAssetUserCount;
  List<InstallationHistory> get combined => _combined;
  bool get loading => _loading;
  bool get showSearchLoading => _showSearchLoading;
}
