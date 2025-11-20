// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TicketCacheAdapter extends TypeAdapter<TicketCache> {
  @override
  final int typeId = 0;

  @override
  TicketCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TicketCache(
      id: fields[0] as String,
      referenceNumber: fields[1] as String,
      name: fields[2] as String,
      facility: fields[3] as String,
      amount: fields[4] as double,
      visitDate: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
      isValid: fields[7] as bool,
      imageUrl: fields[8] as String?,
      email: fields[9] as String?,
      phone: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TicketCache obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.referenceNumber)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.facility)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.visitDate)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isValid)
      ..writeByte(8)
      ..write(obj.imageUrl)
      ..writeByte(9)
      ..write(obj.email)
      ..writeByte(10)
      ..write(obj.phone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
