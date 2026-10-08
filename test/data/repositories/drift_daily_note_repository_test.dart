import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_daily_note_repository.dart';

void main() {
  late AppDatabase db;
  late DriftDailyNoteRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftDailyNoteRepository(db);
  });

  tearDown(() => db.close());

  test('sin nota guardada, watchForDate expone null', () async {
    final note = await repo.watchForDate(DateTime(2026, 7, 20)).first;
    expect(note, isNull);
  });

  test('setNote guarda y watchForDate refleja el texto', () async {
    await repo.setNote(date: DateTime(2026, 7, 20), text: 'Ayuno hasta las 12');

    final note = await repo.watchForDate(DateTime(2026, 7, 20)).first;
    expect(note, 'Ayuno hasta las 12');
  });

  test('setNote con texto vacío borra la nota', () async {
    await repo.setNote(date: DateTime(2026, 7, 20), text: 'Algo');
    await repo.setNote(date: DateTime(2026, 7, 20), text: '  ');

    final note = await repo.watchForDate(DateTime(2026, 7, 20)).first;
    expect(note, isNull);
  });
}
