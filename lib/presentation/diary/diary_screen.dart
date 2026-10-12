import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/text/decimal_format.dart';
import '../../core/text/portion_format.dart';
import '../../domain/meal_plan/meal_plan_providers.dart';
import '../../domain/nutrition/meal.dart';
import '../../domain/nutrition/meal_type.dart';
import '../../domain/nutrition/nutrition_goals.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/nutrition/nutrition_values.dart';
import '../../domain/recipes/recipe_providers.dart';
import '../../domain/recipes/recipe_repository.dart';
import '../common/meal_type_icon.dart';
import '../nutrition/daily_log_sections.dart';
import '../nutrition/food_search_screen.dart';
import '../nutrition/nutrition_summary_card.dart';

Meal? _mealForType(List<Meal> meals, MealType type) {
  for (final meal in meals) {
    if (meal.type == type) {
      return meal;
    }
  }
  return null;
}

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  Future<void> _copyFromAnotherDay(BuildContext context, WidgetRef ref) async {
    final targetDate = ref.read(selectedDiaryDateProvider);
    final sourceDate = await showDatePicker(
      context: context,
      initialDate: targetDate.subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Copiar comidas de qué día',
    );
    if (sourceDate == null || !context.mounted) {
      return;
    }
    await ref
        .read(mealRepositoryProvider)
        .copyMeals(sourceDate: sourceDate, targetDate: targetDate);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comidas del ${DateFormat('d MMM', 'es').format(sourceDate)} '
            'copiadas a este día.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDiaryDateProvider);
    final mealsAsync = ref.watch(mealsForSelectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Diario · ${DateFormat('d MMM', 'es').format(date)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Copiar comidas de otro día',
            onPressed: () => _copyFromAnotherDay(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref
                .read(selectedDiaryDateProvider.notifier)
                .setDate(date.subtract(const Duration(days: 1))),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref
                .read(selectedDiaryDateProvider.notifier)
                .setDate(date.add(const Duration(days: 1))),
          ),
        ],
      ),
      body: SafeArea(
        child: mealsAsync.when(
          data: (meals) => _DiaryBody(meals: meals, date: date),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _DiaryBody extends ConsumerWidget {
  const _DiaryBody({required this.meals, required this.date});

  final List<Meal> meals;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = meals.fold(
      NutritionValues.zero,
      (sum, meal) => sum + meal.totals,
    );
    final goalsAsync = ref.watch(nutritionGoalsProvider);
    final activityAsync = ref.watch(activityEntriesForDateProvider(date));
    final activityKcal =
        activityAsync.value?.fold<double>(0, (sum, a) => sum + a.kcal) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const StreakBadge(),
        const SizedBox(height: 12),
        goalsAsync.when(
          data: (goals) => NutritionSummaryCard(
            totals: totals,
            goals: goals,
            extraCalories: activityKcal,
          ),
          loading: () => NutritionSummaryCard(
            totals: totals,
            goals: NutritionGoals.defaults,
            extraCalories: activityKcal,
          ),
          error: (_, _) => NutritionSummaryCard(
            totals: totals,
            goals: NutritionGoals.defaults,
            extraCalories: activityKcal,
          ),
        ),
        const SizedBox(height: 16),
        for (final type in MealType.values) ...[
          _MealBox(type: type, meal: _mealForType(meals, type), date: date),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        ActivitySection(date: date),
        const SizedBox(height: 12),
        WaterSection(date: date),
        const SizedBox(height: 12),
        NotesSection(date: date),
      ],
    );
  }
}

class _MealBox extends ConsumerWidget {
  const _MealBox({required this.type, required this.meal, required this.date});

  final MealType type;
  final Meal? meal;
  final DateTime date;

  Future<void> _duplicateToAnotherDay(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final targetDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Duplicar esta comida a qué día',
    );
    if (targetDate == null || !context.mounted) {
      return;
    }
    await ref
        .read(mealRepositoryProvider)
        .duplicateMeal(mealId: meal!.id, targetDate: targetDate);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${meal!.displayLabel} duplicada al '
            '${DateFormat('d MMM', 'es').format(targetDate)}.',
          ),
        ),
      );
    }
  }

  Future<void> _clearMeal(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar comida'),
        content: Text(
          'Se quitarán todos los alimentos de ${meal!.displayLabel.toLowerCase()}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(mealRepositoryProvider).clearMeal(meal!.id);
    }
  }

  Future<void> _saveAsRecipe(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: meal!.displayLabel);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar como receta'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre de la receta'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) {
      return;
    }
    await ref
        .read(recipeRepositoryProvider)
        .createRecipe(
          name: name,
          servings: 1,
          ingredients: meal!.items
              .map(
                (item) => RecipeIngredientInput(
                  foodId: item.food.id,
                  quantity: item.quantity,
                  unitLabel: item.unitLabel,
                  gramsEquivalent: item.gramsEquivalent,
                ),
              )
              .toList(),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"$name" guardada en Recetas.')));
    }
  }

  static String _quantityText(MealItem item) =>
      '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} '
      '${item.unitLabel}';

  void _showRecipeItems(
    BuildContext context,
    MealRecipeEntry entry,
    List<MealItem> items,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(entry.name),
              subtitle: Text(formatPortions(entry.portions)),
            ),
            const Divider(height: 1),
            for (final item in items)
              ListTile(
                dense: true,
                title: Text(item.food.name),
                subtitle: Text(
                  '${_quantityText(item)} · '
                  '${item.nutrition.calories.round()} kcal',
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = meal?.items ?? const [];
    final totals = meal?.totals ?? NutritionValues.zero;
    final planned = ref.watch(mealPlanProvider).value?.mealFor(type);
    final targetKcal = planned?.target?.calories;
    final hintStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(mealTypeIcon(type), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (items.isEmpty && targetKcal != null)
                  Text(
                    'Meta ${formatDecimalEs(targetKcal)} kcal',
                    style: hintStyle,
                  ),
                if (items.isNotEmpty) ...[
                  Text(
                    targetKcal == null
                        ? '${totals.calories.round()} kcal'
                        : '${totals.calories.round()} / '
                              '${formatDecimalEs(targetKcal)} kcal',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'duplicate':
                          _duplicateToAnotherDay(context, ref);
                        case 'clear':
                          _clearMeal(context, ref);
                        case 'save_recipe':
                          _saveAsRecipe(context, ref);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicar a otro día'),
                      ),
                      PopupMenuItem(
                        value: 'save_recipe',
                        child: Text('Guardar como receta'),
                      ),
                      PopupMenuItem(
                        value: 'clear',
                        child: Text('Vaciar comida'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            // Lo que el plan del nutri pone en esta comida, como guía al
            // registrar.
            if (planned != null && planned.portions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 2),
                child: Text(
                  'Plan${planned.time == null ? '' : ' ${planned.time}'}: '
                  '${planned.portionsSummary}',
                  style: hintStyle,
                ),
              ),
            if (items.isNotEmpty) ...[
              const Divider(height: 12),
              for (final line in meal!.lines)
                switch (line) {
                  FoodLine(:final item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(item.food.name),
                    subtitle: Text(
                      '${_quantityText(item)} · '
                      '${item.nutrition.calories.round()} kcal',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () =>
                          ref.read(mealRepositoryProvider).removeItem(item.id),
                    ),
                  ),
                  // Una receta se ve como un solo ítem; al tocarla se
                  // muestran los ingredientes que se anotaron.
                  RecipeLine(:final entry, :final items) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.menu_book_outlined, size: 20),
                    minLeadingWidth: 0,
                    title: Text(entry.name),
                    subtitle: Text(
                      '${formatPortions(entry.portions)} · '
                      '${line.nutrition.calories.round()} kcal',
                    ),
                    onTap: () => _showRecipeItems(context, entry, items),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => ref
                          .read(mealRepositoryProvider)
                          .removeRecipeEntry(entry.id),
                    ),
                  ),
                },
            ],
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        FoodSearchScreen(date: date, mealType: type),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
