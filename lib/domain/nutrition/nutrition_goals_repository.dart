import 'nutrition_goals.dart';

abstract class NutritionGoalsRepository {
  Stream<NutritionGoals> watchGoals();

  Future<void> setGoals(NutritionGoals goals);
}
