import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/nutrition/food.dart';
import '../../domain/recipes/recipe.dart';
import '../../domain/recipes/recipe_providers.dart';
import '../../domain/recipes/recipe_repository.dart';
import '../nutrition/food_picker_screen.dart';
import '../../core/text/decimal_format.dart';

class _IngredientDraft {
  _IngredientDraft({
    required this.food,
    required this.quantity,
    required this.unitLabel,
    required this.gramsEquivalent,
    this.isOptional = false,
  });

  final Food food;
  double quantity;
  String unitLabel;
  double gramsEquivalent;
  bool isOptional;
}

class RecipeFormScreen extends ConsumerStatefulWidget {
  const RecipeFormScreen({super.key, this.existingRecipe});

  final Recipe? existingRecipe;

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _servingsController;
  late final TextEditingController _prepMinutesController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _otherIngredientsController;
  late final TextEditingController _tagsController;
  late final TextEditingController _costController;
  final _ingredients = <_IngredientDraft>[];
  bool _saving = false;

  bool get _isEditing => widget.existingRecipe != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRecipe;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _servingsController = TextEditingController(
      text: (existing?.servings ?? 2).toString(),
    );
    _prepMinutesController = TextEditingController(
      text: existing?.prepMinutes?.toString() ?? '',
    );
    _instructionsController = TextEditingController(
      text: existing?.instructions ?? '',
    );
    _otherIngredientsController = TextEditingController(
      text: existing?.otherIngredients.join('\n') ?? '',
    );
    _tagsController = TextEditingController(
      text: existing?.tags.join(', ') ?? '',
    );
    _costController = TextEditingController(
      text: existing?.costEstimate?.toStringAsFixed(0) ?? '',
    );
    if (existing != null) {
      for (final ingredient in existing.ingredients) {
        _ingredients.add(
          _IngredientDraft(
            food: ingredient.food,
            quantity: ingredient.quantity,
            unitLabel: ingredient.unitLabel,
            gramsEquivalent: ingredient.gramsEquivalent,
            isOptional: ingredient.isOptional,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingsController.dispose();
    _prepMinutesController.dispose();
    _instructionsController.dispose();
    _otherIngredientsController.dispose();
    _tagsController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _addIngredient() async {
    final food = await Navigator.of(context).push<Food>(
      MaterialPageRoute(
        builder: (_) => const FoodPickerScreen(title: 'Agregar ingrediente'),
      ),
    );
    if (food == null) {
      return;
    }
    setState(() {
      _ingredients.add(
        _IngredientDraft(
          food: food,
          quantity: 100,
          unitLabel: food.baseUnit,
          gramsEquivalent: 100,
        ),
      );
    });
  }

  void _updateQuantity(_IngredientDraft draft, double quantity) {
    setState(() {
      final serving = draft.unitLabel == draft.food.baseUnit
          ? null
          : draft.food.servings
                .where((s) => s.label == draft.unitLabel)
                .firstOrNull;
      draft.quantity = quantity;
      draft.gramsEquivalent = serving == null
          ? quantity
          : quantity * serving.gramsEquivalent;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ingrediente.')),
      );
      return;
    }
    setState(() => _saving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final otherIngredients = _otherIngredientsController.text
        .split('\n')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final ingredientInputs = _ingredients
        .map(
          (d) => RecipeIngredientInput(
            foodId: d.food.id,
            quantity: d.quantity,
            unitLabel: d.unitLabel,
            gramsEquivalent: d.gramsEquivalent,
            isOptional: d.isOptional,
          ),
        )
        .toList();

    final repo = ref.read(recipeRepositoryProvider);
    if (_isEditing) {
      await repo.updateRecipe(
        id: widget.existingRecipe!.id,
        name: _nameController.text.trim(),
        servings: int.tryParse(_servingsController.text.trim()) ?? 1,
        ingredients: ingredientInputs,
        prepMinutes: int.tryParse(_prepMinutesController.text.trim()),
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        tags: tags,
        otherIngredients: otherIngredients,
        costEstimate: parseDecimalEs(_costController.text),
      );
    } else {
      await repo.createRecipe(
        name: _nameController.text.trim(),
        servings: int.tryParse(_servingsController.text.trim()) ?? 1,
        ingredients: ingredientInputs,
        prepMinutes: int.tryParse(_prepMinutesController.text.trim()),
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        tags: tags,
        otherIngredients: otherIngredients,
        costEstimate: parseDecimalEs(_costController.text),
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar receta' : 'Nueva receta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _servingsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Porciones',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _prepMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minutos (opcional)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Etiquetas separadas por coma (opcional)',
                    hintText: 'Ej: rápido, vegetariano',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Costo estimado (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Preparación (opcional)',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ingredientes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addIngredient,
                    ),
                  ],
                ),
                if (_ingredients.isEmpty)
                  const Text('Aún no hay ingredientes.')
                else
                  ..._ingredients.map(
                    (draft) => _IngredientRow(
                      draft: draft,
                      onQuantityChanged: (q) => _updateQuantity(draft, q),
                      onUnitChanged: (unit) => setState(() {
                        draft.unitLabel = unit;
                        _updateQuantity(draft, draft.quantity);
                      }),
                      onOptionalChanged: (v) =>
                          setState(() => draft.isOptional = v),
                      onRemove: () =>
                          setState(() => _ingredients.remove(draft)),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Otros ingredientes (opcional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Uno por línea, con su cantidad incluida (ej. "Levadura '
                  'seca, 7 g"). No se cuentan en la información '
                  'nutricional: úsalo para agua, sal, levadura, '
                  'condimentos a gusto, etc.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otherIngredientsController,
                  decoration: const InputDecoration(
                    hintText:
                        'Agua tibia, 300 ml\nLevadura seca, 7 g\nSal, 10 g',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar receta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.draft,
    required this.onQuantityChanged,
    required this.onUnitChanged,
    required this.onOptionalChanged,
    required this.onRemove,
  });

  final _IngredientDraft draft;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<bool> onOptionalChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(draft.food.name)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: draft.quantity.toStringAsFixed(0),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    onChanged: (value) =>
                        onQuantityChanged(parseDecimalEs(value) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: draft.unitLabel,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: [
                      DropdownMenuItem(
                        value: draft.food.baseUnit,
                        child: Text(
                          draft.food.baseUnit == 'ml' ? 'ml' : 'gramos',
                        ),
                      ),
                      ...draft.food.servings.map(
                        (s) => DropdownMenuItem(
                          value: s.label,
                          child: Text(s.label),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onUnitChanged(value);
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: draft.isOptional,
                  onChanged: (v) => onOptionalChanged(v ?? false),
                ),
                const Text('Opcional'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
