/// Valores nutricionales por 100 g/ml de un alimento.
class NutritionValues {
  const NutritionValues({
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    this.saturatedFat,
    this.cholesterol,
    this.calcium,
    this.iron,
    this.potassium,
  });

  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double? saturatedFat;
  final double? cholesterol;
  final double? calcium;
  final double? iron;
  final double? potassium;

  static const zero = NutritionValues(
    calories: 0,
    carbs: 0,
    protein: 0,
    fat: 0,
    fiber: 0,
    sugar: 0,
    sodium: 0,
  );

  /// Escala estos valores (definidos por 100 g/ml) a la cantidad real en gramos.
  NutritionValues scaledToGrams(double grams) {
    final factor = grams / 100;
    return NutritionValues(
      calories: calories * factor,
      carbs: carbs * factor,
      protein: protein * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      sugar: sugar * factor,
      sodium: sodium * factor,
      saturatedFat: saturatedFat == null ? null : saturatedFat! * factor,
      cholesterol: cholesterol == null ? null : cholesterol! * factor,
      calcium: calcium == null ? null : calcium! * factor,
      iron: iron == null ? null : iron! * factor,
      potassium: potassium == null ? null : potassium! * factor,
    );
  }

  /// Multiplica todos los valores por [factor] (ej. 1/porciones).
  NutritionValues scaledBy(double factor) {
    return NutritionValues(
      calories: calories * factor,
      carbs: carbs * factor,
      protein: protein * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      sugar: sugar * factor,
      sodium: sodium * factor,
      saturatedFat: saturatedFat == null ? null : saturatedFat! * factor,
      cholesterol: cholesterol == null ? null : cholesterol! * factor,
      calcium: calcium == null ? null : calcium! * factor,
      iron: iron == null ? null : iron! * factor,
      potassium: potassium == null ? null : potassium! * factor,
    );
  }

  NutritionValues operator +(NutritionValues other) {
    double? sumNullable(double? a, double? b) =>
        (a == null && b == null) ? null : (a ?? 0) + (b ?? 0);
    return NutritionValues(
      calories: calories + other.calories,
      carbs: carbs + other.carbs,
      protein: protein + other.protein,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
      sugar: sugar + other.sugar,
      sodium: sodium + other.sodium,
      saturatedFat: sumNullable(saturatedFat, other.saturatedFat),
      cholesterol: sumNullable(cholesterol, other.cholesterol),
      calcium: sumNullable(calcium, other.calcium),
      iron: sumNullable(iron, other.iron),
      potassium: sumNullable(potassium, other.potassium),
    );
  }
}
