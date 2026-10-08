import 'package:drift/drift.dart';

import '../../domain/inventory/inventory_item.dart';
import '../../domain/inventory/inventory_location.dart';
import '../../domain/inventory/inventory_repository.dart';
import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/food_source.dart';
import '../../domain/nutrition/nutrition_values.dart';
import '../database/app_database.dart';
import '../database/watch_tables.dart';

class DriftInventoryRepository implements InventoryRepository {
  DriftInventoryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<InventoryItem>> watchItems() {
    final query = _db.select(_db.inventoryItems)
      ..orderBy([(t) => OrderingTerm.asc(t.expiresAt)]);
    return _db.watchTables({_db.inventoryItems, _db.foods}).asyncMap((_) async {
      final rows = await query.get();
      return Future.wait(rows.map(_toDomain));
    });
  }

  @override
  Future<void> addItem({
    required int foodId,
    required double quantity,
    required String unitLabel,
    required InventoryLocation location,
    DateTime? expiresAt,
    String? notes,
  }) {
    return _db
        .into(_db.inventoryItems)
        .insert(
          InventoryItemsCompanion.insert(
            foodId: foodId,
            quantity: quantity,
            unitLabel: unitLabel,
            location: Value(location.name),
            expiresAt: Value(expiresAt),
            notes: Value(notes),
          ),
        );
  }

  @override
  Future<void> updateItem({
    required int id,
    required double quantity,
    required String unitLabel,
    required InventoryLocation location,
    DateTime? expiresAt,
    String? notes,
  }) {
    return (_db.update(
      _db.inventoryItems,
    )..where((t) => t.id.equals(id))).write(
      InventoryItemsCompanion(
        quantity: Value(quantity),
        unitLabel: Value(unitLabel),
        location: Value(location.name),
        expiresAt: Value(expiresAt),
        notes: Value(notes),
      ),
    );
  }

  @override
  Future<void> deleteItem(int id) {
    return (_db.delete(_db.inventoryItems)..where((t) => t.id.equals(id))).go();
  }

  Future<InventoryItem> _toDomain(InventoryItemRow row) async {
    final foodRow = await (_db.select(
      _db.foods,
    )..where((t) => t.id.equals(row.foodId))).getSingle();

    return InventoryItem(
      id: row.id,
      food: Food(
        id: foodRow.id,
        name: foodRow.name,
        source: FoodSource.fromStorage(foodRow.source),
        baseUnit: foodRow.baseUnit,
        completeness: FoodCompleteness.fromStorage(foodRow.completeness),
        isFavorite: foodRow.isFavorite,
        brand: foodRow.brand,
        barcode: foodRow.barcode,
        notes: foodRow.notes,
        datasetDate: foodRow.datasetDate,
        nutritionPer100: NutritionValues(
          calories: foodRow.calories,
          carbs: foodRow.carbs,
          protein: foodRow.protein,
          fat: foodRow.fat,
          fiber: foodRow.fiber,
          sugar: foodRow.sugar,
          sodium: foodRow.sodium,
          saturatedFat: foodRow.saturatedFat,
          cholesterol: foodRow.cholesterol,
          calcium: foodRow.calcium,
          iron: foodRow.iron,
          potassium: foodRow.potassium,
        ),
      ),
      quantity: row.quantity,
      unitLabel: row.unitLabel,
      location: InventoryLocation.fromStorage(row.location),
      addedAt: row.addedAt,
      expiresAt: row.expiresAt,
      notes: row.notes,
    );
  }
}
