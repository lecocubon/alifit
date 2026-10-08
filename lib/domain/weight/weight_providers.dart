import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_provider.dart';
import '../../data/repositories/drift_weight_repository.dart';
import 'weight_entry.dart';
import 'weight_repository.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return DriftWeightRepository(ref.watch(databaseProvider));
});

final weightEntriesProvider = StreamProvider<List<WeightEntry>>((ref) {
  return ref.watch(weightRepositoryProvider).watchEntries();
});
