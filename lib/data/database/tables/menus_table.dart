import 'package:drift/drift.dart';

import 'recipes_table.dart';

@DataClassName('MenuPlanRow')
class MenuPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withDefault(const Constant(''))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('MenuMealRow')
class MenuMeals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get menuPlanId =>
      integer().references(MenuPlans, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()();
  IntColumn get recipeId => integer().nullable().references(
    Recipes,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get freeformLabel => text().nullable()();
  RealColumn get servings => real().withDefault(const Constant(1))();
  TextColumn get notes => text().nullable()();
}
