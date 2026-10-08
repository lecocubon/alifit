import 'package:flutter/material.dart';

import '../../domain/settings/settings_repository.dart';
import '../database/app_database.dart';

const _themeModeKey = 'theme_mode';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<ThemeMode> watchThemeMode() {
    final query = _db.select(_db.appSettings)
      ..where((t) => t.key.equals(_themeModeKey));
    return query.watchSingleOrNull().map((row) {
      if (row == null) {
        return ThemeMode.system;
      }
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == row.value,
        orElse: () => ThemeMode.system,
      );
    });
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: _themeModeKey, value: mode.name),
        );
  }
}
