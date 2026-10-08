import 'activity_entry.dart';

abstract class ActivityRepository {
  Stream<List<ActivityEntry>> watchForDate(DateTime date);

  Future<void> addEntry({
    required DateTime date,
    required String name,
    required int minutes,
    required double kcal,
  });

  Future<void> removeEntry(int id);
}
