import 'weight_entry.dart';

abstract class WeightRepository {
  Stream<List<WeightEntry>> watchEntries({int limit = 200});

  Future<void> addEntry({
    required DateTime measuredAt,
    required double weightKg,
    String? notes,
  });

  Future<void> deleteEntry(int id);
}
