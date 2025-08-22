import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

part 'bird.g.dart';

@HiveType(typeId: 0)
enum BirdType {
  @HiveField(0)
  chicken,
  @HiveField(1)
  duck,
  @HiveField(2)
  turkey,
  @HiveField(3)
  goose,
  @HiveField(4)
  other,
}

@HiveType(typeId: 1)
enum Gender {
  @HiveField(0)
  male,
  @HiveField(1)
  female,
  @HiveField(2)
  unknown,
}

@HiveType(typeId: 2)
enum BandColor {
  @HiveField(0)
  red,
  @HiveField(1)
  pink,
  @HiveField(2)
  blue,
  @HiveField(3)
  orange,
  @HiveField(4)
  green,
  @HiveField(5)
  none,
}

@HiveType(typeId: 3)
enum SourceType {
  @HiveField(0)
  egg,
  @HiveField(1)
  store,
}

@HiveType(typeId: 4)
class Bird extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final BirdType type;
  @HiveField(2)
  String? imagePath;
  @HiveField(3)
  String breed;
  @HiveField(4)
  int quantity;
  @HiveField(5)
  SourceType source;
  @HiveField(6)
  String? sourceDetail;
  @HiveField(7)
  DateTime date;
  @HiveField(8)
  DateTime? arrivalDate;
  @HiveField(9)
  bool? isAlive;
  @HiveField(10)
  String? healthStatus;
  @HiveField(11)
  Gender gender;
  @HiveField(12)
  BandColor bandColor;
  @HiveField(13)
  String? customBandColor;
  @HiveField(14)
  String location;
  @HiveField(15)
  String notes;
  @HiveField(16)
  List<String> additionalImages;
  @HiveField(17)
  String? label;
  @HiveField(18)
  int? orderIndex;

  Bird({
    String? id,
    required this.type,
    this.imagePath,
    required this.breed,
    required this.quantity,
    required this.source,
    this.sourceDetail,
    required this.date,
    this.arrivalDate,
    this.isAlive,
    this.healthStatus,
    required this.gender,
    required this.bandColor,
    this.customBandColor,
    required this.location,
    this.notes = '',
    this.additionalImages = const [],
    this.label,
    this.orderIndex,
  }) : id = id ?? const Uuid().v4();

  String get typeName {
    switch (type) {
      case BirdType.chicken:
        return 'Chicken';
      case BirdType.duck:
        return 'Duck';
      case BirdType.turkey:
        return 'Turkey';
      case BirdType.goose:
        return 'Goose';
      case BirdType.other:
        return 'Other';
    }
  }

  // extracts chicken type (layer/dual) from notes if its there
  String? get chickenType {
    if (type != BirdType.chicken) return null;
    final match = RegExp(r'Chicken Type: (Layer|Dual)').firstMatch(notes);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }
}
