import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/nutrition/nutrition_goals.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/profile/biological_sex.dart';
import '../../domain/profile/chronic_condition.dart';
import '../../domain/profile/diabetes_type.dart';
import '../../domain/profile/profile_providers.dart';
import '../../domain/weight/weight_providers.dart';
import '../common/measurement_pickers.dart';
import '../common/medical_disclaimer_banner.dart';
import '../nutrition/goal_calculation.dart';

const _stepCount = 6;

/// Wizard de creación de perfil para la primera vez que se abre la app:
/// nombre, condición médica, datos personales, actividad y objetivo,
/// terminando con un cálculo automático de metas nutricionales que se
/// puede ajustar después desde el Perfil.
class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen> {
  int _step = 0;
  bool _saving = false;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  double? _heightCm;
  double? _weightKg;

  final Set<ChronicCondition> _conditions = {};
  DiabetesType? _diabetesType;
  BiologicalSex? _sex;
  ActivityLevel _activityLevel = ActivityLevel.sedentario;
  GoalObjective _goal = GoalObjective.mantener;
  GoalSpeed _speed = GoalSpeed.recomendado;
  bool _diabetesAwareMacros = false;
  NutritionGoals? _result;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 2:
        return _sex != null &&
            _heightCm != null &&
            _weightKg != null &&
            int.tryParse(_ageController.text.trim()) != null;
      default:
        return true;
    }
  }

  void _next() {
    if (!_canContinue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los datos para continuar.')),
      );
      return;
    }
    if (_step == _stepCount - 2) {
      _calculate();
    }
    setState(() => _step++);
  }

  void _back() => setState(() => _step--);

  void _calculate() {
    final age = int.tryParse(_ageController.text.trim());
    if (_heightCm == null || _weightKg == null || age == null || _sex == null) {
      return;
    }
    _result = GoalCalculation.compute(
      sex: _sex!,
      age: age,
      heightCm: _heightCm!,
      weightKg: _weightKg!,
      activityLevel: _activityLevel,
      objective: _goal,
      speed: _speed,
      diabetesAware: _diabetesAwareMacros,
    );
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref
        .read(profileRepositoryProvider)
        .saveProfile(
          name: _nameController.text.trim(),
          conditions: _conditions.toList(),
          diabetesType: _conditions.contains(ChronicCondition.diabetes)
              ? _diabetesType
              : null,
          heightCm: _heightCm,
          biologicalSex: _sex,
          age: int.tryParse(_ageController.text.trim()),
        );
    if (_weightKg != null) {
      await ref
          .read(weightRepositoryProvider)
          .addEntry(measuredAt: DateTime.now(), weightKg: _weightKg!);
    }
    if (_result != null) {
      await ref.read(nutritionGoalsRepositoryProvider).setGoals(_result!);
    }
    // No se navega: app.dart cambia a MainShell automáticamente en cuanto
    // el perfil deja de ser null.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _step == 0
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        title: const Text('Bienvenido a AliFit'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / _stepCount),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStep(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : (_step == _stepCount - 1 ? _finish : _next),
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _step == _stepCount - 1
                            ? 'Comenzar a usar AliFit'
                            : 'Continuar',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return _NameStep(controller: _nameController);
      case 1:
        return _ConditionsStep(
          conditions: _conditions,
          diabetesType: _diabetesType,
          onConditionsChanged: (value) => setState(() {
            _conditions
              ..clear()
              ..addAll(value);
            if (_conditions.contains(ChronicCondition.diabetes)) {
              _diabetesAwareMacros = true;
            }
          }),
          onDiabetesTypeChanged: (value) =>
              setState(() => _diabetesType = value),
        );
      case 2:
        return _PersonalDataStep(
          sex: _sex,
          onSexChanged: (value) => setState(() => _sex = value),
          heightCm: _heightCm,
          onHeightChanged: (value) => setState(() => _heightCm = value),
          weightKg: _weightKg,
          onWeightChanged: (value) => setState(() => _weightKg = value),
          ageController: _ageController,
        );
      case 3:
        return _ActivityStep(
          activityLevel: _activityLevel,
          onChanged: (value) => setState(() => _activityLevel = value),
        );
      case 4:
        return _GoalStep(
          goal: _goal,
          onGoalChanged: (value) => setState(() => _goal = value),
          speed: _speed,
          onSpeedChanged: (value) => setState(() => _speed = value),
          diabetesAwareMacros: _diabetesAwareMacros,
          onDiabetesAwareChanged: (value) =>
              setState(() => _diabetesAwareMacros = value),
        );
      default:
        return _ResultStep(result: _result);
    }
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo te llamas?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Este perfil se guarda solo en tu teléfono. Cada persona que '
          'instale la app configura el suyo por separado.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tu nombre'),
        ),
      ],
    );
  }
}

class _ConditionsStep extends StatelessWidget {
  const _ConditionsStep({
    required this.conditions,
    required this.diabetesType,
    required this.onConditionsChanged,
    required this.onDiabetesTypeChanged,
  });

  final Set<ChronicCondition> conditions;
  final DiabetesType? diabetesType;
  final ValueChanged<Set<ChronicCondition>> onConditionsChanged;
  final ValueChanged<DiabetesType?> onDiabetesTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Tienes alguna condición a considerar?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        const Text('Puedes marcar más de una, o ninguna.'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: ChronicCondition.values.map((condition) {
            return FilterChip(
              label: Text(condition.label),
              selected: conditions.contains(condition),
              onSelected: (selected) {
                final updated = {...conditions};
                if (selected) {
                  updated.add(condition);
                } else {
                  updated.remove(condition);
                }
                onConditionsChanged(updated);
              },
            );
          }).toList(),
        ),
        if (conditions.contains(ChronicCondition.diabetes)) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<DiabetesType>(
            initialValue: diabetesType,
            decoration: const InputDecoration(
              labelText: 'Tipo de diabetes (opcional)',
            ),
            items: DiabetesType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: onDiabetesTypeChanged,
          ),
        ],
        const SizedBox(height: 16),
        const MedicalDisclaimerBanner(),
      ],
    );
  }
}

class _PersonalDataStep extends StatelessWidget {
  const _PersonalDataStep({
    required this.sex,
    required this.onSexChanged,
    required this.heightCm,
    required this.onHeightChanged,
    required this.weightKg,
    required this.onWeightChanged,
    required this.ageController,
  });

  final BiologicalSex? sex;
  final ValueChanged<BiologicalSex?> onSexChanged;
  final double? heightCm;
  final ValueChanged<double> onHeightChanged;
  final double? weightKg;
  final ValueChanged<double> onWeightChanged;
  final TextEditingController ageController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sobre ti', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text(
          'Esta información nos ayuda a calcular tus calorías objetivo.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: BiologicalSex.values.map((value) {
            return ChoiceChip(
              label: Text(value.label),
              selected: sex == value,
              onSelected: (selected) => onSexChanged(selected ? value : null),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HeightPickerTile(
                valueCm: heightCm,
                onChanged: onHeightChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WeightPickerTile(
                valueKg: weightKg,
                onChanged: onWeightChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Edad (años)'),
        ),
      ],
    );
  }
}

class _ActivityStep extends StatelessWidget {
  const _ActivityStep({required this.activityLevel, required this.onChanged});

  final ActivityLevel activityLevel;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cuál es tu nivel de actividad?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        const Text('Puedes cambiarlo después.'),
        const SizedBox(height: 16),
        ...ActivityLevel.values.map(
          (level) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              activityLevel == level
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(level.label),
            onTap: () => onChanged(level),
          ),
        ),
      ],
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.goal,
    required this.onGoalChanged,
    required this.speed,
    required this.onSpeedChanged,
    required this.diabetesAwareMacros,
    required this.onDiabetesAwareChanged,
  });

  final GoalObjective goal;
  final ValueChanged<GoalObjective> onGoalChanged;
  final GoalSpeed speed;
  final ValueChanged<GoalSpeed> onSpeedChanged;
  final bool diabetesAwareMacros;
  final ValueChanged<bool> onDiabetesAwareChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cuál es tu objetivo?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...GoalObjective.values.map(
          (value) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              goal == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(value.label),
            subtitle: value.description == null
                ? null
                : Text(value.description!),
            onTap: () => onGoalChanged(value),
          ),
        ),
        if (goal.usesSpeed) ...[
          const SizedBox(height: 8),
          Text('Velocidad', style: Theme.of(context).textTheme.titleSmall),
          ...GoalSpeed.values.map(
            (value) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                speed == value
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(value.label),
              subtitle: Text(value.description),
              onTap: () => onSpeedChanged(value),
            ),
          ),
        ],
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reparto de macros orientado a diabetes'),
          subtitle: const Text(
            'Algo menos de carbohidratos, más proteína y grasa.',
          ),
          value: diabetesAwareMacros,
          onChanged: (value) => onDiabetesAwareChanged(value ?? false),
        ),
      ],
    );
  }
}

class _ResultStep extends StatelessWidget {
  const _ResultStep({required this.result});

  final NutritionGoals? result;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const Text(
        'Completa los pasos anteriores para calcular tus metas.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Listo! Estas son tus metas',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result!.calories.round()} kcal / día',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Carbohidratos: ${result!.carbs.round()} g · '
                  'Proteínas: ${result!.protein.round()} g · '
                  'Grasas: ${result!.fat.round()} g',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Es solo una estimación referencial. Puedes ajustarla cuando '
          'quieras desde tu Perfil.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
