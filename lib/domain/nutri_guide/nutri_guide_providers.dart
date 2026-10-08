import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_provider.dart';
import '../../data/repositories/drift_nutri_guide_repository.dart';
import 'nutri_guide.dart';
import 'nutri_guide_repository.dart';

final nutriGuideRepositoryProvider = Provider<NutriGuideRepository>((ref) {
  return DriftNutriGuideRepository(ref.watch(databaseProvider));
});

/// La guía importada en "Mi perfil", o null si no hay ninguna.
final nutriGuideProvider = StreamProvider<NutriGuide?>((ref) {
  return ref.watch(nutriGuideRepositoryProvider).watchGuide();
});
