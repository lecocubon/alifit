import 'meal_plan.dart';

/// Plan de comidas importado desde un archivo de perfil.
abstract class MealPlanRepository {
  /// Emite null mientras no se haya importado ningún plan.
  Stream<MealPlan?> watchPlan();

  Future<void> savePlan(String planJson);

  Future<void> clearPlan();
}
