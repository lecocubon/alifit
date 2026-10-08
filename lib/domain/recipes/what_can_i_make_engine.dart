import '../inventory/inventory_item.dart';
import 'recipe.dart';

class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.available,
    required this.missing,
  });

  final Recipe recipe;
  final List<RecipeIngredient> available;
  final List<RecipeIngredient> missing;
}

/// Compara las recetas guardadas contra el inventario disponible y
/// propone las más viables, sin inventar ingredientes: solo cuenta como
/// "disponible" un ingrediente cuyo [RecipeIngredient.food.id] coincide
/// exactamente con un [InventoryItem.food.id] en el inventario.
///
/// Prioriza: 1) recetas con menos ingredientes faltantes, 2) entre
/// empates, las que usan más ingredientes próximos a vencer (para evitar
/// desperdicio).
List<RecipeMatch> findRecipeMatches(
  List<Recipe> recipes,
  List<InventoryItem> inventory, {
  int maxResults = 5,
}) {
  final availableFoodIds = inventory.map((i) => i.food.id).toSet();
  final expiringSoonFoodIds = inventory
      .where((i) => i.isExpiringSoon && !i.isExpired)
      .map((i) => i.food.id)
      .toSet();

  final matches = recipes.map((recipe) {
    final available = <RecipeIngredient>[];
    final missing = <RecipeIngredient>[];
    for (final ingredient in recipe.ingredients) {
      if (availableFoodIds.contains(ingredient.food.id)) {
        available.add(ingredient);
      } else {
        missing.add(ingredient);
      }
    }
    return RecipeMatch(recipe: recipe, available: available, missing: missing);
  }).toList();

  int expiringSoonCount(RecipeMatch match) => match.available
      .where((i) => expiringSoonFoodIds.contains(i.food.id))
      .length;

  matches.sort((a, b) {
    final byMissing = a.missing.length.compareTo(b.missing.length);
    if (byMissing != 0) {
      return byMissing;
    }
    return expiringSoonCount(b).compareTo(expiringSoonCount(a));
  });

  final limit = maxResults.clamp(0, matches.length);
  return matches.take(limit).toList();
}
