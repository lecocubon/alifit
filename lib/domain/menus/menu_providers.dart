import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_provider.dart';
import '../../data/repositories/drift_menu_repository.dart';
import '../recipes/recipe_providers.dart';
import 'menu_meal.dart';
import 'menu_plan.dart';
import 'menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return DriftMenuRepository(
    ref.watch(databaseProvider),
    ref.watch(recipeRepositoryProvider),
  );
});

final menuPlansProvider = StreamProvider<List<MenuPlan>>((ref) {
  return ref.watch(menuRepositoryProvider).watchPlans();
});

final menuPlanProvider = FutureProvider.family<MenuPlan?, int>((ref, id) {
  return ref.watch(menuRepositoryProvider).getPlan(id);
});

final menuMealsProvider = StreamProvider.family<List<MenuMeal>, int>((
  ref,
  menuPlanId,
) {
  return ref.watch(menuRepositoryProvider).watchMeals(menuPlanId);
});
