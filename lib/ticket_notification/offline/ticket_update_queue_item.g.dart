// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_update_queue_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TicketUpdateQueueItemAdapter extends TypeAdapter<TicketUpdateQueueItem> {
  @override
  final int typeId = 5;

  @override
  TicketUpdateQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TicketUpdateQueueItem(
      alarmId: fields[0] as String,
      ticketId: fields[1] as String,
      deviceId: fields[2] as String,
      deviceType: fields[3] as String,
      updateType: fields[4] as String,
      actions: fields[5] as String,
      comments: fields[6] as String,
      payloadJson: fields[7] as String,
      updatedAtEpochMs: fields[8] as int,
      createdByEmail: fields[9] as String,
      uploaded: fields[10] as bool,
      attemptCount: fields[11] as int,
      lastAttemptEpochMs: fields[12] as int?,
      lastError: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TicketUpdateQueueItem obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.alarmId)
      ..writeByte(1)
      ..write(obj.ticketId)
      ..writeByte(2)
      ..write(obj.deviceId)
      ..writeByte(3)
      ..write(obj.deviceType)
      ..writeByte(4)
      ..write(obj.updateType)
      ..writeByte(5)
      ..write(obj.actions)
      ..writeByte(6)
      ..write(obj.comments)
      ..writeByte(7)
      ..write(obj.payloadJson)
      ..writeByte(8)
      ..write(obj.updatedAtEpochMs)
      ..writeByte(9)
      ..write(obj.createdByEmail)
      ..writeByte(10)
      ..write(obj.uploaded)
      ..writeByte(11)
      ..write(obj.attemptCount)
      ..writeByte(12)
      ..write(obj.lastAttemptEpochMs)
      ..writeByte(13)
      ..write(obj.lastError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketUpdateQueueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
