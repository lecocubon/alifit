import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/import/recipe_seeder.dart';
import 'package:alifit/data/import/sr_legacy_importer.dart';
import 'package:alifit/data/import/usda_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('siembra todas las recetas del recetario contra el catálogo base '
      '(sin ingredientes faltantes ni inventados)', () async {
    await UsdaImporter(db).importIfNeeded();
    await SrLegacyImporter(db).importIfNeeded();

    final raw = await rootBundle.loadString('assets/data/recipe_seed.json');
    final expectedCount =
        ((jsonDecode(raw) as Map<String, dynamic>)['recipes'] as List).length;

    final result = await RecipeSeeder(db).seedIfNeeded();

    expect(
      result.skipped,
      isEmpty,
      reason:
          'cada ingrediente del recetario debe existir con el nombre '
          'exacto en el catálogo base (Foundation Foods)',
    );
    expect(result.created, expectedCount);

    final recipes = await db.select(db.recipes).get();
    expect(recipes.length, expectedCount);

    final cazuela = recipes.firstWhere((r) => r.name == 'Cazuela de Vacuno');
    final ingredients = await (db.select(
      db.recipeIngredients,
    )..where((t) => t.recipeId.equals(cazuela.id))).get();
    expect(ingredients, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'no duplica recetas al sembrar dos veces',
    () async {
      await UsdaImporter(db).importIfNeeded();
      await SrLegacyImporter(db).importIfNeeded();
      await RecipeSeeder(db).seedIfNeeded();
      final afterFirst = await db.select(db.recipes).get();

      final secondResult = await RecipeSeeder(db).seedIfNeeded();
      final afterSecond = await db.select(db.recipes).get();

      expect(afterSecond.length, afterFirst.length);
      expect(secondResult.created, 0);
      expect(secondResult.skipped, isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('actualiza una receta existente cuando cambia la versión del '
      'recetario, en vez de omitirla o duplicarla', () async {
    await UsdaImporter(db).importIfNeeded();
    await SrLegacyImporter(db).importIfNeeded();
    await RecipeSeeder(db).seedIfNeeded();

    final before = await (db.select(
      db.recipes,
    )..where((t) => t.name.equals('Cazuela de Vacuno'))).getSingle();

    // Simula que el recetario embebido cambió de versión (como pasaría
    // al actualizar la app), forzando un re-sembrado.
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'recipe_seed_version',
            value: 'version-anterior-simulada',
          ),
        );

    final result = await RecipeSeeder(db).seedIfNeeded();

    final matching = await (db.select(
      db.recipes,
    )..where((t) => t.name.equals('Cazuela de Vacuno'))).get();
    expect(matching, hasLength(1), reason: 'no debe duplicar la receta');
    expect(
      matching.first.id,
      before.id,
      reason: 'debe conservar el mismo id (y con eso el favorito)',
    );
    expect(result.created, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('omite una receta si le falta un ingrediente en el catálogo', () async {
    // No se importa USDA: el catálogo está vacío, así que ningún
    // ingrediente puede resolverse y todas las recetas deben omitirse.
    final result = await RecipeSeeder(db).seedIfNeeded();

    expect(result.created, 0);
    expect(result.skipped, isNotEmpty);

    final recipes = await db.select(db.recipes).get();
    expect(recipes, isEmpty);
  });
}
