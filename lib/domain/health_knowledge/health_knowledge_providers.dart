import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/profile_providers.dart';
import 'condition_guidance.dart';
import 'condition_knowledge_base.dart';

/// Guías dietéticas para todas las condiciones marcadas en el perfil
/// activo. Vacío si no hay perfil o no tiene condiciones. Pensado para
/// alimentar el motor de menús (Fase 5); no se muestra directamente al
/// usuario como pantalla de información.
final activeConditionGuidancesProvider = Provider<List<ConditionGuidance>>((
  ref,
) {
  final profile = ref.watch(activeProfileProvider).value;
  if (profile == null) {
    return const [];
  }
  return profile.conditions
      .map(
        (condition) => ConditionKnowledgeBase.guidanceFor(
          condition,
          diabetesType: profile.diabetesType,
        ),
      )
      .toList();
});
