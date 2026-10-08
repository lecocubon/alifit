enum MealType {
  desayuno,
  colacion,
  almuerzo,
  once,
  cena,
  personalizada;

  String get label => switch (this) {
    MealType.desayuno => 'Desayuno',
    MealType.colacion => 'Colación',
    MealType.almuerzo => 'Almuerzo',
    MealType.once => 'Once',
    MealType.cena => 'Cena',
    MealType.personalizada => 'Personalizada',
  };

  static MealType fromStorage(String value) {
    return MealType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MealType.personalizada,
    );
  }
}
