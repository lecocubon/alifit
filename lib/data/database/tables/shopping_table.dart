import 'package:drift/drift.dart';

import 'foods_table.dart';
import 'menus_table.dart';

@DataClassName('ShoppingItemRow')
class ShoppingItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get menuPlanId =>
      integer().references(MenuPlans, #id, onDelete: KeyAction.cascade)();
  IntColumn get foodId => integer().nullable().references(
    Foods,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  RealColumn get quantity => real()();
  TextColumn get unitLabel => text()();
  TextColumn get category => text()();
  BoolColumn get isOptional => boolean().withDefault(const Constant(false))();
  BoolColumn get isManual => boolean().withDefault(const Constant(false))();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  RealColumn get manualPrice => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
