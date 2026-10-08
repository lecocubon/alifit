import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:alifit/app/providers/database_provider.dart';
import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/domain/meal_plan/meal_plan.dart';
import 'package:alifit/domain/meal_plan/meal_plan_providers.dart';
import 'package:alifit/domain/personal_plan/personal_plan.dart';
import 'package:alifit/presentation/diary/diary_screen.dart';
import 'package:alifit/presentation/meal_plan/meal_plan_screen.dart';

void main() {
  late MealPlan plan;

  setUpAll(() async {
    await initializeDateFormatting('es');
    plan = PersonalPlan.parse(
      File('test/fixtures/perfil_ejemplo.json').readAsStringSync(),
    ).mealPlan!;
  });

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    MealPlan? withPlan,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          mealPlanProvider.overrideWith((ref) => Stream.value(withPlan)),
        ],
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Las consultas en vivo de Drift dejan un temporizador al cerrarse: hay
  // que desmontar la pantalla y avanzar el reloj antes de terminar.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('muestra cada comida con su aporte, porciones y ejemplos', (
    tester,
  ) async {
    await pump(tester, const MealPlanScreen(), withPlan: plan);

    expect(find.text('Plan de ejemplo'), findsOneWidget);
    expect(find.textContaining('Próximo control'), findsOneWidget);
    expect(find.text('Desayuno · 8:00'), findsOneWidget);
    expect(find.text('500 kcal'), findsOneWidget);
    expect(find.text('Proteína: 2 porciones'), findsOneWidget);
    expect(find.text('1 porción = huevo 1 unidad'), findsOneWidget);
    expect(find.text('Cocinar sin aceite.'), findsOneWidget);
    expect(find.text('Avena con leche y 2 huevos.'), findsNothing);

    await tester.tap(find.text('Ejemplos (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Avena con leche y 2 huevos.'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Día de gimnasio'), 200);
    expect(find.text('Suplementación'), findsOneWidget);
    expect(find.text('Llevar una fruta.'), findsOneWidget);
  });

  testWidgets('sin plan importado explica dónde importarlo', (tester) async {
    await pump(tester, const MealPlanScreen());

    expect(find.textContaining('No hay un plan de comidas'), findsOneWidget);
  });

  testWidgets('el Diario muestra la meta y las porciones del plan', (
    tester,
  ) async {
    await pump(tester, const DiaryScreen(), withPlan: plan);

    expect(find.text('Meta 500 kcal'), findsOneWidget);
    expect(
      find.text('Plan 8:00: Cereales 1 · Proteína 2 · Lípidos 0,5'),
      findsOneWidget,
    );
    expect(find.text('Plan 12:00: Frutas 1'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('sin plan, el Diario no muestra metas por comida', (
    tester,
  ) async {
    await pump(tester, const DiaryScreen());

    expect(find.textContaining('Meta '), findsNothing);
    expect(find.textContaining('Plan '), findsNothing);
    await unmount(tester);
  });
}
