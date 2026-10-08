import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/text/text_normalize.dart';
import '../database/app_database.dart';

const _assetPath = 'assets/data/usda_foundation_foods.json';
const _importVersionSettingKey = 'usda_import_version';

class UsdaDatasetInfo {
  const UsdaDatasetInfo({
    required this.dataset,
    required this.datasetDate,
    required this.attribution,
    required this.foodCount,
  });

  final String dataset;
  final String datasetDate;
  final String attribution;
  final int foodCount;
}

Future<UsdaDatasetInfo> loadUsdaDatasetInfo() async {
  final raw = await rootBundle.loadString(_assetPath);
  final data = jsonDecode(raw) as Map<String, dynamic>;
  return UsdaDatasetInfo(
    dataset: data['dataset'] as String,
    datasetDate: data['datasetDate'] as String,
    attribution: data['attribution'] as String,
    foodCount: data['foodCount'] as int,
  );
}

/// Importa el catálogo básico de USDA FoodData Central (Foundation Foods,
/// empaquetado como asset JSON, con nombres traducidos al español) a la
/// base de datos local, una sola vez por versión del pipeline de
/// importación. Ver tool/usda_import/import_usda.dart para el proceso de
/// generación del asset a partir del CSV oficial y sus traducciones.
class UsdaImporter {
  UsdaImporter(this._db);

  final AppDatabase _db;

  Future<void> importIfNeeded() async {
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final datasetDate = data['datasetDate'] as String;
    // Distinto del datasetDate: cambia cuando el pipeline de importación
    // cambia (ej. se agregan/corrigen traducciones) aunque el dataset de
    // USDA en sí siga siendo el mismo.
    final importVersion = (data['importVersion'] as String?) ?? datasetDate;

    final alreadyImported = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(_importVersionSettingKey))).getSingleOrNull();
    if (alreadyImported?.value == importVersion) {
      return;
    }

    final foods = (data['foods'] as List).cast<Map<String, dynamic>>();
    final parsedDate = DateTime.parse(datasetDate);

    await _db.transaction(() async {
      for (final food in foods) {
        await _upsertFood(food, parsedDate);
      }
      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: _importVersionSettingKey,
              value: importVersion,
            ),
          );
    });
  }

  Future<void> _upsertFood(
    Map<String, dynamic> food,
    DateTime datasetDate,
  ) async {
    final sourceId = food['sourceId'] as String;
    final name = food['name'] as String;
    final nameEnglish = food['nameEnglish'] as String?;
    final nutrition = food['nutrition'] as Map<String, dynamic>;

    double? asDouble(String key) => (nutrition[key] as num?)?.toDouble();

    final companion = FoodsCompanion(
      name: Value(name),
      normalizedName: Value(normalizeForSearch(name)),
      source: const Value('usda'),
      sourceId: Value(sourceId),
      baseUnit: Value(food['baseUnit'] as String? ?? 'g'),
      calories: Value(asDouble('calories') ?? 0),
      protein: Value(asDouble('protein') ?? 0),
      fat: Value(asDouble('fat') ?? 0),
      carbs: Value(asDouble('carbs') ?? 0),
      fiber: Value(asDouble('fiber') ?? 0),
      sugar: Value(asDouble('sugar') ?? 0),
      sodium: Value(asDouble('sodium') ?? 0),
      saturatedFat: Value(asDouble('saturatedFat')),
      cholesterol: Value(asDouble('cholesterol')),
      calcium: Value(asDouble('calcium')),
      iron: Value(asDouble('iron')),
      potassium: Value(asDouble('potassium')),
      completeness: Value(food['completeness'] as String? ?? 'partial'),
      datasetDate: Value(datasetDate),
      updatedAt: Value(DateTime.now()),
    );

    final existing =
        await (_db.select(_db.foods)..where(
              (t) => t.source.equals('usda') & t.sourceId.equals(sourceId),
            ))
            .getSingleOrNull();

    final int foodId;
    if (existing != null) {
      foodId = existing.id;
      await (_db.update(
        _db.foods,
      )..where((t) => t.id.equals(foodId))).write(companion);
      await (_db.delete(
        _db.foodServings,
      )..where((t) => t.foodId.equals(foodId))).go();
    } else {
      foodId = await _db.into(_db.foods).insert(companion);
    }

    // No se borran los alias existentes antes de esto: podrían venir de la
    // capa chilena (ChileFoodSeeder) y no deben perderse en una reimportación.
    if (nameEnglish != null && nameEnglish.isNotEmpty && nameEnglish != name) {
      final normalizedEnglish = normalizeForSearch(nameEnglish);
      final aliasExists =
          await (_db.select(_db.foodAliases)..where(
                (t) =>
                    t.foodId.equals(foodId) &
                    t.normalizedAlias.equals(normalizedEnglish),
              ))
              .getSingleOrNull();
      if (aliasExists == null) {
        await _db
            .into(_db.foodAliases)
            .insert(
              FoodAliasesCompanion.insert(
                foodId: foodId,
                alias: nameEnglish,
                normalizedAlias: normalizedEnglish,
              ),
            );
      }
    }

    final servings = (food['servings'] as List).cast<Map<String, dynamic>>();
    for (final serving in servings) {
      await _db
          .into(_db.foodServings)
          .insert(
            FoodServingsCompanion.insert(
              foodId: foodId,
              label: serving['label'] as String,
              gramsEquivalent: (serving['gramsEquivalent'] as num).toDouble(),
            ),
          );
    }
  }
}
