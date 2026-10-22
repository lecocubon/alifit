import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/glucose/glucose_entry.dart';
import '../../domain/glucose/glucose_providers.dart';
import '../../domain/meal_plan/meal_plan_providers.dart';
import '../../domain/nutri_guide/nutri_guide_providers.dart';
import '../../domain/nutrition/nutrition_goals.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/nutrition/nutrition_values.dart';
import '../../domain/profile/profile_providers.dart';
import '../common/medical_disclaimer_banner.dart';
import '../glucose/glucose_screen.dart';
import '../inventory/inventory_screen.dart';
import '../meal_plan/meal_plan_screen.dart';
import '../menus/menus_screen.dart';
import '../nutrition/daily_log_sections.dart';
import '../nutri_guide/nutri_guide_screen.dart';
import '../nutrition/nutrition_trend_screen.dart';
import '../profile/profile_screen.dart';
import '../recipes/recipes_screen.dart';
import '../recipes/what_can_i_make_screen.dart';
import '../updates/update_widgets.dart';
import '../weight/body_metrics_screen.dart';
import '../weight/weight_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final profileAsync = ref.watch(activeProfileProvider);
    // Siempre hoy, aunque el Diario esté mostrando otro día.
    final mealsAsync = ref.watch(mealsForDateProvider(today));
    final glucoseAsync = ref.watch(glucoseEntriesProvider);
    final goalsAsync = ref.watch(nutritionGoalsProvider);
    // La guía es parte del perfil personal: sin guía importada no hay acceso.
    final hasNutriGuide = ref.watch(nutriGuideProvider).value != null;
    final hasMealPlan = ref.watch(mealPlanProvider).value != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AliFit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const UpdateBanner(),
            profileAsync.when(
              data: (profile) => Text(
                '¡Hola, ${profile?.name ?? ''}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            const StreakBadge(),
            const SizedBox(height: 8),
            mealsAsync.when(
              data: (meals) => _TodayCard(
                totals: meals.fold(
                  NutritionValues.zero,
                  (sum, meal) => sum + meal.totals,
                ),
                goals: goalsAsync.value ?? NutritionGoals.defaults,
              ),
              loading: () => const _TodayCardSkeleton(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            glucoseAsync.when(
              data: (entries) => entries.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _LatestGlucoseTile(entry: entries.first),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text(
              'Accesos rápidos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                _QuickAccessTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Recetas',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecipesScreen()),
                  ),
                ),
                _QuickAccessTile(
                  icon: Icons.kitchen_outlined,
                  label: 'Despensa',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  ),
                ),
                _QuickAccessTile(
                  icon: Icons.lightbulb_outline,
                  label: '¿Qué puedo\npreparar?',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WhatCanIMakeScreen(),
                    ),
                  ),
                ),
                _QuickAccessTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Menús y\ncompras',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MenusScreen()),
                  ),
                ),
                _QuickAccessTile(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Peso',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WeightScreen()),
                  ),
                ),
                _QuickAccessTile(
                  icon: Icons.straighten_outlined,
                  label: 'Composición\ncorporal',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BodyMetricsScreen(),
                    ),
                  ),
                ),
                _QuickAccessTile(
                  icon: Icons.show_chart,
                  label: 'Tendencia de\nalimentación',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NutritionTrendScreen(),
                    ),
                  ),
                ),
                if (hasMealPlan)
                  _QuickAccessTile(
                    icon: Icons.restaurant_menu_outlined,
                    label: 'Mi plan',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                    ),
                  ),
                if (hasNutriGuide)
                  _QuickAccessTile(
                    icon: Icons.fact_check_outlined,
                    label: 'Guía del\nnutri',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NutriGuideScreen(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Seguimiento de hoy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ActivitySection(date: today),
            const SizedBox(height: 12),
            WaterSection(date: today),
            const SizedBox(height: 12),
            NotesSection(date: today),
            const SizedBox(height: 24),
            const MedicalDisclaimerBanner(),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.totals, required this.goals});

  final NutritionValues totals;
  final NutritionGoals goals;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = goals.calories > 0
        ? (totals.calories / goals.calories).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoy has consumido',
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${totals.calories.round()}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / ${goals.calories.round()} kcal',
                style: TextStyle(
                  color: colorScheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.25),
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MacroChip(
                label: 'Carbs',
                value: totals.carbs,
                goal: goals.carbs,
                color: colorScheme.onPrimary,
              ),
              const SizedBox(width: 20),
              _MacroChip(
                label: 'Proteínas',
                value: totals.protein,
                goal: goals.protein,
                color: colorScheme.onPrimary,
              ),
              const SizedBox(width: 20),
              _MacroChip(
                label: 'Grasas',
                value: totals.fat,
                goal: goals.fat,
                color: colorScheme.onPrimary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Fibra: ${totals.fiber.round()} g · '
            'Azúcares: ${totals.sugar.round()} g · '
            'Sodio: ${totals.sodium.round()} mg',
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  final String label;
  final double value;
  final double goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${value.round()} / ${goal.round()} g',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 12),
        ),
      ],
    );
  }
}

class _TodayCardSkeleton extends StatelessWidget {
  const _TodayCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _LatestGlucoseTile extends StatelessWidget {
  const _LatestGlucoseTile({required this.entry});

  final GlucoseEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.bloodtype_outlined),
        title: Text('Última glicemia: ${entry.value.toStringAsFixed(0)} mg/dL'),
        subtitle: Text(entry.context.label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const GlucoseScreen())),
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
