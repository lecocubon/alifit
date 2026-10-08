import 'glucose_context.dart';
import 'glucose_entry.dart';

abstract class GlucoseRepository {
  Stream<List<GlucoseEntry>> watchEntries({int limit = 200});

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
  });

  Future<void> deleteEntry(int id);

  Stream<GlucoseRange> watchRange();

  Future<void> setRange({required double low, required double high});
}
