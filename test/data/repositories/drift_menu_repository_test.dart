import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_menu_repository.dart';
import 'package:alifit/data/repositories/drift_recipe_repository.dart';
import 'package:alifit/domain/nutrition/meal_type.dart';
import 'package:alifit/domain/recipes/recipe_repository.dart';

void main() {
  late AppDatabase db;
  late DriftMenuRepository repo;
  late int foodId;
  late int recipeId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftMenuRepository(db, DriftRecipeRepository(db));
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
    recipeId = await DriftRecipeRepository(db).createRecipe(
      name: 'Arroz simple',
      servings: 2,
      ingredients: [
        RecipeIngredientInput(
          foodId: foodId,
          quantity: 200,
          unitLabel: 'g',
          gramsEquivalent: 200,
        ),
      ],
    );
  });

  tearDown(() => db.close());

  test('crea un plan y lo puede leer por id', () async {
    final id = await repo.createPlan(
      label: 'Semana de prueba',
      startDate: DateTime(2026, 7, 20, 15, 30),
    );

    final plan = await repo.getPlan(id);
    expect(plan, isNotNull);
    expect(plan!.label, 'Semana de prueba');
    // La fecha de inicio se normaliza a medianoche (sin hora).
    expect(plan.startDate, DateTime(2026, 7, 20));
    expect(plan.endDate, DateTime(2026, 7, 26));
  });

  test(
    'asigna una receta a un slot y la nutrición escala por porciones',
    () async {
      final planId = await repo.createPlan(
        label: 'Semana',
        startDate: DateTime(2026, 7, 20),
      );

      await repo.setMeal(
        menuPlanId: planId,
        date: DateTime(2026, 7, 20),
        mealType: MealType.almuerzo,
        recipeId: recipeId,
        servings: 2,
      );

      final meals = await repo.watchMeals(planId).first;
      expect(meals, hasLength(1));
      expect(meals.first.recipe?.name, 'Arroz simple');
      // 130 kcal/porción * 2 porciones planificadas = 260.
      expect(meals.first.nutrition?.calories, closeTo(260, 0.01));
    },
  );

  test(
    'asignar dos veces el mismo slot reemplaza la comida anterior',
    () async {
      final planId = await repo.createPlan(
        label: 'Semana',
        startDate: DateTime(2026, 7, 20),
      );

      await repo.setMeal(
        menuPlanId: planId,
        date: DateTime(2026, 7, 20),
        mealType: MealType.desayuno,
        freeformLabel: 'Avena con leche',
      );
      await repo.setMeal(
        menuPlanId: planId,
        date: DateTime(2026, 7, 20),
        mealType: MealType.desayuno,
        recipeId: recipeId,
      );

      final meals = await repo.watchMeals(planId).first;
      expect(meals, hasLength(1));
      expect(meals.first.recipe?.name, 'Arroz simple');
    },
  );

  test('comida libre sin receta usa el texto ingresado como nombre', () async {
    final planId = await repo.createPlan(
      label: 'Semana',
      startDate: DateTime(2026, 7, 20),
    );

    await repo.setMeal(
      menuPlanId: planId,
      date: DateTime(2026, 7, 21),
      mealType: MealType.once,
      freeformLabel: 'Té con pan',
    );

    final meals = await repo.watchMeals(planId).first;
    expect(meals.first.displayName, 'Té con pan');
    expect(meals.first.nutrition, isNull);
  });

  test('quitar una comida la elimina del plan', () async {
    final planId = await repo.createPlan(
      label: 'Semana',
      startDate: DateTime(2026, 7, 20),
    );
    await repo.setMeal(
      menuPlanId: planId,
      date: DateTime(2026, 7, 20),
      mealType: MealType.cena,
      recipeId: recipeId,
    );

    await repo.clearMeal(
      menuPlanId: planId,
      date: DateTime(2026, 7, 20),
      mealType: MealType.cena,
    );

    final meals = await repo.watchMeals(planId).first;
    expect(meals, isEmpty);
  });

  test('eliminar el plan elimina también sus comidas', () async {
    final planId = await repo.createPlan(
      label: 'Semana',
      startDate: DateTime(2026, 7, 20),
    );
    await repo.setMeal(
      menuPlanId: planId,
      date: DateTime(2026, 7, 20),
      mealType: MealType.cena,
      recipeId: recipeId,
    );

    await repo.deletePlan(planId);

    final plans = await repo.watchPlans().first;
    expect(plans, isEmpty);
    final meals = await repo.watchMeals(planId).first;
    expect(meals, isEmpty);
  });
}
