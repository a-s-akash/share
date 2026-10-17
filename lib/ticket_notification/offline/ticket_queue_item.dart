import 'package:hive/hive.dart';

part 'ticket_queue_item.g.dart';

/// A ticket created while offline, queued for sync once connectivity returns.
///
/// [payloadJson] is the exact JSON-encoded postData that would have been sent
/// to createTicketServiceFB — keeping the sync payload self-contained so a
/// sync run months later doesn't depend on any other Hive box still holding
/// the same lookup data (region/zone names, device type, etc.) it was built from.
///
/// Sync state is a plain [uploaded] flag, same as AttendanceRecord.synced and
/// PpeQueueItem.uploaded — no separate "syncing"/"failed" states, so retries
/// just happen naturally on the next sync cycle like every other offline
/// queue in this app. [attemptCount]/[lastError] are diagnostic-only; they
/// don't gate retries.
@HiveType(typeId: 4)
class TicketQueueItem extends HiveObject {
  @HiveField(0)
  String alarmId;

  @HiveField(1)
  String? remoteTicketId;

  @HiveField(2)
  String deviceType;

  @HiveField(3)
  String problemType;

  @HiveField(4)
  String comments;

  @HiveField(5)
  String locationText;

  @HiveField(6)
  double latitude;

  @HiveField(7)
  double longitude;

  @HiveField(8)
  String payloadJson;

  @HiveField(9)
  int createdAtEpochMs;

  @HiveField(10)
  String createdByEmail;

  @HiveField(11)
  bool uploaded;

  @HiveField(12)
  int attemptCount;

  @HiveField(13)
  double tlatitude;

  @HiveField(14)
  double tlongitude;

  @HiveField(15)
  int? lastAttemptEpochMs;

  @HiveField(16)
  String? lastError;

  @HiveField(17)
  String deviceId;

  TicketQueueItem({
    required this.alarmId,
    this.remoteTicketId,
    required this.deviceType,
    required this.deviceId,
    required this.problemType,
    required this.comments,
    required this.locationText,
    required this.latitude,
    required this.longitude,
    required this.payloadJson,
    required this.createdAtEpochMs,
    required this.createdByEmail,
    required this.tlatitude,
    required this.tlongitude,
    this.uploaded = false,
    this.attemptCount = 0,
    this.lastAttemptEpochMs,
    this.lastError,
  });
}
