enum DiabetesType {
  type1,
  type2,
  gestational,
  lada,
  mody,
  type3c,
  prediabetes;

  String get label => switch (this) {
    DiabetesType.type1 => 'Tipo 1',
    DiabetesType.type2 => 'Tipo 2',
    DiabetesType.gestational => 'Gestacional',
    DiabetesType.lada => 'LADA (autoinmune de inicio adulto)',
    DiabetesType.mody => 'MODY',
    DiabetesType.type3c => 'Tipo 3c (pancreatogénica)',
    DiabetesType.prediabetes => 'Prediabetes',
  };

  static DiabetesType? fromStorage(String? value) {
    if (value == null) {
      return null;
    }
    for (final type in DiabetesType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }
}
