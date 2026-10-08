import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/nutrition/nutrition_goals.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/profile/biological_sex.dart';
import '../../domain/profile/chronic_condition.dart';
import '../../domain/profile/profile_providers.dart';
import '../../domain/profile/user_profile.dart';
import '../../domain/weight/weight_entry.dart';
import '../../domain/weight/weight_providers.dart';
import '../common/measurement_pickers.dart';
import '../common/medical_disclaimer_banner.dart';
import 'goal_calculation.dart';

/// Calcula calorías y macros sugeridos a partir del perfil, el peso más
/// reciente, el nivel de actividad y el objetivo. Es solo una estimación
/// referencial (fórmula de Mifflin-St Jeor); no reemplaza una indicación
/// nutricional profesional.
class NutritionGoalsCalculatorScreen extends ConsumerStatefulWidget {
  const NutritionGoalsCalculatorScreen({super.key});

  @override
  ConsumerState<NutritionGoalsCalculatorScreen> createState() =>
      _NutritionGoalsCalculatorScreenState();
}

class _NutritionGoalsCalculatorScreenState
    extends ConsumerState<NutritionGoalsCalculatorScreen> {
  final _ageController = TextEditingController();
  double? _weightKg;
  double? _heightCm;
  BiologicalSex? _sex;
  bool _hasDiabetes = false;
  ActivityLevel _activityLevel = ActivityLevel.sedentario;
  GoalObjective _goal = GoalObjective.mantener;
  GoalSpeed _speed = GoalSpeed.recomendado;
  bool _prefilled = false;
  NutritionGoals? _result;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(
    AsyncValue<UserProfile?> profileAsync,
    AsyncValue<List<WeightEntry>> weightAsync,
  ) {
    if (_prefilled) {
      return;
    }
    final profile = profileAsync.value;
    final weightEntries = weightAsync.value;
    if (profile != null) {
      _sex = profile.biologicalSex;
      _hasDiabetes = profile.conditions.contains(ChronicCondition.diabetes);
      _heightCm = profile.heightCm;
      if (profile.age != null) {
        _ageController.text = profile.age!.toString();
      }
    }
    if (weightEntries != null && weightEntries.isNotEmpty) {
      _weightKg = weightEntries.first.weightKg;
    }
    _prefilled = true;
  }

  void _calculate() {
    final age = int.tryParse(_ageController.text.trim());
    if (_weightKg == null || _heightCm == null || age == null || _sex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa peso, altura, edad y sexo biológico.'),
        ),
      );
      return;
    }

    setState(() {
      _result = GoalCalculation.compute(
        sex: _sex!,
        age: age,
        heightCm: _heightCm!,
        weightKg: _weightKg!,
        activityLevel: _activityLevel,
        objective: _goal,
        speed: _speed,
        diabetesAware: _hasDiabetes,
      );
    });
  }

  Future<void> _apply() async {
    if (_result == null) {
      return;
    }
    await ref.read(nutritionGoalsRepositoryProvider).setGoals(_result!);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileProvider);
    final weightAsync = ref.watch(weightEntriesProvider);
    _prefillIfNeeded(profileAsync, weightAsync);

    return Scaffold(
      appBar: AppBar(title: const Text('Calcular metas automáticamente')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Estimación referencial (fórmula de Mifflin-St Jeor) a '
              'partir de tus datos. Ajusta lo que necesites antes de '
              'calcular.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: WeightPickerTile(
                    valueKg: _weightKg,
                    onChanged: (value) => setState(() => _weightKg = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HeightPickerTile(
                    valueCm: _heightCm,
                    onChanged: (value) => setState(() => _heightCm = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Edad (años)'),
            ),
            const SizedBox(height: 16),
            Text(
              'Sexo biológico',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BiologicalSex.values.map((sex) {
                return ChoiceChip(
                  label: Text(sex.label),
                  selected: _sex == sex,
                  onSelected: (selected) =>
                      setState(() => _sex = selected ? sex : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Nivel de actividad',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...ActivityLevel.values.map(
              (level) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  _activityLevel == level
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(level.label),
                onTap: () => setState(() => _activityLevel = level),
              ),
            ),
            const SizedBox(height: 8),
            Text('Objetivo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: GoalObjective.values.map((goal) {
                return ChoiceChip(
                  label: Text(goal.label),
                  selected: _goal == goal,
                  onSelected: (selected) =>
                      setState(() => _goal = selected ? goal : _goal),
                );
              }).toList(),
            ),
            if (_goal.description != null) ...[
              const SizedBox(height: 4),
              Text(
                _goal.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_goal.usesSpeed) ...[
              const SizedBox(height: 16),
              Text('Velocidad', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...GoalSpeed.values.map(
                (speed) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    _speed == speed
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(speed.label),
                  subtitle: Text(speed.description),
                  onTap: () => setState(() => _speed = speed),
                ),
              ),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Reparto de macros orientado a diabetes'),
              subtitle: const Text(
                'Algo menos de carbohidratos, más proteína y grasa.',
              ),
              value: _hasDiabetes,
              onChanged: (value) =>
                  setState(() => _hasDiabetes = value ?? false),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _calculate, child: const Text('Calcular')),
            if (_result != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_result!.calories.round()} kcal / día',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Carbohidratos: ${_result!.carbs.round()} g · '
                        'Proteínas: ${_result!.protein.round()} g · '
                        'Grasas: ${_result!.fat.round()} g',
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _apply,
                        child: const Text('Usar estas metas'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const MedicalDisclaimerBanner(),
          ],
        ),
      ),
    );
  }
}
