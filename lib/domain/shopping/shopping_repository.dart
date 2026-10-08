import 'shopping_category.dart';
import 'shopping_item.dart';

abstract class ShoppingRepository {
  Stream<List<ShoppingItem>> watchItems(int menuPlanId);

  Future<void> addManualItem({
    required int menuPlanId,
    int? foodId,
    required String name,
    required double quantity,
    required String unitLabel,
    required ShoppingCategory category,
    bool isOptional = false,
  });

  /// Reemplaza los productos generados automáticamente (no los agregados
  /// manualmente) por los recién calculados desde el menú.
  Future<void> regenerateFromMenu(
    int menuPlanId,
    List<ShoppingItemDraft> drafts,
  );

  Future<void> setChecked(int id, bool isChecked);

  Future<void> setManualPrice(int id, double? price);

  Future<void> deleteItem(int id);
}
