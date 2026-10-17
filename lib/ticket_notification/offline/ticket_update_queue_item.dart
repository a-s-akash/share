import 'package:hive/hive.dart';

part 'ticket_update_queue_item.g.dart';

/// The latest pending offline update (status / issue / components / comment)
/// for one ticket, queued for sync once connectivity returns.
///
/// Stored under the ticket's [alarmId] as the Hive key, so there is at most
/// one entry per ticket: further offline updates to the same ticket are
/// merged into it (see TicketRepository.submitUpdate) rather than queued
/// separately. [payloadJson] is the merged postData that will be sent to
/// updateTicketServiceFB.
///
/// Same sync semantics as [TicketQueueItem]: a plain [uploaded] flag, and
/// [attemptCount]/[lastError] are diagnostic-only; they don't gate retries.
///
/// [updateType] is 'details' (UPDATE button) or 'comment' (comment send);
/// once any merged update is 'details', the entry stays 'details'.
@HiveType(typeId: 5)
class TicketUpdateQueueItem extends HiveObject {
  @HiveField(0)
  String alarmId;

  @HiveField(1)
  String ticketId;

  @HiveField(2)
  String deviceId;

  @HiveField(3)
  String deviceType;

  @HiveField(4)
  String updateType;

  @HiveField(5)
  String actions;

  @HiveField(6)
  String comments;

  @HiveField(7)
  String payloadJson;

  @HiveField(8)
  int updatedAtEpochMs;

  @HiveField(9)
  String createdByEmail;

  @HiveField(10)
  bool uploaded;

  @HiveField(11)
  int attemptCount;

  @HiveField(12)
  int? lastAttemptEpochMs;

  @HiveField(13)
  String? lastError;

  TicketUpdateQueueItem({
    required this.alarmId,
    required this.ticketId,
    required this.deviceId,
    required this.deviceType,
    required this.updateType,
    required this.actions,
    required this.comments,
    required this.payloadJson,
    required this.updatedAtEpochMs,
    required this.createdByEmail,
    this.uploaded = false,
    this.attemptCount = 0,
    this.lastAttemptEpochMs,
    this.lastError,
  });
}
