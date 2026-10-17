import 'dart:convert';
import 'dart:developer';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../utils/constants.dart';
import '../../utils/utility.dart';
import '../ticket_model.dart';
import '../ticket_service.dart';
import 'ticket_queue_item.dart';
import 'ticket_update_queue_item.dart';

enum TicketSubmitOutcome { createdOnline, queuedOffline }

class TicketSubmitResult {
  final TicketSubmitOutcome outcome;
  final String alarmId;
  final String? ticketId;

  const TicketSubmitResult._(this.outcome, this.alarmId, this.ticketId);

  factory TicketSubmitResult.createdOnline(String alarmId, String ticketId) =>
      TicketSubmitResult._(
          TicketSubmitOutcome.createdOnline, alarmId, ticketId);

  factory TicketSubmitResult.queuedOffline(String alarmId) =>
      TicketSubmitResult._(TicketSubmitOutcome.queuedOffline, alarmId, null);

  bool get isCreatedOnline => outcome == TicketSubmitOutcome.createdOnline;
}

enum TicketUpdateOutcome { updatedOnline, queuedOffline }

class TicketUpdateResult {
  final TicketUpdateOutcome outcome;

  const TicketUpdateResult._(this.outcome);

  static const updatedOnline =
      TicketUpdateResult._(TicketUpdateOutcome.updatedOnline);

  static const queuedOffline =
      TicketUpdateResult._(TicketUpdateOutcome.queuedOffline);

  bool get isUpdatedOnline => outcome == TicketUpdateOutcome.updatedOnline;
}

/// Single seam deciding whether a ticket is written live or queued locally.
///
/// Nothing else — not the UI, not the sync engine — makes this decision
/// independently, so there is exactly one place that can get it wrong.
class TicketRepository {
  final TicketService _service = TicketService();

  Future<TicketSubmitResult> submit({
    required dynamic context,
    required dynamic ref,
    required Map<String, dynamic> postData,
    required String deviceType,
    required String problemType,
    required String comments,
    required String locationText,
    required double latitude,
    required double longitude,
    required double tlatitude,
    required double tlongitude,
    required String createdByEmail,
  }) async {
    final alarmId = const Uuid().v4();
    // Included so the backend can dedupe if the same locally-queued ticket
    // is ever retried after a partial success (see sync engine retry policy).
    postData['alarm_id'] = alarmId;

    if (await Utility.isConnected()) {
      try {
        final res = await _service.createTicketServiceFB(postData);
        if (res != null && res['status'] == 'success') {
          final ticketId = res['ticketId']?.toString() ?? '';
          await _putSyncedIntoListBox(
            alarmId: alarmId,
            ticketId: ticketId,
            postData: postData,
            deviceType: deviceType,
            problemType: problemType,
            comments: comments,
            locationText: locationText,
            createdByEmail: createdByEmail,
          );
          return TicketSubmitResult.createdOnline(alarmId, ticketId);
        }
        log('[TicketSync] online create rejected by server, queuing alarmId=$alarmId');
      } catch (e) {
        // Connectivity can drop between the isConnected() check and the
        // write itself — fall back to the queue rather than losing the ticket.
        log('[TicketSync] online create threw, queuing alarmId=$alarmId: $e');
      }
    }

    await _queueLocally(
      alarmId: alarmId,
      postData: postData,
      deviceType: deviceType,
      problemType: problemType,
      comments: comments,
      locationText: locationText,
      latitude: latitude,
      longitude: longitude,
      tlatitude: tlatitude,
      tlongitude: tlongitude,
      createdByEmail: createdByEmail,
    );
    return TicketSubmitResult.queuedOffline(alarmId);
  }

  /// Builds the same Ticket shape TicketProvider.getLocalTicketsList would
  /// eventually produce for this ticket, so it doesn't have to wait for the
  /// next login/splash refresh to show up in My Tickets.
  ///
  /// [alarmId] is the ticket's permanent identity — the same value sent as
  /// `alarm_id` at creation, the ticketListBox key for its whole lifetime,
  /// and what submitUpdate/updateTicketServiceFB key updates off of. It
  /// never changes once assigned. [ticketId] is only the human-readable
  /// ticket number the server assigns on sync, purely for display — the two
  /// must never be conflated, or an update call ends up looking up the
  /// ticket by its display number instead of its real identity and 404s.
  Ticket _buildListEntry({
    required String deviceType,
    required String problemType,
    required String comments,
    required String locationText,
    required Map<String, dynamic> postData,
    required String createdByEmail,
    required bool synced,
    required String alarmId,
    String? localId,
    String? ticketId,
  }) {
    return Ticket(
      alarmId: alarmId,
      ticketId: ticketId,
      ticketStatus: 'Open',
      deviceId: postData['entity_name']?.toString() ?? '',
      entityType: deviceType,
      complaineeType: postData['complainee']?.toString() ?? '',
      complainee: postData['ticket_opened_by']?.toString() ?? '',
      priority: postData['priority']?.toString() ?? 'Indeterminate',
      location: locationText,
      problemType: problemType,
      comment: comments,
      deviceType: deviceType,
      latitude: postData['latitude']?.toString() ?? '',
      longitude: postData['longitude']?.toString() ?? '',
      assignee: postData['assignee']?.toString() ?? '',
      // getDurationFB (ticket_controller.dart) parses this with the strict
      // "yyyy-MM-dd HH:mm:ss" format used everywhere else in this box — not
      // ISO8601 — or it throws a FormatException while building the card.
      createdTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      ward: postData['ward']?.toString() ?? '',
      zone: postData['zone']?.toString() ?? '',
      region: postData['region']?.toString() ?? '',
      customer: postData['customer']?.toString() ?? '',
      auditTrail: postData['audit_trail'] != null
          ? List<dynamic>.from(postData['audit_trail'])
          : null,
      localId: localId,
      synced: synced,
    );
  }

  Future<void> _putSyncedIntoListBox({
    required String alarmId,
    required String ticketId,
    required Map<String, dynamic> postData,
    required String deviceType,
    required String problemType,
    required String comments,
    required String locationText,
    required String createdByEmail,
  }) async {
    if (ticketId.isEmpty) return;
    final box = await Utility.openHiveBox(ticketListBox);
    final ticket = _buildListEntry(
      deviceType: deviceType,
      problemType: problemType,
      comments: comments,
      locationText: locationText,
      postData: postData,
      createdByEmail: createdByEmail,
      synced: true,
      alarmId: alarmId,
      ticketId: ticketId,
    );
    await box.put(alarmId, ticket.toJson());
  }

  Future<void> _queueLocally({
    required String alarmId,
    required Map<String, dynamic> postData,
    required String deviceType,
    required String problemType,
    required String comments,
    required String locationText,
    required double latitude,
    required double longitude,
    required double tlatitude,
    required double tlongitude,
    required String createdByEmail,
  }) async {
    final box = await Hive.openBox<TicketQueueItem>(ticketQueueBox);
    final item = TicketQueueItem(
      alarmId: alarmId,
      deviceType: deviceType,
      deviceId: postData['entity_name']?.toString() ?? '',
      problemType: problemType,
      comments: comments,
      locationText: locationText,
      latitude: latitude,
      longitude: longitude,
      payloadJson: jsonEncode(postData),
      createdAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      createdByEmail: createdByEmail,
      tlatitude: tlatitude,
      tlongitude: tlongitude,
    );
    await box.put(alarmId, item);
    log('[TicketSync] queued ticket alarmId=$alarmId (device=$deviceType, problem=$problemType)');

    // Mirror into ticketListBox, keyed by the same alarmId the queue item
    // and _reconcileListBoxEntry (connectivity_sync_service.dart) key off
    // of, so it shows up in My Tickets immediately with the "Not Synced"
    // badge instead of waiting for this to sync.
    final listBox = await Utility.openHiveBox(ticketListBox);
    final ticket = _buildListEntry(
      deviceType: deviceType,
      problemType: problemType,
      comments: comments,
      locationText: locationText,
      postData: postData,
      createdByEmail: createdByEmail,
      synced: false,
      alarmId: alarmId,
      localId: alarmId,
    );
    await listBox.put(alarmId, ticket.toJson());
  }

  /// Same seam as [submit], for updates to an existing ticket (status,
  /// issue identified, components changed, comments).
  ///
  /// The queue holds at most one entry per ticket, keyed by [alarmId]. If the
  /// ticket already has a pending entry, this update is merged into it, and
  /// the merged payload is what goes out (online now, or on the next sync),
  /// so an older queued update can never land after a newer one.
  Future<TicketUpdateResult> submitUpdate({
    required dynamic context,
    required dynamic ref,
    required String alarmId,
    required Map<String, dynamic> postData,
    required String updateType,
    required String ticketId,
    required String deviceId,
    required String deviceType,
    required List<String> actions,
    required String comments,
    required String createdByEmail,
  }) async {
    // Reopen so a pending entry the background isolate has already synced
    // isn't seen here as still pending.
    await Utility.refreshTicketQueueBox();
    final box = Hive.box<TicketUpdateQueueItem>(ticketUpdateQueueBox);
    final pending = box.get(alarmId);
    final hasPending = pending != null && !pending.uploaded;

    // A ticket created offline has no Firestore doc under [alarmId] until
    // its create syncs, so its updates always queue and follow the create.
    final create = Hive.box<TicketQueueItem>(ticketQueueBox).get(alarmId);
    final isCreatePending = create != null && !create.uploaded;

    // What gets queued: this update with its comment recorded as an action,
    // folded into any pending entry. A plain online update with nothing
    // pending goes out exactly as built.
    final payload = hasPending
        ? _mergeUpdatePayloads(
            jsonDecode(pending.payloadJson) as Map<String, dynamic>,
            _withCommentAction(postData))
        : _withCommentAction(postData);

    // Local-first, online or offline: the queue entry and the My Tickets
    // list entry are both written from [payload] (the fully merged latest
    // edit) before any network call is attempted — so the edit is never
    // lost, and the ticket always shows its latest edited state immediately,
    // the same way it did the moment it was typed, whether or not the
    // network call below ends up succeeding.
    final audit = Map<String, dynamic>.from(payload['audit_trail'] ?? {});
    final item = TicketUpdateQueueItem(
      alarmId: alarmId,
      ticketId: ticketId,
      deviceId: deviceId,
      deviceType: deviceType,
      updateType: hasPending && pending.updateType == 'details'
          ? 'details'
          : updateType,
      actions: List<String>.from(audit['actions'] ?? []).join('; '),
      comments: payload['comments'] ?? '',
      payloadJson: jsonEncode(payload),
      updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      createdByEmail: createdByEmail,
      attemptCount: hasPending ? pending.attemptCount : 0,
    );
    await box.put(alarmId, item);
    log('[TicketUpdateSync] ${hasPending ? 'merged' : 'queued'} $updateType update (ticket=$ticketId)');
    await _applyUpdateToListBox(
        alarmId, payload, Map<String, dynamic>.from(postData['audit_trail']));

    if (!isCreatePending && await Utility.isConnected()) {
      try {
        final res = await _service.updateTicketServiceFB(
            context, ref, alarmId, hasPending ? payload : postData);
        if (res == 1) {
          item.uploaded = true;
          item.lastAttemptEpochMs = DateTime.now().millisecondsSinceEpoch;
          item.lastError = null;
          await item.save();
          await _setPendingUpdateFlag(alarmId, false);
          return TicketUpdateResult.updatedOnline;
        }
        log('[TicketUpdateSync] online update rejected by server, queuing ticket=$ticketId');
      } catch (e) {
        // Connectivity can drop between the isConnected() check and the
        // write itself — the update stays queued (already written above)
        // rather than being lost.
        log('[TicketUpdateSync] online update threw, queuing ticket=$ticketId: $e');
      }
    }

    return TicketUpdateResult.queuedOffline;
  }

  /// Flags (or clears) the "Update Pending" badge on this ticket's
  /// ticketListBox entry, if it has one — a ticket not in that box (not
  /// part of "My Tickets") has nothing to patch.
  Future<void> _setPendingUpdateFlag(String alarmId, bool pending) async {
    final box = await Utility.openHiveBox(ticketListBox);
    final raw = box.get(alarmId);
    if (raw == null) return;
    final ticket = Ticket.fromJson(Map<String, dynamic>.from(raw));
    if (ticket.hasPendingUpdate == pending) return;
    ticket.hasPendingUpdate = pending;
    await box.put(alarmId, ticket.toJson());
  }

  /// Patches this ticket's ticketListBox entry with [payload]'s fields —
  /// the same mapping TicketProvider._applyUpdatePayload uses for the
  /// in-memory ticket — so My Tickets shows the edit immediately, and still
  /// shows it correctly once the update actually syncs (nothing else patches
  /// content again at that point; only the pending flag changes then). A
  /// ticket not present in the box (not part of "My Tickets") has nothing
  /// to patch.
  ///
  /// [auditEntry] is this update's own audit entry (with its comment), not
  /// the merged queue payload's: the merged one repeats every earlier action
  /// and carries its comments only as "Commented: ..." actions, so appending
  /// it would duplicate history and hide the comment from the comment list.
  Future<void> _applyUpdateToListBox(String alarmId,
      Map<String, dynamic> payload, Map<String, dynamic> auditEntry) async {
    final box = await Utility.openHiveBox(ticketListBox);
    final raw = box.get(alarmId);
    if (raw == null) return;
    final ticket = Ticket.fromJson(Map<String, dynamic>.from(raw));
    if (payload.containsKey('status')) {
      ticket.ticketStatus = payload['status'];
    }
    if (payload.containsKey('issue_identified')) {
      ticket.issuesIdentified = payload['issue_identified'];
    }
    if (payload.containsKey('components_changed')) {
      ticket.componentsChanged = payload['components_changed'];
    }
    if (payload.containsKey('comments')) {
      ticket.comment = payload['comments'];
    }
    ticket.auditTrail = [...?ticket.auditTrail, auditEntry];
    ticket.hasPendingUpdate = true;
    await box.put(alarmId, ticket.toJson());
  }

  /// Moves this update's audit-trail comment into its actions as
  /// "Commented: ...", so in the offline payload each comment lives only in
  /// the trail's actions, in the order it was made (no separate
  /// audit_trail.comment to duplicate it). The top-level `comments` field is
  /// left as-is. Applied once per update, as it is queued, so a comment is
  /// never turned into an action twice.
  Map<String, dynamic> _withCommentAction(Map<String, dynamic> postData) {
    final audit = Map<String, dynamic>.from(postData['audit_trail'] ?? {});
    final comment = audit['comment']?.toString() ?? '';
    if (comment.isEmpty) return postData;
    return {
      ...postData,
      'audit_trail': {
        ...audit,
        'actions': [
          ...List.from(audit['actions'] ?? []),
          'Commented: $comment'
        ],
        'comment': '',
      },
    };
  }

  static String? _formatAttachmentAction(dynamic attachment) {
    if (attachment == null) return null;
    if (attachment is List && attachment.isNotEmpty) {
      final uuids = attachment
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (uuids.isEmpty) return null;
      return 'attachment : ${uuids.join(', ')}';
    } else if (attachment is String && attachment.trim().isNotEmpty) {
      return 'attachment : ${attachment.trim()}';
    }
    return null;
  }

  /// Folds [newer] into [older]: newer fields win — so top-level `comments`
  /// is always the latest comment — and the audit trail keeps every action
  /// (comments included) in order.
  ///
  /// When multiple offline updates occur, only the latest operation's images
  /// stay in `audit_trail.attachment`. Earlier operations' image UUIDs are
  /// recorded into `actions` as "attachment : uuid1, uuid2, uuid3".
  Map<String, dynamic> _mergeUpdatePayloads(
      Map<String, dynamic> older, Map<String, dynamic> newer) {
    final olderAudit = Map<String, dynamic>.from(older['audit_trail'] ?? {});
    final newerAudit = Map<String, dynamic>.from(newer['audit_trail'] ?? {});
    final newerAttachment = newerAudit['attachment'];
    final olderAttachment = olderAudit['attachment'];

    final olderActions = List<String>.from(olderAudit['actions'] ?? []);
    final newerActions = List<String>.from(newerAudit['actions'] ?? []);

    final hasNewerAttachment = newerAttachment != null &&
        ((newerAttachment is List && newerAttachment.isNotEmpty) ||
            (newerAttachment is String && newerAttachment.trim().isNotEmpty));

    final hasOlderAttachment = olderAttachment != null &&
        ((olderAttachment is List && olderAttachment.isNotEmpty) ||
            (olderAttachment is String && olderAttachment.trim().isNotEmpty));

    dynamic resolvedAttachment;

    if (hasNewerAttachment) {
      // Newer operation has its own attachments.
      // Save all older operations' audit image UUIDs in actions like:
      // "attachment : uuid1, uuid2, uuid3"
      if (hasOlderAttachment) {
        final olderAction = _formatAttachmentAction(olderAttachment);
        if (olderAction != null && !olderActions.contains(olderAction)) {
          olderActions.add(olderAction);
        }
      }
      resolvedAttachment = newerAttachment;
    } else {
      // Newer operation did not capture new attachments; keep older attachment as latest.
      resolvedAttachment = hasOlderAttachment ? olderAttachment : "";
    }

    return {
      ...older,
      ...newer,
      'audit_trail': {
        ...newerAudit,
        'actions': [
          ...olderActions,
          ...newerActions,
        ],
        'attachment': resolvedAttachment,
      },
    };
  }

  /// Deletes tickets that have already synced, once they're older than
  /// [days]. Mirrors LampProvider.cleanupExportedLampData: throttled to run
  /// at most once a day, called once at app startup rather than from the
  /// recurring sync cycle.
  Future<void> cleanupSyncedTickets({int days = 7}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRun = prefs.getInt('ticket_cleanup_ts') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastRun < const Duration(hours: 24).inMilliseconds) {
      return;
    }

    final box = await Hive.openBox<TicketQueueItem>(ticketQueueBox);
    final expiry = days * 24 * 60 * 60 * 1000;

    final List<int> deleteIndexes = [];

    for (int i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item != null &&
          item.uploaded &&
          item.lastAttemptEpochMs != null &&
          now - item.lastAttemptEpochMs! >= expiry) {
        deleteIndexes.add(i);
      }
    }

    // Delete from last index to avoid shifting.
    for (final i in deleteIndexes.reversed) {
      await box.deleteAt(i);
    }

    final updateBox =
        await Hive.openBox<TicketUpdateQueueItem>(ticketUpdateQueueBox);
    final syncedUpdateKeys = updateBox.keys.where((k) {
      final item = updateBox.get(k);
      return item != null &&
          item.uploaded &&
          item.lastAttemptEpochMs != null &&
          now - item.lastAttemptEpochMs! >= expiry;
    }).toList();
    await updateBox.deleteAll(syncedUpdateKeys);

    await prefs.setInt('ticket_cleanup_ts', now);

    log('[TicketSync] Deleted ${deleteIndexes.length} synced ticket records, ${syncedUpdateKeys.length} synced ticket update records');
  }
}
