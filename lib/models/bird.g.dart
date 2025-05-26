
part of 'bird.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BirdAdapter extends TypeAdapter<Bird> {
  @override
  final int typeId = 4;

  @override
  Bird read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bird(
      id: fields[0] as String?,
      type: fields[1] as BirdType,
      imagePath: fields[2] as String?,
      breed: fields[3] as String,
      quantity: fields[4] as int,
      source: fields[5] as SourceType,
      sourceDetail: fields[6] as String?,
      date: fields[7] as DateTime,
      arrivalDate: fields[8] as DateTime?,
      isAlive: fields[9] as bool?,
      healthStatus: fields[10] as String?,
      gender: fields[11] as Gender,
      bandColor: fields[12] as BandColor,
      customBandColor: fields[13] as String?,
      location: fields[14] as String,
      notes: fields[15] as String,
      additionalImages: (fields[16] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Bird obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.breed)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.source)
      ..writeByte(6)
      ..write(obj.sourceDetail)
      ..writeByte(7)
      ..write(obj.date)
      ..writeByte(8)
      ..write(obj.arrivalDate)
      ..writeByte(9)
      ..write(obj.isAlive)
      ..writeByte(10)
      ..write(obj.healthStatus)
      ..writeByte(11)
      ..write(obj.gender)
      ..writeByte(12)
      ..write(obj.bandColor)
      ..writeByte(13)
      ..write(obj.customBandColor)
      ..writeByte(14)
      ..write(obj.location)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.additionalImages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BirdAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BirdTypeAdapter extends TypeAdapter<BirdType> {
  @override
  final int typeId = 0;

  @override
  BirdType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BirdType.chicken;
      case 1:
        return BirdType.duck;
      case 2:
        return BirdType.turkey;
      case 3:
        return BirdType.goose;
      case 4:
        return BirdType.other;
      default:
        return BirdType.chicken;
    }
  }

  @override
  void write(BinaryWriter writer, BirdType obj) {
    switch (obj) {
      case BirdType.chicken:
        writer.writeByte(0);
        break;
      case BirdType.duck:
        writer.writeByte(1);
        break;
      case BirdType.turkey:
        writer.writeByte(2);
        break;
      case BirdType.goose:
        writer.writeByte(3);
        break;
      case BirdType.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BirdTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GenderAdapter extends TypeAdapter<Gender> {
  @override
  final int typeId = 1;

  @override
  Gender read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Gender.male;
      case 1:
        return Gender.female;
      case 2:
        return Gender.unknown;
      default:
        return Gender.male;
    }
  }

  @override
  void write(BinaryWriter writer, Gender obj) {
    switch (obj) {
      case Gender.male:
        writer.writeByte(0);
        break;
      case Gender.female:
        writer.writeByte(1);
        break;
      case Gender.unknown:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BandColorAdapter extends TypeAdapter<BandColor> {
  @override
  final int typeId = 2;

  @override
  BandColor read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BandColor.red;
      case 1:
        return BandColor.pink;
      case 2:
        return BandColor.blue;
      case 3:
        return BandColor.orange;
      case 4:
        return BandColor.green;
      case 5:
        return BandColor.none;
      default:
        return BandColor.red;
    }
  }

  @override
  void write(BinaryWriter writer, BandColor obj) {
    switch (obj) {
      case BandColor.red:
        writer.writeByte(0);
        break;
      case BandColor.pink:
        writer.writeByte(1);
        break;
      case BandColor.blue:
        writer.writeByte(2);
        break;
      case BandColor.orange:
        writer.writeByte(3);
        break;
      case BandColor.green:
        writer.writeByte(4);
        break;
      case BandColor.none:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BandColorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SourceTypeAdapter extends TypeAdapter<SourceType> {
  @override
  final int typeId = 3;

  @override
  SourceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SourceType.egg;
      case 1:
        return SourceType.store;
      default:
        return SourceType.egg;
    }
  }

  @override
  void write(BinaryWriter writer, SourceType obj) {
    switch (obj) {
      case SourceType.egg:
        writer.writeByte(0);
        break;
      case SourceType.store:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
