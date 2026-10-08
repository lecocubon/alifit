import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_provider.dart';
import '../../data/repositories/drift_inventory_repository.dart';
import 'inventory_item.dart';
import 'inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return DriftInventoryRepository(ref.watch(databaseProvider));
});

final inventoryItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  return ref.watch(inventoryRepositoryProvider).watchItems();
});
