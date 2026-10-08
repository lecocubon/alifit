import 'food.dart';
import 'meal_type.dart';
import 'nutrition_values.dart';

class MealItem {
  const MealItem({
    required this.id,
    required this.food,
    required this.quantity,
    required this.unitLabel,
    required this.gramsEquivalent,
  });

  final int id;
  final Food food;

  /// Cantidad ingresada por el usuario (en la unidad [unitLabel]).
  final double quantity;

  /// Texto de la unidad elegida: 'g', 'ml' o el nombre de una porción.
  final String unitLabel;

  /// Gramos/mililitros reales que representa esta cantidad, ya resuelta.
  final double gramsEquivalent;

  NutritionValues get nutrition =>
      food.nutritionPer100.scaledToGrams(gramsEquivalent);
}

class Meal {
  const Meal({
    required this.id,
    required this.date,
    required this.type,
    required this.items,
    this.customLabel,
  });

  final int id;
  final DateTime date;
  final MealType type;
  final String? customLabel;
  final List<MealItem> items;

  String get displayLabel => type == MealType.personalizada
      ? (customLabel?.isNotEmpty == true ? customLabel! : type.label)
      : type.label;

  NutritionValues get totals =>
      items.fold(NutritionValues.zero, (sum, item) => sum + item.nutrition);
}
