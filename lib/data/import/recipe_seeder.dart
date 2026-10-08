import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../database/app_database.dart';

const _assetPath = 'assets/data/recipe_seed.json';
const _seedSettingKey = 'recipe_seed_version';

class RecipeSeedResult {
  const RecipeSeedResult({required this.created, required this.skipped});

  final int created;

  /// Nombres de recetas que no se pudieron sembrar porque alguno de sus
  /// ingredientes no existe en el catálogo actual (ej. depende del
  /// catálogo ampliado y el usuario no lo ha activado).
  final List<String> skipped;
}

/// Siembra un recetario propio de platos tradicionales/genéricos —
/// chilenos, italianos y opciones saludables — escrito para esta app y no
/// copiado de ningún libro, sitio o canal específico (ver
/// assets/data/recipe_seed.json).
///
/// Debe ejecutarse después de [UsdaImporter]: cada ingrediente se resuelve
/// contra un alimento ya existente por nombre exacto. Si algún ingrediente
/// no se encuentra, la receta completa se omite en vez de guardarse con
/// datos incompletos o inventados.
class RecipeSeeder {
  RecipeSeeder(this._db);

  final AppDatabase _db;

  Future<RecipeSeedResult> seedIfNeeded() async {
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final seedVersion = data['seedVersion'] as String;

    final alreadySeeded = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(_seedSettingKey))).getSingleOrNull();
    if (alreadySeeded?.value == seedVersion) {
      return const RecipeSeedResult(created: 0, skipped: []);
    }

    final recipes = (data['recipes'] as List).cast<Map<String, dynamic>>();
    var created = 0;
    final skipped = <String>[];

    await _db.transaction(() async {
      for (final recipe in recipes) {
        final ok = await _seedRecipe(recipe);
        if (ok) {
          created++;
        } else {
          skipped.add(recipe['name'] as String);
        }
      }

      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: _seedSettingKey,
              value: seedVersion,
            ),
          );
    });

    return RecipeSeedResult(created: created, skipped: skipped);
  }

  /// Crea o actualiza (upsert) la receta según el contenido actual del
  /// recetario embebido. Se actualiza en vez de omitirse cuando ya existe
  /// para que las correcciones al recetario (redacción, ingredientes)
  /// lleguen a usuarios que ya la tenían sembrada de una versión anterior;
  /// se preserva el id de la receta (y con eso su estado de favorito).
  Future<bool> _seedRecipe(Map<String, dynamic> recipe) async {
    final name = recipe['name'] as String;

    final ingredientsData = (recipe['ingredients'] as List)
        .cast<Map<String, dynamic>>();
    final resolved = <int, double>{};
    for (final ingredient in ingredientsData) {
      final foodName = ingredient['food'] as String;
      final grams = (ingredient['grams'] as num).toDouble();
      // Algunos alimentos del catálogo base tienen más de una fila con el
      // mismo nombre traducido (distintos registros de origen de USDA);
      // se toma la primera de forma determinista en vez de asumir unicidad.
      final foodRow =
          await (_db.select(_db.foods)
                ..where((t) => t.name.equals(foodName))
                ..orderBy([(t) => OrderingTerm.asc(t.id)])
                ..limit(1))
              .getSingleOrNull();
      if (foodRow == null) {
        return false;
      }
      resolved[foodRow.id] = grams;
    }

    final tags = Value(
      (recipe['tags'] as List? ?? const []).cast<String>().join(','),
    );
    final otherIngredients = Value(
      (recipe['otherIngredients'] as List? ?? const []).cast<String>().join(
        '\n',
      ),
    );
    final servings = Value(recipe['servings'] as int);
    final prepMinutes = Value(recipe['prepMinutes'] as int?);
    final instructions = Value(recipe['instructions'] as String?);

    final existing =
        await (_db.select(_db.recipes)
              ..where((t) => t.name.equals(name))
              ..limit(1))
            .getSingleOrNull();

    final int recipeId;
    if (existing != null) {
      recipeId = existing.id;
      await (_db.update(
        _db.recipes,
      )..where((t) => t.id.equals(recipeId))).write(
        RecipesCompanion(
          servings: servings,
          prepMinutes: prepMinutes,
          instructions: instructions,
          tags: tags,
          otherIngredients: otherIngredients,
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (_db.delete(
        _db.recipeIngredients,
      )..where((t) => t.recipeId.equals(recipeId))).go();
    } else {
      recipeId = await _db
          .into(_db.recipes)
          .insert(
            RecipesCompanion.insert(
              name: name,
              servings: servings,
              prepMinutes: prepMinutes,
              instructions: instructions,
              tags: tags,
              otherIngredients: otherIngredients,
            ),
          );
    }

    for (final entry in resolved.entries) {
      await _db
          .into(_db.recipeIngredients)
          .insert(
            RecipeIngredientsCompanion.insert(
              recipeId: recipeId,
              foodId: entry.key,
              quantity: entry.value,
              unitLabel: 'g',
              gramsEquivalent: entry.value,
            ),
          );
    }

    return true;
  }
}
