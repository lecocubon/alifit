import 'food.dart';
import 'food_source.dart';
import 'nutrition_values.dart';

abstract class FoodRepository {
  Stream<List<Food>> watchRecents({int limit = 10});

  Stream<List<Food>> watchFavorites();

  Future<List<Food>> search(String query, {int limit = 30});

  Future<Food?> getById(int id);

  Future<Food?> getByBarcode(String barcode);

  Future<int> createFood({
    required String name,
    String? brand,
    required NutritionValues nutritionPer100,
    required String baseUnit,
    String? barcode,
    String? notes,
    FoodSource source = FoodSource.user,
  });

  Future<void> updateFood({
    required int id,
    required String name,
    String? brand,
    required NutritionValues nutritionPer100,
    required String baseUnit,
    String? barcode,
    String? notes,
  });

  Future<void> deleteFood(int id);

  Future<void> setFavorite(int foodId, bool isFavorite);

  Stream<List<(int id, String alias)>> watchAliases(int foodId);

  Future<void> addAlias(int foodId, String alias);

  Future<void> removeAlias(int aliasId);
}
