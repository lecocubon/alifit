import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/glucose/glucose_entry.dart';
import '../../domain/glucose/glucose_providers.dart';
import '../common/medical_disclaimer_banner.dart';
import 'glucose_entry_form_screen.dart';

class GlucoseScreen extends ConsumerWidget {
  const GlucoseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(glucoseEntriesProvider);
    final rangeAsync = ref.watch(glucoseRangeProvider);
    final stats = ref.watch(glucoseStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Glicemias')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'glucose_add_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GlucoseEntryFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: entriesAsync.when(
          data: (entries) => rangeAsync.when(
            data: (range) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const MedicalDisclaimerBanner(),
                const SizedBox(height: 16),
                _StatsCard(stats: stats, range: range),
                if (entries.length >= 2) ...[
                  const SizedBox(height: 16),
                  _EvolutionChart(entries: entries, range: range),
                ],
                const SizedBox(height: 16),
                Text(
                  'Historial',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Todavía no hay registros de glicemia.'),
                    ),
                  )
                else
                  ...entries.map(
                    (entry) => _GlucoseEntryTile(entry: entry, range: range),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.range});

  final GlucoseStats stats;
  final GlucoseRange range;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (stats.count == 0)
              const Text('Sin registros todavía.')
            else ...[
              Text(
                'Promedio: ${stats.average.toStringAsFixed(0)} mg/dL '
                '(${stats.count} registros)',
              ),
              Text(
                'Mínimo: ${stats.min.toStringAsFixed(0)} · '
                'Máximo: ${stats.max.toStringAsFixed(0)} mg/dL',
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Rango configurado: ${range.low.toStringAsFixed(0)}–'
              '${range.high.toStringAsFixed(0)} mg/dL',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.entries, required this.range});

  final List<GlucoseEntry> entries;
  final GlucoseRange range;

  @override
  Widget build(BuildContext context) {
    // entries viene en orden descendente; el gráfico se lee de izquierda
    // (más antiguo) a derecha (más reciente).
    final chronological = entries.reversed.take(30).toList();
    final spots = [
      for (var i = 0; i < chronological.length; i++)
        FlSpot(i.toDouble(), chronological[i].value),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Evolución',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 180,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
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
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: range.low,
                          color: Colors.orange,
                          strokeWidth: 1,
                          dashArray: [6, 4],
                        ),
                        HorizontalLine(
                          y: range.high,
                          color: Colors.orange,
                          strokeWidth: 1,
                          dashArray: [6, 4],
                        ),
                      ],
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: false,
                        barWidth: 2,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlucoseEntryTile extends ConsumerWidget {
  const _GlucoseEntryTile({required this.entry, required this.range});

  final GlucoseEntry entry;
  final GlucoseRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outOfRange = !range.isWithinRange(entry.value);
    final dateLabel = DateFormat('d MMM, HH:mm', 'es').format(entry.measuredAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: outOfRange
              ? Colors.orange.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.secondaryContainer,
          child: Text(entry.value.toStringAsFixed(0)),
        ),
        title: Text('${entry.context.label} · $dateLabel'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.relatedMealLabel != null)
              Text(
                'Después de esta comida se registró una glicemia de '
                '${entry.value.toStringAsFixed(0)} mg/dL. Se observa una '
                'posible asociación; no es posible concluir causalidad '
                'con estos datos.',
              ),
            if (outOfRange)
              Text(
                'Fuera del rango configurado. Revisa el plan indicado por '
                'tu profesional de salud.',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            if (entry.notes != null) Text(entry.notes!),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () =>
              ref.read(glucoseRepositoryProvider).deleteEntry(entry.id),
        ),
        isThreeLine:
            entry.relatedMealLabel != null || outOfRange || entry.notes != null,
      ),
    );
  }
}
