import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_provider.dart';
import '../../data/repositories/drift_meal_plan_repository.dart';
import 'meal_plan.dart';
import 'meal_plan_repository.dart';

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return DriftMealPlanRepository(ref.watch(databaseProvider));
});

/// El plan de comidas importado en "Mi perfil", o null si no hay ninguno.
final mealPlanProvider = StreamProvider<MealPlan?>((ref) {
  return ref.watch(mealPlanRepositoryProvider).watchPlan();
});
