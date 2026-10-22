import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/text/portion_format.dart';

import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/food_source.dart';
import '../../domain/nutrition/meal_type.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/recipes/recipe.dart';
import '../../domain/recipes/recipe_providers.dart';
import '../../core/text/text_normalize.dart';
import 'add_meal_item_screen.dart';
import 'add_recipe_to_meal_screen.dart';
import 'barcode_scan_screen.dart';
import 'food_form_screen.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({
    super.key,
    required this.date,
    required this.mealType,
    this.pickerOnly = false,
  });

  final DateTime date;
  final MealType mealType;

  /// Si es true, al elegir un alimento la pantalla se cierra devolviéndolo
  /// (sin guardarlo ni mostrar la pestaña de recetas). Se usa para agregar
  /// un alimento suelto dentro de la edición de una receta.
  final bool pickerOnly;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (!widget.pickerOnly) {
      _tabController = TabController(length: 2, vsync: this);
    }
    // No se puede modificar un provider durante initState; se difiere al
    // primer microtask tras terminar de construir el árbol de widgets.
    Future(() => ref.read(foodSearchQueryProvider.notifier).update(''));
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _selectFood(Food food) async {
    if (widget.pickerOnly) {
      Navigator.of(context).pop(food);
      return;
    }
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddMealItemScreen(
          food: food,
          date: widget.date,
          mealType: widget.mealType,
        ),
      ),
    );
    if (added == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectRecipe(Recipe recipe) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddRecipeToMealScreen(
          recipe: recipe,
          date: widget.date,
          mealType: widget.mealType,
        ),
      ),
    );
    if (added == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// El alimento recién creado queda elegido de inmediato: no hay que
  /// volver a buscarlo.
  Future<void> _createNewFood() async {
    final food = await Navigator.of(
      context,
    ).push<Food>(MaterialPageRoute(builder: (_) => const FoodFormScreen()));
    if (food == null || !mounted) {
      return;
    }
    ref.invalidate(foodSearchResultsProvider);
    await _selectFood(food);
  }

  Future<void> _scanBarcode() async {
    final food = await Navigator.of(
      context,
    ).push<Food>(MaterialPageRoute(builder: (_) => const BarcodeScanScreen()));
    if (food != null) {
      await _selectFood(food);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(foodSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pickerOnly
              ? 'Agregar alimento'
              : 'Agregar a ${widget.mealType.label}',
        ),
        actions: widget.pickerOnly
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Escanear código de barras',
                  onPressed: _scanBarcode,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Crear alimento',
                  onPressed: _createNewFood,
                ),
              ],
        bottom: _tabController == null
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Alimentos'),
                  Tab(text: 'Recetas'),
                ],
              ),
      ),
      body: SafeArea(
        child: _tabController == null
            ? _FoodTab(query: query, onSelect: _selectFood)
            : TabBarView(
                controller: _tabController,
                children: [
                  _FoodTab(query: query, onSelect: _selectFood),
                  _RecipeTab(onSelect: _selectRecipe),
                ],
              ),
      ),
    );
  }
}

class _FoodTab extends ConsumerWidget {
  const _FoodTab({required this.query, required this.onSelect});

  final String query;
  final void Function(Food food) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar alimento...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                ref.read(foodSearchQueryProvider.notifier).update(value),
          ),
        ),
        Expanded(
          child: query.trim().isEmpty
              ? _RecentsAndFavorites(onSelect: onSelect)
              : _SearchResults(onSelect: onSelect),
        ),
      ],
    );
  }
}

class _RecipeTab extends ConsumerStatefulWidget {
  const _RecipeTab({required this.onSelect});

  final void Function(Recipe recipe) onSelect;

  @override
  ConsumerState<_RecipeTab> createState() => _RecipeTabState();
}

class _RecipeTabState extends ConsumerState<_RecipeTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar receta...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: recipesAsync.when(
            data: (recipes) {
              final normalizedQuery = normalizeForSearch(_query);
              final filtered = normalizedQuery.isEmpty
                  ? recipes
                  : recipes
                        .where(
                          (r) => normalizeForSearch(
                            r.name,
                          ).contains(normalizedQuery),
                        )
                        .toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('Sin resultados.'));
              }
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final recipe = filtered[index];
                  return ListTile(
                    title: Text(recipe.name),
                    subtitle: Text(
                      '${recipe.nutritionPerServing.calories.round()} kcal '
                      'por porción · ${formatPortions(recipe.servings)}',
                    ),
                    onTap: () => widget.onSelect(recipe),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

class _RecentsAndFavorites extends ConsumerWidget {
  const _RecentsAndFavorites({required this.onSelect});

  final void Function(Food food) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentFoodsProvider);
    final favorites = ref.watch(favoriteFoodsProvider);

    return ListView(
      children: [
        _Section(
          title: 'Favoritos',
          asyncFoods: favorites,
          onSelect: onSelect,
          emptyText: 'Aún no tienes alimentos favoritos.',
        ),
        _Section(
          title: 'Recientes',
          asyncFoods: recents,
          onSelect: onSelect,
          emptyText: 'Aún no has registrado alimentos.',
        ),
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.onSelect});

  final void Function(Food food) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(foodSearchResultsProvider);
    return results.when(
      data: (foods) => foods.isEmpty
          ? const Center(child: Text('Sin resultados.'))
          : ListView.builder(
              itemCount: foods.length,
              itemBuilder: (context, index) =>
                  _FoodTile(food: foods[index], onTap: onSelect),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.asyncFoods,
    required this.onSelect,
    required this.emptyText,
  });

  final String title;
  final AsyncValue<List<Food>> asyncFoods;
  final void Function(Food food) onSelect;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return asyncFoods.when(
      data: (foods) {
        if (foods.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            ...foods.map((food) => _FoodTile(food: food, onTap: onSelect)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.onTap});

  final Food food;
  final void Function(Food food) onTap;

  @override
  Widget build(BuildContext context) {
    final isForeignSource = food.source == FoodSource.usda;
    return ListTile(
      title: Text(food.name),
      subtitle: Text(
        '${food.nutritionPer100.calories.round()} kcal / 100${food.baseUnit}'
        '${food.brand != null ? ' · ${food.brand}' : ''}'
        '${isForeignSource ? ' · alimento comparable (USDA)' : ''}',
      ),
      trailing: food.isFavorite ? const Icon(Icons.star, size: 18) : null,
      onTap: () => onTap(food),
    );
  }
}
