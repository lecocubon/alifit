import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_meal_repository.dart';
import 'package:alifit/domain/nutrition/meal.dart';
import 'package:alifit/domain/nutrition/meal_repository.dart';
import 'package:alifit/domain/nutrition/meal_type.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('alifit_migration');
    dbFile = File('${tempDir.path}/alifit.sqlite');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('una base de datos de la versión 11 se actualiza a la 12 conservando '
      'las comidas ya registradas', () async {
    final day = DateTime(2026, 10, 8);

    // Se deja el archivo tal como lo tiene un teléfono con la versión 11:
    // sin la tabla de recetas registradas y con meal_items en su forma
    // antigua (sin la columna recipe_entry_id), pero con datos reales.
    var db = AppDatabase(NativeDatabase(dbFile));
    final foodId = await db
        .into(db.foods)
        .insert(
          FoodsCompanion.insert(
            name: 'Arroz Blanco',
            normalizedName: 'arroz blanco',
            source: const Value('user'),
            calories: 130,
            carbs: 28,
            protein: 2.7,
            fat: 0.3,
            fiber: 0.4,
            sugar: 0,
            sodium: 1,
          ),
        );
    final mealId = await db
        .into(db.meals)
        .insert(MealsCompanion.insert(date: day, type: 'almuerzo'));
    await db.customStatement('DROP TABLE meal_items');
    await db.customStatement('DROP TABLE meal_recipe_entries');
    await db.customStatement('''
      CREATE TABLE meal_items (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        meal_id INTEGER NOT NULL REFERENCES meals (id) ON DELETE CASCADE,
        food_id INTEGER NOT NULL REFERENCES foods (id) ON DELETE RESTRICT,
        quantity REAL NOT NULL,
        unit_label TEXT NOT NULL,
        grams_equivalent REAL NOT NULL,
        created_at INTEGER NOT NULL
          DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
      )
    ''');
    await db.customStatement(
      'INSERT INTO meal_items '
      '(meal_id, food_id, quantity, unit_label, grams_equivalent) '
      "VALUES ($mealId, $foodId, 200, 'g', 200)",
    );
    await db.customStatement('PRAGMA user_version = 11');
    await db.close();

    // Al abrirla con la app nueva corre la migración.
    db = AppDatabase(NativeDatabase(dbFile));
    final repo = DriftMealRepository(db);

    final meals = await repo.watchMealsForDate(day).first;
    expect(meals.single.items.single.food.name, 'Arroz Blanco');
    expect(meals.single.totals.calories, closeTo(260, 0.01));
    expect(meals.single.lines.single, isA<FoodLine>());

    // Y sobre esos mismos datos ya se pueden registrar recetas.
    await repo.addRecipe(
      date: day,
      type: MealType.almuerzo,
      recipeName: 'Arroz doble',
      portions: 1,
      items: [
        MealRecipeItemInput(
          foodId: foodId,
          quantity: 100,
          unitLabel: 'g',
          gramsEquivalent: 100,
        ),
      ],
    );
    final updated = (await repo.watchMealsForDate(day).first).single;
    expect(updated.lines, hasLength(2));
    expect(updated.totals.calories, closeTo(390, 0.01));

    await db.close();
  });
}
