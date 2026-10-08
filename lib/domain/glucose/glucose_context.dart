enum GlucoseContext {
  ayunas,
  antesDesayuno,
  despuesDesayuno,
  antesAlmuerzo,
  despuesAlmuerzo,
  antesCena,
  despuesCena,
  antesDeDormir,
  otro;

  String get label => switch (this) {
    GlucoseContext.ayunas => 'Ayunas',
    GlucoseContext.antesDesayuno => 'Antes de desayuno',
    GlucoseContext.despuesDesayuno => 'Después de desayuno',
    GlucoseContext.antesAlmuerzo => 'Antes de almuerzo',
    GlucoseContext.despuesAlmuerzo => 'Después de almuerzo',
    GlucoseContext.antesCena => 'Antes de cena',
    GlucoseContext.despuesCena => 'Después de cena',
    GlucoseContext.antesDeDormir => 'Antes de dormir',
    GlucoseContext.otro => 'Otro',
  };

  static GlucoseContext fromStorage(String value) {
    return GlucoseContext.values.firstWhere(
      (c) => c.name == value,
      orElse: () => GlucoseContext.otro,
    );
  }
}
