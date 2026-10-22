import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/app/providers/database_provider.dart';
import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/domain/nutrition/food.dart';
import 'package:alifit/presentation/nutrition/food_picker_screen.dart';

void main() {
  testWidgets('un alimento creado desde el selector queda elegido sin tener '
      'que buscarlo', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    Food? picked;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await Navigator.of(context).push<Food>(
                  MaterialPageRoute(
                    builder: (_) =>
                        const FoodPickerScreen(title: 'Agregar ingrediente'),
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Crear alimento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Yogurt Oikos natural',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calorías (kcal)'),
      '98',
    );
    await tester.tap(find.text('Guardar alimento'));
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pumpAndSettle();

    expect(picked?.name, 'Yogurt Oikos natural');
    expect(picked?.nutritionPer100.calories, 98);
    expect(find.text('Agregar ingrediente'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
