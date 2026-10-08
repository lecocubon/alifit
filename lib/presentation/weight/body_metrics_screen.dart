import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/profile/biological_sex.dart';
import '../../domain/profile/body_metrics.dart';
import '../../domain/profile/profile_providers.dart';
import '../../domain/weight/weight_providers.dart';
import '../../core/text/decimal_format.dart';

class BodyMetricsScreen extends ConsumerWidget {
  const BodyMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);
    final weightsAsync = ref.watch(weightEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Composición corporal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Estos valores son solo una referencia informativa. No son '
              'un diagnóstico ni reemplazan una evaluación profesional, y '
              'un mismo número puede significar cosas distintas según tu '
              'composición corporal real.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            profileAsync.when(
              data: (profile) => weightsAsync.when(
                data: (weights) {
                  final heightCm = profile?.heightCm;
                  final latestWeight = weights.isEmpty
                      ? null
                      : weights.first.weightKg;
                  final bmi = BodyMetrics.bmi(
                    heightCm: heightCm,
                    weightKg: latestWeight,
                  );
                  return _BmiCard(
                    bmi: bmi,
                    hasHeight: heightCm != null,
                    hasWeight: latestWeight != null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            profileAsync.when(
              data: (profile) => _BodyFatCalculator(
                profileHeightCm: profile?.heightCm,
                profileSex: profile?.biologicalSex,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({
    required this.bmi,
    required this.hasHeight,
    required this.hasWeight,
  });

  final double? bmi;
  final bool hasHeight;
  final bool hasWeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IMC', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (bmi == null)
              Text(
                !hasHeight
                    ? 'Agrega tu altura en Configuración > Perfil para '
                          'calcular tu IMC.'
                    : !hasWeight
                    ? 'Registra al menos un peso en Peso corporal para '
                          'calcular tu IMC.'
                    : 'No se pudo calcular.',
              )
            else ...[
              Text(
                '${bmi!.toStringAsFixed(1)} · ${BodyMetrics.bmiCategory(bmi!)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'El IMC no distingue entre masa muscular y grasa. Dos '
                'personas con el mismo IMC pueden tener composiciones '
                'corporales muy distintas; complementa este número con el '
                'cálculo de % de grasa corporal más abajo si quieres una '
                'referencia más completa.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BodyFatCalculator extends StatefulWidget {
  const _BodyFatCalculator({this.profileHeightCm, this.profileSex});

  final double? profileHeightCm;
  final BiologicalSex? profileSex;

  @override
  State<_BodyFatCalculator> createState() => _BodyFatCalculatorState();
}

class _BodyFatCalculatorState extends State<_BodyFatCalculator> {
  late final TextEditingController _heightController;
  final _neckController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  BiologicalSex? _sex;
  double? _result;
  bool _showHelp = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.profileHeightCm?.toStringAsFixed(0) ?? '',
    );
    _sex = widget.profileSex;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _neckController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  void _calculate() {
    final sex = _sex;
    final height = parseDecimalEs(_heightController.text);
    final neck = parseDecimalEs(_neckController.text);
    final waist = parseDecimalEs(_waistController.text);
    final hip = parseDecimalEs(_hipController.text);

    if (sex == null || height == null || neck == null || waist == null) {
      setState(() => _result = null);
      return;
    }

    setState(() {
      _result = BodyMetrics.bodyFatPercentNavy(
        sex: sex,
        heightCm: height,
        neckCm: neck,
        waistCm: waist,
        hipCm: hip,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final needsHip = _sex == BiologicalSex.female;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '% de grasa corporal (método de circunferencias)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: Icon(_showHelp ? Icons.help : Icons.help_outline),
                  tooltip: 'Cómo medir',
                  onPressed: () => setState(() => _showHelp = !_showHelp),
                ),
              ],
            ),
            if (_showHelp)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Cuello: mide justo debajo de la laringe (nuez).\n'
                  'Cintura: mide a la altura del ombligo, sin apretar.\n'
                  'Cadera: mide en el punto más ancho de los glúteos.\n'
                  'Usa una huincha flexible, de pie, sin ropa gruesa.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            Wrap(
              spacing: 8,
              children: BiologicalSex.values.map((sex) {
                return ChoiceChip(
                  label: Text(sex.label),
                  selected: _sex == sex,
                  onSelected: (_) => setState(() => _sex = sex),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Altura (cm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _neckController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Cuello (cm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _waistController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Cintura (cm)'),
            ),
            if (needsHip) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _hipController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Cadera (cm)'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _calculate, child: const Text('Calcular')),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(
                '${_result!.toStringAsFixed(1)}% · '
                '${BodyMetrics.bodyFatCategory(_sex!, _result!)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
