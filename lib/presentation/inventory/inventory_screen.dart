import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inventory/inventory_item.dart';
import '../../domain/inventory/inventory_location.dart';
import '../../domain/inventory/inventory_providers.dart';
import 'inventory_item_form_screen.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Despensa')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'inventory_add_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InventoryItemFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: itemsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aún no tienes alimentos en tu despensa. Toca + '
                    'para agregar.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final byLocation = <InventoryLocation, List<InventoryItem>>{};
            for (final item in items) {
              (byLocation[item.location] ??= []).add(item);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final location in InventoryLocation.values)
                  if (byLocation[location]?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Text(
                        location.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ...byLocation[location]!.map(
                      (item) => _InventoryTile(item: item),
                    ),
                  ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _InventoryTile extends ConsumerWidget {
  const _InventoryTile({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiryText = item.expiresAt == null
        ? null
        : item.isExpired
        ? 'Vencido'
        : item.isExpiringSoon
        ? 'Vence pronto (${item.daysUntilExpiry}d)'
        : 'Vence en ${item.daysUntilExpiry}d';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: item.isExpired
          ? Theme.of(context).colorScheme.errorContainer
          : item.isExpiringSoon
          ? Colors.orange.withValues(alpha: 0.15)
          : null,
      child: ListTile(
        title: Text(item.food.name),
        subtitle: Text(
          '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} '
          '${item.unitLabel}'
          '${expiryText != null ? ' · $expiryText' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () =>
              ref.read(inventoryRepositoryProvider).deleteItem(item.id),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InventoryItemFormScreen(existingItem: item),
          ),
        ),
      ),
    );
  }
}
