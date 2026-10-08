import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_glucose_repository.dart';
import 'package:alifit/domain/glucose/glucose_context.dart';

void main() {
  late AppDatabase db;
  late DriftGlucoseRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftGlucoseRepository(db);
  });

  tearDown(() => db.close());

  test('el rango por defecto es 70-180 mg/dL', () async {
    final range = await repo.watchRange().first;
    expect(range.low, 70);
    expect(range.high, 180);
  });

  test('setRange actualiza el rango configurado', () async {
    await repo.setRange(low: 80, high: 160);
    final range = await repo.watchRange().first;
    expect(range.low, 80);
    expect(range.high, 160);
    expect(range.isWithinRange(100), isTrue);
    expect(range.isWithinRange(200), isFalse);
  });

  test('addEntry guarda y watchEntries lo devuelve', () async {
    await repo.addEntry(
      measuredAt: DateTime(2026, 1, 1, 8, 30),
      value: 95,
      context: GlucoseContext.ayunas,
      notes: 'Prueba',
    );

    final entries = await repo.watchEntries().first;
    expect(entries, hasLength(1));
    expect(entries.first.value, 95);
    expect(entries.first.context, GlucoseContext.ayunas);
    expect(entries.first.notes, 'Prueba');
  });
}
