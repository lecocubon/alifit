import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/nutrition/activity_entry.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../core/text/decimal_format.dart';

/// Insignia de racha de días registrados seguidos. No muestra nada si la
/// racha es 0.
class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(loggingStreakProvider).value ?? 0;
    if (days <= 0) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            days == 1
                ? '1 día seguido registrando'
                : '$days días seguidos registrando',
            style: TextStyle(color: colorScheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

/// Sección de actividad física de [date]: lista de entradas + botón para
/// agregar (con presets comunes o una actividad personalizada). Se usa
/// tanto en Inicio (con la fecha de hoy) como en el Diario.
class ActivitySection extends ConsumerWidget {
  const ActivitySection({super.key, required this.date});

  final DateTime date;

  Future<void> _addActivity(BuildContext context, WidgetRef ref) async {
    final preset = await showModalBottomSheet<ActivityPreset>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final preset in ActivityPreset.all)
              ListTile(
                title: Text(preset.name),
                subtitle: Text('${preset.kcalPer30Min.round()} kcal / 30 min'),
                onTap: () => Navigator.of(context).pop(preset),
              ),
            ListTile(
              title: const Text('Otra actividad'),
              leading: const Icon(Icons.edit_outlined),
              onTap: () => Navigator.of(
                context,
              ).pop(const ActivityPreset(name: '', kcalPer30Min: 0)),
            ),
          ],
        ),
      ),
    );
    if (preset == null || !context.mounted) {
      return;
    }
    if (preset.name.isEmpty) {
      await _addCustomActivity(context, ref);
      return;
    }
    final minutesText = await _askForMinutes(context, preset.name);
    if (minutesText == null) {
      return;
    }
    final minutes = int.tryParse(minutesText) ?? 30;
    final kcal = preset.kcalPer30Min * minutes / 30;
    await ref
        .read(activityRepositoryProvider)
        .addEntry(date: date, name: preset.name, minutes: minutes, kcal: kcal);
  }

  Future<String?> _askForMinutes(BuildContext context, String name) {
    final controller = TextEditingController(text: '30');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Minutos'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCustomActivity(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final minutesController = TextEditingController(text: '30');
    final kcalController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otra actividad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Actividad'),
            ),
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutos'),
            ),
            TextField(
              controller: kcalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calorías quemadas'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (confirmed != true || nameController.text.trim().isEmpty) {
      return;
    }
    await ref
        .read(activityRepositoryProvider)
        .addEntry(
          date: date,
          name: nameController.text.trim(),
          minutes: int.tryParse(minutesController.text.trim()) ?? 0,
          kcal: parseDecimalEs(kcalController.text) ?? 0,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(activityEntriesForDateProvider(date));
    final entries = entriesAsync.value ?? const [];
    final totalKcal = entries.fold<double>(0, (sum, e) => sum + e.kcal);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Actividad física',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${totalKcal.round()} kcal'),
              ],
            ),
            if (entries.isNotEmpty) ...[
              const Divider(height: 12),
              ...entries.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(entry.name),
                  subtitle: Text(
                    '${entry.minutes} min · ${entry.kcal.round()} kcal',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => ref
                        .read(activityRepositoryProvider)
                        .removeEntry(entry.id),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
                onPressed: () => _addActivity(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de agua de [date]: total del día contra una meta fija, con
/// botones para agregar/quitar un vaso (250 ml).
class WaterSection extends ConsumerWidget {
  const WaterSection({super.key, required this.date});

  final DateTime date;

  static const _goalMl = 2000.0;
  static const _stepMl = 250.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(waterForDateProvider(date));
    final total = totalAsync.value ?? 0;
    final ratio = (total / _goalMl).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Agua',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${total.round()} / ${_goalMl.round()} ml'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: ratio, minHeight: 6),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () =>
                      ref.read(waterRepositoryProvider).removeLastForDate(date),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => ref
                      .read(waterRepositoryProvider)
                      .addWater(date: date, milliliters: _stepMl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nota libre de [date] (una por día).
class NotesSection extends ConsumerStatefulWidget {
  const NotesSection({super.key, required this.date});

  final DateTime date;

  @override
  ConsumerState<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends ConsumerState<NotesSection> {
  final _controller = TextEditingController();
  DateTime? _loadedForDate;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    ref
        .read(dailyNoteRepositoryProvider)
        .setNote(date: widget.date, text: _controller.text);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(dailyNoteForDateProvider(widget.date));
    if (noteAsync.hasValue && _loadedForDate != widget.date) {
      _controller.text = noteAsync.value ?? '';
      _loadedForDate = widget.date;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: ayuno, cómo te sentiste, etc.',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _save,
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
    );
  }
}
