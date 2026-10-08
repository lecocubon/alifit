enum InventoryLocation {
  pantry,
  refrigerator,
  freezer,
  other;

  String get label => switch (this) {
    InventoryLocation.pantry => 'Despensa',
    InventoryLocation.refrigerator => 'Refrigerador',
    InventoryLocation.freezer => 'Congelador',
    InventoryLocation.other => 'Otra',
  };

  static InventoryLocation fromStorage(String value) {
    return InventoryLocation.values.firstWhere(
      (l) => l.name == value,
      orElse: () => InventoryLocation.other,
    );
  }
}
