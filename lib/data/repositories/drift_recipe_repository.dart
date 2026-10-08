import 'package:drift/drift.dart';

import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/food_source.dart';
import '../../domain/nutrition/nutrition_values.dart';
import '../../domain/recipes/recipe.dart';
import '../../domain/recipes/recipe_repository.dart';
import '../database/app_database.dart';
import '../database/watch_tables.dart';

class DriftRecipeRepository implements RecipeRepository {
  DriftRecipeRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Recipe>> watchRecipes() {
    final query = _db.select(_db.recipes)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return _watchRecipeRows(query.get);
  }

  @override
  Stream<List<Recipe>> watchFavorites() {
    final query = _db.select(_db.recipes)
      ..where((t) => t.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return _watchRecipeRows(query.get);
  }

  // Se observan también los ingredientes y alimentos: con solo la tabla
  // recipes, una receta recién creada quedaba mostrando solo los
  // ingredientes que alcanzaban a insertarse antes de la primera lectura.
  Stream<List<Recipe>> _watchRecipeRows(
    Future<List<RecipeRow>> Function() fetch,
  ) {
    return _db
        .watchTables({_db.recipes, _db.recipeIngredients, _db.foods})
        .asyncMap((_) async {
          final rows = await fetch();
          return Future.wait(rows.map(_toDomain));
        });
  }

  @override
  Future<Recipe?> getById(int id) async {
    final row = await (_db.select(
      _db.recipes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toDomain(row);
  }

  @override
  Future<int> createRecipe({
    required String name,
    required int servings,
    required List<RecipeIngredientInput> ingredients,
    int? prepMinutes,
    String? instructions,
    List<String> tags = const [],
    List<String> otherIngredients = const [],
    double? costEstimate,
  }) {
    return _db.transaction(() async {
      final id = await _db
          .into(_db.recipes)
          .insert(
            RecipesCompanion.insert(
              name: name,
              servings: Value(servings),
              prepMinutes: Value(prepMinutes),
              instructions: Value(instructions),
              tags: Value(tags.join(',')),
              otherIngredients: Value(otherIngredients.join('\n')),
              costEstimate: Value(costEstimate),
            ),
          );
      await _insertIngredients(id, ingredients);
      return id;
    });
  }

  @override
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
  }) {
    return _db.transaction(() async {
      await (_db.update(_db.recipes)..where((t) => t.id.equals(id))).write(
        RecipesCompanion(
          name: Value(name),
          servings: Value(servings),
          prepMinutes: Value(prepMinutes),
          instructions: Value(instructions),
          tags: Value(tags.join(',')),
          otherIngredients: Value(otherIngredients.join('\n')),
          costEstimate: Value(costEstimate),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (_db.delete(
        _db.recipeIngredients,
      )..where((t) => t.recipeId.equals(id))).go();
      await _insertIngredients(id, ingredients);
    });
  }

  Future<void> _insertIngredients(
    int recipeId,
    List<RecipeIngredientInput> ingredients,
  ) async {
    for (final ingredient in ingredients) {
      await _db
          .into(_db.recipeIngredients)
          .insert(
            RecipeIngredientsCompanion.insert(
              recipeId: recipeId,
              foodId: ingredient.foodId,
              quantity: ingredient.quantity,
              unitLabel: ingredient.unitLabel,
              gramsEquivalent: ingredient.gramsEquivalent,
              isOptional: Value(ingredient.isOptional),
            ),
          );
    }
  }

  @override
  Future<int> duplicateRecipe(int id) async {
    final original = await getById(id);
    if (original == null) {
      throw ArgumentError('Receta no encontrada: $id');
    }
    return createRecipe(
      name: '${original.name} (copia)',
      servings: original.servings,
      prepMinutes: original.prepMinutes,
      instructions: original.instructions,
      tags: original.tags,
      otherIngredients: original.otherIngredients,
      costEstimate: original.costEstimate,
      ingredients: original.ingredients
          .map(
            (i) => RecipeIngredientInput(
              foodId: i.food.id,
              quantity: i.quantity,
              unitLabel: i.unitLabel,
              gramsEquivalent: i.gramsEquivalent,
              isOptional: i.isOptional,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> deleteRecipe(int id) async {
    await (_db.delete(
      _db.recipeIngredients,
    )..where((t) => t.recipeId.equals(id))).go();
    await (_db.delete(_db.recipes)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> setFavorite(int id, bool isFavorite) {
    return (_db.update(_db.recipes)..where((t) => t.id.equals(id))).write(
      RecipesCompanion(isFavorite: Value(isFavorite)),
    );
  }

  Future<Recipe> _toDomain(RecipeRow row) async {
    final ingredientRows = await (_db.select(
      _db.recipeIngredients,
    )..where((t) => t.recipeId.equals(row.id))).get();

    final ingredients = <RecipeIngredient>[];
    for (final ingredientRow in ingredientRows) {
      final foodRow = await (_db.select(
        _db.foods,
      )..where((t) => t.id.equals(ingredientRow.foodId))).getSingleOrNull();
      if (foodRow == null) {
        continue;
      }
      ingredients.add(
        RecipeIngredient(
          id: ingredientRow.id,
          food: _foodFromRow(foodRow),
          quantity: ingredientRow.quantity,
          unitLabel: ingredientRow.unitLabel,
          gramsEquivalent: ingredientRow.gramsEquivalent,
          isOptional: ingredientRow.isOptional,
        ),
      );
    }

    return Recipe(
      id: row.id,
      name: row.name,
      servings: row.servings,
      ingredients: ingredients,
      prepMinutes: row.prepMinutes,
      instructions: row.instructions,
      tags: row.tags.isEmpty ? [] : row.tags.split(','),
      otherIngredients: row.otherIngredients.isEmpty
          ? []
          : row.otherIngredients.split('\n'),
      costEstimate: row.costEstimate,
      isFavorite: row.isFavorite,
    );
  }

  Food _foodFromRow(FoodRow row) {
    return Food(
      id: row.id,
      name: row.name,
      source: FoodSource.fromStorage(row.source),
      baseUnit: row.baseUnit,
      completeness: FoodCompleteness.fromStorage(row.completeness),
      isFavorite: row.isFavorite,
      brand: row.brand,
      barcode: row.barcode,
      notes: row.notes,
      datasetDate: row.datasetDate,
      nutritionPer100: NutritionValues(
        calories: row.calories,
        carbs: row.carbs,
        protein: row.protein,
        fat: row.fat,
        fiber: row.fiber,
        sugar: row.sugar,
        sodium: row.sodium,
        saturatedFat: row.saturatedFat,
        cholesterol: row.cholesterol,
        calcium: row.calcium,
        iron: row.iron,
        potassium: row.potassium,
      ),
    );
  }
}
