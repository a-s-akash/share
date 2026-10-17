import 'dart:developer';

import 'package:citizen_complaints_list_web/firebase_setup/firebase_services.dart';
import 'package:citizen_complaints_list_web/screens/api/api_services.dart';

import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:hive/hive.dart';

Future<bool> isUpdateRequired() async {
  try {
    final versionDoc = await FirebaseServices.ticketsFirestore
        .collection('utils')
        .doc('dashboard_version')
        .get();
    String latestVersion = versionDoc['latest_version'];
    if (latestVersion != dashboardVersion) {
      return true;
    }
    return false;
  } catch (e) {
    log("Error checking update: $e");
    return false;
  }
}

fetchProjectContext() async {
  final box = await Hive.openBox('project_context');

  if (!box.containsKey(userEmail)) {
    log('Box empty for user $userEmail, fetching in foreground...');
    final projectContext = await fetchProjectContextService();
    if (projectContext != null && projectContext is! String) {
      log(projectContext.toString());
      await box.put(userEmail, projectContext);
      log('Project Context Cached in Hive');
    } else if (projectContext == 401) {
      log('Session expired. Please login again.');
    } else {
      log('Failed to fetch project context');
    }
  } else {
    log('Box has data for user $userEmail, fetching in background...');
    Future(() async {
      final projectContext = await fetchProjectContextService();
      if (projectContext != null && projectContext is! String) {
        log(projectContext.toString());
        await box.put(userEmail, projectContext);
        log('Project Context Updated in Hive (Background)');
      }
    });
  }
}

fetchProblemTypesAndIssuesIdentified() async {
  final box = await Hive.openBox('problemTypesAndIssuesIdentified');

  if (!box.containsKey("problem_types") ||
      !box.containsKey("issues_identified")) {
    log('Problem Type Box empty fetching in foreground...');
    final probsAndIssues = await fetchProblemTypesAndIssuesIdentifiedService();
    if (probsAndIssues != null && probsAndIssues is! String) {
      log(probsAndIssues.toString());
      await box.put("problem_types", probsAndIssues['problem_types']);
      await box.put("issues_identified", probsAndIssues['issues_identified']);
      log('Problems and Issues List Cached in Hive');
    } else {
      log('Failed to fetch problems and issues list');
    }
  } else {
    log('Problem Type Box empty fetching in foreground...');

    Future(() async {
      final probsAndIssues =
          await fetchProblemTypesAndIssuesIdentifiedService();
      if (probsAndIssues != null && probsAndIssues is! String) {
        log(probsAndIssues.toString());
        await box.put("problem_types", probsAndIssues['problem_types']);
        await box.put("issues_identified", probsAndIssues['issues_identified']);
        log('Problems and Issues List Updated in Hive (Background)');
      }
    });
  }
}

Map<String, dynamic> structureData(Map<dynamic, dynamic> data) {
  final Map<String, dynamic> result = {};

  final customers = data['customers'] as Map<String, dynamic>? ?? {};

  customers.forEach((customerName, customerData) {
    final customerMap = customerData as Map<String, dynamic>;

    final Map<String, dynamic> newCustomer = {
      'customer_id': customerMap['customer_id'],
      'regions': {},
    };

    final regions = customerMap['regions'] as Map<String, dynamic>? ?? {};

    regions.forEach((regionId, regionData) {
      final regionMap = regionData as Map<String, dynamic>;
      final String regionName = regionMap['region_name'];

      final Map<String, dynamic> newRegion = {
        'region_id': regionId,
        'zones': {},
      };

      final zones = regionMap['zones'] as Map<String, dynamic>? ?? {};

      zones.forEach((zoneId, zoneData) {
        final zoneMap = zoneData as Map<String, dynamic>;
        final String zoneName = zoneMap['zone_name'];

        final Map<String, dynamic> newZone = {'zone_id': zoneId, 'wards': {}};

        final wards = zoneMap['wards'] as Map<String, dynamic>? ?? {};

        wards.forEach((wardId, wardData) {
          final wardMap = wardData as Map<String, dynamic>;
          final String wardName = wardMap['ward_name'];

          newZone['wards'][wardName] = {'ward_id': wardId};
        });

        newRegion['zones'][zoneName] = newZone;
      });

      newCustomer['regions'][regionName] = newRegion;
    });

    result[customerName] = newCustomer;
  });

  return result;
}
