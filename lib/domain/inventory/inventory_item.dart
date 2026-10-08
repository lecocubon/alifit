import '../nutrition/food.dart';
import 'inventory_location.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.food,
    required this.quantity,
    required this.unitLabel,
    required this.location,
    required this.addedAt,
    this.expiresAt,
    this.notes,
  });

  final int id;
  final Food food;
  final double quantity;
  final String unitLabel;
  final InventoryLocation location;
  final DateTime addedAt;
  final DateTime? expiresAt;
  final String? notes;

  int? get daysUntilExpiry {
    final expiry = expiresAt;
    if (expiry == null) {
      return null;
    }
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final expiryDateOnly = DateTime(expiry.year, expiry.month, expiry.day);
    return expiryDateOnly.difference(todayDateOnly).inDays;
  }

  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 3;
  }

  bool get isExpired {
    final days = daysUntilExpiry;
    return days != null && days < 0;
  }
}
