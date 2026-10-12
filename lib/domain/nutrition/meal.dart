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
    this.recipeEntryId,
  });

  final int id;
  final Food food;

  /// Cantidad ingresada por el usuario (en la unidad [unitLabel]).
  final double quantity;

  /// Texto de la unidad elegida: 'g', 'ml' o el nombre de una porción.
  final String unitLabel;

  /// Gramos/mililitros reales que representa esta cantidad, ya resuelta.
  final double gramsEquivalent;

  /// Si se registró como ingrediente de una receta, a cuál pertenece.
  final int? recipeEntryId;

  NutritionValues get nutrition =>
      food.nutritionPer100.scaledToGrams(gramsEquivalent);
}

/// Una receta registrada en una comida. Guarda el nombre y las porciones del
/// momento del registro: no cambia si después se edita o borra la receta.
class MealRecipeEntry {
  const MealRecipeEntry({
    required this.id,
    required this.name,
    required this.portions,
    this.recipeId,
  });

  final int id;
  final String name;
  final double portions;
  final int? recipeId;
}

/// Lo que el Diario muestra como un ítem de una comida.
sealed class MealLine {
  const MealLine();

  NutritionValues get nutrition;
}

class FoodLine extends MealLine {
  const FoodLine(this.item);

  final MealItem item;

  @override
  NutritionValues get nutrition => item.nutrition;
}

class RecipeLine extends MealLine {
  const RecipeLine({required this.entry, required this.items});

  final MealRecipeEntry entry;
  final List<MealItem> items;

  @override
  NutritionValues get nutrition =>
      items.fold(NutritionValues.zero, (sum, item) => sum + item.nutrition);
}

class Meal {
  const Meal({
    required this.id,
    required this.date,
    required this.type,
    required this.items,
    this.recipeEntries = const [],
    this.customLabel,
  });

  final int id;
  final DateTime date;
  final MealType type;
  final String? customLabel;

  /// Todos los alimentos de la comida, incluidos los ingredientes de las
  /// recetas registradas.
  final List<MealItem> items;
  final List<MealRecipeEntry> recipeEntries;

  String get displayLabel => type == MealType.personalizada
      ? (customLabel?.isNotEmpty == true ? customLabel! : type.label)
      : type.label;

  NutritionValues get totals =>
      items.fold(NutritionValues.zero, (sum, item) => sum + item.nutrition);

  /// Los ítems en el orden en que se registraron, con los ingredientes de
  /// cada receta agrupados en una sola línea.
  List<MealLine> get lines {
    final entriesById = {for (final entry in recipeEntries) entry.id: entry};
    final lines = <MealLine>[];
    final seenEntries = <int>{};
    for (final item in items) {
      final entry = entriesById[item.recipeEntryId];
      if (entry == null) {
        lines.add(FoodLine(item));
      } else if (seenEntries.add(entry.id)) {
        lines.add(
          RecipeLine(
            entry: entry,
            items: items.where((i) => i.recipeEntryId == entry.id).toList(),
          ),
        );
      }
    }
    return lines;
  }
}
