import 'daily_nutrition_total.dart';
import 'meal.dart';
import 'meal_type.dart';

abstract class MealRepository {
  Stream<List<Meal>> watchMealsForDate(DateTime date);

  /// Totales nutricionales por día entre [startDate] y [endDate] (ambos
  /// incluidos), un elemento por día aunque no haya comidas registradas
  /// (en ese caso los totales quedan en cero).
  Future<List<DailyNutritionTotal>> getDailyTotals({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> addItem({
    required DateTime date,
    required MealType type,
    String? customLabel,
    required int foodId,
    required double quantity,
    required String unitLabel,
    required double gramsEquivalent,
  });

  Future<void> updateItemQuantity({
    required int mealItemId,
    required double quantity,
    required String unitLabel,
    required double gramsEquivalent,
  });

  Future<void> removeItem(int mealItemId);

  /// Elimina todos los alimentos de una comida, dejándola vacía.
  Future<void> clearMeal(int mealId);

  /// Copia los alimentos de una comida puntual hacia [targetDate],
  /// manteniendo el mismo tipo de comida (se suman a lo que ya exista ahí,
  /// no se duplica la comida en sí).
  Future<void> duplicateMeal({
    required int mealId,
    required DateTime targetDate,
  });

  /// Copia todas las comidas (y sus alimentos) de [sourceDate] hacia
  /// [targetDate].
  Future<void> copyMeals({
    required DateTime sourceDate,
    required DateTime targetDate,
  });
}
