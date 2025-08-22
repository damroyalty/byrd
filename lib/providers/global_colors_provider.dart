import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalColorsProvider with ChangeNotifier {
  Color _navigationBarColor = const Color(0xFF388E3C);
  
  Color get navigationBarColor => _navigationBarColor;
  
  Future<void> loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    final greenValue = prefs.getInt('home_customTileGreen');
    if (greenValue != null) {
      _navigationBarColor = Color(greenValue);
      _updateNavigationBarColor();
    }
  }
  
  Future<void> updateNavigationBarColor(Color color) async {
    _navigationBarColor = color;
    _updateNavigationBarColor();
    notifyListeners();
  }
  
  void _updateNavigationBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: _navigationBarColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
} 