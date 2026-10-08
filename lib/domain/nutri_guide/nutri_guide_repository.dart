import 'nutri_guide.dart';

/// Guía del nutricionista importada desde un archivo de perfil.
abstract class NutriGuideRepository {
  /// Emite null mientras no se haya importado ninguna guía.
  Stream<NutriGuide?> watchGuide();

  Future<void> saveGuide(String guideJson);

  Future<void> clearGuide();
}
