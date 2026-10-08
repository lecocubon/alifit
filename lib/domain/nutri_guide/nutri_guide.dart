import '../../core/text/decimal_format.dart';

/// Etiqueta de calidad que la guía del nutricionista asigna a un bloque de
/// alimentos (los íconos ✓, cubos con "!" / "!!", advertencia y calavera).
enum NutriQuality {
  saludable,
  igModerado,
  igAlto,
  pocoSaludable,
  altoRiesgo;

  String get label => switch (this) {
    NutriQuality.saludable => 'Saludable',
    NutriQuality.igModerado => 'IG moderado',
    NutriQuality.igAlto => 'IG alto',
    NutriQuality.pocoSaludable => 'Poco saludable',
    NutriQuality.altoRiesgo => 'Alto riesgo',
  };

  String get description => switch (this) {
    NutriQuality.saludable =>
      'Alimentos saludables y recomendados: buena calidad nutricional. Se '
          'recomienda su consumo habitual.',
    NutriQuality.igModerado =>
      'Índice glicémico moderado: generan un aumento moderado de la '
          'glucosa en sangre. Consumir con moderación.',
    NutriQuality.igAlto =>
      'Índice glicémico alto: generan un aumento rápido de la glucosa en '
          'sangre. Consumir ocasionalmente y en porciones moderadas.',
    NutriQuality.pocoSaludable =>
      'Alimentos poco saludables: altos en grasas saturadas, sodio, '
          'azúcares añadidos o altamente procesados. Limitar su consumo.',
    NutriQuality.altoRiesgo =>
      'Alimentos de alto riesgo para la salud: asociados con efectos '
          'perjudiciales para la salud, incluyendo algunos clasificados como '
          'carcinógenos. Evitar o limitar al máximo.',
  };

  static NutriQuality fromStorage(String value) {
    for (final quality in NutriQuality.values) {
      if (quality.name == value) {
        return quality;
      }
    }
    throw FormatException('Calidad desconocida en la guía: "$value"');
  }
}

/// Aporte nutricional (por porción, o por 100 g en los snacks).
class PortionMacros {
  const PortionMacros({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory PortionMacros.fromJson(Map<String, dynamic> json) => PortionMacros(
    calories: (json['calories'] as num).toDouble(),
    protein: (json['protein'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fat: (json['fat'] as num).toDouble(),
  );

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  /// Ej.: "140 kcal · P 3 g · C 30 g · G 1 g".
  String get summary =>
      '${formatDecimalEs(calories)} kcal · '
      'P ${formatDecimalEs(protein)} g · '
      'C ${formatDecimalEs(carbs)} g · '
      'G ${formatDecimalEs(fat)} g';
}

class GuideFood {
  const GuideFood({required this.name, this.measure, this.grams, this.per100g});

  factory GuideFood.fromJson(Map<String, dynamic> json) => GuideFood(
    name: json['name'] as String,
    measure: json['measure'] as String?,
    grams: (json['grams'] as num?)?.toDouble(),
    per100g: json['per100g'] == null
        ? null
        : PortionMacros.fromJson(json['per100g'] as Map<String, dynamic>),
  );

  final String name;

  /// Medida casera de una porción (ej. "3/4 taza").
  final String? measure;
  final double? grams;

  /// Solo en los snacks, que la guía entrega por 100 g.
  final PortionMacros? per100g;

  /// Ej.: "3/4 taza (100 g)", "8 unidades" o "40 g".
  String get measureText {
    final gramsText = grams == null ? null : '${formatDecimalEs(grams!)} g';
    if (measure == null) {
      return gramsText ?? '';
    }
    return gramsText == null ? measure! : '$measure ($gramsText)';
  }
}

/// Alimentos de un subgrupo que comparten la misma etiqueta de calidad.
class GuideBlock {
  const GuideBlock({required this.quality, required this.foods});

  factory GuideBlock.fromJson(Map<String, dynamic> json) => GuideBlock(
    quality: NutriQuality.fromStorage(json['quality'] as String),
    foods: (json['foods'] as List)
        .map((f) => GuideFood.fromJson(f as Map<String, dynamic>))
        .toList(),
  );

  final NutriQuality quality;
  final List<GuideFood> foods;
}

class GuideSubgroup {
  const GuideSubgroup({
    required this.blocks,
    this.label,
    this.note,
    this.portion,
  });

  factory GuideSubgroup.fromJson(Map<String, dynamic> json) => GuideSubgroup(
    label: json['label'] as String?,
    note: json['note'] as String?,
    portion: json['portion'] == null
        ? null
        : PortionMacros.fromJson(json['portion'] as Map<String, dynamic>),
    blocks: (json['blocks'] as List)
        .map((b) => GuideBlock.fromJson(b as Map<String, dynamic>))
        .toList(),
  );

  final String? label;

  /// Aclaración propia de la app sobre algo confuso en la guía original.
  final String? note;

  /// Aporte de 1 porción. Es null en los snacks (van por 100 g).
  final PortionMacros? portion;
  final List<GuideBlock> blocks;
}

class GuideGroup {
  const GuideGroup({required this.name, required this.subgroups});

  factory GuideGroup.fromJson(Map<String, dynamic> json) => GuideGroup(
    name: json['name'] as String,
    subgroups: (json['subgroups'] as List)
        .map((s) => GuideSubgroup.fromJson(s as Map<String, dynamic>))
        .toList(),
  );

  final String name;
  final List<GuideSubgroup> subgroups;
}

/// Guía de porciones de intercambio entregada por el nutricionista.
class NutriGuide {
  const NutriGuide({
    required this.title,
    required this.source,
    required this.intro,
    required this.groups,
    this.date,
  });

  factory NutriGuide.fromJson(Map<String, dynamic> json) => NutriGuide(
    title: json['title'] as String,
    source: json['source'] as String,
    date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
    intro: (json['intro'] as List).cast<String>(),
    groups: (json['groups'] as List)
        .map((g) => GuideGroup.fromJson(g as Map<String, dynamic>))
        .toList(),
  );

  final String title;
  final String source;
  final DateTime? date;
  final List<String> intro;
  final List<GuideGroup> groups;

  int get foodCount => groups
      .expand((g) => g.subgroups)
      .expand((s) => s.blocks)
      .fold(0, (count, block) => count + block.foods.length);
}
