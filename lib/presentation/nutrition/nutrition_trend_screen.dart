import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/nutrition/daily_nutrition_total.dart';
import '../../domain/nutrition/nutrition_goals.dart';
import '../../domain/nutrition/nutrition_providers.dart';

class NutritionTrendScreen extends ConsumerWidget {
  const NutritionTrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(nutritionTrendProvider);
    final goalsAsync = ref.watch(nutritionGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tendencia de alimentación')),
      body: SafeArea(
        child: trendAsync.when(
          data: (days) => goalsAsync.when(
            data: (goals) => _TrendBody(days: days, goals: goals),
            loading: () =>
                _TrendBody(days: days, goals: NutritionGoals.defaults),
            error: (_, _) =>
                _TrendBody(days: days, goals: NutritionGoals.defaults),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _TrendBody extends StatelessWidget {
  const _TrendBody({required this.days, required this.goals});

  final List<DailyNutritionTotal> days;
  final NutritionGoals goals;

  @override
  Widget build(BuildContext context) {
    final daysWithData = days.where((d) => d.totals.calories > 0).toList();
    final average = daysWithData.isEmpty
        ? 0.0
        : daysWithData.fold<double>(0, (sum, d) => sum + d.totals.calories) /
              daysWithData.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Últimos 14 días',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  daysWithData.isEmpty
                      ? 'Todavía no hay suficientes registros.'
                      : 'Promedio: ${average.round()} kcal/día · '
                            'Meta: ${goals.calories.round()} kcal/día',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Calorías por día',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= days.length) {
                                  return const SizedBox.shrink();
                                }
                                // Solo se etiquetan algunos días para que
                                // no se amontonen las etiquetas.
                                if (index % 2 != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat(
                                      'd/M',
                                      'es',
                                    ).format(days[index].date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: goals.calories,
                              color: Colors.orange,
                              strokeWidth: 1,
                              dashArray: [6, 4],
                            ),
                          ],
                        ),
                        barGroups: [
                          for (var i = 0; i < days.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: days[i].totals.calories,
                                  width: 10,
                                  borderRadius: BorderRadius.circular(2),
                                  color:
                                      days[i].totals.calories > goals.calories
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
