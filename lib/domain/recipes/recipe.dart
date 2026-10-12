import '../nutrition/food.dart';
import '../nutrition/nutrition_values.dart';

class RecipeIngredient {
  const RecipeIngredient({
    required this.id,
    required this.food,
    required this.quantity,
    required this.unitLabel,
    required this.gramsEquivalent,
    this.isOptional = false,
  });

  final int id;
  final Food food;
  final double quantity;
  final String unitLabel;
  final double gramsEquivalent;
  final bool isOptional;

  NutritionValues get nutrition =>
      food.nutritionPer100.scaledToGrams(gramsEquivalent);
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.servings,
    required this.ingredients,
    this.prepMinutes,
    this.instructions,
    this.tags = const [],
    this.otherIngredients = const [],
    this.costEstimate,
    this.isFavorite = false,
  });

  final int id;
  final String name;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final int? prepMinutes;
  final String? instructions;
  final List<String> tags;

  /// Ingredientes que no se cuentan en la información nutricional (agua,
  /// sal, levadura, condimentos a gusto, etc.), ya con su cantidad
  /// incluida en el texto (ej. "Levadura seca, 7 g").
  final List<String> otherIngredients;
  final double? costEstimate;
  final bool isFavorite;

  NutritionValues get totalNutrition => ingredients
      .where((i) => !i.isOptional)
      .fold(NutritionValues.zero, (sum, i) => sum + i.nutrition);

  NutritionValues get nutritionPerServing =>
      totalNutrition.scaledBy(servings > 0 ? 1 / servings : 0);

  /// Los ingredientes con sus cantidades llevadas de la receta completa a
  /// [portions] porciones. Los opcionales no cuentan para la nutrición de
  /// la receta, así que solo se incluyen si se pide.
  List<RecipeIngredient> ingredientsFor(
    double portions, {
    bool includeOptional = false,
  }) {
    final factor = servings > 0 ? portions / servings : portions;
    return ingredients
        .where((i) => includeOptional || !i.isOptional)
        .map(
          (i) => RecipeIngredient(
            id: i.id,
            food: i.food,
            quantity: i.quantity * factor,
            unitLabel: i.unitLabel,
            gramsEquivalent: i.gramsEquivalent * factor,
            isOptional: i.isOptional,
          ),
        )
        .toList();
  }
}
