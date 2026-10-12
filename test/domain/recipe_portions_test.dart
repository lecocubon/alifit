import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/core/text/portion_format.dart';
import 'package:alifit/domain/nutrition/food.dart';
import 'package:alifit/domain/nutrition/food_source.dart';
import 'package:alifit/domain/nutrition/nutrition_values.dart';
import 'package:alifit/domain/recipes/recipe.dart';

void main() {
  const food = Food(
    id: 1,
    name: 'Arroz Blanco',
    source: FoodSource.user,
    baseUnit: 'g',
    completeness: FoodCompleteness.complete,
    isFavorite: false,
    nutritionPer100: NutritionValues(
      calories: 130,
      carbs: 28,
      protein: 2.7,
      fat: 0.3,
      fiber: 0.4,
      sugar: 0,
      sodium: 1,
    ),
  );

  RecipeIngredient ingredient(double grams, {bool optional = false}) =>
      RecipeIngredient(
        id: grams.round(),
        food: food,
        quantity: grams,
        unitLabel: 'g',
        gramsEquivalent: grams,
        isOptional: optional,
      );

  final recipe = Recipe(
    id: 1,
    name: 'Arroz para cuatro',
    servings: 4,
    ingredients: [ingredient(400), ingredient(40, optional: true)],
  );

  test('una porción de una receta de 4 lleva un cuarto de cada ingrediente, '
      'y coincide con las kcal por porción que muestra la receta', () {
    final onePortion = recipe.ingredientsFor(1);

    expect(onePortion.single.gramsEquivalent, 100);
    expect(onePortion.single.quantity, 100);
    final kcal = onePortion.fold<double>(
      0,
      (sum, i) => sum + i.nutrition.calories,
    );
    expect(kcal, closeTo(recipe.nutritionPerServing.calories, 0.01));
  });

  test('admite medias porciones y varias porciones', () {
    expect(recipe.ingredientsFor(0.5).single.gramsEquivalent, 50);
    expect(recipe.ingredientsFor(4).single.gramsEquivalent, 400);
  });

  test('los ingredientes opcionales solo van si se piden', () {
    expect(recipe.ingredientsFor(1), hasLength(1));
    final all = recipe.ingredientsFor(1, includeOptional: true);
    expect(all.map((i) => i.gramsEquivalent), [100, 10]);
  });

  test('formatPortions usa singular solo para una porción', () {
    expect(formatPortions(1), '1 porción');
    expect(formatPortions(0.5), '0,5 porciones');
    expect(formatPortions(4), '4 porciones');
  });
}
