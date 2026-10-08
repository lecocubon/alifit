import 'biological_sex.dart';
import 'chronic_condition.dart';
import 'diabetes_type.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.conditions,
    this.diabetesType,
    this.healthConditionNotes,
    this.heightCm,
    this.biologicalSex,
    this.age,
  });

  final int id;
  final String name;
  final List<ChronicCondition> conditions;
  final DiabetesType? diabetesType;
  final String? healthConditionNotes;
  final double? heightCm;
  final BiologicalSex? biologicalSex;
  final int? age;

  bool get hasCondition => conditions.isNotEmpty;

  String get conditionsSummary => conditions.isEmpty
      ? 'Sin condiciones registradas'
      : conditions
            .map(
              (c) => c == ChronicCondition.diabetes && diabetesType != null
                  ? 'Diabetes (${diabetesType!.label})'
                  : c.label,
            )
            .join(', ');
}
