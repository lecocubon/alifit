import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inventory/inventory_providers.dart';
import '../../domain/recipes/recipe_providers.dart';
import '../../domain/recipes/what_can_i_make_engine.dart';
import 'recipe_detail_screen.dart';

class WhatCanIMakeScreen extends ConsumerWidget {
  const WhatCanIMakeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('¿Qué puedo preparar?')),
      body: SafeArea(
        child: recipesAsync.when(
          data: (recipes) => inventoryAsync.when(
            data: (inventory) {
              if (recipes.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aún no tienes recetas guardadas. Crea algunas '
                      'primero para poder comparar contra tu despensa.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (inventory.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Tu despensa está vacía. Agrega alimentos que '
                      'tengas en casa para ver qué puedes preparar.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final matches = findRecipeMatches(recipes, inventory);

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: matches.length,
                itemBuilder: (context, index) =>
                    _MatchCard(match: matches[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final RecipeMatch match;

  @override
  Widget build(BuildContext context) {
    final recipe = match.recipe;
    final perServing = recipe.nutritionPerServing;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(recipe.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${perServing.calories.round()} kcal/porción · '
                '${recipe.servings} porciones'
                '${recipe.prepMinutes != null ? ' · ${recipe.prepMinutes} min' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (match.available.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: match.available
                      .map(
                        (i) => Chip(
                          avatar: const Icon(Icons.check, size: 16),
                          label: Text(i.food.name),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (match.missing.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Faltan:', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: match.missing
                      .map(
                        (i) => Chip(
                          avatar: const Icon(
                            Icons.remove_shopping_cart,
                            size: 16,
                          ),
                          label: Text(i.food.name),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('¡Tienes todo lo necesario!'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
