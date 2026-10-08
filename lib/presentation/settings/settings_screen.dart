import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/import/sr_legacy_import_provider.dart';
import '../../data/import/usda_import_provider.dart';
import '../../domain/glucose/glucose_providers.dart';
import '../../domain/settings/settings_providers.dart';
import '../../core/text/decimal_format.dart';
import '../updates/update_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Apariencia', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            themeModeAsync.when(
              data: (mode) => SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Sistema'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Claro'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Oscuro'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selection) {
                  ref
                      .read(settingsRepositoryProvider)
                      .setThemeMode(selection.first);
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('No se pudo cargar el tema.'),
            ),
            const SizedBox(height: 24),
            Text(
              'Rangos de glicemia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Se usan solo para avisos de referencia, no como indicación '
              'médica. Ajústalos según lo que te indique tu profesional '
              'de salud.',
            ),
            const SizedBox(height: 8),
            const _GlucoseRangeSection(),
            const SizedBox(height: 24),
            Text(
              'Catálogo nutricional',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Un único catálogo, lo más amplio posible: se importa '
              'completo la primera vez que abres la app.',
            ),
            const SizedBox(height: 8),
            const _CatalogInfoSection(),
            const SizedBox(height: 24),
            Text(
              'Actualizaciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Las versiones nuevas se publican en GitHub. La app avisa en '
              'Inicio cuando hay una; también puedes revisar aquí.',
            ),
            const SizedBox(height: 8),
            const UpdatesSection(),
          ],
        ),
      ),
    );
  }
}

class _CatalogInfoSection extends ConsumerWidget {
  const _CatalogInfoSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usdaAsync = ref.watch(usdaDatasetInfoProvider);
    final srLegacyAsync = ref.watch(srLegacyDatasetInfoProvider);

    return usdaAsync.when(
      data: (usda) => srLegacyAsync.when(
        data: (srLegacy) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${usda.foodCount + srLegacy.foodCount} alimentos disponibles '
              'en total.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('${usda.dataset} · ${usda.datasetDate}'),
            Text('${usda.foodCount} alimentos base.'),
            Text(
              usda.attribution,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text('${srLegacy.dataset} · ${srLegacy.datasetDate}'),
            Text('${srLegacy.foodCount} alimentos adicionales.'),
            const Text(
              'Nombres traducidos automáticamente por diccionario (no '
              'revisados a mano como el catálogo base): pueden verse '
              'menos prolijos o con alguna palabra en inglés.',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              srLegacy.attribution,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('No se pudo cargar.'),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text('No se pudo cargar.'),
    );
  }
}

class _GlucoseRangeSection extends ConsumerStatefulWidget {
  const _GlucoseRangeSection();

  @override
  ConsumerState<_GlucoseRangeSection> createState() =>
      _GlucoseRangeSectionState();
}

class _GlucoseRangeSectionState extends ConsumerState<_GlucoseRangeSection> {
  final _lowController = TextEditingController();
  final _highController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _lowController.dispose();
    _highController.dispose();
    super.dispose();
  }

  void _save() {
    final low = parseDecimalEs(_lowController.text);
    final high = parseDecimalEs(_highController.text);
    if (low == null || high == null || low >= high) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un rango válido.')));
      return;
    }
    ref.read(glucoseRepositoryProvider).setRange(low: low, high: high);
  }

  @override
  Widget build(BuildContext context) {
    final rangeAsync = ref.watch(glucoseRangeProvider);

    return rangeAsync.when(
      data: (range) {
        if (!_initialized) {
          _lowController.text = range.low.toStringAsFixed(0);
          _highController.text = range.high.toStringAsFixed(0);
          _initialized = true;
        }
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _lowController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Mínimo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _highController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Máximo'),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text('No se pudo cargar el rango.'),
    );
  }
}
