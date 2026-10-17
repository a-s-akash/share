// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ppe_queue_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PpeQueueItemAdapter extends TypeAdapter<PpeQueueItem> {
  @override
  final int typeId = 3;

  @override
  PpeQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PpeQueueItem(
      sessionId: fields[0] as String,
      imagePath: fields[1] as String,
      timestamp: fields[2] as int,
      uploaded: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PpeQueueItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.uploaded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PpeQueueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
