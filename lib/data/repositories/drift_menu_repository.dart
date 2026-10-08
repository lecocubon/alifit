import 'package:drift/drift.dart';

import '../../domain/menus/menu_meal.dart';
import '../../domain/menus/menu_plan.dart';
import '../../domain/menus/menu_repository.dart';
import '../../domain/nutrition/meal_type.dart';
import '../../domain/recipes/recipe_repository.dart';
import '../database/app_database.dart';
import '../database/watch_tables.dart';

class DriftMenuRepository implements MenuRepository {
  DriftMenuRepository(this._db, this._recipeRepository);

  final AppDatabase _db;
  final RecipeRepository _recipeRepository;

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Stream<List<MenuPlan>> watchPlans() {
    final query = _db.select(_db.menuPlans)
      ..orderBy([(t) => OrderingTerm.desc(t.startDate)]);
    return query.watch().map((rows) => rows.map(_planToDomain).toList());
  }

  @override
  Future<MenuPlan?> getPlan(int id) async {
    final row = await (_db.select(
      _db.menuPlans,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _planToDomain(row);
  }

  @override
  Stream<List<MenuMeal>> watchMeals(int menuPlanId) {
    final query = _db.select(_db.menuMeals)
      ..where((t) => t.menuPlanId.equals(menuPlanId))
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);
    // La receta de cada comida del menú se lee aparte: hay que observar
    // también sus tablas para que editar una receta se vea en el menú.
    return _db
        .watchTables({
          _db.menuMeals,
          _db.recipes,
          _db.recipeIngredients,
          _db.foods,
        })
        .asyncMap((_) async {
          final rows = await query.get();
          return Future.wait(rows.map(_mealToDomain));
        });
  }

  @override
  Future<int> createPlan({required String label, required DateTime startDate}) {
    return _db
        .into(_db.menuPlans)
        .insert(
          MenuPlansCompanion.insert(
            label: Value(label),
            startDate: _dateOnly(startDate),
          ),
        );
  }

  @override
  Future<void> deletePlan(int id) async {
    await (_db.delete(
      _db.menuMeals,
    )..where((t) => t.menuPlanId.equals(id))).go();
    await (_db.delete(
      _db.shoppingItems,
    )..where((t) => t.menuPlanId.equals(id))).go();
    await (_db.delete(_db.menuPlans)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> setMeal({
    required int menuPlanId,
    required DateTime date,
    required MealType mealType,
    int? recipeId,
    String? freeformLabel,
    double servings = 1,
    String? notes,
  }) async {
    final normalizedDate = _dateOnly(date);
    await _deleteSlot(menuPlanId, normalizedDate, mealType);
    await _db
        .into(_db.menuMeals)
        .insert(
          MenuMealsCompanion.insert(
            menuPlanId: menuPlanId,
            date: normalizedDate,
            mealType: mealType.name,
            recipeId: Value(recipeId),
            freeformLabel: Value(freeformLabel),
            servings: Value(servings),
            notes: Value(notes),
          ),
        );
  }

  @override
  Future<void> clearMeal({
    required int menuPlanId,
    required DateTime date,
    required MealType mealType,
  }) {
    return _deleteSlot(menuPlanId, _dateOnly(date), mealType);
  }

  Future<void> _deleteSlot(
    int menuPlanId,
    DateTime normalizedDate,
    MealType mealType,
  ) {
    return (_db.delete(_db.menuMeals)..where(
          (t) =>
              t.menuPlanId.equals(menuPlanId) &
              t.date.equals(normalizedDate) &
              t.mealType.equals(mealType.name),
        ))
        .go();
  }

  MenuPlan _planToDomain(MenuPlanRow row) {
    return MenuPlan(
      id: row.id,
      label: row.label,
      startDate: row.startDate,
      createdAt: row.createdAt,
    );
  }

  Future<MenuMeal> _mealToDomain(MenuMealRow row) async {
    final recipeId = row.recipeId;
    final recipe = recipeId == null
        ? null
        : await _recipeRepository.getById(recipeId);
    return MenuMeal(
      id: row.id,
      menuPlanId: row.menuPlanId,
      date: row.date,
      mealType: MealType.fromStorage(row.mealType),
      recipe: recipe,
      freeformLabel: row.freeformLabel,
      servings: row.servings,
      notes: row.notes,
    );
  }
}
