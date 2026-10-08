import 'dart:convert';

import '../nutri_guide/nutri_guide.dart';
import '../nutri_guide/nutri_guide_repository.dart';
import '../nutrition/nutrition_goals.dart';
import '../nutrition/nutrition_goals_repository.dart';

/// Archivo "Mi perfil": lo que es personal de cada usuario (sus metas y la
/// guía de su nutricionista). No viene dentro de la app: se importa desde
/// Perfil y queda guardado solo en ese teléfono.
///
/// Formato:
/// ```json
/// {
///   "tipo": "alifit-perfil",
///   "nombre": "Plan nutricionista deportivo",
///   "metas": {"calorias": 1900, "carbohidratos": 190,
///             "proteinas": 120, "grasas": 74},
///   "guiaNutri": { ...misma estructura que lee NutriGuide.fromJson... }
/// }
/// ```
/// "metas" y "guiaNutri" son opcionales, pero debe venir al menos uno.
class PersonalPlan {
  const PersonalPlan({this.label, this.goals, this.guide, this.guideJson});

  static const fileType = 'alifit-perfil';

  /// Lee el contenido de un archivo de perfil. Si no es válido lanza
  /// [FormatException] con un mensaje que se puede mostrar al usuario.
  factory PersonalPlan.parse(String raw) {
    const notAProfile = FormatException(
      'El archivo no es un perfil de AliFit.',
    );
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw notAProfile;
    }
    if (decoded is! Map<String, dynamic> || decoded['tipo'] != fileType) {
      throw notAProfile;
    }

    try {
      final goalsJson = decoded['metas'] as Map<String, dynamic>?;
      final guideJson = decoded['guiaNutri'] as Map<String, dynamic>?;
      if (goalsJson == null && guideJson == null) {
        throw const FormatException('El perfil no trae metas ni guía.');
      }
      return PersonalPlan(
        label: decoded['nombre'] as String?,
        goals: goalsJson == null ? null : _parseGoals(goalsJson),
        guide: guideJson == null ? null : NutriGuide.fromJson(guideJson),
        guideJson: guideJson == null ? null : jsonEncode(guideJson),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('El perfil está incompleto o dañado.');
    }
  }

  static NutritionGoals _parseGoals(Map<String, dynamic> json) {
    double read(String key) => (json[key] as num).toDouble();
    final goals = NutritionGoals(
      calories: read('calorias'),
      carbs: read('carbohidratos'),
      protein: read('proteinas'),
      fat: read('grasas'),
    );
    if (goals.calories <= 0 ||
        goals.carbs < 0 ||
        goals.protein < 0 ||
        goals.fat < 0) {
      throw const FormatException('Las metas del perfil no son válidas.');
    }
    return goals;
  }

  final String? label;
  final NutritionGoals? goals;
  final NutriGuide? guide;

  /// La guía tal como venía en el archivo, para guardarla sin cambios.
  final String? guideJson;

  /// Reemplaza las metas y/o la guía actuales por las del perfil.
  Future<void> apply({
    required NutritionGoalsRepository goalsRepository,
    required NutriGuideRepository guideRepository,
  }) async {
    final goals = this.goals;
    if (goals != null) {
      await goalsRepository.setGoals(goals);
    }
    final guideJson = this.guideJson;
    if (guideJson != null) {
      await guideRepository.saveGuide(guideJson);
    }
  }
}
