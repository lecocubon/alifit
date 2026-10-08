import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/meal_type.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/nutrition/nutrition_values.dart';
import '../../domain/recipes/recipe.dart';
import 'food_search_screen.dart';
import '../../core/text/decimal_format.dart';

class _EditableIngredient {
  _EditableIngredient({
    required this.food,
    required double quantity,
    required this.unitLabel,
    required this.gramsPerUnit,
  }) : quantityController = TextEditingController(
         text: quantity == quantity.roundToDouble()
             ? quantity.toStringAsFixed(0)
             : quantity.toStringAsFixed(1),
       );

  final Food food;
  final TextEditingController quantityController;
  final String unitLabel;

  /// Gramos/mililitros equivalentes a 1 unidad de [unitLabel].
  final double gramsPerUnit;

  double get quantity => parseDecimalEs(quantityController.text) ?? 0;

  double get gramsEquivalent => quantity * gramsPerUnit;

  NutritionValues get nutrition =>
      food.nutritionPer100.scaledToGrams(gramsEquivalent);
}

/// Permite agregar una receta al diario, editando o quitando ingredientes
/// solo para este registro puntual (la receta original no se modifica).
class AddRecipeToMealScreen extends ConsumerStatefulWidget {
  const AddRecipeToMealScreen({
    super.key,
    required this.recipe,
    required this.date,
    required this.mealType,
  });

  final Recipe recipe;
  final DateTime date;
  final MealType mealType;

  @override
  ConsumerState<AddRecipeToMealScreen> createState() =>
      _AddRecipeToMealScreenState();
}

class _AddRecipeToMealScreenState extends ConsumerState<AddRecipeToMealScreen> {
  late List<_EditableIngredient> _ingredients;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ingredients = widget.recipe.ingredients
        .map(
          (ingredient) => _EditableIngredient(
            food: ingredient.food,
            quantity: ingredient.quantity,
            unitLabel: ingredient.unitLabel,
            gramsPerUnit: ingredient.quantity > 0
                ? ingredient.gramsEquivalent / ingredient.quantity
                : 0,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final ingredient in _ingredients) {
      ingredient.quantityController.dispose();
    }
    super.dispose();
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index).quantityController.dispose();
    });
  }

  Future<void> _addExtraFood() async {
    final food = await Navigator.of(context).push<Food>(
      MaterialPageRoute(
        builder: (_) => FoodSearchScreen(
          date: widget.date,
          mealType: widget.mealType,
          pickerOnly: true,
        ),
      ),
    );
    if (food == null) {
      return;
    }
    setState(() {
      _ingredients.add(
        _EditableIngredient(
          food: food,
          quantity: 100,
          unitLabel: food.baseUnit,
          gramsPerUnit: 1,
        ),
      );
    });
  }

  NutritionValues get _totals => _ingredients.fold(
    NutritionValues.zero,
    (sum, ingredient) => sum + ingredient.nutrition,
  );

  Future<void> _confirm() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No quedan ingredientes por agregar.')),
      );
      return;
    }
    setState(() => _saving = true);
    final repository = ref.read(mealRepositoryProvider);
    for (final ingredient in _ingredients) {
      if (ingredient.quantity <= 0) {
        continue;
      }
      await repository.addItem(
        date: widget.date,
        type: widget.mealType,
        foodId: ingredient.food.id,
        quantity: ingredient.quantity,
        unitLabel: ingredient.unitLabel,
        gramsEquivalent: ingredient.gramsEquivalent,
      );
    }
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.name)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Ajusta o quita lo que no corresponda antes de agregarlo a '
                '${widget.mealType.label.toLowerCase()}. Esto no cambia la '
                'receta guardada.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _ingredients[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(ingredient.food.name)),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: ingredient.quantityController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                isDense: true,
                                suffixText: ingredient.unitLabel,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeIngredient(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _addExtraFood,
                icon: const Icon(Icons.add),
                label: const Text('Agregar otro alimento'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${totals.calories.round()} kcal · '
                        '${totals.carbs.round()} C · '
                        '${totals.protein.round()} P · '
                        '${totals.fat.round()} G',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      FilledButton(
                        onPressed: _saving ? null : _confirm,
                        child: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Agregar'),
                      ),
                    ],
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
