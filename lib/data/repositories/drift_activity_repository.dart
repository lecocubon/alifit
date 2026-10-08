import 'package:drift/drift.dart';

import '../../domain/nutrition/activity_entry.dart';
import '../../domain/nutrition/activity_repository.dart';
import '../database/app_database.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class DriftActivityRepository implements ActivityRepository {
  DriftActivityRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ActivityEntry>> watchForDate(DateTime date) {
    final day = _dateOnly(date);
    final query = _db.select(_db.activityEntries)
      ..where((t) => t.date.equals(day))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ActivityEntry(
              id: row.id,
              date: row.date,
              name: row.name,
              minutes: row.minutes,
              kcal: row.kcal,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> addEntry({
    required DateTime date,
    required String name,
    required int minutes,
    required double kcal,
  }) {
    return _db
        .into(_db.activityEntries)
        .insert(
          ActivityEntriesCompanion.insert(
            date: _dateOnly(date),
            name: name,
            minutes: minutes,
            kcal: kcal,
          ),
        );
  }

  @override
  Future<void> removeEntry(int id) {
    return (_db.delete(
      _db.activityEntries,
    )..where((t) => t.id.equals(id))).go();
  }
}
