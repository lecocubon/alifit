import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/glucose/glucose_context.dart';
import '../../domain/glucose/glucose_providers.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../common/medical_disclaimer_banner.dart';
import '../../core/text/decimal_format.dart';

class GlucoseEntryFormScreen extends ConsumerStatefulWidget {
  const GlucoseEntryFormScreen({super.key});

  @override
  ConsumerState<GlucoseEntryFormScreen> createState() =>
      _GlucoseEntryFormScreenState();
}

class _GlucoseEntryFormScreenState
    extends ConsumerState<GlucoseEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _hoursAfterController = TextEditingController();
  final _activityController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _medicationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _measuredAt = DateTime.now();
  GlucoseContext _context = GlucoseContext.ayunas;
  int? _relatedMealId;
  bool _saving = false;

  @override
  void dispose() {
    _valueController.dispose();
    _hoursAfterController.dispose();
    _activityController.dispose();
    _symptomsController.dispose();
    _medicationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredAt),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _measuredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _relatedMealId = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(glucoseRepositoryProvider)
        .addEntry(
          measuredAt: _measuredAt,
          value: parseDecimalEs(_valueController.text)!,
          context: _context,
          relatedMealId: _relatedMealId,
          hoursAfterMeal: parseDecimalEs(_hoursAfterController.text),
          physicalActivity: _emptyToNull(_activityController.text),
          symptoms: _emptyToNull(_symptomsController.text),
          medicationNote: _emptyToNull(_medicationController.text),
          notes: _emptyToNull(_notesController.text),
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    final dayMeals = ref.watch(
      mealsForDateProvider(
        DateTime(_measuredAt.year, _measuredAt.month, _measuredAt.day),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo registro de glicemia')),
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
                  title: const Text('Fecha y hora'),
                  subtitle: Text(
                    DateFormat(
                      "d 'de' MMMM yyyy, HH:mm",
                      'es',
                    ).format(_measuredAt),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _pickDateTime,
                ),
                TextFormField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Valor (mg/dL)'),
                  validator: (value) {
                    final parsed = parseDecimalEs(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un valor válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GlucoseContext>(
                  initialValue: _context,
                  decoration: const InputDecoration(labelText: 'Contexto'),
                  items: GlucoseContext.values
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _context = value ?? _context),
                ),
                const SizedBox(height: 12),
                dayMeals.when(
                  data: (meals) => meals.isEmpty
                      ? const SizedBox.shrink()
                      : DropdownButtonFormField<int?>(
                          initialValue: _relatedMealId,
                          decoration: const InputDecoration(
                            labelText: 'Comida relacionada (opcional)',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Ninguna'),
                            ),
                            ...meals.map(
                              (m) => DropdownMenuItem(
                                value: m.id,
                                child: Text(m.displayLabel),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _relatedMealId = value),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hoursAfterController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Horas después de comer (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _activityController,
                  decoration: const InputDecoration(
                    labelText: 'Actividad física (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _symptomsController,
                  decoration: const InputDecoration(
                    labelText: 'Síntomas (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _medicationController,
                  decoration: const InputDecoration(
                    labelText: 'Medicación (nota, opcional)',
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
                const SizedBox(height: 16),
                const MedicalDisclaimerBanner(),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar registro'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
