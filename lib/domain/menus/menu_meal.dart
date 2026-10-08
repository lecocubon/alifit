import '../nutrition/meal_type.dart';
import '../nutrition/nutrition_values.dart';
import '../recipes/recipe.dart';

class MenuMeal {
  const MenuMeal({
    required this.id,
    required this.menuPlanId,
    required this.date,
    required this.mealType,
    this.recipe,
    this.freeformLabel,
    this.servings = 1,
    this.notes,
  });

  final int id;
  final int menuPlanId;
  final DateTime date;
  final MealType mealType;
  final Recipe? recipe;
  final String? freeformLabel;
  final double servings;
  final String? notes;

  String get displayName => recipe?.name ?? freeformLabel ?? 'Comida libre';

  NutritionValues? get nutrition {
    final recipe = this.recipe;
    if (recipe == null) {
      return null;
    }
    return recipe.nutritionPerServing.scaledBy(servings);
  }
}
