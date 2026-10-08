import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/text/decimal_format.dart';
import '../../domain/nutri_guide/nutri_guide_providers.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/personal_plan/personal_plan.dart';
import '../nutri_guide/nutri_guide_screen.dart';

/// "Mi plan del nutri" en Perfil: importa el archivo personal con las metas
/// y la guía de porciones, que no vienen dentro de la app.
class PersonalPlanSection extends ConsumerWidget {
  const PersonalPlanSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = ref.watch(nutriGuideProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi plan del nutri',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'Si tienes un archivo de perfil de AliFit (.json) con el plan de '
          'tu nutricionista, impórtalo aquí: carga tus metas y su guía de '
          'porciones. Queda guardado solo en este teléfono.',
        ),
        if (guide != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fact_check_outlined),
            title: Text(guide.title),
            subtitle: Text('Guía de porciones · ${guide.foodCount} alimentos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const NutriGuideScreen())),
          )
        else
          const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.file_open_outlined),
              label: Text(guide == null ? 'Importar mi perfil' : 'Reemplazar'),
              onPressed: () => _import(context, ref),
            ),
            if (guide != null)
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar guía'),
                onPressed: () => _removeGuide(context, ref),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await openFile();
    if (file == null) {
      return;
    }

    final PersonalPlan plan;
    try {
      plan = PersonalPlan.parse(await file.readAsString());
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan.label ?? 'Importar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.goals case final goals?)
              Text(
                'Metas diarias: ${formatDecimalEs(goals.calories)} kcal · '
                'P ${formatDecimalEs(goals.protein)} g · '
                'C ${formatDecimalEs(goals.carbs)} g · '
                'G ${formatDecimalEs(goals.fat)} g. Reemplazan tus metas '
                'actuales.',
              ),
            if (plan.goals != null && plan.guide != null)
              const SizedBox(height: 8),
            if (plan.guide case final guide?)
              Text(
                'Guía del nutri: ${guide.groups.length} grupos, '
                '${guide.foodCount} alimentos.',
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
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await plan.apply(
      goalsRepository: ref.read(nutritionGoalsRepositoryProvider),
      guideRepository: ref.read(nutriGuideRepositoryProvider),
    );
    messenger.showSnackBar(const SnackBar(content: Text('Perfil importado.')));
  }

  Future<void> _removeGuide(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quitar la guía del nutri?'),
        content: const Text(
          'Se borra de este teléfono. Tus metas y tus registros no cambian. '
          'Puedes volver a importarla con tu archivo de perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(nutriGuideRepositoryProvider).clearGuide();
    }
  }
}
