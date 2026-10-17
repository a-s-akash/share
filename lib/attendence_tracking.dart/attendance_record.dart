import 'package:hive/hive.dart';
part 'attendance_record.g.dart';

@HiveType(typeId: 2)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  String sessionId;

  /// "login" or "logout"
  @HiveField(1)
  String type;

  /// Original event timestamp in milliseconds (offline capture time)
  @HiveField(2)
  int timestamp;

  @HiveField(3)
  double latitude;

  @HiveField(4)
  double longitude;

  @HiveField(5)
  bool synced;

  AttendanceRecord({
    required this.sessionId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.synced = false,
  });
}
