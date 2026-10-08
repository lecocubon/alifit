import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/domain/health_knowledge/condition_knowledge_base.dart';
import 'package:alifit/domain/profile/chronic_condition.dart';
import 'package:alifit/domain/profile/diabetes_type.dart';

void main() {
  test('cada condición con guía tiene al menos una fuente citada', () {
    for (final condition in ChronicCondition.values) {
      final guidance = ConditionKnowledgeBase.guidanceFor(condition);
      if (condition == ChronicCondition.other) {
        expect(guidance.sources, isEmpty);
        continue;
      }
      expect(
        guidance.sources,
        isNotEmpty,
        reason: '${condition.name} debería citar al menos una fuente',
      );
      expect(guidance.summary, isNotEmpty);
    }
  });

  test('MODY y tipo 3c agregan una nota adicional y fuente específica', () {
    final mody = ConditionKnowledgeBase.guidanceFor(
      ChronicCondition.diabetes,
      diabetesType: DiabetesType.mody,
    );
    expect(mody.additionalNote, contains('MODY'));
    expect(mody.sources.length, greaterThan(2));

    final type3c = ConditionKnowledgeBase.guidanceFor(
      ChronicCondition.diabetes,
      diabetesType: DiabetesType.type3c,
    );
    expect(type3c.additionalNote, contains('pancreat'));
  });

  test('hipertensión incluye el límite de sodio de DASH', () {
    final guidance = ConditionKnowledgeBase.guidanceFor(
      ChronicCondition.hypertension,
    );
    final sodiumNote = guidance.nutrientNotes.firstWhere(
      (n) => n.nutrientKey == 'sodium',
    );
    expect(sodiumNote.maxPerDay, 2300);
  });
}
