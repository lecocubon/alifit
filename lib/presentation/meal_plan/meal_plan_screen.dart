import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/text/decimal_format.dart';
import '../../domain/meal_plan/meal_plan.dart';
import '../../domain/meal_plan/meal_plan_providers.dart';
import '../common/meal_type_icon.dart';
import '../common/medical_disclaimer_banner.dart';

/// Plan de comidas del nutricionista: porciones de cada comida del día, con
/// ejemplos, suplementación y recomendaciones deportivas.
class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(mealPlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi plan de comidas')),
      body: SafeArea(
        child: planAsync.when(
          data: (plan) => plan == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay un plan de comidas importado. Puedes '
                      'importarlo desde Perfil → Mi plan del nutri.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HeaderCard(plan: plan),
                    for (final meal in plan.meals) _MealCard(meal: meal),
                    if (plan.supplements.isNotEmpty)
                      _BulletCard(
                        icon: Icons.medication_outlined,
                        title: 'Suplementación',
                        items: plan.supplements,
                      ),
                    for (final tip in plan.sportTips)
                      _BulletCard(
                        icon: Icons.directions_run,
                        title: tip.title,
                        items: tip.items,
                      ),
                    const SizedBox(height: 8),
                    const MedicalDisclaimerBanner(),
                  ],
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.plan});

  final MealPlan plan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = plan.date;
    final controlDate = plan.controlDate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.title, style: textTheme.titleMedium),
            if (date != null)
              Text(
                'Del ${DateFormat("d 'de' MMMM y", 'es').format(date)}',
                style: textTheme.bodySmall,
              ),
            if (plan.objective case final objective?) ...[
              const SizedBox(height: 8),
              Text('Objetivo: $objective'),
            ],
            if (plan.guidance case final guidance?) ...[
              const SizedBox(height: 4),
              Text(guidance),
            ],
            if (controlDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Próximo control: '
                    '${DateFormat("EEEE d 'de' MMMM", 'es').format(controlDate)}',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final PlannedMeal meal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hintStyle = textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final target = meal.target;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(mealTypeIcon(meal.type), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.time == null
                        ? meal.type.label
                        : '${meal.type.label} · ${meal.time}',
                    style: textTheme.titleMedium,
                  ),
                ),
                if (target != null)
                  Text(
                    '${formatDecimalEs(target.calories)} kcal',
                    style: textTheme.titleSmall,
                  ),
              ],
            ),
            if (target != null)
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  'P ${formatDecimalEs(target.protein)} g · '
                  'C ${formatDecimalEs(target.carbs)} g · '
                  'G ${formatDecimalEs(target.fat)} g',
                  style: hintStyle,
                ),
              ),
            const Divider(height: 16),
            for (final portion in meal.portions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${portion.group}: ${portion.amountText}',
                      style: textTheme.titleSmall,
                    ),
                    if (portion.equivalents case final equivalents?)
                      Text('1 porción = $equivalents', style: hintStyle),
                  ],
                ),
              ),
            for (final comment in meal.comments)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(comment, style: hintStyle)),
                  ],
                ),
              ),
            if (meal.examples.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text('Ejemplos (${meal.examples.length})'),
                children: [
                  for (final (i, example) in meal.examples.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 24, child: Text('${i + 1})')),
                          Expanded(child: Text(example)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
