import 'inventory_item.dart';
import 'inventory_location.dart';

abstract class InventoryRepository {
  Stream<List<InventoryItem>> watchItems();

  Future<void> addItem({
    required int foodId,
    required double quantity,
    required String unitLabel,
    required InventoryLocation location,
    DateTime? expiresAt,
    String? notes,
  });

  Future<void> updateItem({
    required int id,
    required double quantity,
    required String unitLabel,
    required InventoryLocation location,
    DateTime? expiresAt,
    String? notes,
  });

  Future<void> deleteItem(int id);
}
