enum ChronicCondition {
  diabetes,
  hypertension,
  lactoseIntolerance,
  other;

  String get label => switch (this) {
    ChronicCondition.diabetes => 'Diabetes',
    ChronicCondition.hypertension => 'Hipertensión',
    ChronicCondition.lactoseIntolerance => 'Intolerancia a la lactosa',
    ChronicCondition.other => 'Otra',
  };

  static ChronicCondition? fromStorage(String value) {
    for (final condition in ChronicCondition.values) {
      if (condition.name == value) {
        return condition;
      }
    }
    return null;
  }
}
