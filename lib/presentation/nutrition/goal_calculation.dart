import '../../domain/nutrition/nutrition_goals.dart';
import '../../domain/profile/biological_sex.dart';

enum ActivityLevel {
  sedentario,
  ligero,
  moderado,
  intenso;

  String get label => switch (this) {
    ActivityLevel.sedentario => 'Sedentario (poco o nada de ejercicio)',
    ActivityLevel.ligero => 'Ligero (1-3 días/semana)',
    ActivityLevel.moderado => 'Moderado (3-5 días/semana)',
    ActivityLevel.intenso => 'Intenso (6-7 días/semana)',
  };

  double get factor => switch (this) {
    ActivityLevel.sedentario => 1.2,
    ActivityLevel.ligero => 1.375,
    ActivityLevel.moderado => 1.55,
    ActivityLevel.intenso => 1.725,
  };
}

enum GoalObjective {
  bajar,
  mantener,
  subir,
  ganarMusculo,
  controlGlicemia;

  String get label => switch (this) {
    GoalObjective.bajar => 'Bajar de peso',
    GoalObjective.mantener => 'Mantener peso',
    GoalObjective.subir => 'Subir de peso',
    GoalObjective.ganarMusculo => 'Ganar masa muscular',
    GoalObjective.controlGlicemia => 'Control de glicemia',
  };

  String? get description => switch (this) {
    GoalObjective.ganarMusculo =>
      'Superávit calórico más acotado con más proteína, pensado para '
          'acompañar entrenamiento de fuerza.',
    GoalObjective.controlGlicemia =>
      'Mantiene tu peso, pero con menos carbohidratos y más proteína/grasa '
          'para ayudar a suavizar los picos de glicemia.',
    _ => null,
  };

  /// Si este objetivo ofrece elegir [GoalSpeed] (los que mantienen el peso
  /// o se enfocan en glicemia no lo necesitan).
  bool get usesSpeed =>
      this == GoalObjective.bajar ||
      this == GoalObjective.subir ||
      this == GoalObjective.ganarMusculo;

  /// Calorías a sumar (o restar) al gasto diario según [speed]. "Ganar
  /// masa muscular" usa un superávit más acotado (menos grasa acumulada);
  /// los objetivos sin [usesSpeed] no ajustan nada.
  double calorieAdjustment(GoalSpeed speed) {
    return switch (this) {
      GoalObjective.bajar => -speed.magnitude,
      GoalObjective.subir => speed.magnitude,
      GoalObjective.ganarMusculo => speed.magnitude / 2,
      GoalObjective.mantener || GoalObjective.controlGlicemia => 0,
    };
  }
}

/// Qué tan agresivo es el déficit/superávit calórico. "Recomendado"
/// equivale a ~0,5 kg por semana, el ritmo estándar y sostenible.
enum GoalSpeed {
  lento,
  recomendado,
  rapido;

  String get label => switch (this) {
    GoalSpeed.lento => 'Lento',
    GoalSpeed.recomendado => 'Recomendado',
    GoalSpeed.rapido => 'Rápido',
  };

  String get description => switch (this) {
    GoalSpeed.lento =>
      '~0,25 kg/semana, el cambio más gradual y fácil de sostener.',
    GoalSpeed.recomendado => '~0,5 kg/semana, el ritmo estándar y seguro.',
    GoalSpeed.rapido =>
      '~0,75 kg/semana, resultados más rápidos pero más difícil de sostener.',
  };

  double get magnitude => switch (this) {
    GoalSpeed.lento => 250,
    GoalSpeed.recomendado => 500,
    GoalSpeed.rapido => 750,
  };
}

/// Estimación referencial de calorías y macros (fórmula de Mifflin-St
/// Jeor); no reemplaza una indicación nutricional profesional.
class GoalCalculation {
  static NutritionGoals compute({
    required BiologicalSex sex,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    required GoalObjective objective,
    required GoalSpeed speed,
    required bool diabetesAware,
  }) {
    final bmr = sex == BiologicalSex.male
        ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
        : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    final tdee = bmr * activityLevel.factor;
    var calories = tdee + objective.calorieAdjustment(speed);
    if (calories < 1200) {
      calories = 1200;
    }

    final macros = _macroSplit(
      objective: objective,
      diabetesAware: diabetesAware,
    );

    return NutritionGoals(
      calories: calories,
      carbs: calories * macros.carbsPct / 4,
      protein: calories * macros.proteinPct / 4,
      fat: calories * macros.fatPct / 9,
    );
  }

  /// Reparto de macros (referencial, no reemplaza la indicación de tu
  /// profesional de salud): más proteína si el objetivo es ganar músculo,
  /// más bajo en carbohidratos si es control de glicemia o si hay
  /// diabetes.
  static ({double carbsPct, double proteinPct, double fatPct}) _macroSplit({
    required GoalObjective objective,
    required bool diabetesAware,
  }) {
    if (objective == GoalObjective.controlGlicemia) {
      return (carbsPct: 0.35, proteinPct: 0.30, fatPct: 0.35);
    }
    if (objective == GoalObjective.ganarMusculo) {
      final carbsPct = diabetesAware ? 0.35 : 0.40;
      return (
        carbsPct: carbsPct,
        proteinPct: 0.30,
        fatPct: 1 - carbsPct - 0.30,
      );
    }
    final carbsPct = diabetesAware ? 0.40 : 0.45;
    final fatPct = diabetesAware ? 0.35 : 0.30;
    return (carbsPct: carbsPct, proteinPct: 0.25, fatPct: fatPct);
  }
}
