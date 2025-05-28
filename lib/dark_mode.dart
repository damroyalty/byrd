import 'package:flutter/material.dart';

class _ThemeModeNotifier extends ValueNotifier<bool> {
  _ThemeModeNotifier(super.value);
}

final ValueNotifier<bool> darkModeNotifier = _ThemeModeNotifier(false);