import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/daily_log_table.dart';
import 'tables/foods_table.dart';
import 'tables/glucose_table.dart';
import 'tables/inventory_table.dart';
import 'tables/meals_table.dart';
import 'tables/menus_table.dart';
import 'tables/recipes_table.dart';
import 'tables/shopping_table.dart';
import 'tables/weight_table.dart';

part 'app_database.g.dart';

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Lista de [ChronicCondition] separadas por coma (ej. "diabetes,hypertension").
  TextColumn get conditions => text().withDefault(const Constant(''))();
  TextColumn get diabetesType => text().nullable()();
  TextColumn get healthConditionNotes => text().nullable()();
  RealColumn get heightCm => real().nullable()();

  /// 'male' o 'female'; solo se usa para la fórmula de % de grasa corporal.
  TextColumn get biologicalSex => text().nullable()();
  IntColumn get age => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    UserProfiles,
    AppSettings,
    Foods,
    FoodAliases,
    FoodServings,
    Meals,
    MealItems,
    GlucoseEntries,
    WeightEntries,
    Recipes,
    RecipeIngredients,
    InventoryItems,
    MenuPlans,
    MenuMeals,
    ShoppingItems,
    ActivityEntries,
    WaterLogs,
    DailyNotes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'alifit'));

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(foods);
        await m.createTable(foodAliases);
        await m.createTable(foodServings);
        await m.createTable(meals);
        await m.createTable(mealItems);
      }
      if (from < 3) {
        await m.createTable(glucoseEntries);
      }
      if (from < 4) {
        await m.createTable(weightEntries);
      }
      if (from < 5) {
        await m.addColumn(userProfiles, userProfiles.conditions);
        await m.addColumn(userProfiles, userProfiles.diabetesType);
        await m.addColumn(userProfiles, userProfiles.heightCm);
        await m.addColumn(userProfiles, userProfiles.biologicalSex);
      }
      if (from < 6) {
        await m.createTable(recipes);
        await m.createTable(recipeIngredients);
      }
      if (from < 7) {
        await m.createTable(inventoryItems);
      }
      if (from < 8) {
        await m.createTable(menuPlans);
        await m.createTable(menuMeals);
      }
      if (from < 9) {
        await m.createTable(shoppingItems);
      }
      if (from < 10) {
        await m.addColumn(recipes, recipes.otherIngredients);
      }
      if (from < 11) {
        await m.addColumn(userProfiles, userProfiles.age);
        await m.createTable(activityEntries);
        await m.createTable(waterLogs);
        await m.createTable(dailyNotes);
      }
    },
  );
}
