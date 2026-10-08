import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/nutrition/nutrition_goals.dart';
import '../../domain/nutrition/nutrition_providers.dart';
import '../../domain/profile/profile_providers.dart';
import '../nutrition/nutrition_goals_calculator_screen.dart';
import 'personal_plan_section.dart';
import 'profile_setup_screen.dart';
import '../../core/text/decimal_format.dart';

/// Pantalla de perfil: datos personales y metas nutricionales, accesible
/// desde el ícono de perfil en Inicio.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            profileAsync.when(
              data: (profile) => profile == null
                  ? const SizedBox.shrink()
                  : ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(profile.name),
                      subtitle: Text(profile.conditionsSummary),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProfileSetupScreen(existingProfile: profile),
                        ),
                      ),
                    ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('No se pudo cargar el perfil.'),
            ),
            const SizedBox(height: 24),
            Text(
              'Metas nutricionales diarias',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Se usan para mostrar tu avance del día en Inicio y el '
              'Diario. Ajústalas según lo que te indique tu profesional '
              'de salud, o déjalas con los valores por defecto.',
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular por mí'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NutritionGoalsCalculatorScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _NutritionGoalsSection(),
            const SizedBox(height: 24),
            const PersonalPlanSection(),
          ],
        ),
      ),
    );
  }
}

class _NutritionGoalsSection extends ConsumerStatefulWidget {
  const _NutritionGoalsSection();

  @override
  ConsumerState<_NutritionGoalsSection> createState() =>
      _NutritionGoalsSectionState();
}

class _NutritionGoalsSectionState
    extends ConsumerState<_NutritionGoalsSection> {
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _save() {
    final calories = parseDecimalEs(_caloriesController.text);
    final carbs = parseDecimalEs(_carbsController.text);
    final protein = parseDecimalEs(_proteinController.text);
    final fat = parseDecimalEs(_fatController.text);
    if (calories == null ||
        carbs == null ||
        protein == null ||
        fat == null ||
        calories <= 0 ||
        carbs < 0 ||
        protein < 0 ||
        fat < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa valores válidos.')));
      return;
    }
    ref
        .read(nutritionGoalsRepositoryProvider)
        .setGoals(
          NutritionGoals(
            calories: calories,
            carbs: carbs,
            protein: protein,
            fat: fat,
          ),
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Metas guardadas.')));
  }

  void _fill(NutritionGoals goals) {
    _caloriesController.text = goals.calories.toStringAsFixed(0);
    _carbsController.text = goals.carbs.toStringAsFixed(0);
    _proteinController.text = goals.protein.toStringAsFixed(0);
    _fatController.text = goals.fat.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(nutritionGoalsProvider);
    // Las metas también cambian al importar un perfil: los campos se
    // actualizan para no seguir mostrando las anteriores.
    ref.listen(nutritionGoalsProvider, (_, next) => next.whenData(_fill));

    return goalsAsync.when(
      data: (goals) {
        if (!_initialized) {
          _fill(goals);
          _initialized = true;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calorías (kcal)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Carbohidratos (g)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Proteínas (g)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Grasas (g)'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(icon: const Icon(Icons.check), onPressed: _save),
              ],
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text('No se pudieron cargar las metas.'),
    );
  }
}
