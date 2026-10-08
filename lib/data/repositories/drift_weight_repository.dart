import 'package:drift/drift.dart';

import '../../domain/weight/weight_entry.dart';
import '../../domain/weight/weight_repository.dart';
import '../database/app_database.dart';

class DriftWeightRepository implements WeightRepository {
  DriftWeightRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<WeightEntry>> watchEntries({int limit = 200}) {
    final query = _db.select(_db.weightEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
      ..limit(limit);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => WeightEntry(
              id: row.id,
              measuredAt: row.measuredAt,
              weightKg: row.weightKg,
              notes: row.notes,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> addEntry({
    required DateTime measuredAt,
    required double weightKg,
    String? notes,
  }) {
    return _db
        .into(_db.weightEntries)
        .insert(
          WeightEntriesCompanion.insert(
            measuredAt: measuredAt,
            weightKg: weightKg,
            notes: Value(notes),
          ),
        );
  }

  @override
  Future<void> deleteEntry(int id) {
    return (_db.delete(_db.weightEntries)..where((t) => t.id.equals(id))).go();
  }
}
