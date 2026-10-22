import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:alifit/app/providers/database_provider.dart';
import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_meal_repository.dart';
import 'package:alifit/domain/nutrition/meal_type.dart';
import 'package:alifit/domain/nutrition/nutrition_providers.dart';
import 'package:alifit/domain/updates/update_providers.dart';
import 'package:alifit/presentation/home/home_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('"Hoy has consumido" muestra hoy aunque el Diario esté en otro '
      'día', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(() async {
      final foodId = await db
          .into(db.foods)
          .insert(
            FoodsCompanion.insert(
              name: 'Arroz',
              normalizedName: 'arroz',
              source: const Value('user'),
              calories: 100,
              carbs: 0,
              protein: 0,
              fat: 0,
              fiber: 0,
              sugar: 0,
              sodium: 0,
            ),
          );
      final repo = DriftMealRepository(db);
      for (final (day, grams) in [(21, 130.0), (22, 260.0)]) {
        await repo.addItem(
          date: DateTime(2026, 10, day),
          type: MealType.almuerzo,
          foodId: foodId,
          quantity: grams,
          unitLabel: 'g',
          gramsEquivalent: grams,
        );
      }
    });

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 22, 12)),
        availableUpdateProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(selectedDiaryDateProvider.notifier)
        .setDate(DateTime(2026, 10, 21));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('260'), findsOneWidget);
    expect(find.text('130'), findsNothing);

    // Las consultas en vivo de Drift dejan un temporizador al cerrarse.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
