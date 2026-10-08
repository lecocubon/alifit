import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_activity_repository.dart';

void main() {
  late AppDatabase db;
  late DriftActivityRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftActivityRepository(db);
  });

  tearDown(() => db.close());

  test('agregar una actividad se refleja en watchForDate', () async {
    await repo.addEntry(
      date: DateTime(2026, 7, 20),
      name: 'Caminata',
      minutes: 30,
      kcal: 120,
    );

    final entries = await repo.watchForDate(DateTime(2026, 7, 20)).first;
    expect(entries, hasLength(1));
    expect(entries.first.name, 'Caminata');
    expect(entries.first.kcal, 120);
  });

  test('no mezcla actividades de otros días', () async {
    await repo.addEntry(
      date: DateTime(2026, 7, 20),
      name: 'Caminata',
      minutes: 30,
      kcal: 120,
    );

    final entries = await repo.watchForDate(DateTime(2026, 7, 21)).first;
    expect(entries, isEmpty);
  });

  test('removeEntry elimina la actividad', () async {
    await repo.addEntry(
      date: DateTime(2026, 7, 20),
      name: 'Caminata',
      minutes: 30,
      kcal: 120,
    );
    final entry = (await repo.watchForDate(DateTime(2026, 7, 20)).first).first;

    await repo.removeEntry(entry.id);

    final entries = await repo.watchForDate(DateTime(2026, 7, 20)).first;
    expect(entries, isEmpty);
  });
}
