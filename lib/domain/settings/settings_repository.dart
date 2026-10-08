import 'package:flutter/material.dart';

abstract class SettingsRepository {
  Stream<ThemeMode> watchThemeMode();

  Future<void> setThemeMode(ThemeMode mode);
}
