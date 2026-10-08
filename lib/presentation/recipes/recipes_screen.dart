import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/text/text_normalize.dart';
import '../../domain/recipes/recipe.dart';
import '../../domain/recipes/recipe_providers.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';
import 'what_can_i_make_screen.dart';

enum _RecipeFolder {
  todas,
  chilena,
  italiana,
  saludable;

  String get label => switch (this) {
    _RecipeFolder.todas => 'Todas',
    _RecipeFolder.chilena => 'Chilena',
    _RecipeFolder.italiana => 'Italiana',
    _RecipeFolder.saludable => 'Saludable',
  };

  bool matches(Recipe recipe) {
    switch (this) {
      case _RecipeFolder.todas:
        return true;
      case _RecipeFolder.chilena:
        return recipe.tags.contains('chilena');
      case _RecipeFolder.italiana:
        return recipe.tags.contains('italiana');
      case _RecipeFolder.saludable:
        // Carpeta "genérica": saludable pero sin encasillarse en una
        // cocina específica (esas ya se ven en Chilena/Italiana).
        return recipe.tags.contains('saludable') &&
            !recipe.tags.contains('chilena') &&
            !recipe.tags.contains('italiana');
    }
  }
}

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _RecipeFolder _folder = _RecipeFolder.todas;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: '¿Qué puedo preparar?',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WhatCanIMakeScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recipes_add_fab',
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const RecipeFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: recipesAsync.when(
          data: (recipes) {
            if (recipes.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aún no tienes recetas guardadas. Toca + para crear '
                    'la primera.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final normalizedQuery = normalizeForSearch(_query);
            final filtered = recipes.where((r) {
              if (!_folder.matches(r)) {
                return false;
              }
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return normalizeForSearch(r.name).contains(normalizedQuery);
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar receta...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final folder in _RecipeFolder.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(folder.label),
                            selected: _folder == folder,
                            onSelected: (_) => setState(() => _folder = folder),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Sin resultados.'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final recipe = filtered[index];
                            final perServing = recipe.nutritionPerServing;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(recipe.name),
                                subtitle: Text(
                                  '${perServing.calories.round()} kcal/porción · '
                                  '${recipe.servings} porciones'
                                  '${recipe.prepMinutes != null ? ' · ${recipe.prepMinutes} min' : ''}',
                                ),
                                trailing: recipe.isFavorite
                                    ? const Icon(Icons.star, size: 18)
                                    : null,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RecipeDetailScreen(recipeId: recipe.id),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
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
