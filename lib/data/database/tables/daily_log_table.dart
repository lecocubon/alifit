import 'package:drift/drift.dart';

@DataClassName('ActivityEntryRow')
class ActivityEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Fecha (sin hora) de la actividad, guardada a medianoche UTC.
  DateTimeColumn get date => dateTime()();
  TextColumn get name => text()();
  IntColumn get minutes => integer()();
  RealColumn get kcal => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('WaterLogRow')
class WaterLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Fecha (sin hora) del registro, guardada a medianoche UTC.
  DateTimeColumn get date => dateTime()();
  RealColumn get milliliters => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('DailyNoteRow')
class DailyNotes extends Table {
  /// Fecha (sin hora) de la nota, guardada a medianoche UTC.
  DateTimeColumn get date => dateTime()();
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {date};
}
