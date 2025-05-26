import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/bird.dart';

class BirdsProvider with ChangeNotifier {
  final Box<Bird> _box = Hive.box<Bird>('birds');

  List<Bird> get birds => _box.values.toList();

  List<Bird> getBirdsByType(BirdType type) {
    return birds.where((bird) => bird.type == type).toList();
  }

  int getBirdCountByType(BirdType type) {
    return birds.where((bird) => bird.type == type).length;
  }

  void addBird(Bird bird) {
    _box.put(bird.id, bird);
    notifyListeners();
  }

  void updateBird(Bird updatedBird) {
    _box.put(updatedBird.id, updatedBird);
    notifyListeners();
  }

  void removeBird(String id) {
    _box.delete(id);
    notifyListeners();
  }
}