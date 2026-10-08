import 'package:drift/drift.dart';

import '../../domain/glucose/glucose_context.dart';
import '../../domain/glucose/glucose_entry.dart';
import '../../domain/glucose/glucose_repository.dart';
import '../database/app_database.dart';
import '../database/watch_tables.dart';

const _rangeLowKey = 'glucose_range_low';
const _rangeHighKey = 'glucose_range_high';
const _defaultLow = 70.0;
const _defaultHigh = 180.0;

class DriftGlucoseRepository implements GlucoseRepository {
  DriftGlucoseRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<GlucoseEntry>> watchEntries({int limit = 200}) {
    final query = _db.select(_db.glucoseEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
      ..limit(limit);
    return _db.watchTables({_db.glucoseEntries, _db.meals}).asyncMap((_) async {
      final rows = await query.get();
      final entries = <GlucoseEntry>[];
      for (final row in rows) {
        String? mealLabel;
        if (row.relatedMealId != null) {
          final meal = await (_db.select(
            _db.meals,
          )..where((t) => t.id.equals(row.relatedMealId!))).getSingleOrNull();
          mealLabel = meal?.type;
        }
        entries.add(
          GlucoseEntry(
            id: row.id,
            measuredAt: row.measuredAt,
            value: row.value,
            context: GlucoseContext.fromStorage(row.context),
            relatedMealId: row.relatedMealId,
            relatedMealLabel: mealLabel,
            hoursAfterMeal: row.hoursAfterMeal,
            physicalActivity: row.physicalActivity,
            symptoms: row.symptoms,
            medicationNote: row.medicationNote,
            notes: row.notes,
          ),
        );
      }
      return entries;
    });
  }

  @override
  Future<void> addEntry({
    required DateTime measuredAt,
    required double value,
    required GlucoseContext context,
    int? relatedMealId,
    double? hoursAfterMeal,
    String? physicalActivity,
    String? symptoms,
    String? medicationNote,
    String? notes,
  }) {
    return _db
        .into(_db.glucoseEntries)
        .insert(
          GlucoseEntriesCompanion.insert(
            measuredAt: measuredAt,
            value: value,
            context: context.name,
            relatedMealId: Value(relatedMealId),
            hoursAfterMeal: Value(hoursAfterMeal),
            physicalActivity: Value(physicalActivity),
            symptoms: Value(symptoms),
            medicationNote: Value(medicationNote),
            notes: Value(notes),
          ),
        );
  }

  @override
  Future<void> deleteEntry(int id) {
    return (_db.delete(_db.glucoseEntries)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<GlucoseRange> watchRange() {
    final query = _db.select(_db.appSettings)
      ..where((t) => t.key.isIn([_rangeLowKey, _rangeHighKey]));
    return query.watch().map((rows) {
      final map = {for (final r in rows) r.key: r.value};
      return GlucoseRange(
        low: double.tryParse(map[_rangeLowKey] ?? '') ?? _defaultLow,
        high: double.tryParse(map[_rangeHighKey] ?? '') ?? _defaultHigh,
      );
    });
  }

  @override
  Future<void> setRange({required double low, required double high}) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: _rangeLowKey, value: low.toString()),
        );
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _rangeHighKey,
            value: high.toString(),
          ),
        );
  }
}
