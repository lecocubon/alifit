import '../../domain/nutrition/nutrition_goals.dart';
import '../../domain/nutrition/nutrition_goals_repository.dart';
import '../database/app_database.dart';

const _caloriesKey = 'nutrition_goal_calories';
const _carbsKey = 'nutrition_goal_carbs';
const _proteinKey = 'nutrition_goal_protein';
const _fatKey = 'nutrition_goal_fat';

class DriftNutritionGoalsRepository implements NutritionGoalsRepository {
  DriftNutritionGoalsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<NutritionGoals> watchGoals() {
    final query = _db.select(_db.appSettings)
      ..where(
        (t) => t.key.isIn([_caloriesKey, _carbsKey, _proteinKey, _fatKey]),
      );
    return query.watch().map((rows) {
      final map = {for (final r in rows) r.key: r.value};
      final defaults = NutritionGoals.defaults;
      return NutritionGoals(
        calories: double.tryParse(map[_caloriesKey] ?? '') ?? defaults.calories,
        carbs: double.tryParse(map[_carbsKey] ?? '') ?? defaults.carbs,
        protein: double.tryParse(map[_proteinKey] ?? '') ?? defaults.protein,
        fat: double.tryParse(map[_fatKey] ?? '') ?? defaults.fat,
      );
    });
  }

  @override
  Future<void> setGoals(NutritionGoals goals) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _caloriesKey,
            value: goals.calories.toString(),
          ),
        );
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _carbsKey,
            value: goals.carbs.toString(),
          ),
        );
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _proteinKey,
            value: goals.protein.toString(),
          ),
        );
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _fatKey,
            value: goals.fat.toString(),
          ),
        );
  }
}
