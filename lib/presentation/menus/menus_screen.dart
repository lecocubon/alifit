import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/menus/menu_plan.dart';
import '../../domain/menus/menu_providers.dart';
import 'menu_plan_detail_screen.dart';

class MenusScreen extends ConsumerWidget {
  const MenusScreen({super.key});

  DateTime _nextMonday() {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final daysUntilMonday = (DateTime.monday - todayDateOnly.weekday + 7) % 7;
    return todayDateOnly.add(
      Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday),
    );
  }

  Future<void> _createPlan(BuildContext context, WidgetRef ref) async {
    final labelController = TextEditingController();
    var startDate = _nextMonday();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo plan semanal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: 'Nombre (opcional)',
                  hintText:
                      'Ej: Semana del ${DateFormat('d MMM', 'es').format(startDate)}',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de inicio'),
                subtitle: Text(
                  DateFormat('EEEE d MMMM y', 'es').format(startDate),
                ),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                  }
                },
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
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (created != true) {
      return;
    }
    final label = labelController.text.trim().isEmpty
        ? 'Semana del ${DateFormat('d MMM', 'es').format(startDate)}'
        : labelController.text.trim();
    final id = await ref
        .read(menuRepositoryProvider)
        .createPlan(label: label, startDate: startDate);
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MenuPlanDetailScreen(menuPlanId: id)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(menuPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Menús')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'menus_add_fab',
        onPressed: () => _createPlan(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aún no tienes planes de menú. Toca + para crear tu '
                    'primer plan semanal.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              itemBuilder: (context, index) => _PlanTile(plan: plans[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({required this.plan});

  final MenuPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMM', 'es');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(plan.label),
        subtitle: Text(
          '${dateFormat.format(plan.startDate)} – ${dateFormat.format(plan.endDate)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => ref.read(menuRepositoryProvider).deletePlan(plan.id),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MenuPlanDetailScreen(menuPlanId: plan.id),
          ),
        ),
      ),
    );
  }
}
