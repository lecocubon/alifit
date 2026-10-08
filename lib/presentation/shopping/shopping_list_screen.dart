import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inventory/inventory_providers.dart';
import '../../domain/menus/menu_providers.dart';
import '../../domain/shopping/shopping_category.dart';
import '../../domain/shopping/shopping_item.dart';
import '../../domain/shopping/shopping_list_generator.dart';
import '../../domain/shopping/shopping_providers.dart';
import '../../core/text/decimal_format.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key, required this.menuPlanId});

  final int menuPlanId;

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final meals = await ref.read(menuMealsProvider(menuPlanId).future);
    final inventory = await ref.read(inventoryItemsProvider.future);
    final drafts = generateShoppingList(meals: meals, inventory: inventory);
    await ref
        .read(shoppingRepositoryProvider)
        .regenerateFromMenu(menuPlanId, drafts);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            drafts.isEmpty
                ? 'No hay productos por comprar: revisa que el menú tenga '
                      'recetas planificadas o que ya tengas todo en la '
                      'despensa.'
                : 'Lista actualizada con ${drafts.length} productos.',
          ),
        ),
      );
    }
  }

  Future<void> _addManualItem(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'unidad');
    var category = ShoppingCategory.otros;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Agregar producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Unidad'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ShoppingCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: ShoppingCategory.values
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => category = value ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || nameController.text.trim().isEmpty) {
      return;
    }
    await ref
        .read(shoppingRepositoryProvider)
        .addManualItem(
          menuPlanId: menuPlanId,
          name: nameController.text.trim(),
          quantity: parseDecimalEs(quantityController.text) ?? 1,
          unitLabel: unitController.text.trim().isEmpty
              ? 'unidad'
              : unitController.text.trim(),
          category: category,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingItemsProvider(menuPlanId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Generar desde el menú',
            onPressed: () => _regenerate(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'shopping_add_fab',
        onPressed: () => _addManualItem(context, ref),
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
                    'Tu lista está vacía. Toca el ícono de recargar para '
                    'generarla desde el menú, o + para agregar un producto '
                    'manualmente.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final byCategory = <ShoppingCategory, List<ShoppingItem>>{};
            for (final item in items) {
              (byCategory[item.category] ??= []).add(item);
            }
            final total = items.fold<double>(
              0,
              (sum, i) => sum + (i.manualPrice ?? 0),
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (total > 0)
                  Card(
                    child: ListTile(
                      title: const Text('Total estimado'),
                      trailing: Text('\$${total.toStringAsFixed(0)}'),
                    ),
                  ),
                for (final category in ShoppingCategory.values)
                  if (byCategory[category]?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        category.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ...byCategory[category]!.map(
                      (item) => _ShoppingTile(item: item),
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

class _ShoppingTile extends ConsumerWidget {
  const _ShoppingTile({required this.item});

  final ShoppingItem item;

  Future<void> _editPrice(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: item.manualPrice?.toStringAsFixed(0) ?? '',
    );
    final price = await showDialog<double?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Precio estimado'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Precio (\$)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(parseDecimalEs(controller.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (price != null) {
      await ref.read(shoppingRepositoryProvider).setManualPrice(item.id, price);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantityLabel = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toStringAsFixed(0)
        : item.quantity.toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: CheckboxListTile(
        value: item.isChecked,
        onChanged: (checked) => ref
            .read(shoppingRepositoryProvider)
            .setChecked(item.id, checked ?? false),
        title: Text(
          item.name,
          style: item.isChecked
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          '$quantityLabel ${item.unitLabel}'
          '${item.isOptional ? ' · opcional' : ''}'
          '${item.manualPrice != null ? ' · \$${item.manualPrice!.toStringAsFixed(0)}' : ''}',
        ),
        secondary: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.attach_money, size: 20),
              onPressed: () => _editPrice(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () =>
                  ref.read(shoppingRepositoryProvider).deleteItem(item.id),
            ),
          ],
        ),
      ),
    );
  }
}
