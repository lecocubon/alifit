abstract class DailyNoteRepository {
  Stream<String?> watchForDate(DateTime date);

  Future<void> setNote({required DateTime date, required String text});
}
