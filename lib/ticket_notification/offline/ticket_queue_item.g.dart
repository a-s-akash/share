// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_queue_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TicketQueueItemAdapter extends TypeAdapter<TicketQueueItem> {
  @override
  final int typeId = 4;

  @override
  TicketQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TicketQueueItem(
      alarmId: fields[0] as String,
      remoteTicketId: fields[1] as String?,
      deviceType: fields[2] as String,
      deviceId: fields[17] as String,
      problemType: fields[3] as String,
      comments: fields[4] as String,
      locationText: fields[5] as String,
      latitude: fields[6] as double,
      longitude: fields[7] as double,
      payloadJson: fields[8] as String,
      createdAtEpochMs: fields[9] as int,
      createdByEmail: fields[10] as String,
      uploaded: fields[11] as bool,
      attemptCount: fields[12] as int,
      tlatitude: fields[13] as double,
      tlongitude: fields[14] as double,
      lastAttemptEpochMs: fields[15] as int?,
      lastError: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TicketQueueItem obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.alarmId)
      ..writeByte(1)
      ..write(obj.remoteTicketId)
      ..writeByte(2)
      ..write(obj.deviceType)
      ..writeByte(17)
      ..write(obj.deviceId)
      ..writeByte(3)
      ..write(obj.problemType)
      ..writeByte(4)
      ..write(obj.comments)
      ..writeByte(5)
      ..write(obj.locationText)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude)
      ..writeByte(8)
      ..write(obj.payloadJson)
      ..writeByte(9)
      ..write(obj.createdAtEpochMs)
      ..writeByte(10)
      ..write(obj.createdByEmail)
      ..writeByte(11)
      ..write(obj.uploaded)
      ..writeByte(12)
      ..write(obj.attemptCount)
      ..writeByte(13)
      ..write(obj.tlatitude)
      ..writeByte(14)
      ..write(obj.tlongitude)
      ..writeByte(15)
      ..write(obj.lastAttemptEpochMs)
      ..writeByte(16)
      ..write(obj.lastError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketQueueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
