import 'dart:convert';

import '../../domain/nutri_guide/nutri_guide.dart';
import '../../domain/nutri_guide/nutri_guide_repository.dart';
import '../database/app_database.dart';

const _guideKey = 'nutri_guide';

class DriftNutriGuideRepository implements NutriGuideRepository {
  DriftNutriGuideRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<NutriGuide?> watchGuide() {
    final query = _db.select(_db.appSettings)
      ..where((t) => t.key.equals(_guideKey));
    return query.watchSingleOrNull().map((row) {
      if (row == null) {
        return null;
      }
      try {
        return NutriGuide.fromJson(
          jsonDecode(row.value) as Map<String, dynamic>,
        );
      } catch (_) {
        // Solo se guardan guías ya validadas al importar; si aun así no se
        // puede leer, se trata como si no hubiera guía.
        return null;
      }
    });
  }

  @override
  Future<void> saveGuide(String guideJson) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: _guideKey, value: guideJson),
        );
  }

  @override
  Future<void> clearGuide() async {
    await (_db.delete(
      _db.appSettings,
    )..where((t) => t.key.equals(_guideKey))).go();
  }
}
