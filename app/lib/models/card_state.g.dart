// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardStateAdapter extends TypeAdapter<CardState> {
  @override
  final int typeId = 2;

  @override
  CardState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardState(
      entryId: fields[0] as String,
      easeFactor: fields[1] as double,
      repetitions: fields[2] as int,
      intervalDays: fields[3] as int,
      nextDueMs: fields[4] as int?,
      totalReviews: fields[5] as int,
      isFavorite: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CardState obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.entryId)
      ..writeByte(1)
      ..write(obj.easeFactor)
      ..writeByte(2)
      ..write(obj.repetitions)
      ..writeByte(3)
      ..write(obj.intervalDays)
      ..writeByte(4)
      ..write(obj.nextDueMs)
      ..writeByte(5)
      ..write(obj.totalReviews)
      ..writeByte(6)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
