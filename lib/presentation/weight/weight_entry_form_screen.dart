import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/weight/weight_providers.dart';
import '../../core/text/decimal_format.dart';

class WeightEntryFormScreen extends ConsumerStatefulWidget {
  const WeightEntryFormScreen({super.key});

  @override
  ConsumerState<WeightEntryFormScreen> createState() =>
      _WeightEntryFormScreenState();
}

class _WeightEntryFormScreenState extends ConsumerState<WeightEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _measuredAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(
        () => _measuredAt = DateTime(
          date.year,
          date.month,
          date.day,
          _measuredAt.hour,
          _measuredAt.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(weightRepositoryProvider)
        .addEntry(
          measuredAt: _measuredAt,
          weightKg: parseDecimalEs(_weightController.text)!,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo registro de peso')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha'),
                  subtitle: Text(
                    '${_measuredAt.day}/${_measuredAt.month}/${_measuredAt.year}',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickDate,
                ),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  validator: (value) {
                    final parsed = parseDecimalEs(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un peso válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
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
