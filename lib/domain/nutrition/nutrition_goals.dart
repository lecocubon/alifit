class NutritionGoals {
  const NutritionGoals({
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  final double calories;
  final double carbs;
  final double protein;
  final double fat;

  static const defaults = NutritionGoals(
    calories: 2000,
    carbs: 250,
    protein: 100,
    fat: 65,
  );
}
