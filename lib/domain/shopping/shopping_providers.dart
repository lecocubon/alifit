import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_provider.dart';
import '../../data/repositories/drift_shopping_repository.dart';
import 'shopping_item.dart';
import 'shopping_repository.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return DriftShoppingRepository(ref.watch(databaseProvider));
});

final shoppingItemsProvider = StreamProvider.family<List<ShoppingItem>, int>((
  ref,
  menuPlanId,
) {
  return ref.watch(shoppingRepositoryProvider).watchItems(menuPlanId);
});
