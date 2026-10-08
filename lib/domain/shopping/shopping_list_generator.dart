import '../inventory/inventory_item.dart';
import '../menus/menu_meal.dart';
import 'food_categorizer.dart';
import 'shopping_item.dart';

class _Accumulated {
  _Accumulated({required this.foodId, required this.name})
    : grams = 0,
      allOptional = true;

  final int foodId;
  final String name;
  double grams;
  bool allOptional;
}

const _gramsBasedUnits = {'g', 'ml'};

/// Genera la lista de compras a partir de las comidas planificadas con
/// receta: suma los gramos necesarios de cada ingrediente (escalados por
/// las porciones planificadas de cada comida) y descuenta lo que ya hay
/// en el inventario (solo se descuenta inventario expresado en gramos o
/// mililitros, ya que las recetas normalizan sus ingredientes a esa base).
///
/// Las comidas sin receta (comida libre) no aportan ingredientes
/// estructurados y no se incluyen en la agregación.
List<ShoppingItemDraft> generateShoppingList({
  required List<MenuMeal> meals,
  required List<InventoryItem> inventory,
}) {
  final availableGramsByFood = <int, double>{};
  for (final item in inventory) {
    if (!_gramsBasedUnits.contains(item.unitLabel.toLowerCase())) {
      continue;
    }
    availableGramsByFood.update(
      item.food.id,
      (value) => value + item.quantity,
      ifAbsent: () => item.quantity,
    );
  }

  final accumulated = <int, _Accumulated>{};
  for (final meal in meals) {
    final recipe = meal.recipe;
    if (recipe == null || recipe.servings <= 0) {
      continue;
    }
    final fraction = meal.servings / recipe.servings;
    for (final ingredient in recipe.ingredients) {
      final entry = accumulated.putIfAbsent(
        ingredient.food.id,
        () => _Accumulated(
          foodId: ingredient.food.id,
          name: ingredient.food.name,
        ),
      );
      entry.grams += ingredient.gramsEquivalent * fraction;
      entry.allOptional = entry.allOptional && ingredient.isOptional;
    }
  }

  final drafts = <ShoppingItemDraft>[];
  for (final entry in accumulated.values) {
    final available = availableGramsByFood[entry.foodId] ?? 0;
    final remaining = entry.grams - available;
    if (remaining <= 0.5) {
      continue;
    }
    drafts.add(
      ShoppingItemDraft(
        foodId: entry.foodId,
        name: entry.name,
        quantity: remaining,
        unitLabel: 'g',
        category: categorizeFood(entry.name),
        isOptional: entry.allOptional,
      ),
    );
  }

  drafts.sort((a, b) => a.name.compareTo(b.name));
  return drafts;
}
