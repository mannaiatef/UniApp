// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'specialty.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpecialtyAdapter extends TypeAdapter<Specialty> {
  @override
  final int typeId = 1;

  @override
  Specialty read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Specialty(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      videoUrl: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Specialty obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.videoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialtyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
