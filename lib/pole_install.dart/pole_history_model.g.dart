// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pole_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstallationHistoryAdapter extends TypeAdapter<InstallationHistory> {
  @override
  final int typeId = 0;

  @override
  InstallationHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationHistory(
      date: fields[0] as String,
      pole: fields[1] as int,
      switchPoint: fields[2] as int,
      transformer: fields[3] as int,
      wardId: fields[4] as String,
      usermail: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationHistory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.pole)
      ..writeByte(2)
      ..write(obj.switchPoint)
      ..writeByte(3)
      ..write(obj.transformer)
      ..writeByte(4)
      ..write(obj.wardId)
      ..writeByte(5)
      ..write(obj.usermail);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
