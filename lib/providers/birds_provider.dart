import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/bird.dart';

class BirdsProvider with ChangeNotifier {
  final Box<Bird> _box = Hive.box<Bird>('birds');

  List<Bird> get birds => _box.values.toList();

  List<Bird> getBirdsByType(BirdType type) {
    final birdsOfType = birds.where((bird) => bird.type == type).toList();
    
    bool needsUpdate = false;
    for (int i = 0; i < birdsOfType.length; i++) {
      if (birdsOfType[i].orderIndex == null) {
        needsUpdate = true;
        break;
      }
    }
    
    if (needsUpdate) {
      birdsOfType.sort((a, b) => a.date.compareTo(b.date));
      for (int i = 0; i < birdsOfType.length; i++) {
        final updatedBird = Bird(
          id: birdsOfType[i].id,
          type: birdsOfType[i].type,
          imagePath: birdsOfType[i].imagePath,
          breed: birdsOfType[i].breed,
          quantity: birdsOfType[i].quantity,
          source: birdsOfType[i].source,
          sourceDetail: birdsOfType[i].sourceDetail,
          date: birdsOfType[i].date,
          arrivalDate: birdsOfType[i].arrivalDate,
          isAlive: birdsOfType[i].isAlive,
          healthStatus: birdsOfType[i].healthStatus,
          gender: birdsOfType[i].gender,
          bandColor: birdsOfType[i].bandColor,
          customBandColor: birdsOfType[i].customBandColor,
          location: birdsOfType[i].location,
          notes: birdsOfType[i].notes,
          additionalImages: birdsOfType[i].additionalImages,
          label: birdsOfType[i].label,
          orderIndex: i,
        );
        _box.put(updatedBird.id, updatedBird);
      }
      notifyListeners();
    } else {
      birdsOfType.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
    }
    
    return birdsOfType;
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

  void reorderBirds(BirdType type, int oldIndex, int newIndex) {
    final birdsOfType = getBirdsByType(type);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final bird = birdsOfType.removeAt(oldIndex);
    birdsOfType.insert(newIndex, bird);
    
    for (int i = 0; i < birdsOfType.length; i++) {
      final updatedBird = Bird(
        id: birdsOfType[i].id,
        type: birdsOfType[i].type,
        imagePath: birdsOfType[i].imagePath,
        breed: birdsOfType[i].breed,
        quantity: birdsOfType[i].quantity,
        source: birdsOfType[i].source,
        sourceDetail: birdsOfType[i].sourceDetail,
        date: birdsOfType[i].date,
        arrivalDate: birdsOfType[i].arrivalDate,
        isAlive: birdsOfType[i].isAlive,
        healthStatus: birdsOfType[i].healthStatus,
        gender: birdsOfType[i].gender,
        bandColor: birdsOfType[i].bandColor,
        customBandColor: birdsOfType[i].customBandColor,
        location: birdsOfType[i].location,
        notes: birdsOfType[i].notes,
        additionalImages: birdsOfType[i].additionalImages,
        label: birdsOfType[i].label,
        orderIndex: i,
      );
      _box.put(updatedBird.id, updatedBird);
    }
    
    notifyListeners();
  }
}
