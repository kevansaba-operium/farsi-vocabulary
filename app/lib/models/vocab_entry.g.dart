// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VocabEntryAdapter extends TypeAdapter<VocabEntry> {
  @override
  final int typeId = 0;

  @override
  VocabEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabEntry(
      id: fields[0] as String,
      farsi: fields[1] as String,
      transliteration: fields[2] as String,
      english: fields[3] as String,
      partOfSpeech: fields[4] as String?,
      notes: fields[5] as String,
      examples: (fields[6] as List).cast<VocabExample>(),
      imagePath: fields[7] as String?,
      tags: (fields[8] as List).cast<String>(),
      sourceFile: fields[9] as String,
      lessonNumber: fields[10] as int?,
      date: fields[11] as String?,
      needsReview: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VocabEntry obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.farsi)
      ..writeByte(2)
      ..write(obj.transliteration)
      ..writeByte(3)
      ..write(obj.english)
      ..writeByte(4)
      ..write(obj.partOfSpeech)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.examples)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.sourceFile)
      ..writeByte(10)
      ..write(obj.lessonNumber)
      ..writeByte(11)
      ..write(obj.date)
      ..writeByte(12)
      ..write(obj.needsReview);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VocabExampleAdapter extends TypeAdapter<VocabExample> {
  @override
  final int typeId = 1;

  @override
  VocabExample read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabExample(
      farsi: fields[0] as String,
      transliteration: fields[1] as String,
      english: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, VocabExample obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.farsi)
      ..writeByte(1)
      ..write(obj.transliteration)
      ..writeByte(2)
      ..write(obj.english);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabExampleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
