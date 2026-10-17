// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_details_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TravelLocationEntityAdapter extends TypeAdapter<TravelLocationEntity> {
  @override
  final int typeId = 1;

  @override
  TravelLocationEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TravelLocationEntity(
      lat: fields[0] as double,
      long: fields[1] as double,
      timestamp: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TravelLocationEntity obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.lat)
      ..writeByte(1)
      ..write(obj.long)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelLocationEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
