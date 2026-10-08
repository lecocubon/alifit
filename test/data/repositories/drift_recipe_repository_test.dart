import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_meal_repository.dart';
import 'package:alifit/data/repositories/drift_recipe_repository.dart';
import 'package:alifit/domain/recipes/recipe_repository.dart';

void main() {
  late AppDatabase db;
  late DriftRecipeRepository repo;
  late int foodId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftRecipeRepository(db);
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

  test('crea una receta y calcula la nutrición por porción', () async {
    final id = await repo.createRecipe(
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

    final recipe = await repo.getById(id);
    expect(recipe, isNotNull);
    expect(recipe!.ingredients, hasLength(1));
    // 200g de arroz (130 kcal/100g) = 260 kcal totales / 2 porciones = 130.
    expect(recipe.nutritionPerServing.calories, closeTo(130, 0.01));
  });

  test('duplicar receta crea una copia independiente', () async {
    final id = await repo.createRecipe(
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

    final duplicatedId = await repo.duplicateRecipe(id);
    final all = await repo.watchRecipes().first;
    expect(all, hasLength(2));
    expect(duplicatedId, isNot(id));
  });

  test('eliminar receta la quita de la lista', () async {
    final id = await repo.createRecipe(
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

    await repo.deleteRecipe(id);
    final all = await repo.watchRecipes().first;
    expect(all, isEmpty);
  });

  test('watchRecipes muestra todos los ingredientes de una receta recién '
      'creada y se actualiza al editarla', () async {
    RecipeIngredientInput ingredient(double grams) => RecipeIngredientInput(
      foodId: foodId,
      quantity: grams,
      unitLabel: 'g',
      gramsEquivalent: grams,
    );

    final snapshots = <List<int>>[];
    final sub = repo.watchRecipes().listen(
      (recipes) =>
          snapshots.add(recipes.map((r) => r.ingredients.length).toList()),
    );
    await pumpEventQueue(times: 50);

    final id = await repo.createRecipe(
      name: 'Avena trasnochada',
      servings: 1,
      ingredients: [ingredient(40), ingredient(40), ingredient(40)],
    );
    await pumpEventQueue(times: 50);
    expect(snapshots.last, [3]);

    await repo.updateRecipe(
      id: id,
      name: 'Avena trasnochada',
      servings: 1,
      ingredients: [ingredient(40)],
    );
    await pumpEventQueue(times: 50);
    expect(snapshots.last, [1]);

    await sub.cancel();
  });

  test('watchRecipes se actualiza al editar aunque el Diario también esté '
      'observando la base de datos', () async {
    // El Diario observa comidas con el mismo mecanismo; si ambas
    // consultas tuvieran el mismo SQL, Drift las compartiría y Recetas
    // solo reaccionaría a cambios de comidas.
    final diarySub = DriftMealRepository(
      db,
    ).watchMealsForDate(DateTime(2026, 10, 8)).listen((_) {});
    await pumpEventQueue(times: 50);

    RecipeIngredientInput ingredient(double grams) => RecipeIngredientInput(
      foodId: foodId,
      quantity: grams,
      unitLabel: 'g',
      gramsEquivalent: grams,
    );
    final id = await repo.createRecipe(
      name: 'Avena trasnochada',
      servings: 1,
      ingredients: [ingredient(40), ingredient(40)],
    );

    final grams = <double>[];
    final sub = repo.watchRecipes().listen(
      (recipes) => grams.add(recipes.single.ingredients.first.quantity),
    );
    await pumpEventQueue(times: 50);
    expect(grams.last, 40);

    await repo.updateRecipe(
      id: id,
      name: 'Avena trasnochada',
      servings: 1,
      ingredients: [ingredient(65), ingredient(5)],
    );
    await pumpEventQueue(times: 50);
    expect(grams.last, 65);

    await sub.cancel();
    await diarySub.cancel();
  });

  test('eliminar receta no deja RecipeIngredients huérfanos', () async {
    final id = await repo.createRecipe(
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

    await repo.deleteRecipe(id);

    final orphanedIngredients = await (db.select(
      db.recipeIngredients,
    )..where((t) => t.recipeId.equals(id))).get();
    expect(orphanedIngredients, isEmpty);
  });
}
