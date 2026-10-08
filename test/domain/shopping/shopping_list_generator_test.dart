import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/domain/inventory/inventory_item.dart';
import 'package:alifit/domain/inventory/inventory_location.dart';
import 'package:alifit/domain/menus/menu_meal.dart';
import 'package:alifit/domain/nutrition/food.dart';
import 'package:alifit/domain/nutrition/food_source.dart';
import 'package:alifit/domain/nutrition/meal_type.dart';
import 'package:alifit/domain/nutrition/nutrition_values.dart';
import 'package:alifit/domain/recipes/recipe.dart';
import 'package:alifit/domain/shopping/shopping_category.dart';
import 'package:alifit/domain/shopping/shopping_list_generator.dart';

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

RecipeIngredient _ingredient(
  Food food, {
  double grams = 100,
  bool isOptional = false,
}) {
  return RecipeIngredient(
    id: food.id,
    food: food,
    quantity: grams,
    unitLabel: 'g',
    gramsEquivalent: grams,
    isOptional: isOptional,
  );
}

MenuMeal _meal(int id, Recipe recipe, {double servings = 1}) {
  return MenuMeal(
    id: id,
    menuPlanId: 1,
    date: DateTime(2026, 7, 20),
    mealType: MealType.almuerzo,
    recipe: recipe,
    servings: servings,
  );
}

void main() {
  final rice = _food(1, 'Arroz');
  final chicken = _food(2, 'Pollo');

  test('agrega ingredientes escalados por porciones planificadas', () {
    // Receta de 2 porciones con 200g de arroz (100g/porción).
    final recipe = Recipe(
      id: 1,
      name: 'Arroz simple',
      servings: 2,
      ingredients: [_ingredient(rice, grams: 200)],
    );
    // Se planifica 1 porción -> se necesita la mitad del lote: 100g.
    final meals = [_meal(1, recipe, servings: 1)];

    final drafts = generateShoppingList(meals: meals, inventory: const []);

    expect(drafts, hasLength(1));
    expect(drafts.first.name, 'Arroz');
    expect(drafts.first.quantity, closeTo(100, 0.01));
    expect(drafts.first.unitLabel, 'g');
    expect(drafts.first.category, ShoppingCategory.despensa);
  });

  test('descuenta lo que ya hay en inventario (en gramos/ml)', () {
    final recipe = Recipe(
      id: 1,
      name: 'Arroz simple',
      servings: 1,
      ingredients: [_ingredient(rice, grams: 300)],
    );
    final meals = [_meal(1, recipe)];
    final inventory = [
      InventoryItem(
        id: 1,
        food: rice,
        quantity: 200,
        unitLabel: 'g',
        location: InventoryLocation.pantry,
        addedAt: DateTime.now(),
      ),
    ];

    final drafts = generateShoppingList(meals: meals, inventory: inventory);

    expect(drafts, hasLength(1));
    expect(drafts.first.quantity, closeTo(100, 0.01));
  });

  test('si el inventario cubre todo, no aparece en la lista', () {
    final recipe = Recipe(
      id: 1,
      name: 'Arroz simple',
      servings: 1,
      ingredients: [_ingredient(rice, grams: 100)],
    );
    final meals = [_meal(1, recipe)];
    final inventory = [
      InventoryItem(
        id: 1,
        food: rice,
        quantity: 500,
        unitLabel: 'g',
        location: InventoryLocation.pantry,
        addedAt: DateTime.now(),
      ),
    ];

    final drafts = generateShoppingList(meals: meals, inventory: inventory);

    expect(drafts, isEmpty);
  });

  test('suma el mismo ingrediente entre varias comidas', () {
    final recipe = Recipe(
      id: 1,
      name: 'Arroz simple',
      servings: 1,
      ingredients: [_ingredient(rice, grams: 100)],
    );
    final meals = [_meal(1, recipe), _meal(2, recipe)];

    final drafts = generateShoppingList(meals: meals, inventory: const []);

    expect(drafts, hasLength(1));
    expect(drafts.first.quantity, closeTo(200, 0.01));
  });

  test('marca como opcional solo si todas las apariciones lo son', () {
    final recipeOptional = Recipe(
      id: 1,
      name: 'Con pollo opcional',
      servings: 1,
      ingredients: [_ingredient(chicken, grams: 100, isOptional: true)],
    );
    final recipeRequired = Recipe(
      id: 2,
      name: 'Con pollo obligatorio',
      servings: 1,
      ingredients: [_ingredient(chicken, grams: 100)],
    );

    final onlyOptional = generateShoppingList(
      meals: [_meal(1, recipeOptional)],
      inventory: const [],
    );
    expect(onlyOptional.first.isOptional, isTrue);

    final mixed = generateShoppingList(
      meals: [_meal(1, recipeOptional), _meal(2, recipeRequired)],
      inventory: const [],
    );
    expect(mixed.first.isOptional, isFalse);
  });

  test('las comidas libres (sin receta) no aportan ingredientes', () {
    final freeform = MenuMeal(
      id: 1,
      menuPlanId: 1,
      date: DateTime(2026, 7, 20),
      mealType: MealType.desayuno,
      freeformLabel: 'Fruta libre',
    );

    final drafts = generateShoppingList(meals: [freeform], inventory: const []);

    expect(drafts, isEmpty);
  });
}
