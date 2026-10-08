import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/app/providers/database_provider.dart';
import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/presentation/nutrition/food_form_screen.dart';

void main() {
  testWidgets('el formulario de alimento acepta coma decimal (13,4 g)', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FoodFormScreen()),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Pan de prueba',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calorías (kcal)'),
      '188',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Proteínas (g)'),
      '13,4',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Carbohidratos (g)'),
      '30,3',
    );
    await tester.tap(find.text('Guardar alimento'));
    await tester.pumpAndSettle();

    final saved = await (db.select(
      db.foods,
    )..where((t) => t.name.equals('Pan de prueba'))).getSingle();
    expect(saved.calories, 188);
    expect(saved.protein, closeTo(13.4, 0.001));
    expect(saved.carbs, closeTo(30.3, 0.001));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
