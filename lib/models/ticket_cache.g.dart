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
      age: fields[2] as int?,
      facility: fields[3] as String,
      amount: fields[4] as double,
      visitDate: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
      transactionStatus: fields[7] as String,
      ageCategory: fields[8] as String?,
      amountDue: fields[9] as double?,
      changeAmount: fields[10] as double?,
      ticketType: fields[11] as String?,
      totalPeople: fields[12] as int?,
      peopleBelow12: fields[13] as int?,
      people12Above: fields[14] as int?,
      isClubMember: fields[15] as bool?,
      isResident: fields[16] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, TicketCache obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.referenceNumber)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.facility)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.visitDate)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.transactionStatus)
      ..writeByte(8)
      ..write(obj.ageCategory)
      ..writeByte(9)
      ..write(obj.amountDue)
      ..writeByte(10)
      ..write(obj.changeAmount)
      ..writeByte(11)
      ..write(obj.ticketType)
      ..writeByte(12)
      ..write(obj.totalPeople)
      ..writeByte(13)
      ..write(obj.peopleBelow12)
      ..writeByte(14)
      ..write(obj.people12Above)
      ..writeByte(15)
      ..write(obj.isClubMember)
      ..writeByte(16)
      ..write(obj.isResident);
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
