import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/import/sr_legacy_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('está inactivo hasta llamar a importIfNeeded', () async {
    final importer = SrLegacyImporter(db);
    expect(await importer.isActive(), isFalse);

    await importer.importIfNeeded();
    expect(await importer.isActive(), isTrue);

    final foods = await db.select(db.foods).get();
    expect(foods, isNotEmpty);
  });

  test('no duplica al reimportar', () async {
    final importer = SrLegacyImporter(db);
    await importer.importIfNeeded();
    final afterFirst = await db.select(db.foods).get();

    await importer.importIfNeeded();
    final afterSecond = await db.select(db.foods).get();
    expect(afterSecond.length, afterFirst.length);
  });

  test('loadSrLegacyDatasetInfo expone metadatos', () async {
    final info = await loadSrLegacyDatasetInfo();
    expect(info.foodCount, greaterThan(1000));
  });
}
