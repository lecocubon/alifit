import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/text/text_normalize.dart';
import '../database/app_database.dart';

const _assetPath = 'assets/data/chile_food_seed.json';
const _seedSettingKey = 'chile_seed_version';

/// Siembra la capa local chilena (sección 6 del encargo): sinónimos que
/// apuntan a alimentos ya existentes (p.ej. "palta" -> el aguacate de
/// USDA) y alimentos genuinamente chilenos sin equivalente razonable en el
/// catálogo importado (p.ej. marraqueta). Debe ejecutarse después de
/// [UsdaImporter], ya que los alias dependen de que esos alimentos existan.
class ChileFoodSeeder {
  ChileFoodSeeder(this._db);

  final AppDatabase _db;

  Future<void> seedIfNeeded() async {
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final seedVersion = data['seedVersion'] as String;

    final alreadySeeded = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(_seedSettingKey))).getSingleOrNull();
    if (alreadySeeded?.value == seedVersion) {
      return;
    }

    await _db.transaction(() async {
      final aliases = (data['aliases'] as List).cast<Map<String, dynamic>>();
      for (final alias in aliases) {
        await _seedAlias(
          matchFoodName: alias['matchFoodName'] as String,
          alias: alias['alias'] as String,
        );
      }

      final foods = (data['foods'] as List).cast<Map<String, dynamic>>();
      for (final food in foods) {
        await _upsertChileFood(food);
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
  }

  Future<void> _seedAlias({
    required String matchFoodName,
    required String alias,
  }) async {
    final food =
        await (_db.select(_db.foods)..where(
              (t) => t.source.equals('usda') & t.name.equals(matchFoodName),
            ))
            .getSingleOrNull();
    if (food == null) {
      return;
    }

    final normalized = normalizeForSearch(alias);
    final existing =
        await (_db.select(_db.foodAliases)..where(
              (t) =>
                  t.foodId.equals(food.id) &
                  t.normalizedAlias.equals(normalized),
            ))
            .getSingleOrNull();
    if (existing != null) {
      return;
    }

    await _db
        .into(_db.foodAliases)
        .insert(
          FoodAliasesCompanion.insert(
            foodId: food.id,
            alias: alias,
            normalizedAlias: normalized,
          ),
        );
  }

  Future<void> _upsertChileFood(Map<String, dynamic> food) async {
    final slug = food['slug'] as String;
    final name = food['name'] as String;
    final nutrition = food['nutrition'] as Map<String, dynamic>;

    double? asDouble(String key) => (nutrition[key] as num?)?.toDouble();

    final companion = FoodsCompanion(
      name: Value(name),
      normalizedName: Value(normalizeForSearch(name)),
      source: const Value('chile'),
      sourceId: Value(slug),
      baseUnit: Value(food['baseUnit'] as String? ?? 'g'),
      calories: Value(asDouble('calories') ?? 0),
      protein: Value(asDouble('protein') ?? 0),
      fat: Value(asDouble('fat') ?? 0),
      carbs: Value(asDouble('carbs') ?? 0),
      fiber: Value(asDouble('fiber') ?? 0),
      sugar: Value(asDouble('sugar') ?? 0),
      sodium: Value(asDouble('sodium') ?? 0),
      completeness: Value(food['completeness'] as String? ?? 'partial'),
      notes: Value(food['notes'] as String?),
      updatedAt: Value(DateTime.now()),
    );

    final existing =
        await (_db.select(
              _db.foods,
            )..where((t) => t.source.equals('chile') & t.sourceId.equals(slug)))
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
