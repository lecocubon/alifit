import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_weight_repository.dart';

void main() {
  late AppDatabase db;
  late DriftWeightRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftWeightRepository(db);
  });

  tearDown(() => db.close());

  test('addEntry guarda y watchEntries lo devuelve ordenado desc', () async {
    await repo.addEntry(measuredAt: DateTime(2026, 1, 1), weightKg: 80);
    await repo.addEntry(measuredAt: DateTime(2026, 1, 15), weightKg: 78.5);

    final entries = await repo.watchEntries().first;
    expect(entries, hasLength(2));
    expect(entries.first.weightKg, 78.5);
    expect(entries.last.weightKg, 80);
  });

  test('deleteEntry elimina el registro', () async {
    await repo.addEntry(measuredAt: DateTime(2026, 1, 1), weightKg: 80);
    final entries = await repo.watchEntries().first;

    await repo.deleteEntry(entries.first.id);
    final afterDelete = await repo.watchEntries().first;
    expect(afterDelete, isEmpty);
  });
}
