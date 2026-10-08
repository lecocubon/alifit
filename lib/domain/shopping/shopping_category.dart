enum ShoppingCategory {
  frutasYVerduras,
  carnes,
  lacteos,
  despensa,
  congelados,
  panaderia,
  otros;

  String get label => switch (this) {
    ShoppingCategory.frutasYVerduras => 'Frutas y verduras',
    ShoppingCategory.carnes => 'Carnes',
    ShoppingCategory.lacteos => 'Lácteos',
    ShoppingCategory.despensa => 'Despensa',
    ShoppingCategory.congelados => 'Congelados',
    ShoppingCategory.panaderia => 'Panadería',
    ShoppingCategory.otros => 'Otros',
  };

  static ShoppingCategory fromStorage(String value) {
    return ShoppingCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ShoppingCategory.otros,
    );
  }
}
