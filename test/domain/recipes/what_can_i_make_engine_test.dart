import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/domain/inventory/inventory_item.dart';
import 'package:alifit/domain/inventory/inventory_location.dart';
import 'package:alifit/domain/nutrition/food.dart';
import 'package:alifit/domain/nutrition/food_source.dart';
import 'package:alifit/domain/nutrition/nutrition_values.dart';
import 'package:alifit/domain/recipes/recipe.dart';
import 'package:alifit/domain/recipes/what_can_i_make_engine.dart';

Food _food(int id, String name) {
  return Food(
    id: id,
    name: name,
    source: FoodSource.user,
    baseUnit: 'g',
    completeness: FoodCompleteness.complete,
    isFavorite: false,
    nutritionPer100: const NutritionValues(
      calories: 100,
      carbs: 10,
      protein: 5,
      fat: 2,
      fiber: 1,
      sugar: 1,
      sodium: 10,
    ),
  );
}

RecipeIngredient _ingredient(Food food, {double grams = 100}) {
  return RecipeIngredient(
    id: food.id,
    food: food,
    quantity: grams,
    unitLabel: 'g',
    gramsEquivalent: grams,
  );
}

InventoryItem _inventoryItem(Food food, {DateTime? expiresAt}) {
  return InventoryItem(
    id: food.id,
    food: food,
    quantity: 500,
    unitLabel: 'g',
    location: InventoryLocation.pantry,
    addedAt: DateTime.now(),
    expiresAt: expiresAt,
  );
}

void main() {
  final rice = _food(1, 'Arroz');
  final chicken = _food(2, 'Pollo');
  final egg = _food(3, 'Huevo');
  final milk = _food(4, 'Leche');

  test(
    'una receta con todos los ingredientes disponibles no tiene faltantes',
    () {
      final recipe = Recipe(
        id: 1,
        name: 'Arroz con pollo',
        servings: 2,
        ingredients: [_ingredient(rice), _ingredient(chicken)],
      );
      final inventory = [_inventoryItem(rice), _inventoryItem(chicken)];

      final matches = findRecipeMatches([recipe], inventory);

      expect(matches, hasLength(1));
      expect(matches.first.missing, isEmpty);
      expect(matches.first.available, hasLength(2));
    },
  );

  test('una receta con ingredientes faltantes los lista correctamente', () {
    final recipe = Recipe(
      id: 1,
      name: 'Arroz con pollo',
      servings: 2,
      ingredients: [_ingredient(rice), _ingredient(chicken)],
    );
    final inventory = [_inventoryItem(rice)];

    final matches = findRecipeMatches([recipe], inventory);

    expect(matches.first.available.map((i) => i.food.id), [rice.id]);
    expect(matches.first.missing.map((i) => i.food.id), [chicken.id]);
  });

  test('prioriza recetas con menos ingredientes faltantes', () {
    final completeRecipe = Recipe(
      id: 1,
      name: 'Solo arroz',
      servings: 1,
      ingredients: [_ingredient(rice)],
    );
    final incompleteRecipe = Recipe(
      id: 2,
      name: 'Arroz con pollo y huevo',
      servings: 1,
      ingredients: [_ingredient(rice), _ingredient(chicken), _ingredient(egg)],
    );
    final inventory = [_inventoryItem(rice)];

    final matches = findRecipeMatches([
      incompleteRecipe,
      completeRecipe,
    ], inventory);

    expect(matches.first.recipe.id, completeRecipe.id);
    expect(matches.first.missing, isEmpty);
  });

  test(
    'en empate de faltantes, prioriza la que usa ingredientes por vencer',
    () {
      final recipeA = Recipe(
        id: 1,
        name: 'Con leche',
        servings: 1,
        ingredients: [_ingredient(rice), _ingredient(milk)],
      );
      final recipeB = Recipe(
        id: 2,
        name: 'Con huevo',
        servings: 1,
        ingredients: [_ingredient(rice), _ingredient(egg)],
      );
      // Ambas recetas tienen 1 disponible (arroz) y 1 faltante cada una,
      // pero la leche está por vencer.
      final inventory = [
        _inventoryItem(rice),
        _inventoryItem(
          milk,
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      ];

      final matches = findRecipeMatches([recipeB, recipeA], inventory);

      expect(matches.first.recipe.id, recipeA.id);
    },
  );

  test('respeta maxResults', () {
    final recipes = List.generate(
      10,
      (i) => Recipe(
        id: i,
        name: 'Receta $i',
        servings: 1,
        ingredients: [_ingredient(rice)],
      ),
    );

    final matches = findRecipeMatches(recipes, [
      _inventoryItem(rice),
    ], maxResults: 3);

    expect(matches, hasLength(3));
  });
}
