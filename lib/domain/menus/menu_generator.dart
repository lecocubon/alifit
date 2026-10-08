import '../inventory/inventory_item.dart';
import '../nutrition/meal_type.dart';
import '../recipes/recipe.dart';

typedef MenuSlot = ({DateTime date, MealType mealType});

class MenuSlotAssignment {
  const MenuSlotAssignment({
    required this.date,
    required this.mealType,
    required this.recipe,
  });

  final DateTime date;
  final MealType mealType;
  final Recipe recipe;
}

const List<MealType> defaultGeneratedMealTypes = [
  MealType.desayuno,
  MealType.almuerzo,
  MealType.once,
  MealType.cena,
];

/// Rellena, con recetas guardadas, los espacios vacíos de un menú semanal.
///
/// Motor basado en reglas simples (sin IA): para cada espacio vacío,
/// prioriza 1) recetas con menos ingredientes faltantes respecto al
/// inventario, 2) entre empates, las que aprovechan ingredientes próximos
/// a vencer, 3) variedad (evita repetir una misma receta más de
/// [maxRepeatsPerRecipe] veces salvo que no existan alternativas), y
/// 4) recetas simples (30 minutos o menos de preparación).
List<MenuSlotAssignment> generateWeeklyMenu({
  required List<DateTime> days,
  required List<Recipe> recipes,
  required List<InventoryItem> inventory,
  List<MealType> mealTypes = defaultGeneratedMealTypes,
  Set<MenuSlot> alreadyFilled = const {},
  int maxRepeatsPerRecipe = 2,
}) {
  if (recipes.isEmpty) {
    return const [];
  }

  final availableFoodIds = inventory.map((i) => i.food.id).toSet();
  final expiringSoonFoodIds = inventory
      .where((i) => i.isExpiringSoon && !i.isExpired)
      .map((i) => i.food.id)
      .toSet();

  int missingCount(Recipe recipe) => recipe.ingredients
      .where((i) => !availableFoodIds.contains(i.food.id))
      .length;

  int expiringSoonCount(Recipe recipe) => recipe.ingredients
      .where((i) => expiringSoonFoodIds.contains(i.food.id))
      .length;

  final usageCount = <int, int>{};
  final assignments = <MenuSlotAssignment>[];

  for (final date in days) {
    for (final mealType in mealTypes) {
      final slot = (date: date, mealType: mealType);
      if (alreadyFilled.contains(slot)) {
        continue;
      }

      var candidates = recipes
          .where((r) => (usageCount[r.id] ?? 0) < maxRepeatsPerRecipe)
          .toList();
      if (candidates.isEmpty) {
        // Todas las recetas alcanzaron el tope de repeticiones: se
        // permite reutilizar para no dejar el espacio vacío.
        candidates = recipes.toList();
      }

      candidates.sort((a, b) {
        final byMissing = missingCount(a).compareTo(missingCount(b));
        if (byMissing != 0) {
          return byMissing;
        }
        final byExpiring = expiringSoonCount(b).compareTo(expiringSoonCount(a));
        if (byExpiring != 0) {
          return byExpiring;
        }
        final aQuick = a.prepMinutes != null && a.prepMinutes! <= 30;
        final bQuick = b.prepMinutes != null && b.prepMinutes! <= 30;
        if (aQuick != bQuick) {
          return aQuick ? -1 : 1;
        }
        final byUsage = (usageCount[a.id] ?? 0).compareTo(
          usageCount[b.id] ?? 0,
        );
        if (byUsage != 0) {
          return byUsage;
        }
        return a.id.compareTo(b.id);
      });

      final chosen = candidates.first;
      usageCount[chosen.id] = (usageCount[chosen.id] ?? 0) + 1;
      assignments.add(
        MenuSlotAssignment(date: date, mealType: mealType, recipe: chosen),
      );
    }
  }

  return assignments;
}
