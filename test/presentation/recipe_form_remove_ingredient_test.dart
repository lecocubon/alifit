import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/app/providers/database_provider.dart';
import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_recipe_repository.dart';
import 'package:alifit/domain/recipes/recipe_repository.dart';
import 'package:alifit/presentation/recipes/recipe_form_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  Future<int> insertFood(String name) => db
      .into(db.foods)
      .insert(
        FoodsCompanion.insert(
          name: name,
          normalizedName: name.toLowerCase(),
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

  List<String> quantities(WidgetTester tester) => tester
      .widgetList<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Cantidad'),
          matching: find.byType(EditableText),
        ),
      )
      .map((e) => e.controller.text)
      .toList();

  testWidgets('al quitar un ingrediente del medio, los de abajo muestran su '
      'propia cantidad', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(db.close);

    final recipe = await tester.runAsync(() async {
      final repo = DriftRecipeRepository(db);
      final ids = [
        await insertFood('Avena'),
        await insertFood('Yogurt natural'),
        await insertFood('Leche descremada'),
      ];
      final quantities = [35.0, 52.0, 69.0];
      final id = await repo.createRecipe(
        name: 'Avena trasnochada',
        servings: 1,
        ingredients: [
          for (var i = 0; i < ids.length; i++)
            RecipeIngredientInput(
              foodId: ids[i],
              quantity: quantities[i],
              unitLabel: 'g',
              gramsEquivalent: quantities[i],
            ),
        ],
      );
      return repo.getById(id);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: RecipeFormScreen(existingRecipe: recipe)),
      ),
    );
    await tester.pumpAndSettle();
    expect(quantities(tester), ['35', '52', '69']);

    await tester.tap(find.byIcon(Icons.close).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Yogurt natural'), findsNothing);
    expect(quantities(tester), ['35', '69']);
  });
}
