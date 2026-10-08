import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_nutrition_goals_repository.dart';
import 'package:alifit/domain/nutrition/nutrition_goals.dart';

void main() {
  late AppDatabase db;
  late DriftNutritionGoalsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftNutritionGoalsRepository(db);
  });

  tearDown(() => db.close());

  test('sin metas guardadas, expone los valores por defecto', () async {
    final goals = await repo.watchGoals().first;
    expect(goals.calories, NutritionGoals.defaults.calories);
    expect(goals.carbs, NutritionGoals.defaults.carbs);
    expect(goals.protein, NutritionGoals.defaults.protein);
    expect(goals.fat, NutritionGoals.defaults.fat);
  });

  test('setGoals guarda y watchGoals refleja los nuevos valores', () async {
    await repo.setGoals(
      const NutritionGoals(calories: 1800, carbs: 200, protein: 120, fat: 55),
    );

    final goals = await repo.watchGoals().first;
    expect(goals.calories, 1800);
    expect(goals.carbs, 200);
    expect(goals.protein, 120);
    expect(goals.fat, 55);
  });
}
