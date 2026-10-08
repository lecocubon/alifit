import 'package:flutter/material.dart';

import '../../domain/nutrition/nutrition_goals.dart';
import '../../domain/nutrition/nutrition_values.dart';

/// Tarjeta de resumen nutricional: calorías y macros con barra de avance
/// contra la meta configurada, más fibra/azúcares/sodio informativos (sin
/// meta asociada).
class NutritionSummaryCard extends StatelessWidget {
  const NutritionSummaryCard({
    super.key,
    required this.totals,
    required this.goals,
    this.title = 'Total del día',
    this.extraCalories = 0,
  });

  final NutritionValues totals;
  final NutritionGoals goals;
  final String title;

  /// Calorías quemadas por actividad física, sumadas a la meta del día
  /// (igual que hacen la mayoría de los apps de conteo de calorías).
  final double extraCalories;

  @override
  Widget build(BuildContext context) {
    final calorieGoal = goals.calories + extraCalories;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _GoalRow(
              label: extraCalories > 0
                  ? 'Calorías (+${extraCalories.round()} por actividad)'
                  : 'Calorías',
              consumed: totals.calories,
              goal: calorieGoal,
              unit: 'kcal',
            ),
            const SizedBox(height: 10),
            _GoalRow(
              label: 'Carbohidratos',
              consumed: totals.carbs,
              goal: goals.carbs,
              unit: 'g',
            ),
            const SizedBox(height: 10),
            _GoalRow(
              label: 'Proteínas',
              consumed: totals.protein,
              goal: goals.protein,
              unit: 'g',
            ),
            const SizedBox(height: 10),
            _GoalRow(
              label: 'Grasas',
              consumed: totals.fat,
              goal: goals.fat,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              'Fibra: ${totals.fiber.toStringAsFixed(0)} g · '
              'Azúcares: ${totals.sugar.toStringAsFixed(0)} g · '
              'Sodio: ${totals.sodium.toStringAsFixed(0)} mg',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.unit,
  });

  final String label;
  final double consumed;
  final double goal;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final ratio = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final over = goal > 0 && consumed > goal;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${consumed.round()} / ${goal.round()} $unit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: over ? colorScheme.error : colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
