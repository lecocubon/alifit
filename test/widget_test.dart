import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:alifit/app/app.dart';
import 'package:alifit/app/providers/database_provider.dart';
import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/import/sr_legacy_import_provider.dart';
import 'package:alifit/data/import/sr_legacy_importer.dart';
import 'package:alifit/data/import/usda_import_provider.dart';
import 'package:alifit/data/import/usda_importer.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('muestra el onboarding y luego el shell principal', (
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
        overrides: [
          databaseProvider.overrideWithValue(db),
          // El import real de ~377 alimentos y la carga del asset de
          // catálogo animan el spinner de carga lo suficiente como para que
          // pumpAndSettle nunca se estabilice; este test verifica
          // navegación/onboarding, no el catálogo USDA.
          catalogSetupProvider.overrideWith((ref) async {}),
          usdaDatasetInfoProvider.overrideWith(
            (ref) async => const UsdaDatasetInfo(
              dataset: 'test',
              datasetDate: '2000-01-01',
              attribution: 'test',
              foodCount: 0,
            ),
          ),
          srLegacyDatasetInfoProvider.overrideWith(
            (ref) async => const SrLegacyDatasetInfo(
              dataset: 'test',
              datasetDate: '2000-01-01',
              attribution: 'test',
              foodCount: 0,
            ),
          ),
        ],
        child: const AliFitApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a AliFit'), findsOneWidget);

    // Paso 1: nombre.
    await tester.enterText(find.byType(TextField).first, 'Nico');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Paso 2: condición médica (se deja sin marcar).
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Paso 3: sexo, altura, peso y edad.
    await tester.tap(find.text('Masculino'));
    await tester.pumpAndSettle();
    // Altura: abre el selector de rueda y acepta el valor por defecto.
    await tester.tap(find.text('Seleccionar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    // Peso: abre el selector de rueda y acepta el valor por defecto.
    await tester.tap(find.text('Seleccionar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '30');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Paso 4: nivel de actividad (se deja el valor por defecto).
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Paso 5: objetivo (se deja el valor por defecto).
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Paso 6: resultado del cálculo.
    await tester.tap(find.text('Comenzar a usar AliFit'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('¡Hola, Nico!'), findsOneWidget);

    // Desmonta el árbol explícitamente y purga temporizadores pendientes de
    // los streams de Drift antes de que termine el test (evita el falso
    // positivo "Timer is still pending" del binding de pruebas).
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
