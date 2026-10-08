import 'package:drift/drift.dart';

import 'foods_table.dart';

@DataClassName('RecipeRow')
class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get servings => integer().withDefault(const Constant(1))();
  IntColumn get prepMinutes => integer().nullable()();
  TextColumn get instructions => text().nullable()();

  /// Etiquetas separadas por coma.
  TextColumn get tags => text().withDefault(const Constant(''))();

  /// Ingredientes que no se cuentan en la información nutricional (agua,
  /// sal, levadura, condimentos a gusto, etc.), uno por línea, con su
  /// cantidad ya incluida en el texto (ej. "Levadura seca, 7 g"). No
  /// referencian un alimento del catálogo porque no se busca calcular su
  /// aporte nutricional, sino solo que la receta quede completa para
  /// prepararla.
  TextColumn get otherIngredients => text().withDefault(const Constant(''))();
  RealColumn get costEstimate => real().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('RecipeIngredientRow')
class RecipeIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId =>
      integer().references(Recipes, #id, onDelete: KeyAction.cascade)();
  IntColumn get foodId =>
      integer().references(Foods, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantity => real()();
  TextColumn get unitLabel => text()();
  RealColumn get gramsEquivalent => real()();
  BoolColumn get isOptional => boolean().withDefault(const Constant(false))();
}
