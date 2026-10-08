import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_provider.dart';
import '../../data/repositories/drift_glucose_repository.dart';
import 'glucose_entry.dart';
import 'glucose_repository.dart';

final glucoseRepositoryProvider = Provider<GlucoseRepository>((ref) {
  return DriftGlucoseRepository(ref.watch(databaseProvider));
});

final glucoseEntriesProvider = StreamProvider<List<GlucoseEntry>>((ref) {
  return ref.watch(glucoseRepositoryProvider).watchEntries();
});

final glucoseRangeProvider = StreamProvider<GlucoseRange>((ref) {
  return ref.watch(glucoseRepositoryProvider).watchRange();
});

final glucoseStatsProvider = Provider<GlucoseStats>((ref) {
  final entriesAsync = ref.watch(glucoseEntriesProvider);
  final entries = entriesAsync.value;
  if (entries == null || entries.isEmpty) {
    return const GlucoseStats.empty();
  }
  final values = entries.map((e) => e.value).toList();
  final sum = values.reduce((a, b) => a + b);
  return GlucoseStats(
    average: sum / values.length,
    min: values.reduce((a, b) => a < b ? a : b),
    max: values.reduce((a, b) => a > b ? a : b),
    count: values.length,
  );
});
