import 'package:drift/drift.dart';

import '../../domain/nutrition/daily_nutrition_total.dart';
import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/food_source.dart';
import '../../domain/nutrition/meal.dart';
import '../../domain/nutrition/meal_repository.dart';
import '../../domain/nutrition/meal_type.dart';
import '../../domain/nutrition/nutrition_values.dart';
import '../database/app_database.dart';
import '../database/watch_tables.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class DriftMealRepository implements MealRepository {
  DriftMealRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Meal>> watchMealsForDate(DateTime date) {
    final day = _dateOnly(date);
    final query = _db.select(_db.meals)
      ..where((t) => t.date.equals(day))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);

    // Se observan también mealItems y foods: con solo la tabla meals,
    // agregar o quitar un alimento de una comida que ya existe no volvía
    // a emitir y la pantalla quedaba desactualizada.
    return _db
        .watchTables({
          _db.meals,
          _db.mealItems,
          _db.mealRecipeEntries,
          _db.foods,
        })
        .asyncMap((_) async {
          final mealRows = await query.get();
          final meals = <Meal>[];
          for (final mealRow in mealRows) {
            meals.add(
              Meal(
                id: mealRow.id,
                date: mealRow.date,
                type: MealType.fromStorage(mealRow.type),
                customLabel: mealRow.customLabel,
                items: await _itemsForMeal(mealRow.id),
                recipeEntries: await _recipeEntriesForMeal(mealRow.id),
              ),
            );
          }
          return meals;
        });
  }

  Future<List<MealRecipeEntry>> _recipeEntriesForMeal(int mealId) async {
    final rows = await (_db.select(
      _db.mealRecipeEntries,
    )..where((t) => t.mealId.equals(mealId))).get();
    return rows
        .map(
          (row) => MealRecipeEntry(
            id: row.id,
            name: row.recipeName,
            portions: row.portions,
            recipeId: row.recipeId,
          ),
        )
        .toList();
  }

  Future<List<MealItem>> _itemsForMeal(int mealId) async {
    final itemRows = await (_db.select(
      _db.mealItems,
    )..where((t) => t.mealId.equals(mealId))).get();

    final items = <MealItem>[];
    for (final itemRow in itemRows) {
      final foodRow = await (_db.select(
        _db.foods,
      )..where((t) => t.id.equals(itemRow.foodId))).getSingleOrNull();
      if (foodRow == null) {
        continue;
      }
      items.add(
        MealItem(
          id: itemRow.id,
          food: _foodFromRow(foodRow),
          quantity: itemRow.quantity,
          unitLabel: itemRow.unitLabel,
          gramsEquivalent: itemRow.gramsEquivalent,
          recipeEntryId: itemRow.recipeEntryId,
        ),
      );
    }
    return items;
  }

  Food _foodFromRow(FoodRow row) {
    return Food(
      id: row.id,
      name: row.name,
      source: FoodSource.fromStorage(row.source),
      baseUnit: row.baseUnit,
      completeness: FoodCompleteness.fromStorage(row.completeness),
      isFavorite: row.isFavorite,
      brand: row.brand,
      barcode: row.barcode,
      notes: row.notes,
      datasetDate: row.datasetDate,
      nutritionPer100: NutritionValues(
        calories: row.calories,
        carbs: row.carbs,
        protein: row.protein,
        fat: row.fat,
        fiber: row.fiber,
        sugar: row.sugar,
        sodium: row.sodium,
        saturatedFat: row.saturatedFat,
        cholesterol: row.cholesterol,
        calcium: row.calcium,
        iron: row.iron,
        potassium: row.potassium,
      ),
    );
  }

  Future<int> _mealIdFor(
    DateTime date,
    MealType type,
    String? customLabel,
  ) async {
    final day = _dateOnly(date);
    final existing =
        await (_db.select(_db.meals)
              ..where((t) => t.date.equals(day) & t.type.equals(type.name)))
            .getSingleOrNull();
    if (existing != null) {
      return existing.id;
    }
    return _db
        .into(_db.meals)
        .insert(
          MealsCompanion.insert(
            date: day,
            type: type.name,
            customLabel: Value(customLabel),
          ),
        );
  }

  @override
  Future<void> addItem({
    required DateTime date,
    required MealType type,
    String? customLabel,
    required int foodId,
    required double quantity,
    required String unitLabel,
    required double gramsEquivalent,
  }) async {
    final mealId = await _mealIdFor(date, type, customLabel);
    await _db
        .into(_db.mealItems)
        .insert(
          MealItemsCompanion.insert(
            mealId: mealId,
            foodId: foodId,
            quantity: quantity,
            unitLabel: unitLabel,
            gramsEquivalent: gramsEquivalent,
          ),
        );
  }

  @override
  Future<void> addRecipe({
    required DateTime date,
    required MealType type,
    String? customLabel,
    int? recipeId,
    required String recipeName,
    required double portions,
    required List<MealRecipeItemInput> items,
  }) {
    return _db.transaction(() async {
      final mealId = await _mealIdFor(date, type, customLabel);
      await _insertRecipeEntry(
        mealId: mealId,
        recipeId: recipeId,
        recipeName: recipeName,
        portions: portions,
        items: items,
      );
    });
  }

  Future<void> _insertRecipeEntry({
    required int mealId,
    required int? recipeId,
    required String recipeName,
    required double portions,
    required List<MealRecipeItemInput> items,
  }) async {
    final entryId = await _db
        .into(_db.mealRecipeEntries)
        .insert(
          MealRecipeEntriesCompanion.insert(
            mealId: mealId,
            recipeId: Value(recipeId),
            recipeName: recipeName,
            portions: portions,
          ),
        );
    for (final item in items) {
      await _db
          .into(_db.mealItems)
          .insert(
            MealItemsCompanion.insert(
              mealId: mealId,
              foodId: item.foodId,
              recipeEntryId: Value(entryId),
              quantity: item.quantity,
              unitLabel: item.unitLabel,
              gramsEquivalent: item.gramsEquivalent,
            ),
          );
    }
  }

  @override
  Future<void> updateItemQuantity({
    required int mealItemId,
    required double quantity,
    required String unitLabel,
    required double gramsEquivalent,
  }) {
    return (_db.update(
      _db.mealItems,
    )..where((t) => t.id.equals(mealItemId))).write(
      MealItemsCompanion(
        quantity: Value(quantity),
        unitLabel: Value(unitLabel),
        gramsEquivalent: Value(gramsEquivalent),
      ),
    );
  }

  @override
  Future<void> removeItem(int mealItemId) {
    return (_db.delete(
      _db.mealItems,
    )..where((t) => t.id.equals(mealItemId))).go();
  }

  @override
  Future<void> removeRecipeEntry(int recipeEntryId) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.mealItems,
      )..where((t) => t.recipeEntryId.equals(recipeEntryId))).go();
      await (_db.delete(
        _db.mealRecipeEntries,
      )..where((t) => t.id.equals(recipeEntryId))).go();
    });
  }

  @override
  Future<void> clearMeal(int mealId) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.mealItems,
      )..where((t) => t.mealId.equals(mealId))).go();
      await (_db.delete(
        _db.mealRecipeEntries,
      )..where((t) => t.mealId.equals(mealId))).go();
    });
  }

  @override
  Future<void> duplicateMeal({
    required int mealId,
    required DateTime targetDate,
  }) async {
    final mealRow = await (_db.select(
      _db.meals,
    )..where((t) => t.id.equals(mealId))).getSingleOrNull();
    if (mealRow == null) {
      return;
    }
    final type = MealType.fromStorage(mealRow.type);
    final items = await _itemsForMeal(mealId);
    final recipeEntries = await _recipeEntriesForMeal(mealId);
    await _db.transaction(() async {
      final targetMealId = await _mealIdFor(
        targetDate,
        type,
        mealRow.customLabel,
      );
      for (final item in items.where((i) => i.recipeEntryId == null)) {
        await _db
            .into(_db.mealItems)
            .insert(
              MealItemsCompanion.insert(
                mealId: targetMealId,
                foodId: item.food.id,
                quantity: item.quantity,
                unitLabel: item.unitLabel,
                gramsEquivalent: item.gramsEquivalent,
              ),
            );
      }
      // Cada receta se copia como una receta nueva en el día de destino.
      for (final entry in recipeEntries) {
        await _insertRecipeEntry(
          mealId: targetMealId,
          recipeId: entry.recipeId,
          recipeName: entry.name,
          portions: entry.portions,
          items: items
              .where((i) => i.recipeEntryId == entry.id)
              .map(
                (i) => MealRecipeItemInput(
                  foodId: i.food.id,
                  quantity: i.quantity,
                  unitLabel: i.unitLabel,
                  gramsEquivalent: i.gramsEquivalent,
                ),
              )
              .toList(),
        );
      }
    });
  }

  @override
  Future<List<DailyNutritionTotal>> getDailyTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = <DailyNutritionTotal>[];
    var day = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    while (!day.isAfter(end)) {
      final mealRows = await (_db.select(
        _db.meals,
      )..where((t) => t.date.equals(day))).get();
      var totals = NutritionValues.zero;
      for (final mealRow in mealRows) {
        final items = await _itemsForMeal(mealRow.id);
        for (final item in items) {
          totals = totals + item.nutrition;
        }
      }
      results.add(DailyNutritionTotal(date: day, totals: totals));
      day = _dateOnly(day.add(const Duration(days: 1)));
    }
    return results;
  }

  @override
  Future<void> copyMeals({
    required DateTime sourceDate,
    required DateTime targetDate,
  }) async {
    final day = _dateOnly(sourceDate);
    final mealRows = await (_db.select(
      _db.meals,
    )..where((t) => t.date.equals(day))).get();
    for (final mealRow in mealRows) {
      await duplicateMeal(mealId: mealRow.id, targetDate: targetDate);
    }
  }
}
