import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/import/usda_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('importa alimentos de USDA y no duplica al reimportar', () async {
    final importer = UsdaImporter(db);

    await importer.importIfNeeded();
    final afterFirstImport = await db.select(db.foods).get();
    expect(afterFirstImport, isNotEmpty);
    expect(afterFirstImport.every((f) => f.source == 'usda'), isTrue);

    await importer.importIfNeeded();
    final afterSecondImport = await db.select(db.foods).get();
    expect(afterSecondImport.length, afterFirstImport.length);
  });

  test('loadUsdaDatasetInfo expone metadatos del dataset', () async {
    final info = await loadUsdaDatasetInfo();
    expect(info.foodCount, greaterThan(0));
    expect(info.datasetDate, isNotEmpty);
  });

  test('los nombres quedan en español y el inglés queda como alias', () async {
    final importer = UsdaImporter(db);
    await importer.importIfNeeded();

    final avenas = await (db.select(
      db.foods,
    )..where((t) => t.name.like('Avena%'))).get();
    expect(
      avenas,
      isNotEmpty,
      reason: 'debería existir un alimento en español',
    );
    final avena = avenas.first;

    final aliases = await (db.select(
      db.foodAliases,
    )..where((t) => t.foodId.equals(avena.id))).get();
    expect(
      aliases.any((a) => a.alias.toLowerCase().contains('oat')),
      isTrue,
      reason: 'el nombre en inglés debería quedar como alias buscable',
    );
  });
}
