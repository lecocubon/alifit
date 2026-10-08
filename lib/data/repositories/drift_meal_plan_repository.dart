import 'dart:convert';

import '../../domain/meal_plan/meal_plan.dart';
import '../../domain/meal_plan/meal_plan_repository.dart';
import '../database/app_database.dart';

const _planKey = 'meal_plan';

class DriftMealPlanRepository implements MealPlanRepository {
  DriftMealPlanRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<MealPlan?> watchPlan() {
    final query = _db.select(_db.appSettings)
      ..where((t) => t.key.equals(_planKey));
    return query.watchSingleOrNull().map((row) {
      if (row == null) {
        return null;
      }
      try {
        return MealPlan.fromJson(jsonDecode(row.value) as Map<String, dynamic>);
      } catch (_) {
        // Solo se guardan planes ya validados al importar; si aun así no se
        // puede leer, se trata como si no hubiera plan.
        return null;
      }
    });
  }

  @override
  Future<void> savePlan(String planJson) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: _planKey, value: planJson),
        );
  }

  @override
  Future<void> clearPlan() async {
    await (_db.delete(
      _db.appSettings,
    )..where((t) => t.key.equals(_planKey))).go();
  }
}
