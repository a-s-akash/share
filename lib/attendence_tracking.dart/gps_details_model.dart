import 'package:hive/hive.dart';
part 'gps_details_model.g.dart';

@HiveType(typeId: 1)
class TravelLocationEntity extends HiveObject {
  @HiveField(0)
  double lat;

  @HiveField(1)
  double long;

  @HiveField(2)
  int timestamp;

  TravelLocationEntity({
    required this.lat,
    required this.long,
    required this.timestamp,
  });
}
