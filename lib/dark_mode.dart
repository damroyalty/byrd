import 'package:flutter/material.dart';

class _ThemeModeNotifier extends ValueNotifier<bool> {
  _ThemeModeNotifier(bool value) : super(value);
}

final ValueNotifier<bool> darkModeNotifier = _ThemeModeNotifier(false); 