import 'nutrition_values.dart';

class DailyNutritionTotal {
  const DailyNutritionTotal({required this.date, required this.totals});

  final DateTime date;
  final NutritionValues totals;
}
