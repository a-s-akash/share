import 'package:hive/hive.dart';
part 'ppe_queue_item.g.dart';

@HiveType(typeId: 3)
class PpeQueueItem extends HiveObject {
  @HiveField(0)
  String sessionId;

  /// Absolute path to the compressed PPE image on device
  @HiveField(1)
  String imagePath;

  @HiveField(2)
  int timestamp;

  @HiveField(3)
  bool uploaded;

  PpeQueueItem({
    required this.sessionId,
    required this.imagePath,
    required this.timestamp,
    this.uploaded = false,
  });
}
