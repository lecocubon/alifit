import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/text/portion_format.dart';
import '../../domain/nutrition/meal_repository.dart';
import '../../domain/nutrition/meal_type.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/recipes/recipe.dart';
import '../../domain/recipes/recipe_providers.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final int recipeId;

  Future<void> _registerToDiary(
    BuildContext context,
    WidgetRef ref,
    Recipe recipe,
  ) async {
    final choice = await showModalBottomSheet<(MealType, double)>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RegisterSheet(recipe: recipe),
    );
    if (choice == null || !context.mounted) {
      return;
    }
    final (mealType, portions) = choice;

    await ref
        .read(mealRepositoryProvider)
        .addRecipe(
          date: ref.read(selectedDiaryDateProvider),
          type: mealType,
          recipeId: recipe.id,
          recipeName: recipe.name,
          portions: portions,
          items: recipe
              .ingredientsFor(portions)
              .map(
                (i) => MealRecipeItemInput(
                  foodId: i.food.id,
                  quantity: i.quantity,
                  unitLabel: i.unitLabel,
                  gramsEquivalent: i.gramsEquivalent,
                ),
              )
              .toList(),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${recipe.name} (${formatPortions(portions)}) registrada en '
            '${mealType.label}.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);

    return Scaffold(
      body: recipesAsync.when(
        data: (recipes) {
          final recipe = recipes.where((r) => r.id == recipeId).firstOrNull;
          if (recipe == null) {
            return const Center(child: Text('Receta no encontrada.'));
          }
          final perServing = recipe.nutritionPerServing;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(recipe.name),
                actions: [
                  IconButton(
                    icon: Icon(
                      recipe.isFavorite ? Icons.star : Icons.star_border,
                    ),
                    onPressed: () => ref
                        .read(recipeRepositoryProvider)
                        .setFavorite(recipe.id, !recipe.isFavorite),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RecipeFormScreen(existingRecipe: recipe),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'duplicate') {
                        await ref
                            .read(recipeRepositoryProvider)
                            .duplicateRecipe(recipe.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Receta duplicada.')),
                          );
                        }
                      } else if (value == 'delete') {
                        await ref
                            .read(recipeRepositoryProvider)
                            .deleteRecipe(recipe.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicar'),
                      ),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Wrap(
                      spacing: 16,
                      children: [
                        Text(formatPortions(recipe.servings)),
                        if (recipe.prepMinutes != null)
                          Text('${recipe.prepMinutes} min'),
                        if (recipe.costEstimate != null)
                          Text('\$${recipe.costEstimate!.toStringAsFixed(0)}'),
                      ],
                    ),
                    if (recipe.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: recipe.tags
                            .map((t) => Chip(label: Text(t)))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Por porción',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text('${perServing.calories.round()} kcal'),
                            Text(
                              'C: ${perServing.carbs.toStringAsFixed(0)} g · '
                              'P: ${perServing.protein.toStringAsFixed(0)} g · '
                              'G: ${perServing.fat.toStringAsFixed(0)} g',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ingredientes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ...recipe.ingredients.map(
                      (i) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(i.food.name),
                        subtitle: Text(
                          '${i.quantity.toStringAsFixed(i.quantity == i.quantity.roundToDouble() ? 0 : 1)} '
                          '${i.unitLabel}'
                          '${i.isOptional ? ' · opcional' : ''}',
                        ),
                      ),
                    ),
                    if (recipe.otherIngredients.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Otros (no se cuentan en la información nutricional)',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      ...recipe.otherIngredients.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.circle, size: 8),
                          title: Text(item),
                        ),
                      ),
                    ],
                    if (recipe.instructions != null &&
                        recipe.instructions!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Preparación',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(recipe.instructions!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Registrar en el Diario'),
                      onPressed: () => _registerToDiary(context, ref, recipe),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

/// Hoja para elegir cuántas porciones se comieron y en qué comida anotarlas.
class _RegisterSheet extends StatefulWidget {
  const _RegisterSheet({required this.recipe});

  final Recipe recipe;

  @override
  State<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<_RegisterSheet> {
  static const _step = 0.5;
  double _portions = 1;

  @override
  Widget build(BuildContext context) {
    final kcal = widget.recipe.nutritionPerServing.calories * _portions;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('¿Cuántas porciones?'),
              subtitle: Text(
                '${formatPortions(_portions)} · ${kcal.round()} kcal',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Menos',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _portions > _step
                        ? () => setState(() => _portions -= _step)
                        : null,
                  ),
                  IconButton(
                    tooltip: 'Más',
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _portions += _step),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final type in MealType.values)
              ListTile(
                title: Text(type.label),
                onTap: () => Navigator.of(context).pop((type, _portions)),
              ),
          ],
        ),
      ),
    );
  }
}
