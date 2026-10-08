import 'food_source.dart';
import 'nutrition_values.dart';

class FoodServing {
  const FoodServing({
    required this.id,
    required this.label,
    required this.gramsEquivalent,
  });

  final int id;
  final String label;
  final double gramsEquivalent;
}

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.source,
    required this.nutritionPer100,
    required this.baseUnit,
    required this.completeness,
    required this.isFavorite,
    this.brand,
    this.barcode,
    this.notes,
    this.datasetDate,
    this.servings = const [],
  });

  final int id;
  final String name;
  final FoodSource source;
  final NutritionValues nutritionPer100;

  /// 'g' o 'ml'.
  final String baseUnit;
  final FoodCompleteness completeness;
  final bool isFavorite;
  final String? brand;
  final String? barcode;
  final String? notes;
  final DateTime? datasetDate;
  final List<FoodServing> servings;
}
