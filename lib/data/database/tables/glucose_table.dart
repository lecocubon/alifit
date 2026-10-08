import 'package:drift/drift.dart';

import 'meals_table.dart';

@DataClassName('GlucoseEntryRow')
class GlucoseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get measuredAt => dateTime()();
  RealColumn get value => real()();
  TextColumn get context => text()();
  IntColumn get relatedMealId => integer().nullable().references(
    Meals,
    #id,
    onDelete: KeyAction.setNull,
  )();
  RealColumn get hoursAfterMeal => real().nullable()();
  TextColumn get physicalActivity => text().nullable()();
  TextColumn get symptoms => text().nullable()();
  TextColumn get medicationNote => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
