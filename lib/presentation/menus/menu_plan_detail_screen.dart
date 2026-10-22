import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/time/calendar_days.dart';
import '../../domain/inventory/inventory_providers.dart';
import '../../domain/menus/menu_generator.dart';
import '../../domain/menus/menu_meal.dart';
import '../../domain/menus/menu_providers.dart';
import '../../domain/nutrition/meal_type.dart';
import '../../domain/recipes/recipe.dart';
import '../../domain/recipes/recipe_providers.dart';
import '../shopping/shopping_list_screen.dart';

class _SlotAction {
  const _SlotAction._({
    this.recipeId,
    this.freeformLabel,
    this.isClear = false,
  });

  factory _SlotAction.recipe(int id) => _SlotAction._(recipeId: id);
  factory _SlotAction.freeform(String label) =>
      _SlotAction._(freeformLabel: label);
  factory _SlotAction.clear() => const _SlotAction._(isClear: true);

  final int? recipeId;
  final String? freeformLabel;
  final bool isClear;
}

class MenuPlanDetailScreen extends ConsumerWidget {
  const MenuPlanDetailScreen({super.key, required this.menuPlanId});

  final int menuPlanId;

  Future<void> _editSlot(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    MealType mealType,
    MenuMeal? existing,
  ) async {
    final recipes = ref.read(recipesProvider).value ?? const <Recipe>[];
    final freeformController = TextEditingController(
      text: existing?.recipe == null ? (existing?.freeformLabel ?? '') : '',
    );

    final result = await showModalBottomSheet<_SlotAction>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${mealType.label} · ${DateFormat('EEEE d MMM', 'es').format(date)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: freeformController,
                      decoration: const InputDecoration(
                        labelText: 'Comida libre (sin receta)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      final text = freeformController.text.trim();
                      if (text.isEmpty) {
                        return;
                      }
                      Navigator.of(context).pop(_SlotAction.freeform(text));
                    },
                  ),
                ],
              ),
              if (existing != null) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_SlotAction.clear()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Quitar comida de este espacio'),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Recetas guardadas',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: recipes.isEmpty
                    ? const Center(
                        child: Text('Aún no tienes recetas guardadas.'),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return ListTile(
                            title: Text(recipe.name),
                            subtitle: Text(
                              '${recipe.nutritionPerServing.calories.round()} kcal/porción',
                            ),
                            onTap: () => Navigator.of(
                              context,
                            ).pop(_SlotAction.recipe(recipe.id)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) {
      return;
    }
    final repo = ref.read(menuRepositoryProvider);
    if (result.isClear) {
      await repo.clearMeal(
        menuPlanId: menuPlanId,
        date: date,
        mealType: mealType,
      );
    } else if (result.recipeId != null) {
      await repo.setMeal(
        menuPlanId: menuPlanId,
        date: date,
        mealType: mealType,
        recipeId: result.recipeId,
      );
    } else if (result.freeformLabel != null) {
      await repo.setMeal(
        menuPlanId: menuPlanId,
        date: date,
        mealType: mealType,
        freeformLabel: result.freeformLabel,
      );
    }
  }

  Future<void> _generateAutomatically(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final plan = await ref.read(menuPlanProvider(menuPlanId).future);
      if (plan == null) {
        return;
      }
      final recipes = await ref.read(recipesProvider.future);
      if (recipes.isEmpty) {
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No hay recetas guardadas'),
              content: const Text(
                'Necesitas al menos una receta guardada (en Recetas) para '
                'que el generador automático pueda proponer un menú.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
        return;
      }
      final inventory = await ref.read(inventoryItemsProvider.future);
      final existingMeals = await ref.read(
        menuMealsProvider(menuPlanId).future,
      );

      final days = List.generate(7, (i) => addDays(plan.startDate, i));
      final alreadyFilled = existingMeals
          .map((m) => (date: m.date, mealType: m.mealType))
          .toSet();

      final assignments = generateWeeklyMenu(
        days: days,
        recipes: recipes,
        inventory: inventory,
        alreadyFilled: alreadyFilled,
      );

      final repo = ref.read(menuRepositoryProvider);
      for (final assignment in assignments) {
        await repo.setMeal(
          menuPlanId: menuPlanId,
          date: assignment.date,
          mealType: assignment.mealType,
          recipeId: assignment.recipe.id,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              assignments.isEmpty
                  ? 'No había espacios vacíos por completar (todos los '
                        'espacios de desayuno/almuerzo/once/cena ya tienen '
                        'algo asignado).'
                  : 'Se completaron ${assignments.length} espacios del menú.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el menú: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(menuPlanProvider(menuPlanId));
    final mealsAsync = ref.watch(menuMealsProvider(menuPlanId));

    return Scaffold(
      appBar: AppBar(
        title: Text(planAsync.value?.label ?? 'Plan de menú'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generar automáticamente',
            onPressed: () => _generateAutomatically(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Lista de compras',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShoppingListScreen(menuPlanId: menuPlanId),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: planAsync.when(
          data: (plan) {
            if (plan == null) {
              return const Center(child: Text('Este plan ya no existe.'));
            }
            return mealsAsync.when(
              data: (meals) {
                final byDate = <DateTime, Map<MealType, MenuMeal>>{};
                for (final meal in meals) {
                  (byDate[meal.date] ??= {})[meal.mealType] = meal;
                }
                final days = List.generate(
                  7,
                  (i) => addDays(plan.startDate, i),
                );
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final date = days[index];
                    final mealsForDay = byDate[date] ?? const {};
                    return _DayCard(
                      date: date,
                      meals: mealsForDay,
                      onSlotTap: (mealType, existing) =>
                          _editSlot(context, ref, date, mealType, existing),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.meals,
    required this.onSlotTap,
  });

  final DateTime date;
  final Map<MealType, MenuMeal> meals;
  final void Function(MealType mealType, MenuMeal? existing) onSlotTap;

  @override
  Widget build(BuildContext context) {
    final dailyKcal = meals.values.fold<double>(
      0,
      (sum, meal) => sum + (meal.nutrition?.calories ?? 0),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE d MMM', 'es').format(date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (dailyKcal > 0)
                  Text(
                    '${dailyKcal.round()} kcal',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const Divider(),
            for (final mealType in MealType.values)
              _SlotRow(
                mealType: mealType,
                meal: meals[mealType],
                onTap: () => onSlotTap(mealType, meals[mealType]),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.mealType, this.meal, required this.onTap});

  final MealType mealType;
  final MenuMeal? meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentMeal = meal;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(mealType.label),
      subtitle: currentMeal == null
          ? const Text('Sin planificar')
          : Text(
              currentMeal.nutrition != null
                  ? '${currentMeal.displayName} · '
                        '${currentMeal.nutrition!.calories.round()} kcal'
                  : currentMeal.displayName,
            ),
      trailing: Icon(
        currentMeal == null ? Icons.add_circle_outline : Icons.chevron_right,
      ),
      onTap: onTap,
    );
  }
}
