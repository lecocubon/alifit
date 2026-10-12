import '../../core/text/decimal_format.dart';
import '../../core/text/portion_format.dart';
import '../nutri_guide/nutri_guide.dart' show PortionMacros;
import '../nutrition/meal_type.dart';

/// Porciones de un grupo de alimentos que el plan asigna a una comida.
class PlannedPortion {
  const PlannedPortion({
    required this.group,
    required this.amount,
    this.equivalents,
  });

  factory PlannedPortion.fromJson(Map<String, dynamic> json) => PlannedPortion(
    group: json['grupo'] as String,
    amount: (json['cantidad'] as num).toDouble(),
    equivalents: json['equivale'] as String?,
  );

  final String group;
  final double amount;

  /// A qué equivale 1 porción (ej. "avena 1/2 taza, pan molde 2 rebanadas").
  final String? equivalents;

  /// Ej.: "1 porción", "0,5 porciones".
  String get amountText => formatPortions(amount);
}

class PlannedMeal {
  const PlannedMeal({
    required this.type,
    required this.portions,
    this.time,
    this.target,
    this.examples = const [],
    this.comments = const [],
  });

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    final storedType = json['tipo'] as String;
    final type = MealType.values.where((t) => t.name == storedType).firstOrNull;
    if (type == null) {
      throw FormatException('Comida desconocida en el plan: "$storedType".');
    }
    return PlannedMeal(
      type: type,
      time: json['hora'] as String?,
      target: json['aporte'] == null
          ? null
          : PortionMacros.fromJson(json['aporte'] as Map<String, dynamic>),
      portions: (json['porciones'] as List)
          .map((p) => PlannedPortion.fromJson(p as Map<String, dynamic>))
          .toList(),
      examples: (json['ejemplos'] as List? ?? const []).cast<String>(),
      comments: (json['comentarios'] as List? ?? const []).cast<String>(),
    );
  }

  final MealType type;

  /// Hora sugerida, ej. "8:00".
  final String? time;

  /// Aporte de la comida según el plan.
  final PortionMacros? target;
  final List<PlannedPortion> portions;
  final List<String> examples;
  final List<String> comments;

  /// Ej.: "Cereales 1 · Proteína 2 · Lípidos 0,5".
  String get portionsSummary => portions
      .map((p) => '${p.group} ${formatDecimalEs(p.amount)}')
      .join(' · ');
}

/// Recomendaciones para un tipo de día (gimnasio, fútbol...).
class SportTip {
  const SportTip({required this.title, required this.items});

  factory SportTip.fromJson(Map<String, dynamic> json) => SportTip(
    title: json['titulo'] as String,
    items: (json['indicaciones'] as List).cast<String>(),
  );

  final String title;
  final List<String> items;
}

/// Plan de comidas del nutricionista: qué porciones van en cada comida del
/// día, con ejemplos, suplementación y recomendaciones deportivas.
class MealPlan {
  const MealPlan({
    required this.title,
    required this.meals,
    this.date,
    this.objective,
    this.guidance,
    this.controlDate,
    this.supplements = const [],
    this.sportTips = const [],
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        json[key] == null ? null : DateTime.parse(json[key] as String);
    return MealPlan(
      title: json['titulo'] as String,
      date: date('fecha'),
      objective: json['objetivo'] as String?,
      guidance: json['indicaciones'] as String?,
      controlDate: date('control'),
      meals: (json['comidas'] as List)
          .map((m) => PlannedMeal.fromJson(m as Map<String, dynamic>))
          .toList(),
      supplements: (json['suplementacion'] as List? ?? const []).cast<String>(),
      sportTips: (json['deporte'] as List? ?? const [])
          .map((t) => SportTip.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  final String title;
  final DateTime? date;
  final String? objective;
  final String? guidance;

  /// Fecha del próximo control con el nutricionista.
  final DateTime? controlDate;
  final List<PlannedMeal> meals;
  final List<String> supplements;
  final List<SportTip> sportTips;

  PlannedMeal? mealFor(MealType type) =>
      meals.where((meal) => meal.type == type).firstOrNull;
}
