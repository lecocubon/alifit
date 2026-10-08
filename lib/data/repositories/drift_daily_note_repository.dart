import '../../domain/nutrition/daily_note_repository.dart';
import '../database/app_database.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class DriftDailyNoteRepository implements DailyNoteRepository {
  DriftDailyNoteRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<String?> watchForDate(DateTime date) {
    final day = _dateOnly(date);
    final query = _db.select(_db.dailyNotes)..where((t) => t.date.equals(day));
    return query.watchSingleOrNull().map((row) => row?.content);
  }

  @override
  Future<void> setNote({required DateTime date, required String text}) async {
    final day = _dateOnly(date);
    if (text.trim().isEmpty) {
      await (_db.delete(_db.dailyNotes)..where((t) => t.date.equals(day))).go();
      return;
    }
    await _db
        .into(_db.dailyNotes)
        .insertOnConflictUpdate(
          DailyNotesCompanion.insert(date: day, content: text),
        );
  }
}
