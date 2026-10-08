import 'package:drift/drift.dart';

import '../../domain/profile/biological_sex.dart';
import '../../domain/profile/chronic_condition.dart';
import '../../domain/profile/diabetes_type.dart';
import '../../domain/profile/profile_repository.dart';
import '../../domain/profile/user_profile.dart';
import '../database/app_database.dart';

class DriftProfileRepository implements ProfileRepository {
  DriftProfileRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<UserProfile?> watchProfile() {
    final query = _db.select(_db.userProfiles)
      ..orderBy([(t) => OrderingTerm.asc(t.id)])
      ..limit(1);
    return query.watchSingleOrNull().map(_toDomain);
  }

  @override
  Future<void> saveProfile({
    required String name,
    required List<ChronicCondition> conditions,
    DiabetesType? diabetesType,
    String? healthConditionNotes,
    double? heightCm,
    BiologicalSex? biologicalSex,
    int? age,
  }) async {
    final existing = await (_db.select(
      _db.userProfiles,
    )..limit(1)).getSingleOrNull();

    final companion = UserProfilesCompanion(
      name: Value(name),
      conditions: Value(conditions.map((c) => c.name).join(',')),
      diabetesType: Value(diabetesType?.name),
      healthConditionNotes: Value(healthConditionNotes),
      heightCm: Value(heightCm),
      biologicalSex: Value(biologicalSex?.name),
      age: Value(age),
      updatedAt: Value(DateTime.now()),
    );

    if (existing == null) {
      await _db.into(_db.userProfiles).insert(companion);
    } else {
      await (_db.update(
        _db.userProfiles,
      )..where((t) => t.id.equals(existing.id))).write(companion);
    }
  }

  UserProfile? _toDomain(UserProfileRow? row) {
    if (row == null) {
      return null;
    }
    final conditions = row.conditions
        .split(',')
        .map(ChronicCondition.fromStorage)
        .whereType<ChronicCondition>()
        .toList();
    return UserProfile(
      id: row.id,
      name: row.name,
      conditions: conditions,
      diabetesType: DiabetesType.fromStorage(row.diabetesType),
      healthConditionNotes: row.healthConditionNotes,
      heightCm: row.heightCm,
      biologicalSex: BiologicalSex.fromStorage(row.biologicalSex),
      age: row.age,
    );
  }
}
