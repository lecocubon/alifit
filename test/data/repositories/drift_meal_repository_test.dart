import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_meal_repository.dart';
import 'package:alifit/domain/nutrition/meal.dart';
import 'package:alifit/domain/nutrition/meal_repository.dart';
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

  group('recetas registradas', () {
    final day = DateTime(2026, 10, 12);

    MealRecipeItemInput ingredient(double grams) => MealRecipeItemInput(
      foodId: foodId,
      quantity: grams,
      unitLabel: 'g',
      gramsEquivalent: grams,
    );

    Future<void> addWaffle({double portions = 1}) => repo.addRecipe(
      date: day,
      type: MealType.desayuno,
      recipeId: 7,
      recipeName: 'Waffle casero',
      portions: portions,
      items: [ingredient(19 * portions), ingredient(36 * portions)],
    );

    Future<Meal> breakfast([DateTime? date]) async =>
        (await repo.watchMealsForDate(date ?? day).first).single;

    test('una receta queda como una sola línea con sus calorías sumadas, '
        'junto a los alimentos sueltos', () async {
      await repo.addItem(
        date: day,
        type: MealType.desayuno,
        foodId: foodId,
        quantity: 100,
        unitLabel: 'g',
        gramsEquivalent: 100,
      );
      await addWaffle();

      final meal = await breakfast();
      expect(meal.items, hasLength(3));
      expect(meal.lines, hasLength(2));
      expect(meal.lines.first, isA<FoodLine>());

      final recipe = meal.lines.last as RecipeLine;
      expect(recipe.entry.name, 'Waffle casero');
      expect(recipe.entry.portions, 1);
      expect(recipe.entry.recipeId, 7);
      expect(recipe.items, hasLength(2));
      // 55 g de arroz (130 kcal/100 g).
      expect(recipe.nutrition.calories, closeTo(71.5, 0.01));
      expect(meal.totals.calories, closeTo(201.5, 0.01));
    });

    test(
      'la misma receta registrada dos veces son dos líneas distintas',
      () async {
        await addWaffle();
        await addWaffle(portions: 2);

        final lines = (await breakfast()).lines.cast<RecipeLine>();
        expect(lines.map((l) => l.entry.portions), [1, 2]);
        expect(lines.last.nutrition.calories, closeTo(143, 0.01));
      },
    );

    test(
      'removeRecipeEntry quita la receta completa y avisa a la pantalla',
      () async {
        await addWaffle();
        await addWaffle(portions: 2);
        final lineCounts = <int>[];
        final sub = repo
            .watchMealsForDate(day)
            .listen((meals) => lineCounts.add(meals.single.lines.length));
        await pumpEventQueue(times: 50);
        expect(lineCounts.last, 2);

        final first = (await breakfast()).lines.first as RecipeLine;
        await repo.removeRecipeEntry(first.entry.id);
        await pumpEventQueue(times: 50);

        expect(lineCounts.last, 1);
        final meal = await breakfast();
        expect(meal.items, hasLength(2));
        expect(meal.recipeEntries.single.portions, 2);
        await sub.cancel();
      },
    );

    test('duplicateMeal copia la receta como receta, no como ingredientes '
        'sueltos', () async {
      await addWaffle(portions: 2);
      final target = DateTime(2026, 10, 13);

      await repo.duplicateMeal(
        mealId: (await breakfast()).id,
        targetDate: target,
      );

      final copy = (await breakfast(target)).lines.single as RecipeLine;
      expect(copy.entry.name, 'Waffle casero');
      expect(copy.entry.portions, 2);
      expect(copy.items, hasLength(2));
      // La original sigue intacta y son registros independientes.
      final original = (await breakfast()).lines.single as RecipeLine;
      expect(original.entry.id, isNot(copy.entry.id));
    });

    test('clearMeal también quita las recetas registradas', () async {
      await addWaffle();
      final meal = await breakfast();

      await repo.clearMeal(meal.id);

      final cleared = await breakfast();
      expect(cleared.items, isEmpty);
      expect(cleared.recipeEntries, isEmpty);
    });
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

  // Con la hora de Chile, sumar 24 horas al sábado 3 de abril de 2027 (que
  // dura 25) daba otra vez el sábado y el ciclo no terminaba nunca: la
  // racha de Inicio se quedaba calculando del 4 de abril a comienzos de
  // junio.
  test(
    'getDailyTotals termina y cuenta cada día en un rango con cambio de hora',
    () async {
      await repo.addItem(
        date: DateTime(2027, 4, 4),
        type: MealType.almuerzo,
        foodId: foodId,
        quantity: 100,
        unitLabel: 'g',
        gramsEquivalent: 100,
      );

      final totals = await repo.getDailyTotals(
        startDate: DateTime(2027, 4, 1),
        endDate: DateTime(2027, 4, 6),
      );

      expect(totals.map((t) => t.date.day), [1, 2, 3, 4, 5, 6]);
      expect(totals[3].totals.calories, closeTo(130, 0.01));
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
