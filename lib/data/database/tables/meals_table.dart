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

/// Una receta registrada en una comida: sus ingredientes son filas de
/// [MealItems] que apuntan a ella, y el Diario los muestra como un solo ítem.
/// El nombre y las porciones se guardan aquí, así el registro no cambia si
/// después se edita o se borra la receta.
@DataClassName('MealRecipeEntryRow')
class MealRecipeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId =>
      integer().references(Meals, #id, onDelete: KeyAction.cascade)();

  /// Receta de origen, solo como referencia (puede ya no existir).
  IntColumn get recipeId => integer().nullable()();
  TextColumn get recipeName => text()();
  RealColumn get portions => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('MealItemRow')
class MealItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId =>
      integer().references(Meals, #id, onDelete: KeyAction.cascade)();
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.restrict)();

  /// Si el alimento se registró como ingrediente de una receta.
  IntColumn get recipeEntryId => integer().nullable().references(
    MealRecipeEntries,
    #id,
    onDelete: KeyAction.cascade,
  )();
  RealColumn get quantity => real()();
  TextColumn get unitLabel => text()();
  RealColumn get gramsEquivalent => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
