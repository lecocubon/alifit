import 'daily_nutrition_total.dart';
import 'meal.dart';
import 'meal_type.dart';

/// Un ingrediente de una receta al registrarla en una comida, con la
/// cantidad ya ajustada a las porciones que se comieron.
class MealRecipeItemInput {
  const MealRecipeItemInput({
    required this.foodId,
    required this.quantity,
    required this.unitLabel,
    required this.gramsEquivalent,
  });

  final int foodId;
  final double quantity;
  final String unitLabel;
  final double gramsEquivalent;
}

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

  /// Registra una receta en una comida como un solo ítem del Diario, con
  /// sus ingredientes en [items].
  Future<void> addRecipe({
    required DateTime date,
    required MealType type,
    String? customLabel,
    int? recipeId,
    required String recipeName,
    required double portions,
    required List<MealRecipeItemInput> items,
  });

  Future<void> updateItemQuantity({
    required int mealItemId,
    required double quantity,
    required String unitLabel,
    required double gramsEquivalent,
  });

  Future<void> removeItem(int mealItemId);

  /// Quita de la comida una receta registrada, con todos sus ingredientes.
  Future<void> removeRecipeEntry(int recipeEntryId);

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
