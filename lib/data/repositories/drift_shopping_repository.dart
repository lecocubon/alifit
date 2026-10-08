import 'package:drift/drift.dart';

import '../../domain/shopping/shopping_category.dart';
import '../../domain/shopping/shopping_item.dart';
import '../../domain/shopping/shopping_repository.dart';
import '../database/app_database.dart';

class DriftShoppingRepository implements ShoppingRepository {
  DriftShoppingRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ShoppingItem>> watchItems(int menuPlanId) {
    final query = _db.select(_db.shoppingItems)
      ..where((t) => t.menuPlanId.equals(menuPlanId))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> addManualItem({
    required int menuPlanId,
    int? foodId,
    required String name,
    required double quantity,
    required String unitLabel,
    required ShoppingCategory category,
    bool isOptional = false,
  }) {
    return _db
        .into(_db.shoppingItems)
        .insert(
          ShoppingItemsCompanion.insert(
            menuPlanId: menuPlanId,
            foodId: Value(foodId),
            name: name,
            quantity: quantity,
            unitLabel: unitLabel,
            category: category.name,
            isOptional: Value(isOptional),
            isManual: const Value(true),
          ),
        );
  }

  @override
  Future<void> regenerateFromMenu(
    int menuPlanId,
    List<ShoppingItemDraft> drafts,
  ) async {
    await (_db.delete(_db.shoppingItems)..where(
          (t) => t.menuPlanId.equals(menuPlanId) & t.isManual.equals(false),
        ))
        .go();
    for (final draft in drafts) {
      await _db
          .into(_db.shoppingItems)
          .insert(
            ShoppingItemsCompanion.insert(
              menuPlanId: menuPlanId,
              foodId: Value(draft.foodId),
              name: draft.name,
              quantity: draft.quantity,
              unitLabel: draft.unitLabel,
              category: draft.category.name,
              isOptional: Value(draft.isOptional),
            ),
          );
    }
  }

  @override
  Future<void> setChecked(int id, bool isChecked) {
    return (_db.update(_db.shoppingItems)..where((t) => t.id.equals(id))).write(
      ShoppingItemsCompanion(isChecked: Value(isChecked)),
    );
  }

  @override
  Future<void> setManualPrice(int id, double? price) {
    return (_db.update(_db.shoppingItems)..where((t) => t.id.equals(id))).write(
      ShoppingItemsCompanion(manualPrice: Value(price)),
    );
  }

  @override
  Future<void> deleteItem(int id) {
    return (_db.delete(_db.shoppingItems)..where((t) => t.id.equals(id))).go();
  }

  ShoppingItem _toDomain(ShoppingItemRow row) {
    return ShoppingItem(
      id: row.id,
      menuPlanId: row.menuPlanId,
      foodId: row.foodId,
      name: row.name,
      quantity: row.quantity,
      unitLabel: row.unitLabel,
      category: ShoppingCategory.fromStorage(row.category),
      isOptional: row.isOptional,
      isManual: row.isManual,
      isChecked: row.isChecked,
      manualPrice: row.manualPrice,
      notes: row.notes,
    );
  }
}
