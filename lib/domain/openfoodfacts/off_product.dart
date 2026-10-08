import '../nutrition/nutrition_values.dart';

/// Producto tal como fue consultado en Open Food Facts, antes de decidir
/// si se guarda en el catálogo local.
class OffProduct {
  const OffProduct({
    required this.barcode,
    required this.name,
    required this.nutritionPer100,
    required this.fetchedAt,
    this.brand,
    this.country,
    this.missingFields = const [],
    this.inconsistencyWarning,
  });

  final String barcode;
  final String name;
  final NutritionValues nutritionPer100;
  final DateTime fetchedAt;
  final String? brand;
  final String? country;

  /// Campos nutricionales que Open Food Facts no informó para este
  /// producto (se completan como 0, pero se muestran como faltantes).
  final List<String> missingFields;

  /// Advertencia cuando los valores declarados parecen inconsistentes
  /// entre sí (ej. calorías muy altas o que no calzan con los macros).
  final String? inconsistencyWarning;

  bool get isComplete => missingFields.isEmpty;
}
