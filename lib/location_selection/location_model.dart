// import 'package:hive/hive.dart';

// part 'location_model.g.dart';

// @HiveType(typeId: 1)
// class Ward extends HiveObject {
//   @HiveField(0)
//   String id;
//   @HiveField(1)
//   String name;
//   @HiveField(2)
//   String label;

//   Ward({required this.id, required this.name, required this.label});
// }

// @HiveType(typeId: 2)
// class Zone extends HiveObject {
//   @HiveField(0)
//   String id;
//   @HiveField(1)
//   String name;
//   @HiveField(2)
//   String label;
//   @HiveField(3)
//   Map<String, Ward> wards;

//   Zone(
//       {required this.id,
//       required this.name,
//       required this.label,
//       required this.wards});
// }

// @HiveType(typeId: 3)
// class Region extends HiveObject {
//   @HiveField(0)
//   String id;
//   @HiveField(1)
//   String name;
//   @HiveField(2)
//   Map<String, Zone> zones;

//   Region({required this.id, required this.name, required this.zones});
// }

// @HiveType(typeId: 4)
// class Customer extends HiveObject {
//   @HiveField(0)
//   String id;
//   @HiveField(1)
//   String name;
//   @HiveField(2)
//   Map<String, Region> regions;

//   Customer({required this.id, required this.name, required this.regions});
// }
