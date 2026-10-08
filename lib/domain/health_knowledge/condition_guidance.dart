class KnowledgeSource {
  const KnowledgeSource({required this.name, required this.url});

  final String name;
  final String url;
}

/// Nota sobre un nutriente relevante para una condición (ej. límite de
/// sodio en hipertensión). [maxPerDay] queda disponible para que el motor
/// de menús (Fase 5) pueda puntuar recetas, no se muestra directamente.
class NutrientNote {
  const NutrientNote({
    required this.nutrientKey,
    required this.guidance,
    this.maxPerDay,
    this.minPerDay,
  });

  /// Debe coincidir con un campo de NutritionValues (sodium, fiber, etc.).
  final String nutrientKey;
  final String guidance;
  final double? maxPerDay;
  final double? minPerDay;
}

/// Pautas dietéticas generales (no clínicas, no farmacológicas) para una
/// condición crónica, pensadas como insumo para el motor de menús y
/// búsqueda, no como consejo médico. Todo el contenido debe poder
/// rastrearse a una fuente en [sources].
class ConditionGuidance {
  const ConditionGuidance({
    required this.title,
    required this.summary,
    required this.foodsToPrioritize,
    required this.foodsToLimit,
    required this.nutrientNotes,
    required this.sources,
    this.additionalNote,
  });

  final String title;
  final String summary;
  final List<String> foodsToPrioritize;
  final List<String> foodsToLimit;
  final List<NutrientNote> nutrientNotes;
  final List<KnowledgeSource> sources;

  /// Nota adicional específica (ej. matices por subtipo de diabetes).
  final String? additionalNote;
}
