import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_water_repository.dart';

void main() {
  late AppDatabase db;
  late DriftWaterRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftWaterRepository(db);
  });

  tearDown(() => db.close());

  test('suma los registros de agua del día', () async {
    await repo.addWater(date: DateTime(2026, 7, 20), milliliters: 250);
    await repo.addWater(date: DateTime(2026, 7, 20), milliliters: 250);

    final total = await repo.watchTotalForDate(DateTime(2026, 7, 20)).first;
    expect(total, 500);
  });

  test('no mezcla registros de otros días', () async {
    await repo.addWater(date: DateTime(2026, 7, 20), milliliters: 250);

    final total = await repo.watchTotalForDate(DateTime(2026, 7, 21)).first;
    expect(total, 0);
  });

  test('removeLastForDate quita el último registro agregado', () async {
    await repo.addWater(date: DateTime(2026, 7, 20), milliliters: 250);
    await repo.addWater(date: DateTime(2026, 7, 20), milliliters: 250);

    await repo.removeLastForDate(DateTime(2026, 7, 20));

    final total = await repo.watchTotalForDate(DateTime(2026, 7, 20)).first;
    expect(total, 250);
  });

  test('removeLastForDate sin registros no falla', () async {
    await repo.removeLastForDate(DateTime(2026, 7, 20));

    final total = await repo.watchTotalForDate(DateTime(2026, 7, 20)).first;
    expect(total, 0);
  });
}
