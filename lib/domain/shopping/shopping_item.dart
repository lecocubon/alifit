import 'shopping_category.dart';

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.menuPlanId,
    this.foodId,
    required this.name,
    required this.quantity,
    required this.unitLabel,
    required this.category,
    this.isOptional = false,
    this.isManual = false,
    this.isChecked = false,
    this.manualPrice,
    this.notes,
  });

  final int id;
  final int menuPlanId;
  final int? foodId;
  final String name;
  final double quantity;
  final String unitLabel;
  final ShoppingCategory category;
  final bool isOptional;
  final bool isManual;
  final bool isChecked;
  final double? manualPrice;
  final String? notes;
}

/// Producto propuesto por el generador antes de guardarse en la base de
/// datos (todavía no tiene id).
class ShoppingItemDraft {
  const ShoppingItemDraft({
    this.foodId,
    required this.name,
    required this.quantity,
    required this.unitLabel,
    required this.category,
    this.isOptional = false,
  });

  final int? foodId;
  final String name;
  final double quantity;
  final String unitLabel;
  final ShoppingCategory category;
  final bool isOptional;
}
