import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/food_source.dart';
import '../../domain/nutrition/meal_type.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../core/text/decimal_format.dart';

class AddMealItemScreen extends ConsumerStatefulWidget {
  const AddMealItemScreen({
    super.key,
    required this.food,
    required this.date,
    required this.mealType,
  });

  final Food food;
  final DateTime date;
  final MealType mealType;

  @override
  ConsumerState<AddMealItemScreen> createState() => _AddMealItemScreenState();
}

class _AddMealItemScreenState extends ConsumerState<AddMealItemScreen> {
  late final TextEditingController _quantityController;

  /// null significa "gramos/mililitros directos"; si no, es el id de una
  /// FoodServing predefinida.
  int? _selectedServingId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double get _quantity => parseDecimalEs(_quantityController.text) ?? 0;

  double get _gramsEquivalent {
    if (_selectedServingId == null) {
      return _quantity;
    }
    final serving = widget.food.servings.firstWhere(
      (s) => s.id == _selectedServingId,
    );
    return _quantity * serving.gramsEquivalent;
  }

  String get _unitLabel {
    if (_selectedServingId == null) {
      return widget.food.baseUnit;
    }
    return widget.food.servings
        .firstWhere((s) => s.id == _selectedServingId)
        .label;
  }

  Future<void> _confirm() async {
    if (_quantity <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa una cantidad.')));
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(mealRepositoryProvider)
        .addItem(
          date: widget.date,
          type: widget.mealType,
          foodId: widget.food.id,
          quantity: _quantity,
          unitLabel: _unitLabel,
          gramsEquivalent: _gramsEquivalent,
        );
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = widget.food.nutritionPer100.scaledToGrams(
      _gramsEquivalent,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.food.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.food.source == FoodSource.usda)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Valor nutricional estimado utilizando un alimento '
                    'comparable (base de datos USDA).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedServingId,
                      decoration: const InputDecoration(labelText: 'Unidad'),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            widget.food.baseUnit == 'ml'
                                ? 'Mililitros (ml)'
                                : 'Gramos (g)',
                          ),
                        ),
                        ...widget.food.servings.map(
                          (serving) => DropdownMenuItem(
                            value: serving.id,
                            child: Text(serving.label),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedServingId = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Equivale a ${_gramsEquivalent.toStringAsFixed(0)} '
                '${widget.food.baseUnit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aporte nutricional',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Calorías: ${nutrition.calories.round()} kcal'),
                      Text(
                        'Carbohidratos: ${nutrition.carbs.toStringAsFixed(1)} g',
                      ),
                      Text(
                        'Proteínas: ${nutrition.protein.toStringAsFixed(1)} g',
                      ),
                      Text('Grasas: ${nutrition.fat.toStringAsFixed(1)} g'),
                      Text('Fibra: ${nutrition.fiber.toStringAsFixed(1)} g'),
                      Text('Azúcares: ${nutrition.sugar.toStringAsFixed(1)} g'),
                      Text('Sodio: ${nutrition.sodium.toStringAsFixed(0)} mg'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _confirm,
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
