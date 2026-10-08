enum FoodSource {
  usda,
  chile,
  user,
  openFoodFacts;

  String get label => switch (this) {
    FoodSource.usda => 'USDA FoodData Central',
    FoodSource.chile => 'Catálogo chileno',
    FoodSource.user => 'Creado por ti',
    FoodSource.openFoodFacts => 'Open Food Facts',
  };

  static FoodSource fromStorage(String value) {
    return FoodSource.values.firstWhere(
      (source) => source.name == value,
      orElse: () => FoodSource.user,
    );
  }
}

enum FoodCompleteness {
  complete,
  partial;

  static FoodCompleteness fromStorage(String value) {
    return FoodCompleteness.values.firstWhere(
      (c) => c.name == value,
      orElse: () => FoodCompleteness.partial,
    );
  }
}
