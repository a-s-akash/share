import 'package:hive/hive.dart';
part 'pole_history_model.g.dart';

@HiveType(typeId: 0) // must be unique for each Hive model
class InstallationHistory extends HiveObject {
  @HiveField(0)
  String date;

  @HiveField(1)
  int pole;

  @HiveField(2)
  int switchPoint;

  @HiveField(3)
  int transformer;

  @HiveField(4)
  String wardId;

  @HiveField(5)
  String usermail;

  InstallationHistory({
    required this.date,
    required this.pole,
    required this.switchPoint,
    required this.transformer,
    required this.wardId,
    required this.usermail,
  });
}
