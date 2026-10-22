import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_provider.dart';
import '../../core/time/calendar_days.dart';
import '../../data/repositories/drift_activity_repository.dart';
import '../../data/repositories/drift_daily_note_repository.dart';
import '../../data/repositories/drift_food_repository.dart';
import '../../data/repositories/drift_meal_repository.dart';
import '../../data/repositories/drift_nutrition_goals_repository.dart';
import '../../data/repositories/drift_water_repository.dart';
import 'activity_entry.dart';
import 'activity_repository.dart';
import 'daily_note_repository.dart';
import 'daily_nutrition_total.dart';
import 'food.dart';
import 'food_repository.dart';
import 'meal.dart';
import 'meal_repository.dart';
import 'nutrition_goals.dart';
import 'nutrition_goals_repository.dart';
import 'water_repository.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return DriftFoodRepository(ref.watch(databaseProvider));
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return DriftMealRepository(ref.watch(databaseProvider));
});

final nutritionGoalsRepositoryProvider = Provider<NutritionGoalsRepository>((
  ref,
) {
  return DriftNutritionGoalsRepository(ref.watch(databaseProvider));
});

final nutritionGoalsProvider = StreamProvider<NutritionGoals>((ref) {
  return ref.watch(nutritionGoalsRepositoryProvider).watchGoals();
});

final recentFoodsProvider = StreamProvider<List<Food>>((ref) {
  return ref.watch(foodRepositoryProvider).watchRecents();
});

final favoriteFoodsProvider = StreamProvider<List<Food>>((ref) {
  return ref.watch(foodRepositoryProvider).watchFavorites();
});

final foodAliasesProvider =
    StreamProvider.family<List<(int id, String alias)>, int>((ref, foodId) {
      return ref.watch(foodRepositoryProvider).watchAliases(foodId);
    });

class FoodSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final foodSearchQueryProvider =
    NotifierProvider<FoodSearchQueryNotifier, String>(
      FoodSearchQueryNotifier.new,
    );

final foodSearchResultsProvider = FutureProvider<List<Food>>((ref) async {
  final query = ref.watch(foodSearchQueryProvider);
  return ref.read(foodRepositoryProvider).search(query);
});

/// Reloj de la app; se reemplaza en los tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// La fecha de hoy, sin hora. La app la vuelve a calcular al volver a
/// primer plano ([TodayNotifier.refresh]): si quedó abierta de un día para
/// otro, Inicio y el Diario no siguen mostrando el día anterior.
class TodayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _today();

  DateTime _today() {
    final now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }

  void refresh() {
    final today = _today();
    if (today != state) {
      state = today;
    }
  }
}

final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

/// Fecha seleccionada para el Diario (por defecto, hoy).
class SelectedDiaryDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    // Si el Diario estaba en hoy y cambia el día, pasa al nuevo hoy; si se
    // eligió otra fecha, se respeta.
    ref.listen(todayProvider, (previous, next) {
      if (state == previous) {
        state = next;
      }
    });
    return ref.read(todayProvider);
  }

  void setDate(DateTime date) =>
      state = DateTime(date.year, date.month, date.day);
}

final selectedDiaryDateProvider =
    NotifierProvider<SelectedDiaryDateNotifier, DateTime>(
      SelectedDiaryDateNotifier.new,
    );

final mealsForSelectedDateProvider = StreamProvider<List<Meal>>((ref) {
  final date = ref.watch(selectedDiaryDateProvider);
  return ref.watch(mealRepositoryProvider).watchMealsForDate(date);
});

/// Comidas de un día cualquiera (Inicio usa hoy aunque el Diario esté en
/// otra fecha).
final mealsForDateProvider = StreamProvider.family<List<Meal>, DateTime>((
  ref,
  date,
) {
  final day = DateTime(date.year, date.month, date.day);
  return ref.watch(mealRepositoryProvider).watchMealsForDate(day);
});

/// Totales diarios de los últimos 14 días (incluyendo hoy), para el
/// gráfico de tendencia de alimentación.
final nutritionTrendProvider = FutureProvider<List<DailyNutritionTotal>>((ref) {
  final today = ref.watch(todayProvider);
  // Se recalcula cuando cambian las comidas de hoy o del día seleccionado
  // en el Diario.
  ref.watch(mealsForDateProvider(today));
  ref.watch(mealsForSelectedDateProvider);
  return ref
      .watch(mealRepositoryProvider)
      .getDailyTotals(startDate: addDays(today, -13), endDate: today);
});

/// Días consecutivos con al menos una comida registrada (sin contar en
/// contra el día de hoy si todavía no se ha registrado nada).
final loggingStreakProvider = FutureProvider<int>((ref) async {
  final today = ref.watch(todayProvider);
  ref.watch(mealsForDateProvider(today));
  ref.watch(mealsForSelectedDateProvider);
  final totals = await ref
      .watch(mealRepositoryProvider)
      .getDailyTotals(startDate: addDays(today, -60), endDate: today);

  var index = totals.length - 1;
  if (index >= 0 && totals[index].totals.calories <= 0) {
    index--;
  }
  var streak = 0;
  for (; index >= 0; index--) {
    if (totals[index].totals.calories > 0) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return DriftActivityRepository(ref.watch(databaseProvider));
});

/// Actividades registradas en [date]. Se usa `.family` (en vez de atarse a
/// [selectedDiaryDateProvider]) para que tanto el Diario como Inicio puedan
/// mostrar la fecha que corresponda a cada uno.
final activityEntriesForDateProvider =
    StreamProvider.family<List<ActivityEntry>, DateTime>((ref, date) {
      return ref.watch(activityRepositoryProvider).watchForDate(date);
    });

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return DriftWaterRepository(ref.watch(databaseProvider));
});

final waterForDateProvider = StreamProvider.family<double, DateTime>((
  ref,
  date,
) {
  return ref.watch(waterRepositoryProvider).watchTotalForDate(date);
});

final dailyNoteRepositoryProvider = Provider<DailyNoteRepository>((ref) {
  return DriftDailyNoteRepository(ref.watch(databaseProvider));
});

final dailyNoteForDateProvider = StreamProvider.family<String?, DateTime>((
  ref,
  date,
) {
  return ref.watch(dailyNoteRepositoryProvider).watchForDate(date);
});
