import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inventory/inventory_item.dart';
import '../../domain/inventory/inventory_location.dart';
import '../../domain/inventory/inventory_providers.dart';
import '../../domain/nutrition/food.dart';
import '../nutrition/food_picker_screen.dart';
import '../../core/text/decimal_format.dart';

class InventoryItemFormScreen extends ConsumerStatefulWidget {
  const InventoryItemFormScreen({super.key, this.existingItem});

  final InventoryItem? existingItem;

  @override
  ConsumerState<InventoryItemFormScreen> createState() =>
      _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState
    extends ConsumerState<InventoryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  late final TextEditingController _customUnitController;
  Food? _food;
  InventoryLocation _location = InventoryLocation.pantry;
  DateTime? _expiresAt;
  String _unitLabel = 'g';
  bool _saving = false;

  /// Unidades genéricas para productos que no se convierten fácilmente a
  /// peso o volumen (ej. una caja de leche: no sabes cuántos gramos pesa).
  static const _genericUnits = [
    'unidad',
    'paquete',
    'caja',
    'bolsa',
    'lata',
    'frasco',
  ];

  bool get _isEditing => widget.existingItem != null;

  List<String> get _unitOptions {
    final food = _food;
    final options = <String>[
      if (food != null) food.baseUnit,
      if (food != null) ...food.servings.map((s) => s.label),
      ..._genericUnits,
    ];
    if (!options.contains(_unitLabel)) {
      options.add(_unitLabel);
    }
    return options.toSet().toList();
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    _food = existing?.food;
    _quantityController = TextEditingController(
      text: existing?.quantity.toStringAsFixed(0) ?? '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _customUnitController = TextEditingController();
    _location = existing?.location ?? InventoryLocation.pantry;
    _expiresAt = existing?.expiresAt;
    _unitLabel = existing?.unitLabel ?? (_food?.baseUnit ?? 'g');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  Future<void> _pickFood() async {
    final food = await Navigator.of(
      context,
    ).push<Food>(MaterialPageRoute(builder: (_) => const FoodPickerScreen()));
    if (food != null) {
      setState(() {
        _food = food;
        _unitLabel = food.baseUnit;
        _customUnitController.clear();
      });
    }
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() => _expiresAt = date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _food == null) {
      if (_food == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Elige un alimento.')));
      }
      return;
    }
    setState(() => _saving = true);
    final quantity = parseDecimalEs(_quantityController.text) ?? 0;
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    final customUnit = _customUnitController.text.trim();
    final unitLabel = customUnit.isNotEmpty ? customUnit : _unitLabel;

    if (_isEditing) {
      await ref
          .read(inventoryRepositoryProvider)
          .updateItem(
            id: widget.existingItem!.id,
            quantity: quantity,
            unitLabel: unitLabel,
            location: _location,
            expiresAt: _expiresAt,
            notes: notes,
          );
    } else {
      await ref
          .read(inventoryRepositoryProvider)
          .addItem(
            foodId: _food!.id,
            quantity: quantity,
            unitLabel: unitLabel,
            location: _location,
            expiresAt: _expiresAt,
            notes: notes,
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
        title: Text(_isEditing ? 'Editar en despensa' : 'Agregar a despensa'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_food?.name ?? 'Elegir alimento'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _isEditing ? null : _pickFood,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                        ),
                        validator: (value) {
                          final parsed = parseDecimalEs(value);
                          return (parsed == null || parsed <= 0)
                              ? 'Ingresa una cantidad válida'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unitLabel,
                        decoration: const InputDecoration(labelText: 'Unidad'),
                        items: _unitOptions
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _unitLabel = value ?? _unitLabel;
                          _customUnitController.clear();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customUnitController,
                  decoration: const InputDecoration(
                    labelText: 'O escribe otra unidad (opcional)',
                    hintText: 'Ej: caja de 1L, six pack',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InventoryLocation>(
                  initialValue: _location,
                  decoration: const InputDecoration(labelText: 'Ubicación'),
                  items: InventoryLocation.values
                      .map(
                        (l) => DropdownMenuItem(value: l, child: Text(l.label)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _location = value ?? _location),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _expiresAt == null
                        ? 'Fecha de vencimiento (opcional)'
                        : 'Vence: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}',
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _pickExpiry,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                  ),
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
                      : const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
