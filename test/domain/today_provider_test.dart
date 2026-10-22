import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/app/providers/database_provider.dart';
import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/domain/nutrition/nutrition_providers.dart';

void main() {
  late DateTime now;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    now = DateTime(2026, 10, 21, 23, 50);
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('si la app queda abierta de un día para otro, el Diario pasa al nuevo '
      'día al volver a la app', () {
    expect(container.read(selectedDiaryDateProvider), DateTime(2026, 10, 21));

    now = DateTime(2026, 10, 22, 7, 30);
    container.read(todayProvider.notifier).refresh();

    expect(container.read(todayProvider), DateTime(2026, 10, 22));
    expect(container.read(selectedDiaryDateProvider), DateTime(2026, 10, 22));
  });

  test(
    'si se eligió otra fecha en el Diario, se respeta al cambiar el día',
    () {
      container
          .read(selectedDiaryDateProvider.notifier)
          .setDate(DateTime(2026, 10, 19));

      now = DateTime(2026, 10, 22, 7, 30);
      container.read(todayProvider.notifier).refresh();

      expect(container.read(selectedDiaryDateProvider), DateTime(2026, 10, 19));
    },
  );
}
