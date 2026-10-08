import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import 'barcode_scan_screen.dart';
import 'food_form_screen.dart';

/// Selector de alimentos genérico: devuelve el [Food] elegido vía
/// Navigator.pop, sin registrar nada. Usado para elegir ingredientes de
/// una receta o ítems de inventario.
class FoodPickerScreen extends ConsumerStatefulWidget {
  const FoodPickerScreen({super.key, this.title = 'Elegir alimento'});

  final String title;

  @override
  ConsumerState<FoodPickerScreen> createState() => _FoodPickerScreenState();
}

class _FoodPickerScreenState extends ConsumerState<FoodPickerScreen> {
  @override
  void initState() {
    super.initState();
    Future(() => ref.read(foodSearchQueryProvider.notifier).update(''));
  }

  Future<void> _createNewFood() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FoodFormScreen()));
  }

  Future<void> _scanBarcode() async {
    final food = await Navigator.of(
      context,
    ).push<Food>(MaterialPageRoute(builder: (_) => const BarcodeScanScreen()));
    if (food != null && mounted) {
      Navigator.of(context).pop(food);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(foodSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
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
      ),
      body: SafeArea(
        child: Column(
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
                  ? const _RecentsAndFavorites()
                  : const _SearchResults(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentsAndFavorites extends ConsumerWidget {
  const _RecentsAndFavorites();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentFoodsProvider);
    final favorites = ref.watch(favoriteFoodsProvider);

    return ListView(
      children: [
        _Section(title: 'Favoritos', asyncFoods: favorites),
        _Section(title: 'Recientes', asyncFoods: recents),
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(foodSearchResultsProvider);
    return results.when(
      data: (foods) => foods.isEmpty
          ? const Center(child: Text('Sin resultados.'))
          : ListView.builder(
              itemCount: foods.length,
              itemBuilder: (context, index) => _FoodTile(food: foods[index]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.asyncFoods});

  final String title;
  final AsyncValue<List<Food>> asyncFoods;

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
            ...foods.map((food) => _FoodTile(food: food)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(food.name),
      subtitle: Text(
        '${food.nutritionPer100.calories.round()} kcal / 100${food.baseUnit}',
      ),
      onTap: () => Navigator.of(context).pop(food),
    );
  }
}
