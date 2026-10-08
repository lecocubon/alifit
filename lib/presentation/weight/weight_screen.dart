import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/weight/weight_entry.dart';
import '../../domain/weight/weight_providers.dart';
import 'weight_entry_form_screen.dart';

class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(weightEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Peso corporal')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'weight_add_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WeightEntryFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: entriesAsync.when(
          data: (entries) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(entries: entries),
              if (entries.length >= 2) ...[
                const SizedBox(height: 16),
                _WeightChart(entries: entries),
              ],
              const SizedBox(height: 16),
              Text('Historial', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Todavía no hay registros de peso.'),
                  ),
                )
              else
                ...entries.map(
                  (entry) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('${entry.weightKg.toStringAsFixed(1)} kg'),
                      subtitle: Text(
                        DateFormat(
                              'd MMM yyyy',
                              'es',
                            ).format(entry.measuredAt) +
                            (entry.notes != null ? ' · ${entry.notes}' : ''),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => ref
                            .read(weightRepositoryProvider)
                            .deleteEntry(entry.id),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.entries});

  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    String trendText = 'Sin registros todavía.';
    if (entries.length >= 2) {
      // entries viene descendente: [0] es el más reciente.
      final diff = entries.first.weightKg - entries.last.weightKg;
      final sign = diff > 0 ? '+' : '';
      trendText =
          'Actual: ${entries.first.weightKg.toStringAsFixed(1)} kg · '
          'Cambio desde el primer registro: $sign${diff.toStringAsFixed(1)} kg';
    } else if (entries.length == 1) {
      trendText = 'Actual: ${entries.first.weightKg.toStringAsFixed(1)} kg';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(trendText),
          ],
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.entries});

  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    final chronological = entries.reversed.take(60).toList();
    final spots = [
      for (var i = 0; i < chronological.length; i++)
        FlSpot(i.toDouble(), chronological[i].weightKg),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
