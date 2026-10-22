import 'package:drift/drift.dart';

import '../../core/text/text_normalize.dart';
import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/food_repository.dart';
import '../../domain/nutrition/food_source.dart';
import '../../domain/nutrition/nutrition_values.dart';
import '../database/app_database.dart';
import '../database/watch_tables.dart';

class DriftFoodRepository implements FoodRepository {
  DriftFoodRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Food>> watchRecents({int limit = 10}) {
    final query = _db.selectOnly(_db.mealItems, distinct: true)
      ..addColumns([_db.mealItems.foodId])
      ..orderBy([OrderingTerm.desc(_db.mealItems.createdAt)])
      ..limit(limit);

    return _db
        .watchTables({_db.mealItems, _db.foods, _db.foodServings})
        .asyncMap((_) async {
          final rows = await query.get();
          final ids = rows.map((r) => r.read(_db.mealItems.foodId)!).toList();
          final foods = <Food>[];
          for (final id in ids) {
            final food = await getById(id);
            if (food != null) {
              foods.add(food);
            }
          }
          return foods;
        });
  }

  @override
  Stream<List<Food>> watchFavorites() {
    final query = _db.select(_db.foods)
      ..where((t) => t.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return _db.watchTables({_db.foods, _db.foodServings}).asyncMap((_) async {
      final rows = await query.get();
      return Future.wait(rows.map(_toDomain));
    });
  }

  @override
  Future<List<Food>> search(String query, {int limit = 30}) async {
    final normalized = normalizeForSearch(query);
    if (normalized.isEmpty) {
      final rows =
          await (_db.select(_db.foods)
                ..orderBy([(t) => OrderingTerm.asc(t.name)])
                ..limit(limit))
              .get();
      return Future.wait(rows.map((row) => _toDomain(row)));
    }

    // Cada palabra de la búsqueda debe aparecer en el nombre, en cualquier
    // orden ("semillas zapallo" encuentra "Pepitas de Zapallo (Semillas de
    // Calabaza)").
    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    Expression<bool> containsAllTokens(GeneratedColumn<String> column) => tokens
        .map<Expression<bool>>((token) => column.like('%$token%'))
        .reduce((a, b) => a & b);

    final matchingFoodIds = _db.selectOnly(_db.foodAliases)
      ..addColumns([_db.foodAliases.foodId])
      ..where(containsAllTokens(_db.foodAliases.normalizedAlias));

    // Se trae un conjunto más amplio de coincidencias directas del que se
    // necesita para poder reordenarlas por relevancia antes de aplicar el
    // límite final; si no, un alimento genérico como "pasta" puede quedar
    // enterrado entre platos preparados o de marca que también contienen
    // la palabra (ej. "Pasta Cuatro Quesos" antes que la pasta seca sola).
    final directRows =
        await (_db.select(_db.foods)
              ..where((t) => containsAllTokens(t.normalizedName))
              ..limit(limit * 4))
            .get();

    final aliasFoodIds = (await matchingFoodIds.get())
        .map((r) => r.read(_db.foodAliases.foodId)!)
        .toSet();
    aliasFoodIds.removeAll(directRows.map((r) => r.id));

    final aliasRows = aliasFoodIds.isEmpty
        ? <FoodRow>[]
        : await (_db.select(
            _db.foods,
          )..where((t) => t.id.isIn(aliasFoodIds))).get();

    final rankedDirect = _rankByRelevance(directRows, normalized);
    final combined = [...rankedDirect, ...aliasRows].take(limit).toList();
    return Future.wait(combined.map(_toDomain));
  }

  /// Prioriza coincidencias exactas, luego nombres que empiezan con la
  /// búsqueda, y dentro de cada nivel los nombres más cortos primero (los
  /// alimentos genéricos suelen tener nombres más simples que los platos
  /// preparados o de marca con muchos calificadores).
  List<FoodRow> _rankByRelevance(List<FoodRow> rows, String normalizedQuery) {
    int score(FoodRow row) {
      final name = row.normalizedName;
      if (name == normalizedQuery) {
        return 0;
      }
      if (name.startsWith(normalizedQuery)) {
        return 1;
      }
      if (name.contains(normalizedQuery)) {
        return 2;
      }
      return 3;
    }

    final sorted = [...rows];
    sorted.sort((a, b) {
      final scoreDiff = score(a).compareTo(score(b));
      if (scoreDiff != 0) {
        return scoreDiff;
      }
      return a.name.length.compareTo(b.name.length);
    });
    return sorted;
  }

  @override
  Future<Food?> getById(int id) async {
    final row = await (_db.select(
      _db.foods,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toDomain(row);
  }

  @override
  Future<Food?> getByBarcode(String barcode) async {
    // Puede haber más de un alimento con el mismo código (ej. uno creado a
    // mano y otro de Open Food Facts): se usa el más reciente.
    final row =
        await (_db.select(_db.foods)
              ..where((t) => t.barcode.equals(barcode))
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toDomain(row);
  }

  @override
  Future<int> createFood({
    required String name,
    String? brand,
    required NutritionValues nutritionPer100,
    required String baseUnit,
    String? barcode,
    String? notes,
    FoodSource source = FoodSource.user,
  }) {
    return _db
        .into(_db.foods)
        .insert(
          FoodsCompanion.insert(
            name: name,
            normalizedName: normalizeForSearch(name),
            source: Value(source.name),
            brand: Value(brand),
            barcode: Value(barcode),
            notes: Value(notes),
            baseUnit: Value(baseUnit),
            calories: nutritionPer100.calories,
            carbs: nutritionPer100.carbs,
            protein: nutritionPer100.protein,
            fat: nutritionPer100.fat,
            fiber: nutritionPer100.fiber,
            sugar: nutritionPer100.sugar,
            sodium: nutritionPer100.sodium,
            completeness: const Value('complete'),
          ),
        );
  }

  @override
  Future<void> updateFood({
    required int id,
    required String name,
    String? brand,
    required NutritionValues nutritionPer100,
    required String baseUnit,
    String? barcode,
    String? notes,
  }) {
    return (_db.update(_db.foods)..where((t) => t.id.equals(id))).write(
      FoodsCompanion(
        name: Value(name),
        normalizedName: Value(normalizeForSearch(name)),
        brand: Value(brand),
        barcode: Value(barcode),
        notes: Value(notes),
        baseUnit: Value(baseUnit),
        calories: Value(nutritionPer100.calories),
        carbs: Value(nutritionPer100.carbs),
        protein: Value(nutritionPer100.protein),
        fat: Value(nutritionPer100.fat),
        fiber: Value(nutritionPer100.fiber),
        sugar: Value(nutritionPer100.sugar),
        sodium: Value(nutritionPer100.sodium),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteFood(int id) {
    return (_db.delete(_db.foods)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> setFavorite(int foodId, bool isFavorite) {
    return (_db.update(_db.foods)..where((t) => t.id.equals(foodId))).write(
      FoodsCompanion(isFavorite: Value(isFavorite)),
    );
  }

  @override
  Stream<List<(int id, String alias)>> watchAliases(int foodId) {
    final query = _db.select(_db.foodAliases)
      ..where((t) => t.foodId.equals(foodId))
      ..orderBy([(t) => OrderingTerm.asc(t.alias)]);
    return query.watch().map(
      (rows) => rows.map((row) => (row.id, row.alias)).toList(),
    );
  }

  @override
  Future<void> addAlias(int foodId, String alias) {
    return _db
        .into(_db.foodAliases)
        .insert(
          FoodAliasesCompanion.insert(
            foodId: foodId,
            alias: alias,
            normalizedAlias: normalizeForSearch(alias),
          ),
        );
  }

  @override
  Future<void> removeAlias(int aliasId) {
    return (_db.delete(
      _db.foodAliases,
    )..where((t) => t.id.equals(aliasId))).go();
  }

  Future<Food> _toDomain(FoodRow row) async {
    final servingRows = await (_db.select(
      _db.foodServings,
    )..where((t) => t.foodId.equals(row.id))).get();

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
      servings: servingRows
          .map(
            (s) => FoodServing(
              id: s.id,
              label: s.label,
              gramsEquivalent: s.gramsEquivalent,
            ),
          )
          .toList(),
    );
  }
}
