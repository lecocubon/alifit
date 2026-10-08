import 'recipe.dart';

class RecipeIngredientInput {
  const RecipeIngredientInput({
    required this.foodId,
    required this.quantity,
    required this.unitLabel,
    required this.gramsEquivalent,
    this.isOptional = false,
  });

  final int foodId;
  final double quantity;
  final String unitLabel;
  final double gramsEquivalent;
  final bool isOptional;
}

abstract class RecipeRepository {
  Stream<List<Recipe>> watchRecipes();

  Stream<List<Recipe>> watchFavorites();

  Future<Recipe?> getById(int id);

  Future<int> createRecipe({
    required String name,
    required int servings,
    required List<RecipeIngredientInput> ingredients,
    int? prepMinutes,
    String? instructions,
    List<String> tags = const [],
    List<String> otherIngredients = const [],
    double? costEstimate,
  });

  Future<void> updateRecipe({
    required int id,
    required String name,
    required int servings,
    required List<RecipeIngredientInput> ingredients,
    int? prepMinutes,
    String? instructions,
    List<String> tags = const [],
    List<String> otherIngredients = const [],
    double? costEstimate,
  });

  Future<int> duplicateRecipe(int id);

  Future<void> deleteRecipe(int id);

  Future<void> setFavorite(int id, bool isFavorite);
}
