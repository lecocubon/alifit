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
    return _db.watchTables({_db.meals, _db.mealItems, _db.foods}).asyncMap((
      _,
    ) async {
      final mealRows = await query.get();
      final meals = <Meal>[];
      for (final mealRow in mealRows) {
        final items = await _itemsForMeal(mealRow.id);
        meals.add(
          Meal(
            id: mealRow.id,
            date: mealRow.date,
            type: MealType.fromStorage(mealRow.type),
            customLabel: mealRow.customLabel,
            items: items,
          ),
        );
      }
      return meals;
    });
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
  Future<void> clearMeal(int mealId) {
    return (_db.delete(
      _db.mealItems,
    )..where((t) => t.mealId.equals(mealId))).go();
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
    final targetMealId = await _mealIdFor(
      targetDate,
      type,
      mealRow.customLabel,
    );
    for (final item in items) {
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
