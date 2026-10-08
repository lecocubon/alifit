import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:alifit/domain/nutri_guide/nutri_guide.dart';
import 'package:alifit/domain/nutri_guide/nutri_guide_providers.dart';
import 'package:alifit/domain/personal_plan/personal_plan.dart';
import 'package:alifit/presentation/nutri_guide/nutri_guide_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NutriGuide guide;

  setUpAll(() async {
    await initializeDateFormatting('es');
    guide = PersonalPlan.parse(
      File('test/fixtures/perfil_ejemplo.json').readAsStringSync(),
    ).guide!;
  });

  Future<void> pumpScreen(WidgetTester tester, {NutriGuide? withGuide}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nutriGuideProvider.overrideWith((ref) => Stream.value(withGuide)),
        ],
        child: const MaterialApp(home: NutriGuideScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los grupos y expande uno para ver sus alimentos', (
    tester,
  ) async {
    await pumpScreen(tester, withGuide: guide);

    expect(find.text('Guía del nutri'), findsOneWidget);
    expect(find.text('Cereales / carbohidratos'), findsOneWidget);
    expect(find.text('Avena natural o tradicional'), findsNothing);

    await tester.tap(find.text('Cereales / carbohidratos'));
    await tester.pumpAndSettle();

    expect(find.text('Avena natural o tradicional'), findsOneWidget);
    expect(find.text('IG moderado'), findsWidgets);
  });

  testWidgets('el buscador filtra alimentos sin importar tildes', (
    tester,
  ) async {
    await pumpScreen(tester, withGuide: guide);

    await tester.enterText(find.byType(TextField), 'cuscus');
    await tester.pumpAndSettle();

    expect(find.text('Cuscús cocido'), findsOneWidget);
    expect(find.text('Cuscús crudo'), findsOneWidget);
    expect(find.text('Cereales / carbohidratos'), findsNothing);
  });

  testWidgets('el buscador avisa cuando no hay resultados', (tester) async {
    await pumpScreen(tester, withGuide: guide);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('Sin resultados en la guía.'), findsOneWidget);
  });

  testWidgets('sin guía importada explica dónde importarla', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('No hay una guía importada'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
