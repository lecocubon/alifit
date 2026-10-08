import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/nutrition/food.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/nutrition/nutrition_values.dart';
import '../../core/text/decimal_format.dart';

enum _EntryMode { per100, perServing, perUnit }

class FoodFormScreen extends ConsumerStatefulWidget {
  const FoodFormScreen({super.key, this.existingFood, this.prefilledBarcode});

  final Food? existingFood;

  /// Código de barras a precargar al crear un alimento nuevo (ej. cuando
  /// viene de un escaneo que no encontró coincidencia en Open Food Facts).
  final String? prefilledBarcode;

  @override
  ConsumerState<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends ConsumerState<FoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _notesController;
  late final TextEditingController _gramsPerReferenceController;

  final _nutrientControllers = <String, TextEditingController>{};
  _EntryMode _mode = _EntryMode.per100;
  bool _saving = false;

  static const _nutrientFields = [
    ('calories', 'Calorías (kcal)'),
    ('carbs', 'Carbohidratos (g)'),
    ('protein', 'Proteínas (g)'),
    ('fat', 'Grasas (g)'),
    ('fiber', 'Fibra (g)'),
    ('sugar', 'Azúcares (g)'),
    ('sodium', 'Sodio (mg)'),
  ];

  bool get _isEditing => widget.existingFood != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingFood;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _brandController = TextEditingController(text: existing?.brand ?? '');
    _barcodeController = TextEditingController(
      text: existing?.barcode ?? widget.prefilledBarcode ?? '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _gramsPerReferenceController = TextEditingController(text: '100');

    final n = existing?.nutritionPer100;
    for (final (key, _) in _nutrientFields) {
      final value = switch (key) {
        'calories' => n?.calories,
        'carbs' => n?.carbs,
        'protein' => n?.protein,
        'fat' => n?.fat,
        'fiber' => n?.fiber,
        'sugar' => n?.sugar,
        'sodium' => n?.sodium,
        _ => null,
      };
      _nutrientControllers[key] = TextEditingController(
        text: value == null ? '' : _trimZeros(value),
      );
    }
  }

  String _trimZeros(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _notesController.dispose();
    _gramsPerReferenceController.dispose();
    for (final c in _nutrientControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(String text) => parseDecimalEs(text) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final referenceGrams = _mode == _EntryMode.per100
        ? 100.0
        : _parse(_gramsPerReferenceController.text);
    if (referenceGrams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa los gramos de referencia.')),
      );
      return;
    }

    final enteredCalories = _parse(_nutrientControllers['calories']!.text);
    final enteredCarbs = _parse(_nutrientControllers['carbs']!.text);
    final enteredProtein = _parse(_nutrientControllers['protein']!.text);
    final enteredFat = _parse(_nutrientControllers['fat']!.text);
    final enteredFiber = _parse(_nutrientControllers['fiber']!.text);
    final enteredSugar = _parse(_nutrientControllers['sugar']!.text);
    final enteredSodium = _parse(_nutrientControllers['sodium']!.text);

    final scale = 100 / referenceGrams;
    final per100 = NutritionValues(
      calories: enteredCalories * scale,
      carbs: enteredCarbs * scale,
      protein: enteredProtein * scale,
      fat: enteredFat * scale,
      fiber: enteredFiber * scale,
      sugar: enteredSugar * scale,
      sodium: enteredSodium * scale,
    );

    setState(() => _saving = true);
    final repo = ref.read(foodRepositoryProvider);
    final int id;
    if (_isEditing) {
      id = widget.existingFood!.id;
      await repo.updateFood(
        id: id,
        name: _nameController.text.trim(),
        brand: _emptyToNull(_brandController.text),
        nutritionPer100: per100,
        baseUnit: 'g',
        barcode: _emptyToNull(_barcodeController.text),
        notes: _emptyToNull(_notesController.text),
      );
    } else {
      id = await repo.createFood(
        name: _nameController.text.trim(),
        brand: _emptyToNull(_brandController.text),
        nutritionPer100: per100,
        baseUnit: 'g',
        barcode: _emptyToNull(_barcodeController.text),
        notes: _emptyToNull(_notesController.text),
      );
    }

    if (mounted) {
      final saved = await repo.getById(id);
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    }
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar alimento' : 'Nuevo alimento'),
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
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    labelText: 'Marca (opcional)',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ingresar valores nutricionales...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<_EntryMode>(
                  segments: const [
                    ButtonSegment(
                      value: _EntryMode.per100,
                      label: Text('Por 100 g'),
                    ),
                    ButtonSegment(
                      value: _EntryMode.perServing,
                      label: Text('Por porción'),
                    ),
                    ButtonSegment(
                      value: _EntryMode.perUnit,
                      label: Text('Por unidad'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) =>
                      setState(() => _mode = selection.first),
                ),
                if (_mode != _EntryMode.per100) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gramsPerReferenceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: _mode == _EntryMode.perServing
                          ? 'Gramos por porción'
                          : 'Gramos por unidad',
                    ),
                    validator: (value) => (_parse(value ?? '') <= 0)
                        ? 'Ingresa un valor mayor a 0'
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                ..._nutrientFields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _nutrientControllers[field.$1],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: field.$2),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de barras (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                  ),
                  maxLines: 2,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 24),
                  _AliasSection(foodId: widget.existingFood!.id),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar alimento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lista de nombres/sinónimos locales (ej. chilenos) para este alimento,
/// usados por la búsqueda además del nombre principal.
class _AliasSection extends ConsumerStatefulWidget {
  const _AliasSection({required this.foodId});

  final int foodId;

  @override
  ConsumerState<_AliasSection> createState() => _AliasSectionState();
}

class _AliasSectionState extends ConsumerState<_AliasSection> {
  final _aliasController = TextEditingController();

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _addAlias() async {
    final value = _aliasController.text.trim();
    if (value.isEmpty) {
      return;
    }
    await ref.read(foodRepositoryProvider).addAlias(widget.foodId, value);
    _aliasController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final aliasesAsync = ref.watch(foodAliasesProvider(widget.foodId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sinónimos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'Otros nombres con los que también se busca este alimento '
          '(ej. nombres chilenos).',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _aliasController,
                decoration: const InputDecoration(hintText: 'Ej: Palta'),
                onSubmitted: (_) => _addAlias(),
              ),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: _addAlias),
          ],
        ),
        aliasesAsync.when(
          data: (aliases) => Wrap(
            spacing: 8,
            children: aliases
                .map(
                  (a) => Chip(
                    label: Text(a.$2),
                    onDeleted: () =>
                        ref.read(foodRepositoryProvider).removeAlias(a.$1),
                  ),
                )
                .toList(),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
