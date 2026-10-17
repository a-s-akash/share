import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart' as appsettings;
import 'package:schnell_luminator/attendence_tracking.dart/user_tracking_controller.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/device_page/device_service.dart';
import 'package:schnell_luminator/s3_bucket/s3_config.dart';
import 'package:schnell_luminator/utils/image_compression_util.dart';
import 'package:uuid/uuid.dart';
import 'package:schnell_luminator/ticket_notification/comment_model.dart';
import 'package:schnell_luminator/utils/constants.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../survey/connectivity_sync_service.dart';
import 'package:schnell_luminator/utils/session.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../login_page/login_controller.dart';
import '../utils/secure_storage.dart';
import '../utils/utility.dart';
import 'offline/ticket_repository.dart';
import 'offline/ticket_update_queue_item.dart';
import 'ticket_model.dart';
import 'ticket_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';

final ticketController =
    ChangeNotifierProvider<TicketProvider>((ref) => TicketProvider());

class TicketProvider extends ChangeNotifier {
  final TicketService _service = TicketService();
  final TicketRepository _repository = TicketRepository();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replacedEntityNameController =
      TextEditingController();
  List<Ticket> _tickets = [];
  List<Ticket> _filteredTickets = [];
  late Ticket _selectedTicekt;
  List<Comments> _comments = [];
  String _searchText = '';
  int scrollCount = 0;
  String _selectedContextId = '';
  String _selectedContextType = '';
  String _selectedContextName = '';
  int _totalTicketsCount = 0;
  int _totalTicketsCountBasedOnStatus = 0;
  int _fetchedTicketCount = 0;
  DocumentSnapshot? _ticketCursor;
  bool _ticketHasNext = true;
  String _ticketStatusValue = 'Ticket Status (ALL)';
  String _componentsChangedValue = 'Components Changed';
  String _issuesIdentifiedValue = 'Issues Identified';
  String _newTicketStatus = '';
  String _newComponentsChangedValue = '';
  String _newIssuesIdentifiedValue = '';
  bool _isComponentChangeFieldEnabled = false;
  String _eneteredComment = '';
  //For Ticket Creation
  // String _selectedDeviceType = 'Device/Asset Type*';
  String _selectedDeviceOrAssetName = 'Device / Asset Id';
  String _location = '';
  String _deviceZone = '';
  String _deviceCustomer = '';
  String _deviceCustomerId = '';
  String _deviceWard = '';
  String _deviceRegion = '';
  String _deviceRegionId = '';
  String _deviceZoneId = '';
  String _deviceWardId = '';
  double _deviceLatitude = 0;
  double _deviceLongitude = 0;
  double _ticketLatitude = 0;
  double _ticketLongitude = 0;
  String _panelId = '';
  String _meterSerialNo = '';
  String _spNo = '';
  String _selectedPriority = 'Priority';
  String _selectedProblemType = 'Problem Type*';
  String _selectedStatus = 'Status';
  String _selectedAssignee = 'Assignee';
  String _selectedcomplainee = 'Complainee';
  String _selectedComplaineePhoneNo = '';
  String _enteredTicketCreationComments = '';
  String _deviceOrAssetType = "others";
  bool isTicketLampJson = false;
  bool _isTicketsOfSpecificDevice = false;
  List<String> _availableEntityTypes = [];
  // String _previousReplacedEntityName = '';

  List<String> _deviceNames = [];
  final TextEditingController _locController = TextEditingController();
  final TextEditingController _complaineePHController = TextEditingController();
  final TextEditingController _creationCommentsController =
      TextEditingController();
  final TextEditingController _autoCompletecontroller =
      TextEditingController(text: "device/asset id");
  Map? _originatorDetail;
  String _ticketDeviceId = '';
  List<XFile?> _fetchedCapturedImages = [];

  final List _sortByCategories = [
    {'name': 'By Status', 'isSelected': true},
    {'name': 'By Priority', 'isSelected': false},
    {'name': 'By Date', 'isSelected': false},
    {'name': 'By Ticket Id', 'isSelected': false},
    {'name': 'By Device', 'isSelected': false},
  ];

  void changeComponenetChangedFieldValue() {
    _isComponentChangeFieldEnabled = !_isComponentChangeFieldEnabled;
    notifyListeners();
  }

  void updateTicketStatus(field, value) {
    switch (field) {
      case 'status':
        _newTicketStatus = value;
        break;
      case 'components':
        _componentsChangedValue = value;
        _newComponentsChangedValue = value;
        if (value != "Components Changed") {
          _newIssuesIdentifiedValue = value;
        }
        break;
      case 'issues':
        _issuesIdentifiedValue = value;
        _newIssuesIdentifiedValue = value;
        if (!isComponentChangeEnabled) {
          _isComponentChangeFieldEnabled = false;
        }
        break;
      default:
    }
    log('Luminator: Selected ticket $field is $_newTicketStatus');
    notifyListeners();
  }

  bool get isComponentChangeEnabled {
    if (_newIssuesIdentifiedValue.isEmpty ||
        _newIssuesIdentifiedValue == 'Issues Identified') {
      return false;
    }

    final probIssueBox = Hive.box('problemTypesAndIssuesIdentified');
    final List nonComponents =
        probIssueBox.get('issues_identified')['non_components'] ?? [];

    return !nonComponents.contains(_newIssuesIdentifiedValue);
  }

  void resetFieldValues(Ticket ticket) {
    _newTicketStatus = '';
    _newComponentsChangedValue =
        ticket.ticketDetails?['t_changed_component'] ?? '';
    _newIssuesIdentifiedValue =
        ticket.ticketDetails?['t_issue_identified'] ?? '';
    _isComponentChangeFieldEnabled = false;
    _componentsChangedValue = 'Components Changed';
    _issuesIdentifiedValue = 'Issues Identified';
    _eneteredComment = '';
    _commentController.text = '';
    _replacedEntityNameController.text = ticket.replacedEntityName ?? '';
  }

  void updateSelectedTicket(Ticket ticket) {
    _selectedTicekt = ticket;
    _newIssuesIdentifiedValue = ticket.issuesIdentified ?? 'Issues Identified';

    _isComponentChangeFieldEnabled =
        isComponentChangeEnabled && (ticket.componentsChanged ?? false);

    // _previousReplacedEntityName = ticket.replacedEntityName ?? '';
    // _replacedEntityNameController.text = _previousReplacedEntityName;
  }

  bool isLessThanOneDay(int milliseconds) {
    DateTime currentTime = DateTime.now();
    DateTime targetTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    Duration difference = currentTime.difference(targetTime);
    return difference.inDays < 1;
  }

  String getDuration(String timeStamp) {
    int milliseconds = int.parse(timeStamp) * 1000;
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    String timeAgo = timeago.format(dateTime, locale: 'en_short');
    return timeAgo;
  }

  String getDurationFB(String timeStamp) {
    if (timeStamp == '') return '';
    DateTime dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(timeStamp);
    return timeago.format(dateTime, locale: 'en_short');
  }

  void updateSearchText(String value) {
    _searchText = value;
    getFilteredTickets();
  }

  updateSelectedAssetId(
      String contextId, String contextType, String contextName) {
    _ticketStatusValue = 'Ticket Status (ALL)';
    _selectedContextId = contextId;
    _selectedContextType = contextType;
    _selectedContextName = contextName;
  }

  getFilteredTickets() {
    if (_searchText != '') {
      _filteredTickets = _tickets
          .where((element) =>
              element.ticketId.toString().toLowerCase().contains(_searchText) ||
              element.ticketStatus
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              element.deviceId
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              element.problemType
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              element.priority
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              element.comment
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              element.complaineeType
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              element.location
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()))
          .toList();
    } else {
      _filteredTickets = _tickets;
    }
    notifyListeners();
  }

  void sortTickets(context, int index) async {
    Navigator.of(context, rootNavigator: true).pop();
    for (int i = 0; i < _sortByCategories.length; i++) {
      _sortByCategories[i]['isSelected'] = false;
    }
    switch (index) {
      case 0:
        _filteredTickets
            .sort((a, b) => a.ticketStatus!.compareTo(b.ticketStatus!));
        break;
      case 1:
        _filteredTickets.sort((a, b) => a.priority!.compareTo(b.priority!));
        break;
      case 2:
        _filteredTickets
            .sort((a, b) => b.createdTime!.compareTo(a.createdTime!));
        break;
      case 3:
        _filteredTickets
            .sort((a, b) => a.ticketId!.compareTo(b.ticketId ?? ''));
        break;
      case 4:
        _filteredTickets.sort((a, b) => a.deviceId!.compareTo(b.deviceId!));
        break;
      default:
        break;
    }
    log('selected index: $index');
    _sortByCategories[index]['isSelected'] = true;
    notifyListeners();
  }

  setScrollCount(int count) {
    scrollCount = count;
    notifyListeners();
  }

  Future<void> updateTicketDetailsFB(BuildContext context, WidgetRef ref,
      Ticket ticket, enteredComment,
      {List<String>? attachment}) async {
    EasyLoading.show(status: 'loading...', dismissOnTap: false);
    String ccmsAssetsId = ref.read(deviceController).ccmsAssetsId;
    String smslcAssetId = ref.read(deviceController).smslcAssetId;
    String firstDeviceId = ref.read(deviceController).firstDeviceId;
    DateTime now = DateTime.now();
    String datetime = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    final secureStorage = SecureStorageService();
    String userId = await secureStorage.getUserId() ?? '';
    String usermail = ref.watch(loginController).userMail;
    String username = usermail.split("@").first.toUpperCase();

    Map<String, dynamic> postData = {};
    List<String> actionsPerformed = [];

    if (_newTicketStatus != '' && ticket.ticketStatus != _newTicketStatus) {
      postData['status'] = _newTicketStatus;
      if (_newTicketStatus == 'Visited-Closed') {
        postData['ticket_closed_on'] = datetime;
        postData['ticket_closed_by'] = username;
        postData['ticket_closed_by_mail_id'] = usermail;
        postData['ticket_closed_by_user_id'] = userId;
      }
      actionsPerformed.add(
          "Status changed from ${ticket.ticketStatus} to $_newTicketStatus");
    }

    if (_newIssuesIdentifiedValue != '' &&
        _newIssuesIdentifiedValue != 'Issues Identified' &&
        ticket.issuesIdentified != _newIssuesIdentifiedValue) {
      postData['issue_identified'] = _newIssuesIdentifiedValue;
      if (ticket.issuesIdentified == '' || ticket.issuesIdentified == null) {
        actionsPerformed.add("Issues Identified: $_newIssuesIdentifiedValue");
      } else {
        actionsPerformed.add(
            "Issues Identified changed from ${ticket.issuesIdentified} to $_newIssuesIdentifiedValue");
      }
    }

    if (ticket.componentsChanged == null && _isComponentChangeFieldEnabled) {
      postData['components_changed'] = _isComponentChangeFieldEnabled;
      actionsPerformed.add("Components Changed: Yes");
    } else if (ticket.componentsChanged != null &&
        ticket.componentsChanged != _isComponentChangeFieldEnabled) {
      postData['components_changed'] = _isComponentChangeFieldEnabled;
      actionsPerformed.add(
          "Components Changed Toggled: ${ticket.componentsChanged! ? 'Yes' : 'No'} -> ${_isComponentChangeFieldEnabled ? 'Yes' : 'No'}");
    }

    // if (_replacedEntityNameController.text.isNotEmpty &&
    //     ticket.replacedEntityName != _previousReplacedEntityName) {
    //   postData['replaced_entity_name'] = _replacedEntityNameController.text;
    //   if (_previousReplacedEntityName.isEmpty) {
    //     actionsPerformed.add(
    //       "Replaced $_newIssuesIdentifiedValue Name updated to ${_replacedEntityNameController.text}",
    //     );
    //   } else if (_replacedEntityNameController.text.isEmpty) {
    //     actionsPerformed.add(
    //       "Replaced $_newIssuesIdentifiedValue Name cleared",
    //     );
    //   } else {
    //     actionsPerformed.add(
    //       "Replaced $_newIssuesIdentifiedValue Name updated from $_previousReplacedEntityName to ${_replacedEntityNameController.text}",
    //     );
    //   }
    // }
    if (enteredComment != '') {
      postData['comments'] = enteredComment;
    }
    postData['audit_trail'] = {
      "actions": actionsPerformed,
      "on": datetime,
      "by": username,
      "user_id": userId,
      "mail_id": usermail,
      "comment": enteredComment,
      "attachment": (attachment != null && attachment.isNotEmpty)
          ? attachment
          : "",
    };

    try {
      log(postData.toString());
      log('DEBUG ticket.alarmId=${ticket.alarmId} ticket.ticketId=${ticket.ticketId}');

      final result = await _repository.submitUpdate(
        context: context,
        ref: ref,
        alarmId: ticket.alarmId!,
        postData: postData,
        updateType: 'details',
        ticketId: ticket.ticketId ?? '',
        deviceId: ticket.deviceId ?? '',
        deviceType: ticket.deviceType ?? '',
        actions: actionsPerformed,
        comments: enteredComment,
        createdByEmail: usermail,
      );

      if (!result.isUpdatedOnline) {
        // Reflect the queued change on the in-memory ticket (shared with the
        // list) so the user sees it until the next online refresh.
        _applyLocalTicketUpdate(ticket, postData, datetime);
        clearComments();
        _fetchedCapturedImages = [];
        EasyLoading.dismiss();
        if (context.mounted) {
          await successTick(context,
              "No internet connection — ticket update saved offline and will sync automatically.");
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop(true);
          }
        }
        return;
      }

      bool isLocationTrackingRequi = await isLocationTrackingRequired();
      clearComments();
      _fetchedCapturedImages = [];
      // Track "Components Changed" activity if applicable
      if (isLocationTrackingRequi) {
        if (_isComponentChangeFieldEnabled) {
          await ref.read(userTrackingController).activityLocationTracking(
                ref,
                '$_newComponentsChangedValue Components Changed',
                ticket.deviceId!,
                entityType: ticket.deviceType,
                isTicket: true,
              );
        }
      }
      EasyLoading.dismiss();
      await successTick(context, ErrorMessages.ticketSuccessAlert);
      // getTicketsBasedOnStatusFB(context, ref, status, selectedContext, selectedContextName);
      Navigator.of(context, rootNavigator: true).pop(true);
      // Track "status updated" activity if applicable

      if (isLocationTrackingRequi) {
        if (_newTicketStatus.isNotEmpty) {
          ref.read(userTrackingController).activityLocationTracking(
                ref,
                _newTicketStatus,
                ticket.deviceId,
                entityType: ticket.deviceType,
                isTicket: true,
              );
        }
      }

      if (_isTicketsOfSpecificDevice) {
        if (context.mounted) {
          await ref.read(ticketController).getTicketsBasedOnStatusFB(
              context, ref, 'Closed', entityIdForSpecificDeviceTicket: [
            _deviceOrAssetType == 'ccms' ? ccmsAssetsId : smslcAssetId,
            firstDeviceId
          ]);
        }
      } else {
        if (context.mounted) {
          await ref
              .read(ticketController)
              .getTicketsBasedOnStatusFB(context, ref, 'Pending');
        }
      }
    } catch (e) {
      log(e.toString());
    }
  }

  void _applyLocalTicketUpdate(
      Ticket ticket, Map<String, dynamic> postData, String datetime) {
    _applyUpdatePayload(ticket, postData, datetime);
    notifyListeners();
  }

  void _applyUpdatePayload(
      Ticket ticket, Map<String, dynamic> postData, String datetime) {
    if (postData.containsKey('status')) {
      ticket.ticketStatus = postData['status'];
    }
    if (postData.containsKey('issue_identified')) {
      ticket.issuesIdentified = postData['issue_identified'];
    }
    if (postData.containsKey('components_changed')) {
      ticket.componentsChanged = postData['components_changed'];
    }
    if (postData.containsKey('comments')) {
      ticket.comment = postData['comments'];
    }
    ticket.auditTrail = [...?ticket.auditTrail, postData['audit_trail']];
    ticket.lastModifiedDate = getDurationFB(datetime);
  }

  /// Builds a [Ticket] from a Firestore ticket doc; [alarmId] is the doc id.
  Ticket _ticketFromData(String alarmId, Map<String, dynamic> ticketData) {
    return Ticket(
      alarmId: alarmId,
      ticketId: ticketData['ticket_id'] ?? '',
      ticketStatus: ticketData['status'] ?? '',
      deviceId: ticketData['entity_name'] ?? '',
      entityType: ticketData['entity_type'] ?? '',
      complaineeType: ticketData['complainee'] ?? '',
      complainee: ticketData['ticket_opened_by'] ?? '',
      priority: ticketData['priority'] ?? '',
      assignee: ticketData['assignee'] ?? '',
      assigneeId: ticketData['assignee_id'] ?? '',
      location: ticketData['location'] ?? '',
      problemType: ticketData['problem_type'] ?? '',
      comment: ticketData['comments'] ?? '',
      deviceType: ticketData['entity_type'] ?? '',
      latitude: ticketData['latitude']?.toString() ?? '',
      longitude: ticketData['longitude']?.toString() ?? '',
      createdTime: ticketData['ticket_opened_on']?.toString() ?? '',
      lastModifiedDate: getDurationFB(
        (ticketData['last_updated_on'] ?? ticketData['ticket_opened_on'])
                ?.toString() ??
            '',
      ),
      componentsChanged: ticketData['components_changed'] ?? false,
      issuesIdentified: ticketData['issue_identified'] ?? '',
      auditTrail: List<dynamic>.from(ticketData['audit_trail'] ?? []),
      // replacedEntityName: ticketData['replaced_entity_name'] ?? '',
    );
  }

  List<String> _statusesFor(String status) =>
      status.toUpperCase() == 'TICKET STATUS (ALL)'
          ? []
          : status.toUpperCase() == 'PENDING'
              ? ['Open', 'Assigned', 'Waiting-For-Support']
              : [status];

  /// Layers each ticket's pending offline update (if any) over what the
  /// server / Firestore cache returned, so queued changes stay visible.
  void _overlayPendingUpdates(List<Ticket> tickets) {
    final updateBox = Hive.box<TicketUpdateQueueItem>(ticketUpdateQueueBox);
    for (final ticket in tickets) {
      final update = updateBox.get(ticket.alarmId);
      if (update == null || update.uploaded) continue;
      _applyUpdatePayload(
          ticket,
          jsonDecode(update.payloadJson) as Map<String, dynamic>,
          DateFormat("yyyy-MM-dd HH:mm:ss").format(
              DateTime.fromMillisecondsSinceEpoch(update.updatedAtEpochMs)));
    }
  }

  Future<void> getTicketsBasedOnStatusFB(
    BuildContext context,
    WidgetRef ref,
    String status, {
    bool isScroll = false,
    List<String> entityIdForSpecificDeviceTicket =
        const [], // required only for fetching tickets under specific device/asset
  }) async {
    String selectedContextName =
        ref.watch(ticketController).selectedContextName;
    String selectedContextType =
        ref.watch(ticketController).selectedContextType;
    List<String> statuses = _statusesFor(status);
    if (isTicketsOfSpecificDevice) {
      status = 'Pending';
      statuses = ['Visited-Closed', 'Verified-Closed', 'Closed'];
    }

    if (!isScroll) {
      _ticketCursor = null;
      _ticketHasNext = true;
      setScrollCount(0);
    }

    if (isScroll && !_ticketHasNext) return;

    var res = await _service.getDefaultTicketServiceFB(
        context,
        ref,
        selectedContextType,
        selectedContextName,
        statuses,
        _isTicketsOfSpecificDevice,
        cursor: _ticketCursor,
        entityIds: entityIdForSpecificDeviceTicket);
    // Null when the Firestore query failed (e.g. offline with no cache) —
    // carry on with an empty page rather than crash.
    res ??= {'data': [], 'totalElements': 0, 'hasNext': false};

    _totalTicketsCountBasedOnStatus = res['totalElements'] ?? 0;
    log('total tickets count based on status: $status - $_totalTicketsCountBasedOnStatus');
    _ticketHasNext = res['hasNext'] ?? false;
    _ticketCursor = res['cursor'];

    List<dynamic> ticketResponse = List<dynamic>.from(res['data']);

    setScrollCount(ticketResponse.isNotEmpty
        ? (isScroll ? scrollCount + 1 : 1)
        : scrollCount);

    _tickets = ticketResponse.map((ticket) {
      Map<String, dynamic> ticketData = ticket.data() as Map<String, dynamic>;
      // log(ticket.id.toString());
      return Ticket(
        alarmId: ticket.id.toString(),
        ticketId: ticketData['ticket_id'] ?? '',
        ticketStatus: ticketData['status'] ?? '',
        deviceId: ticketData['entity_name'] ?? '',
        entityType: ticketData['entity_type'] ?? '',
        complaineeType: ticketData['complainee'] ?? '',
        complainee: ticketData['ticket_opened_by'] ?? '',
        priority: ticketData['priority'] ?? '',
        assignee: ticketData['assignee'] ?? '',
        assigneeId: ticketData['assignee_id'] ?? '',
        location: ticketData['location'] ?? '',
        problemType: ticketData['problem_type'] ?? '',
        comment: ticketData['comments'] ?? '',
        deviceType: ticketData['entity_type'] ?? '',
        latitude: ticketData['latitude']?.toString() ?? '',
        longitude: ticketData['longitude']?.toString() ?? '',
        createdTime: ticketData['ticket_opened_on']?.toString() ?? '',
        lastModifiedDate: getDurationFB(
          (ticketData['last_updated_on'] ?? ticketData['ticket_opened_on'])
                  ?.toString() ??
              '',
        ),
        componentsChanged: ticketData['components_changed'] ?? false,
        issuesIdentified: ticketData['issue_identified'] ?? '',
        auditTrail: ticketData['audit_trail'] ?? [],
        // replacedEntityName: ticketData['replaced_entity_name'] ?? '',
        ward: ticketData['ward'] ?? '',
        zone: ticketData['zone'] ?? '',
        region: ticketData['region'] ?? '',
        customer: ticketData['customer'] ?? '',
      );
    }).toList();

    // Pick up queue writes made by the background sync isolate before
    // layering offline updates over the fetched page.
    await Utility.refreshTicketQueueBox();
    _overlayPendingUpdates(_tickets);

    if (isScroll) {
      _filteredTickets = [..._filteredTickets, ..._tickets];
      _fetchedTicketCount = _filteredTickets.length;
      _tickets = _filteredTickets;
    } else {
      _filteredTickets = _tickets;
      _fetchedTicketCount = _filteredTickets.length;
    }
    // } else {
    //   await ref.read(ticketController).isTicketsOfSpecificDeviceOrAsset(false);
    //   if (context.mounted) {
    //     await getTickets(context, ref,
    //         isScroll: isScroll, selectedRegion: selectedRegion);
    //   }
    // }
    _ticketStatusValue = status;
    EasyLoading.dismiss();
    notifyListeners();
  }

  Future<void> getLocalTicketsList(userMail) async {
    List<DocumentSnapshot> snapshots =
        await _service.fetchMyTicketServiceFB(userMail);

    List<Ticket> myTickets = snapshots.map((ticket) {
      Map<String, dynamic> ticketData = ticket.data() as Map<String, dynamic>;
      return Ticket(
        alarmId: ticket.id.toString(),
        ticketId: ticketData['ticket_id'] ?? '',
        ticketStatus: ticketData['status'] ?? '',
        deviceId: ticketData['entity_name'] ?? '',
        entityType: ticketData['entity_type'] ?? '',
        complaineeType: ticketData['complainee'] ?? '',
        complainee: ticketData['ticket_opened_by'] ?? '',
        priority: ticketData['priority'] ?? '',
        assignee: ticketData['assignee'] ?? '',
        assigneeId: ticketData['assignee_id'] ?? '',
        location: ticketData['location'] ?? '',
        problemType: ticketData['problem_type'] ?? '',
        comment: ticketData['comments'] ?? '',
        deviceType: ticketData['entity_type'] ?? '',
        latitude: ticketData['latitude']?.toString() ?? '',
        longitude: ticketData['longitude']?.toString() ?? '',
        createdTime: ticketData['ticket_opened_on']?.toString() ?? '',
        lastModifiedDate: getDurationFB(
          (ticketData['last_updated_on'] ?? ticketData['ticket_opened_on'])
                  ?.toString() ??
              '',
        ),
        componentsChanged: ticketData['components_changed'] ?? false,
        issuesIdentified: ticketData['issue_identified'] ?? '',
        auditTrail: ticketData['audit_trail'] ?? [],
        ward: ticketData['ward'] ?? '',
        zone: ticketData['zone'] ?? '',
        region: ticketData['region'] ?? '',
        customer: ticketData['customer'] ?? '',
      );
    }).toList();

    log('myTickets: ${myTickets.map((t) => t.ticketId).toList()}');

    // Hive can't persist live DocumentSnapshot objects — store the plain
    // JSON-able maps instead, same shape used to rebuild Ticket offline.
    //
    // Stored one entry per ticket (key = alarmId), not one blob under a
    // single key — that's what lets the ticket list screen react to
    // individual add/update/delete via box.listenable() instead of having
    // to be told to reload. Any key no longer present in this fetch (ticket
    // reassigned away, or the old single-blob 'myTickets' key from before
    // this change) gets pruned so the box never grows past "my tickets" —
    // except a key still keyed by localId (an offline-created ticket that
    // hasn't synced yet): the server fetch can never contain it since it
    // doesn't exist server-side yet, so pruning it here would silently drop
    // a ticket the user is still waiting to sync.
    final box = await Utility.openHiveBox(ticketListBox);
    final freshKeys =
        myTickets.map((t) => t.alarmId).whereType<String>().toSet();
    final staleKeys = box.keys.where((key) {
      if (freshKeys.contains(key)) return false;
      final raw = box.get(key);
      if (raw is Map) {
        final unsynced = Map<String, dynamic>.from(raw)['synced'] == false;
        if (unsynced) return false;
      }
      return true;
    }).toList();
    for (final key in staleKeys) {
      await box.delete(key);
    }
    for (final ticket in myTickets) {
      if (ticket.alarmId != null) {
        await box.put(ticket.alarmId, ticket.toJson());
      }
    }
  }

  Future<void> getTicketsCountBasedOnStatusFB(
    BuildContext context,
    WidgetRef ref,
    dynamic status,
  ) async {
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;

    String currentContext = 'customer';
    if (selectedWard != '') {
      currentContext = 'ward';
    } else if (selectedZone != '') {
      currentContext = 'zone';
    } else if (selectedRegion != '') {
      currentContext = 'region';
    }

    List<String> statuses = status.toUpperCase() == 'PENDING'
        ? ['Open', 'Assigned', 'Waiting-For-Support']
        : [status];

    int count = await _service.fetchTicketsCountService(
        ref, context, currentContext, selectedContextId, statuses,
        isTotalCountRequired: true);

    await Utility.openHiveBox(countBox);
    _updateCount(count);
  }

  void _updateCount(int count) {
    final box = Hive.box(countBox);
    _totalTicketsCount = count;
    box.put('ticketCount', count);
    log("Updated Hive ticketCount = ${box.get('ticketCount')}");
    notifyListeners();
  }

  Future<void> loadLocalTicketsCount() async {
    var box = await Hive.openBox('countBox');
    _totalTicketsCount = box.get('ticketCount', defaultValue: 0);
    log("Updated Hive ticketCount(local)= $_totalTicketsCount");
    notifyListeners();
  }

  textFieldUpdate(eneteredComment) {
    _eneteredComment = eneteredComment;
    notifyListeners();
  }

  // void componentIdUpdate(String value) {
  //   notifyListeners();
  // }

  void clearComments() {
    // _comments.insert(0, Comments.fromJson(responseData));
    _commentController.clear();
    _eneteredComment = '';
    notifyListeners();
  }

  // Future<void> updateTicketComment(BuildContext context, WidgetRef ref,
  //     Ticket ticket, String comment) async {
  //   EasyLoading.show(status: 'loading...', dismissOnTap: false);
  //   final Map<String, dynamic> postDataForDBActivity = {
  //     "alarmId": {"id": ticket.alarmId, "entityType": "ALARM"},
  //     "comment": {"text": comment}
  //   };

  //   final Map<String, dynamic> postDataForDetailsBlock = {
  //     "id": {"entityType": "ALARM", "id": ticket.alarmId},
  //     "originator": {
  //       "entityType": ticket.originatorType,
  //       "id": ticket.originatorId
  //     },
  //     "details": ticket.ticketDetails,
  //     "severity": ticket.priority
  //   };
  //   if (_eneteredComment != '') {
  //     postDataForDetailsBlock['details']["t_comment"] = _eneteredComment;
  //   }

  //   try {
  //     log(postDataForDBActivity.toString());
  //     await _service.updateTicketCommentService(context, ref, ticket.alarmId!,
  //         postDataForDBActivity, postDataForDetailsBlock, addCommnets);
  //     bool isLocationTrackingRequi = await isLocationTrackingRequired();
  //     if (isLocationTrackingRequi) {
  //       ref.read(userTrackingController).activityLocationTracking(
  //           ref, 'Comments Updation', ticket.ticketId,
  //           entityType: ticket.ticketDetails!['t_entityType'], isTicket: true);
  //     }
  //   } catch (e) {
  //     log(e.toString());
  //   }
  // }

  Future<void> updateTicketCommentFB(BuildContext context, WidgetRef ref,
      Ticket ticket, String comment) async {
    EasyLoading.show(status: 'loading...', dismissOnTap: false);
    DateTime now = DateTime.now();
    String datetime = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    final secureStorage = SecureStorageService();
    String userId = await secureStorage.getUserId() ?? '';
    String usermail = ref.watch(loginController).userMail;
    String username = usermail.split("@").first.toUpperCase();

    final Map<String, dynamic> postData = {
      "comments": comment,
      "audit_trail": {
        "actions": [],
        "on": datetime,
        "by": username,
        "user_id": userId,
        "mail_id": usermail,
        "comment": comment,
        "attachment": ""
      }
    };

    try {
      log(postData.toString());
      final result = await _repository.submitUpdate(
        context: context,
        ref: ref,
        alarmId: ticket.alarmId!,
        postData: postData,
        updateType: 'comment',
        ticketId: ticket.ticketId ?? '',
        deviceId: ticket.deviceId ?? '',
        deviceType: ticket.deviceType ?? '',
        actions: const [],
        comments: comment,
        createdByEmail: usermail,
      );
      clearComments();
      // auditTrail is null on a ticket just created from this device (its
      // ticketListBox entry is built locally, with no trail yet).
      _selectedTicekt.auditTrail = [
        ...?_selectedTicekt.auditTrail,
        postData["audit_trail"]
      ];
      notifyListeners();
      EasyLoading.dismiss();
      if (!result.isUpdatedOnline) {
        if (context.mounted) {
          showSnackBar(ref, context,
              "No internet connection — comment saved offline and will sync automatically.");
        }
      } else {
        bool isLocationTrackingRequi = await isLocationTrackingRequired();
        if (isLocationTrackingRequi) {
          ref.read(userTrackingController).activityLocationTracking(
              ref, 'Comments Updation', ticket.deviceId,
              entityType: ticket.entityType, isTicket: true);
        }
      }
    } catch (e) {
      log(e.toString());
      showSnackBar(ref, context, ErrorMessages.tryAgainError);
    }
  }

  void saveCommnets(responseData) {
    _comments = [];
    List commentsList = responseData;
    for (var e in commentsList) {
      _comments.add(Comments.fromJson(e));
    }
  }

  //For Ticket Creation
  void saveDevices(responseData) {
    _deviceNames = [];
    List deviceNamesList = responseData;
    for (var e in deviceNamesList) {
      _deviceNames.add(e["latest"]["ENTITY_FIELD"]["name"]["value"]);
    }
    notifyListeners();
  }

  isTicketsOfSpecificDeviceOrAsset(value) {
    _isTicketsOfSpecificDevice = value;
    notifyListeners();
  }

  loadInitialDetailsOfEntities(WidgetRef ref, String entityType) {
    String usermail = ref.watch(loginController).userMail;
    String ccmsAssetName = ref.watch(deviceController).ccmsAssetName;
    String smslcAssetName = ref.watch(deviceController).smslcAssetName;
    String ccmsLandmark = ref.watch(deviceController).ccmsLandmark;
    String smslcLandmark = ref.watch(deviceController).smslcLandmark;
    String firstDeviceLable = ref.watch(deviceController).firstDeviceLable;
    String ccmszone = ref.watch(deviceController).ccmszone;
    String ccmsward = ref.watch(deviceController).ccmsward;
    String ccmsregion = ref.watch(deviceController).ccmsregion;
    String ccmsLat = ref.watch(deviceController).ccmsLat;
    String ccmsLong = ref.watch(deviceController).ccmsLong;
    String ccmsAssetsId = ref.watch(deviceController).ccmsAssetsId;

    String smslczone = ref.watch(deviceController).smslczone;
    String smslcward = ref.watch(deviceController).smslcward;
    String smslcregion = ref.watch(deviceController).smslcregion;
    String smslcLat = ref.watch(deviceController).smslcLat;
    String smslcLong = ref.watch(deviceController).smslcLong;
    String smslcAssetId = ref.watch(deviceController).smslcAssetId;

    if (entityType.toUpperCase() == 'GW') {
      // Build available entity types based on what's present
      _availableEntityTypes = [];
      if (ccmsAssetName.isNotEmpty) _availableEntityTypes.add('ccms');
      if (firstDeviceLable.isNotEmpty) _availableEntityTypes.add('gw');

      // Default to CCMS if available, otherwise GW
      String defaultType = ccmsAssetName.isNotEmpty ? 'ccms' : 'gw';
      String defaultName =
          defaultType == 'ccms' ? ccmsAssetName : firstDeviceLable;

      _creationCommentsController.text = '';
      _autoCompletecontroller.text = defaultName;
      _selectedDeviceOrAssetName = defaultName;
      _locController.text = ccmsLandmark;
      _deviceOrAssetType = defaultType;
      _location = ccmsLandmark;
      _selectedProblemType = 'Problem Type*';
      _selectedAssignee = usermail;
      _enteredTicketCreationComments = '';
      _ticketDeviceId = ccmsAssetsId;
      saveDeviceDetails(_location, ccmsregion, ccmszone, ccmsward,
          double.parse(ccmsLat), double.parse(ccmsLong), '', '', '', ref);
    } else if (entityType.toUpperCase() == 'SEMC') {
      // Build available entity types based on what's present
      _availableEntityTypes = [];
      if (smslcAssetName.isNotEmpty) _availableEntityTypes.add('smslc');
      if (firstDeviceLable.isNotEmpty) _availableEntityTypes.add('semc');

      // Default to SMSLC if available, otherwise SEMC
      String defaultType = smslcAssetName.isNotEmpty ? 'smslc' : 'semc';
      String defaultName =
          defaultType == 'smslc' ? smslcAssetName : firstDeviceLable;

      _creationCommentsController.text = '';
      _autoCompletecontroller.text = defaultName;
      _selectedDeviceOrAssetName = defaultName;
      _locController.text = smslcLandmark;
      _deviceOrAssetType = defaultType;
      _location = smslcLandmark;
      _selectedProblemType = 'Problem Type*';
      _selectedAssignee = usermail;
      _enteredTicketCreationComments = '';
      _ticketDeviceId = smslcAssetId;
      saveDeviceDetails(_location, smslcregion, smslczone, smslcward,
          double.parse(smslcLat), double.parse(smslcLong), '', '', '', ref);
    }
  }

  updateSelectedFields(context, WidgetRef ref, String? value, String? fieldName,
      bool isDeviceSelection,
      {bool isMaintenanceTicket = false}) async {
    String usermail = ref.watch(loginController).userMail;

    if (fieldName == "deviceType") {
      _deviceOrAssetType = value!;
      _deviceNames = [];

      if (isMaintenanceTicket) {
        // Update name and location based on selected type
        String ccmsAssetName = ref.watch(deviceController).ccmsAssetName;
        String ccmsAssetsId = ref.watch(deviceController).ccmsAssetsId;
        String smslcAssetName = ref.watch(deviceController).smslcAssetName;
        String ccmsLandmark = ref.watch(deviceController).ccmsLandmark;
        String smslcLandmark = ref.watch(deviceController).smslcLandmark;
        String smslcAssetId = ref.watch(deviceController).smslcAssetId;
        String firstDeviceLable = ref.watch(deviceController).firstDeviceLable;
        String firstDeviceId = ref.watch(deviceController).firstDeviceId;

        switch (value) {
          case 'ccms':
            _autoCompletecontroller.text = ccmsAssetName;
            _selectedDeviceOrAssetName = ccmsAssetName;
            _locController.text = ccmsLandmark;
            _location = ccmsLandmark;
            _ticketDeviceId = ccmsAssetsId;
            // saveDeviceDetails(_location, ccmszone, ccmsward, ccmsregion,
            //     double.parse(ccmsLat), double.parse(ccmsLong), ref);
            break;
          case 'gw':
            _autoCompletecontroller.text = firstDeviceLable;
            _selectedDeviceOrAssetName = firstDeviceLable;
            _locController.text = ccmsLandmark;
            _location = ccmsLandmark;
            _ticketDeviceId = firstDeviceId;
            // saveDeviceDetails(_location, ccmszone, ccmsward, ccmsregion,
            //     double.parse(ccmsLat), double.parse(ccmsLong), ref);

            break;
          case 'smslc':
            _autoCompletecontroller.text = smslcAssetName;
            _selectedDeviceOrAssetName = smslcAssetName;
            _locController.text = smslcLandmark;
            _location = smslcLandmark;
            _ticketDeviceId = smslcAssetId;
            // saveDeviceDetails(_location, smslczone, smslcward, smslcregion,
            //     double.parse(smslcLat), double.parse(smslcLong), ref);
            break;
          case 'semc':
            _autoCompletecontroller.text = firstDeviceLable;
            _selectedDeviceOrAssetName = firstDeviceLable;
            _locController.text = smslcLandmark;
            _location = smslcLandmark;
            _ticketDeviceId = firstDeviceId;
            // saveDeviceDetails(_location, smslczone, smslcward, smslcregion,
            //     double.parse(smslcLat), double.parse(smslcLong), ref);
            break;
        }
      }
      _selectedProblemType = 'Problem Type*';
    } else if (fieldName == "Device / Asset Id") {
      _selectedDeviceOrAssetName = value!;
      getTicketDeviceId(context, ref);
    } else if (fieldName == "location") {
      _location = value!;
    } else if (fieldName == "priority") {
      _selectedPriority = value!;
    } else if (fieldName == "problemType") {
      _selectedProblemType = value!;
    } else if (fieldName == "status") {
      _selectedStatus = value!;
    } else if (fieldName == "complainee") {
      _selectedcomplainee = value!;
    } else if (fieldName == "complaineePH") {
      _selectedComplaineePhoneNo = value!;
    } else if (fieldName == "comments") {
      _enteredTicketCreationComments = value!;
    } else if (fieldName == "reset") {
      _creationCommentsController.text = '';
      _autoCompletecontroller.clear();
      _locController.text = '';
      _deviceOrAssetType = 'others';
      _location = '';
      _deviceZone = '';
      _deviceWard = '';
      _deviceRegion = '';
      _deviceZoneId = '';
      _deviceWardId = '';
      _deviceLatitude = 0;
      _deviceLongitude = 0;
      _ticketLatitude = 0;
      _ticketLongitude = 0;
      _deviceCustomer = '';
      _deviceCustomerId = '';
      _deviceRegionId = '';
      _selectedPriority = 'Priority';
      _selectedProblemType = 'Problem Type*';
      _selectedStatus = 'Status';
      _selectedAssignee = usermail;
      _selectedcomplainee = 'Complainee';
      _selectedComplaineePhoneNo = '';
      _enteredTicketCreationComments = '';
      _deviceNames = [];
      _selectedDeviceOrAssetName = 'Device / Asset Id';
    }
    if (isDeviceSelection) {
      _creationCommentsController.text = '';
      _autoCompletecontroller.clear();
      _locController.text = '';
      _location = '';
      _deviceZone = '';
      _deviceWard = '';
      _deviceRegion = '';
      _deviceZoneId = '';
      _deviceWardId = '';
      _deviceLatitude = 0;
      _deviceLongitude = 0;
      _deviceCustomer = '';
      _deviceCustomerId = '';
      _deviceRegionId = '';
      _selectedPriority = 'Priority';
      _selectedProblemType = 'Problem Type*';
      _selectedStatus = 'Status';
      _selectedAssignee = 'Assignee';
      _selectedcomplainee = 'Complainee';
      _selectedComplaineePhoneNo = '';
      _enteredTicketCreationComments = '';
      _deviceNames = [];
    }
    notifyListeners();
  }

  Future<String> getEntityTypeForTicket(
    WidgetRef ref,
    BuildContext context,
    String scannedData,
  ) async {
    String deviceOrAsset;
    dynamic decodedData;
    try {
      decodedData = jsonDecode(scannedData);
      isTicketLampJson = true;
    } catch (e) {
      isTicketLampJson = false;
    }

    if (isTicketLampJson && decodedData is Map<String, dynamic>) {
      deviceOrAsset =
          '${decodedData['m']}-${decodedData['w']}-${decodedData['l']}-${decodedData['d']}-${decodedData['y']}-${decodedData['i']}';
    } else {
      deviceOrAsset = scannedData;
    }
    var res = await DeviceService()
        .deviceListSearchService(ref, context, deviceOrAsset, 0, '');

    if (res == 1) {
      List deviceSearchList = ref.read(deviceController).deviceSearchList;
      var exactMatch = deviceSearchList.firstWhere(
        (item) => item['name'] == deviceOrAsset,
        orElse: () => null,
      );
      if (exactMatch != null) {
        _deviceOrAssetType = exactMatch['type'];
      } else {
        _deviceOrAssetType = "others";
      }
      return deviceOrAsset;
    } else if (res == 404) {
      _deviceOrAssetType = "others";
      return deviceOrAsset;
    }
    return "";
  }

  Future<void> updateImages() async {
    _fetchedCapturedImages = [];

    _fetchedCapturedImages = List<XFile?>.filled(3, null);
    notifyListeners();
    return;
  }

  void setCapturedImages(List<XFile?> images) {
    _fetchedCapturedImages = List<XFile?>.from(images);
    notifyListeners();
  }

  Future<List<String>> uploadTicketImages(List<XFile?> capturedImages) async {
    const uuid = Uuid();
    final isOnline = await Utility.isConnected();
    final box = await Utility.openHiveBox(ticketImagesQueueBox);

    final futures = <Future<String?>>[];

    for (int i = 0; i < capturedImages.length; i++) {
      final img = capturedImages[i];
      if (img != null) {
        final imageUuid = uuid.v4();
        futures.add(() async {
          try {
            final compressedPath =
                await ImageCompressionUtil.compressAndSaveImage(
              originalImagePath: img.path,
              fileName: imageUuid,
            );
            await box.put(imageUuid, {
              'filePath': compressedPath,
              'fileName': imageUuid,
              'folder': S3Config.grievanceFolder,
              'uploaded': false,
            });
            log('Queued ticket image $i locally with uuid: $imageUuid');
            return imageUuid;
          } catch (e) {
            log('Error preparing ticket image $i: $e');
            return imageUuid;
          }
        }());
      }
    }

    final results = await Future.wait(futures);
    final imageUuids = results.whereType<String>().toList();

    // Trigger background S3 upload if online without blocking ticket creation/updation
    if (isOnline) {
      SimpleSyncService.performTicketImageSync().catchError((e) {
        log('Background ticket image upload error: $e');
      });
    }

    return imageUuids;
  }

  Future<void> createTicketWithImages(
    BuildContext context,
    WidgetRef ref,
    List<XFile?> capturedImages,
    String usermail,
    String username,
  ) async {
    EasyLoading.show(status: 'Creating ticket...', dismissOnTap: false);
    try {
      List<String> imageUuids = await uploadTicketImages(capturedImages);
      await createTicketDetailsFB(
        context,
        ref,
        usermail,
        username,
        attachment: imageUuids,
      );
    } catch (e) {
      EasyLoading.dismiss();
      log('Error in createTicketWithImages: $e');
      if (context.mounted) {
        await snackBar(context, 'Error', 'Failed to create ticket: $e');
      }
    }
  }

  Future<void> updateTicketWithImages(
    BuildContext context,
    WidgetRef ref,
    Ticket ticket,
    String enteredComment,
    List<XFile?> capturedImages,
  ) async {
    EasyLoading.show(status: 'Updating ticket...', dismissOnTap: false);
    try {
      List<String> imageUuids = await uploadTicketImages(capturedImages);
      await updateTicketDetailsFB(
        context,
        ref,
        ticket,
        enteredComment,
        attachment: imageUuids,
      );
    } catch (e) {
      EasyLoading.dismiss();
      log('Error in updateTicketWithImages: $e');
      if (context.mounted) {
        await snackBar(context, 'Error', 'Failed to update ticket: $e');
      }
    }
  }

  Future<void> getLpDetailsForLamp(
    WidgetRef ref,
    BuildContext context,
    String scannedData,
  ) async {
    // dynamic decodedData;

    // decodedData = jsonDecode(scannedData);

    // scannedData =
    //     '${decodedData['m']}-${decodedData['w']}-${decodedData['l']}-${decodedData['d']}-${decodedData['y']}-${decodedData['i']}';

    var result =
        await _service.getLpDetailsForLampService(ref, context, scannedData);
    if (result != '') {
      await saveDeviceDetails(
          result['lmpLocation'],
          result['lmpRegion'],
          result['lmpZone'],
          result['lmpWard'],
          result['lmLatitude'],
          result['lmLongitude'],
          result['lmPanelId'],
          result['lmMeterSerialNo'],
          result['lmSpNo'],
          ref);
    }
  }

  Future<void> saveDeviceDetails(
      String loc,
      String region,
      String zone,
      String ward,
      double lat,
      double long,
      String panelId,
      String meterSerialNo,
      String spNo,
      WidgetRef ref) async {
    _location = loc;
    _deviceLatitude = lat;
    _deviceLongitude = long;
    _locController.text = loc;
    _deviceZone = zone;
    _deviceWard = ward;
    _deviceRegion = region;
    _panelId = panelId;
    _meterSerialNo = meterSerialNo;
    _spNo = spNo;

    try {
      final userMail = ref.read(loginController).userMail;
      final box = await Hive.openBox("locationContext");
      final data = box.get(userMail);

      if (data != null) {
        final customers = data['customers'] as Map<dynamic, dynamic>?;
        if (customers != null) {
          for (var customerEntry in customers.entries) {
            final regions =
                customerEntry.value['regions'] as Map<dynamic, dynamic>?;
            if (regions != null) {
              for (var regionEntry in regions.entries) {
                if (regionEntry.value['region_name'] == region) {
                  _deviceCustomerId = customerEntry.value['customer_id'];
                  _deviceCustomer = customerEntry.key;
                  _deviceRegionId = regionEntry.key;
                  final zones =
                      regionEntry.value['zones'] as Map<dynamic, dynamic>?;
                  if (zones != null) {
                    for (var zoneEntry in zones.entries) {
                      if (zoneEntry.value['zone_name'] == zone) {
                        _deviceZoneId = zoneEntry.key;
                        final wards =
                            zoneEntry.value['wards'] as Map<dynamic, dynamic>?;
                        if (wards != null) {
                          for (var wardEntry in wards.entries) {
                            if (wardEntry.value['ward_name'] == ward) {
                              _deviceWardId = wardEntry.key;
                              break;
                            }
                          }
                        }
                        break;
                      }
                    }
                  }
                  break;
                }
              }
            }
          }
        }
      }
      log("Fetched Location IDs - Region: $_deviceRegionId, Zone: $_deviceZoneId, Ward: $_deviceWardId");
    } catch (e) {
      log("Error fetching location IDs from Hive: $e");
    }

    notifyListeners();
  }

  Future<void> getTicketDeviceId(
    context,
    ref,
  ) async {
    if (!await Utility.isConnected()) {
      return;
    }

    _originatorDetail = await _service.getdeviceId(
        context, ref, _deviceOrAssetType, _selectedDeviceOrAssetName);
    _ticketDeviceId = _originatorDetail!['id'];
    if (!_isTicketsOfSpecificDevice) {
      await Utility.isConnected().then((value) async {
        if (value) {
          var res = await _service.getDeviceDetailsService(
              _selectedDeviceOrAssetName, _deviceOrAssetType);
          if (res != null) {
            await saveDeviceDetails(
                res['location'],
                res['region'],
                res['zone'],
                res['ward'],
                res['latitude'],
                res['longitude'],
                res['panelId'],
                res['meterSerialNo'],
                res['spNo'],
                ref);
          }
        } else {
          await saveDeviceDetails("", "", "", "", 0.0, 0.0, '', '', '', ref);
        }
      });
    }
  }

  Future<dynamic> createTicketDetailsFB(
      BuildContext context, WidgetRef ref, usermail, username,
      {List<String>? attachment}) async {
    final isOnline = await Utility.isConnected();
    EasyLoading.show(status: 'loading...', dismissOnTap: false);
    String ccmsAssetsId = ref.read(deviceController).ccmsAssetsId;
    String smslcAssetId = ref.read(deviceController).smslcAssetId;
    String firstDeviceId = ref.read(deviceController).firstDeviceId;
    String consolidatedCustomerId;
    String consolidatedRegionId;
    String consolidatedZoneId;
    String consolidatedWardId;
    String consolidatedCustomer;
    String consolidatedRegion;
    String consolidatedZone;
    String consolidatedWard;

    final secureStorage = SecureStorageService();
    String userId = await secureStorage.getUserId() ?? '';

    if (_deviceOrAssetType == "others" || !isOnline) {
      consolidatedCustomer = ref.watch(deviceController).selectedCustomer;
      consolidatedCustomerId = ref.watch(deviceController).selectedCustomerId;
      consolidatedRegion = ref.watch(deviceController).selectedRegion;
      consolidatedRegionId = ref.watch(deviceController).selectedRegionId;
      consolidatedZone = ref.watch(deviceController).selectedZone;
      consolidatedZoneId = ref.watch(deviceController).selectedZoneId;
      consolidatedWard = ref.watch(deviceController).selectedWard;
      consolidatedWardId = ref.watch(deviceController).selectedWardId;
    } else {
      consolidatedCustomer = _deviceCustomer;
      consolidatedCustomerId = _deviceCustomerId;
      consolidatedRegion = _deviceRegion;
      consolidatedRegionId = _deviceRegionId;
      consolidatedZone = _deviceZone;
      consolidatedZoneId = _deviceZoneId;
      consolidatedWard = _deviceWard;
      consolidatedWardId = _deviceWardId;
    }

    String consolidatedDeviceType;

    if (_deviceOrAssetType == "ccms" || _deviceOrAssetType == "smslc") {
      consolidatedDeviceType = 'slc';
    } else if (_deviceOrAssetType == "gw" || _deviceOrAssetType == "semc") {
      consolidatedDeviceType = 'gw';
    } else if (_deviceOrAssetType == "ilm" || _deviceOrAssetType == "ilm-4g") {
      consolidatedDeviceType = 'ilm';
    } else {
      consolidatedDeviceType = _deviceOrAssetType;
    }

    DateTime now = DateTime.now();
    String datetime = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    final Map<String, dynamic> postData = {
      "customer": consolidatedCustomer,
      "customer_id": consolidatedCustomerId,
      "region": consolidatedRegion,
      "region_id": consolidatedRegionId,
      "zone": consolidatedZone,
      "zone_id": consolidatedZoneId,
      "ward": consolidatedWard,
      "ward_id": consolidatedWardId,
      "entity_type": consolidatedDeviceType,
      "entity_id": _ticketDeviceId,
      "entity_name": _selectedDeviceOrAssetName != "Device / Asset Id"
          ? _selectedDeviceOrAssetName
          : "",
      "problem_type": _selectedProblemType,
      "complainee": "Serviceman",
      "longitude": _deviceLongitude,
      "latitude": _deviceLatitude,
      "panel_id": _panelId,
      "meter_serial_no": _meterSerialNo,
      "sp_no": _spNo,
      "location": _location,
      "ticket_opened_by": username,
      "ticket_opened_on": datetime,
      "ticket_opened_by_user_id": userId,
      "ticket_opened_by_mail_id": usermail,
      "status": "Assigned",
      "priority": "Major",
      "comments": _enteredTicketCreationComments,
      "assignee": username,
      "assignee_mail_id": usermail,
      "assignee_id": userId,
      "audit_trail": [
        {
          "actions": ["Opened", "Assigned to $username"],
          "on": datetime,
          "by": username,
          "user_id": userId,
          "mail_id": usermail,
          "comment": _enteredTicketCreationComments,
          "attachment": (attachment != null && attachment.isNotEmpty)
              ? attachment
              : "",
        }
      ]
    };

    log(postData.toString());
    final result = await _repository.submit(
      context: context,
      ref: ref,
      postData: postData,
      deviceType: consolidatedDeviceType,
      problemType: _selectedProblemType,
      comments: _enteredTicketCreationComments,
      locationText: _location,
      latitude: _deviceLatitude,
      longitude: _deviceLongitude,
      tlatitude: _ticketLatitude,
      tlongitude: _ticketLongitude,
      createdByEmail: usermail,
    );

    if (result.isCreatedOnline) {
      bool isLocationTrackingRequi = await isLocationTrackingRequired();
      if (isLocationTrackingRequi) {
        ref.read(userTrackingController).activityLocationTracking(
            ref, 'Ticket Creation', _selectedDeviceOrAssetName,
            entityType: consolidatedDeviceType, isTicket: true);
      }

      EasyLoading.dismiss();
      if (context.mounted) {
        await successTick(
            context, "Ticket ${result.ticketId} created successfully");
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(true);
        }
      }
      ref
          .read(ticketController)
          .getTicketsCountBasedOnStatusFB(context, ref, 'Pending');
      if (_isTicketsOfSpecificDevice) {
        if (context.mounted) {
          await ref.read(ticketController).getTicketsBasedOnStatusFB(
              context, ref, 'Closed', entityIdForSpecificDeviceTicket: [
            _deviceOrAssetType == 'ccms' ? ccmsAssetsId : smslcAssetId,
            firstDeviceId
          ]);
        }
      } else {
        if (context.mounted) {
          await ref
              .read(ticketController)
              .getTicketsBasedOnStatusFB(context, ref, 'Pending');
        }
      }
    } else {
      EasyLoading.dismiss();
      if (context.mounted) {
        await successTick(context,
            "No internet connection — ticket saved offline and will sync automatically.");
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(true);
        }
      }
    }
  }

  bool get canUpdate {
    bool componentsChanged = (_selectedTicekt.componentsChanged == null
        ? _isComponentChangeFieldEnabled
        : _selectedTicekt.componentsChanged != _isComponentChangeFieldEnabled);

    bool issuesChanged =
        (_selectedTicekt.issuesIdentified != _newIssuesIdentifiedValue &&
            (_newIssuesIdentifiedValue != "Issues Identified" &&
                _newIssuesIdentifiedValue != ''));

    bool statusChanged = (_newTicketStatus != "" &&
        _newTicketStatus != _selectedTicekt.ticketStatus);

    // bool entityNameChanged = (_replacedEntityNameController.text.isNotEmpty &&
    //     _replacedEntityNameController.text != _previousReplacedEntityName);

    return componentsChanged || issuesChanged || statusChanged;
    // ||
    // entityNameChanged;
  }

  checkPermission() async {
    bool serviceEnabled;
    LocationPermission serviceEnb;
    serviceEnb = await Geolocator.checkPermission();
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    switch (serviceEnb) {
      case LocationPermission.denied:
        serviceEnb = await Geolocator.requestPermission();
        break;
      case LocationPermission.deniedForever:
        await appsettings.openAppSettings();
        break;
      case LocationPermission.whileInUse:
        null;
        break;
      case LocationPermission.always:
        null;
        break;
      case LocationPermission.unableToDetermine:
        null;
        break;
    }

    if (serviceEnb == LocationPermission.whileInUse ||
        serviceEnb == LocationPermission.always) {
      if (serviceEnabled) {
        fetchLocationForTicket(); //modified
      }
    }
  }

  clearTicketRelatedValues() {
    _ticketDeviceId = '';
    _ticketLatitude = 0.0;
    _ticketLongitude = 0.0;
    _fetchedCapturedImages = [];
    notifyListeners();
  }

  fetchLocationForTicket() async {
    Position locationData;
    LocationPermission serviceEnb = await Geolocator.checkPermission();
    if (serviceEnb == LocationPermission.denied ||
        serviceEnb == LocationPermission.deniedForever) {
      checkPermission();
    }

    locationData = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(accuracy: LocationAccuracy.high),
    );
    _ticketLatitude = locationData.latitude;
    _ticketLongitude = locationData.longitude;

    notifyListeners();
  }

  TextEditingController get commentController => _commentController;
  // TextEditingController get replacedEntityNameController =>
  //     _replacedEntityNameController;
  TextEditingController get autoCompletecontroller => _autoCompletecontroller;
  String get selectedDeviceOrAssetName => _selectedDeviceOrAssetName;
  String get eneteredComment => _eneteredComment;
  String get newComponentsChangedValue => _newComponentsChangedValue;
  String get newIssuesIdentifiedValue => _newIssuesIdentifiedValue;
  String get newTicketStatus => _newTicketStatus;
  String get searchText => _searchText;
  int get fetchedTicketCount => _fetchedTicketCount;
  int get totalTicketsCount => _totalTicketsCount;
  int get totalTicketsCountBasedOnStatus => _totalTicketsCountBasedOnStatus;
  String get ticketStatusValue => _ticketStatusValue;
  String get componentsChangedValue => _componentsChangedValue;
  String get issuesIdentifiedValue => _issuesIdentifiedValue;
  List<Ticket> get tickets => _tickets;
  List get sortByCategories => _sortByCategories;
  Ticket get selectedTicekt => _selectedTicekt;
  List<Ticket> get filteredTickets => _filteredTickets;
  List<Comments> get comments => _comments;
  bool get isComponentChangeFieldEnabled => _isComponentChangeFieldEnabled;
  bool get isTicketsOfSpecificDevice => _isTicketsOfSpecificDevice;
  bool get ticketHasNext => _ticketHasNext;
  DocumentSnapshot? get ticketCursor => _ticketCursor;
  //For Ticket Creation
  TextEditingController get locController => _locController;
  TextEditingController get complaineePHController => _complaineePHController;
  TextEditingController get creationCommentsController =>
      _creationCommentsController;
  String get deviceOrAssetType => _deviceOrAssetType;
  List<String> get availableEntityTypes => _availableEntityTypes;
  String get location => _location;
  String get deviceZone => _deviceZone;
  String get deviceWard => _deviceWard;
  String get deviceRegion => _deviceRegion;
  String get selectedPriority => _selectedPriority;
  String get selectedProblemType => _selectedProblemType;
  String get selectedStatus => _selectedStatus;
  String get selectedContextId => _selectedContextId;
  String get selectedContextType => _selectedContextType;
  String get selectedContextName => _selectedContextName;
  String get selectedAssignee => _selectedAssignee;
  String get selectedcomplainee => _selectedcomplainee;
  String get selectedComplaineePhoneNo => _selectedComplaineePhoneNo;
  String get enteredTicketCreationComments => _enteredTicketCreationComments;
  List<String> get deviceNames => _deviceNames;
  String get ticketDeviceId => _ticketDeviceId;
  double get ticketLatitude => _ticketLatitude;
  double get ticketLongitude => _ticketLongitude;
  List<XFile?> get fetchedCapturedImages => _fetchedCapturedImages;
}
