import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/domain/inventory/inventory_item.dart';
import 'package:alifit/domain/inventory/inventory_location.dart';
import 'package:alifit/domain/menus/menu_generator.dart';
import 'package:alifit/domain/nutrition/food.dart';
import 'package:alifit/domain/nutrition/food_source.dart';
import 'package:alifit/domain/nutrition/meal_type.dart';
import 'package:alifit/domain/nutrition/nutrition_values.dart';
import 'package:alifit/domain/recipes/recipe.dart';

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
  final milk = _food(3, 'Leche');
  final egg = _food(4, 'Huevo');

  final riceOnly = Recipe(
    id: 1,
    name: 'Solo arroz',
    servings: 1,
    ingredients: [_ingredient(rice)],
  );
  final riceAndChicken = Recipe(
    id: 2,
    name: 'Arroz con pollo',
    servings: 1,
    ingredients: [_ingredient(rice), _ingredient(chicken)],
  );

  test('no toca espacios ya ocupados', () {
    final days = [DateTime(2026, 7, 20)];
    final assignments = generateWeeklyMenu(
      days: days,
      recipes: [riceOnly],
      inventory: [_inventoryItem(rice)],
      mealTypes: const [MealType.desayuno, MealType.almuerzo],
      alreadyFilled: {
        (date: DateTime(2026, 7, 20), mealType: MealType.desayuno),
      },
    );

    expect(assignments, hasLength(1));
    expect(assignments.first.mealType, MealType.almuerzo);
  });

  test('prioriza la receta con menos ingredientes faltantes', () {
    final assignments = generateWeeklyMenu(
      days: [DateTime(2026, 7, 20)],
      recipes: [riceAndChicken, riceOnly],
      inventory: [_inventoryItem(rice)],
      mealTypes: const [MealType.almuerzo],
    );

    expect(assignments.first.recipe.id, riceOnly.id);
  });

  test(
    'en empate de faltantes, prioriza la receta que usa ingredientes por vencer',
    () {
      final withMilk = Recipe(
        id: 3,
        name: 'Con leche',
        servings: 1,
        ingredients: [_ingredient(rice), _ingredient(milk)],
      );
      final withEgg = Recipe(
        id: 4,
        name: 'Con huevo',
        servings: 1,
        ingredients: [_ingredient(rice), _ingredient(egg)],
      );

      final assignments = generateWeeklyMenu(
        days: [DateTime(2026, 7, 20)],
        recipes: [withEgg, withMilk],
        inventory: [
          _inventoryItem(rice),
          _inventoryItem(egg),
          _inventoryItem(
            milk,
            expiresAt: DateTime.now().add(const Duration(days: 1)),
          ),
        ],
        mealTypes: const [MealType.almuerzo],
      );

      expect(assignments.first.recipe.id, withMilk.id);
    },
  );

  test('respeta el tope de repeticiones cuando hay alternativas', () {
    final assignments = generateWeeklyMenu(
      days: [
        DateTime(2026, 7, 20),
        DateTime(2026, 7, 21),
        DateTime(2026, 7, 22),
      ],
      recipes: [riceOnly, riceAndChicken],
      inventory: [_inventoryItem(rice), _inventoryItem(chicken)],
      mealTypes: const [MealType.almuerzo],
      maxRepeatsPerRecipe: 1,
    );

    expect(assignments, hasLength(3));
    final usedRecipeIds = assignments.map((a) => a.recipe.id).toSet();
    expect(usedRecipeIds, {riceOnly.id, riceAndChicken.id});
  });

  test('sin recetas guardadas no genera asignaciones', () {
    final assignments = generateWeeklyMenu(
      days: [DateTime(2026, 7, 20)],
      recipes: const [],
      inventory: const [],
      mealTypes: const [MealType.almuerzo],
    );

    expect(assignments, isEmpty);
  });
}
