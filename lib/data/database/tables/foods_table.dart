import 'package:drift/drift.dart';

@DataClassName('FoodRow')
class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 300)();
  TextColumn get normalizedName => text()();
  TextColumn get source => text().withDefault(const Constant('user'))();
  TextColumn get sourceId => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// 'g' o 'ml'.
  TextColumn get baseUnit => text().withDefault(const Constant('g'))();

  RealColumn get calories => real()();
  RealColumn get carbs => real()();
  RealColumn get protein => real()();
  RealColumn get fat => real()();
  RealColumn get fiber => real()();
  RealColumn get sugar => real()();
  RealColumn get sodium => real()();
  RealColumn get saturatedFat => real().nullable()();
  RealColumn get cholesterol => real().nullable()();
  RealColumn get calcium => real().nullable()();
  RealColumn get iron => real().nullable()();
  RealColumn get potassium => real().nullable()();

  TextColumn get completeness =>
      text().withDefault(const Constant('partial'))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get datasetDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('FoodAliasRow')
class FoodAliases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.cascade)();
  TextColumn get alias => text()();
  TextColumn get normalizedAlias => text()();
}

@DataClassName('FoodServingRow')
class FoodServings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();
  RealColumn get gramsEquivalent => real()();
}
