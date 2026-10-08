import 'biological_sex.dart';
import 'chronic_condition.dart';
import 'diabetes_type.dart';
import 'user_profile.dart';

abstract class ProfileRepository {
  Stream<UserProfile?> watchProfile();

  Future<void> saveProfile({
    required String name,
    required List<ChronicCondition> conditions,
    DiabetesType? diabetesType,
    String? healthConditionNotes,
    double? heightCm,
    BiologicalSex? biologicalSex,
    int? age,
  });
}
