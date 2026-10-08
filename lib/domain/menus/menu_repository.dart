import '../nutrition/meal_type.dart';
import 'menu_meal.dart';
import 'menu_plan.dart';

abstract class MenuRepository {
  Stream<List<MenuPlan>> watchPlans();

  Future<MenuPlan?> getPlan(int id);

  Stream<List<MenuMeal>> watchMeals(int menuPlanId);

  Future<int> createPlan({required String label, required DateTime startDate});

  Future<void> deletePlan(int id);

  /// Crea o reemplaza la comida planificada para un día y tipo de comida
  /// dados (un slot solo puede tener una comida planificada a la vez).
  Future<void> setMeal({
    required int menuPlanId,
    required DateTime date,
    required MealType mealType,
    int? recipeId,
    String? freeformLabel,
    double servings = 1,
    String? notes,
  });

  Future<void> clearMeal({
    required int menuPlanId,
    required DateTime date,
    required MealType mealType,
  });
}
