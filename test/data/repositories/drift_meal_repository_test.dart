import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_meal_repository.dart';
import 'package:alifit/domain/nutrition/meal_type.dart';

void main() {
  late AppDatabase db;
  late DriftMealRepository repo;
  late int foodId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftMealRepository(db);
    foodId = await db
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
  });

  tearDown(() => db.close());

  test('agregar un alimento crea la comida y se refleja en el total', () async {
    await repo.addItem(
      date: DateTime(2026, 7, 20),
      type: MealType.almuerzo,
      foodId: foodId,
      quantity: 200,
      unitLabel: 'g',
      gramsEquivalent: 200,
    );

    final meals = await repo.watchMealsForDate(DateTime(2026, 7, 20)).first;
    expect(meals, hasLength(1));
    expect(meals.first.totals.calories, closeTo(260, 0.01));
  });

  test(
    'duplicateMeal copia los alimentos a otro día con el mismo tipo',
    () async {
      await repo.addItem(
        date: DateTime(2026, 7, 20),
        type: MealType.almuerzo,
        foodId: foodId,
        quantity: 200,
        unitLabel: 'g',
        gramsEquivalent: 200,
      );
      final original =
          (await repo.watchMealsForDate(DateTime(2026, 7, 20)).first).first;

      await repo.duplicateMeal(
        mealId: original.id,
        targetDate: DateTime(2026, 7, 21),
      );

      final copied = await repo.watchMealsForDate(DateTime(2026, 7, 21)).first;
      expect(copied, hasLength(1));
      expect(copied.first.type, MealType.almuerzo);
      expect(copied.first.totals.calories, closeTo(260, 0.01));
    },
  );

  test('duplicateMeal hacia un día que ya tiene ese tipo de comida suma los '
      'alimentos en vez de reemplazarlos', () async {
    await repo.addItem(
      date: DateTime(2026, 7, 20),
      type: MealType.almuerzo,
      foodId: foodId,
      quantity: 200,
      unitLabel: 'g',
      gramsEquivalent: 200,
    );
    await repo.addItem(
      date: DateTime(2026, 7, 21),
      type: MealType.almuerzo,
      foodId: foodId,
      quantity: 100,
      unitLabel: 'g',
      gramsEquivalent: 100,
    );
    final original =
        (await repo.watchMealsForDate(DateTime(2026, 7, 20)).first).first;

    await repo.duplicateMeal(
      mealId: original.id,
      targetDate: DateTime(2026, 7, 21),
    );

    final meals = await repo.watchMealsForDate(DateTime(2026, 7, 21)).first;
    expect(meals, hasLength(1));
    expect(meals.first.items, hasLength(2));
  });

  test('copyMeals copia todas las comidas de un día a otro', () async {
    await repo.addItem(
      date: DateTime(2026, 7, 20),
      type: MealType.desayuno,
      foodId: foodId,
      quantity: 100,
      unitLabel: 'g',
      gramsEquivalent: 100,
    );
    await repo.addItem(
      date: DateTime(2026, 7, 20),
      type: MealType.cena,
      foodId: foodId,
      quantity: 150,
      unitLabel: 'g',
      gramsEquivalent: 150,
    );

    await repo.copyMeals(
      sourceDate: DateTime(2026, 7, 20),
      targetDate: DateTime(2026, 7, 25),
    );

    final meals = await repo.watchMealsForDate(DateTime(2026, 7, 25)).first;
    expect(
      meals.map((m) => m.type),
      containsAll([MealType.desayuno, MealType.cena]),
    );
  });

  test('watchMealsForDate se actualiza al agregar o quitar alimentos de una '
      'comida que ya existe', () async {
    final day = DateTime(2026, 7, 20);
    await repo.addItem(
      date: day,
      type: MealType.almuerzo,
      foodId: foodId,
      quantity: 200,
      unitLabel: 'g',
      gramsEquivalent: 200,
    );

    final totals = <double>[];
    final sub = repo
        .watchMealsForDate(day)
        .listen((meals) => totals.add(meals.first.totals.calories));
    await pumpEventQueue(times: 50);
    expect(totals.last, closeTo(260, 0.01));

    // Misma comida (almuerzo): solo cambia la tabla de alimentos.
    await repo.addItem(
      date: day,
      type: MealType.almuerzo,
      foodId: foodId,
      quantity: 100,
      unitLabel: 'g',
      gramsEquivalent: 100,
    );
    await pumpEventQueue(times: 50);
    expect(totals.last, closeTo(390, 0.01));

    final meal = (await repo.watchMealsForDate(day).first).first;
    await repo.removeItem(meal.items.last.id);
    await pumpEventQueue(times: 50);
    expect(totals.last, closeTo(260, 0.01));

    await sub.cancel();
  });

  test('clearMeal deja la comida sin alimentos', () async {
    await repo.addItem(
      date: DateTime(2026, 7, 20),
      type: MealType.almuerzo,
      foodId: foodId,
      quantity: 200,
      unitLabel: 'g',
      gramsEquivalent: 200,
    );
    final meal =
        (await repo.watchMealsForDate(DateTime(2026, 7, 20)).first).first;

    await repo.clearMeal(meal.id);

    final meals = await repo.watchMealsForDate(DateTime(2026, 7, 20)).first;
    expect(meals.first.items, isEmpty);
  });

  test('getDailyTotals retorna un elemento por día del rango, en cero si no '
      'hay comidas', () async {
    await repo.addItem(
      date: DateTime(2026, 7, 20),
      type: MealType.almuerzo,
      foodId: foodId,
      quantity: 200,
      unitLabel: 'g',
      gramsEquivalent: 200,
    );

    final totals = await repo.getDailyTotals(
      startDate: DateTime(2026, 7, 19),
      endDate: DateTime(2026, 7, 21),
    );

    expect(totals, hasLength(3));
    expect(totals[0].totals.calories, 0);
    expect(totals[1].totals.calories, closeTo(260, 0.01));
    expect(totals[2].totals.calories, 0);
  });
}
