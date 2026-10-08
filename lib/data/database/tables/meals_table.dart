import 'package:drift/drift.dart';

import 'foods_table.dart';

@DataClassName('MealRow')
class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Fecha (sin hora) de la comida, guardada a medianoche UTC.
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()();
  TextColumn get customLabel => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('MealItemRow')
class MealItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId =>
      integer().references(Meals, #id, onDelete: KeyAction.cascade)();
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantity => real()();
  TextColumn get unitLabel => text()();
  RealColumn get gramsEquivalent => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
