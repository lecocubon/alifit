import 'package:drift/drift.dart';

import '../../domain/nutrition/water_repository.dart';
import '../database/app_database.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class DriftWaterRepository implements WaterRepository {
  DriftWaterRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<double> watchTotalForDate(DateTime date) {
    final day = _dateOnly(date);
    final query = _db.select(_db.waterLogs)..where((t) => t.date.equals(day));
    return query.watch().map(
      (rows) => rows.fold<double>(0, (sum, row) => sum + row.milliliters),
    );
  }

  @override
  Future<void> addWater({required DateTime date, required double milliliters}) {
    return _db
        .into(_db.waterLogs)
        .insert(
          WaterLogsCompanion.insert(
            date: _dateOnly(date),
            milliliters: milliliters,
          ),
        );
  }

  @override
  Future<void> removeLastForDate(DateTime date) async {
    final day = _dateOnly(date);
    final last =
        await (_db.select(_db.waterLogs)
              ..where((t) => t.date.equals(day))
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();
    if (last == null) {
      return;
    }
    await (_db.delete(_db.waterLogs)..where((t) => t.id.equals(last.id))).go();
  }
}
