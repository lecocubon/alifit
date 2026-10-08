import 'package:drift/drift.dart';

import 'foods_table.dart';

@DataClassName('InventoryItemRow')
class InventoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantity => real()();
  TextColumn get unitLabel => text()();
  TextColumn get location => text().withDefault(const Constant('pantry'))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}
