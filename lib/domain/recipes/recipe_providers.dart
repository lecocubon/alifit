import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_provider.dart';
import '../../data/repositories/drift_recipe_repository.dart';
import 'recipe.dart';
import 'recipe_repository.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return DriftRecipeRepository(ref.watch(databaseProvider));
});

final recipesProvider = StreamProvider<List<Recipe>>((ref) {
  return ref.watch(recipeRepositoryProvider).watchRecipes();
});

final favoriteRecipesProvider = StreamProvider<List<Recipe>>((ref) {
  return ref.watch(recipeRepositoryProvider).watchFavorites();
});
