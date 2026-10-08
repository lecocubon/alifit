import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/import/chile_food_seeder.dart';
import 'package:alifit/data/import/usda_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test(
    'agrega alimentos chilenos propios (marraqueta, hallulla, pan amasado), sin duplicar',
    () async {
      await UsdaImporter(db).importIfNeeded();

      final seeder = ChileFoodSeeder(db);
      await seeder.seedIfNeeded();

      final chileFoods = await (db.select(
        db.foods,
      )..where((t) => t.source.equals('chile'))).get();
      expect(chileFoods.map((f) => f.name), contains('Marraqueta'));
      expect(chileFoods.map((f) => f.name), contains('Hallulla'));
      expect(chileFoods.map((f) => f.name), contains('Pan Amasado'));

      await seeder.seedIfNeeded();
      final chileFoodsAfterRerun = await (db.select(
        db.foods,
      )..where((t) => t.source.equals('chile'))).get();
      expect(chileFoodsAfterRerun.length, chileFoods.length);
    },
  );
}
