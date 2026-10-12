import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:alifit/app/providers/database_provider.dart';
import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_meal_repository.dart';
import 'package:alifit/data/repositories/drift_recipe_repository.dart';
import 'package:alifit/domain/nutrition/meal.dart';
import 'package:alifit/domain/nutrition/meal_repository.dart';
import 'package:alifit/domain/nutrition/meal_type.dart';
import 'package:alifit/domain/recipes/recipe_repository.dart';
import 'package:alifit/presentation/diary/diary_screen.dart';
import 'package:alifit/presentation/recipes/recipe_detail_screen.dart';

void main() {
  late AppDatabase db;
  late int flourId;
  late int milkId;

  setUpAll(() => initializeDateFormatting('es'));

  Future<int> insertFood(String name, double calories) => db
      .into(db.foods)
      .insert(
        FoodsCompanion.insert(
          name: name,
          normalizedName: name.toLowerCase(),
          source: const Value('user'),
          calories: calories,
          carbs: 0,
          protein: 0,
          fat: 0,
          fiber: 0,
          sugar: 0,
          sodium: 0,
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    flourId = await insertFood('Harina de trigo', 366);
    milkId = await insertFood('Leche descremada', 33);
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
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

  testWidgets('el Diario muestra la receta como un solo ítem y la quita '
      'completa', (tester) async {
    await tester.runAsync(
      () => DriftMealRepository(db).addRecipe(
        date: DateTime.now(),
        type: MealType.desayuno,
        recipeName: 'Waffle casero',
        portions: 1,
        items: [
          MealRecipeItemInput(
            foodId: flourId,
            quantity: 19,
            unitLabel: 'g',
            gramsEquivalent: 19,
          ),
          MealRecipeItemInput(
            foodId: milkId,
            quantity: 36,
            unitLabel: 'g',
            gramsEquivalent: 36,
          ),
        ],
      ),
    );
    await pump(tester, const DiaryScreen());

    expect(find.text('Waffle casero'), findsOneWidget);
    // 19 g de harina (69,5 kcal) + 36 g de leche (11,9 kcal).
    expect(find.text('1 porción · 81 kcal'), findsOneWidget);
    expect(find.text('Harina de trigo'), findsNothing);
    expect(find.text('Leche descremada'), findsNothing);

    // Al tocarla se ven los ingredientes que se anotaron.
    await tester.tap(find.text('Waffle casero'));
    await tester.pumpAndSettle();
    expect(find.text('Harina de trigo'), findsOneWidget);
    expect(find.text('19 g · 70 kcal'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Waffle casero'), findsNothing);

    await unmount(tester);
  });

  testWidgets('al registrar una receta de varias porciones se anota solo lo '
      'que se comió', (tester) async {
    final recipeId = await tester.runAsync(
      () => DriftRecipeRepository(db).createRecipe(
        name: 'Masa para waffles',
        servings: 4,
        ingredients: [
          RecipeIngredientInput(
            foodId: flourId,
            quantity: 200,
            unitLabel: 'g',
            gramsEquivalent: 200,
          ),
        ],
      ),
    );
    await pump(tester, RecipeDetailScreen(recipeId: recipeId!));

    expect(find.text('4 porciones'), findsOneWidget);
    await tester.tap(find.text('Registrar en el Diario'));
    await tester.pumpAndSettle();
    // Parte en 1 porción: 200 g de harina / 4 = 50 g = 183 kcal.
    expect(find.text('1 porción · 183 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Más'));
    await tester.pumpAndSettle();
    expect(find.text('1,5 porciones · 275 kcal'), findsOneWidget);

    await tester.tap(find.text('Desayuno'));
    await tester.pumpAndSettle();
    expect(
      find.text('Masa para waffles (1,5 porciones) registrada en Desayuno.'),
      findsOneWidget,
    );

    final meal = await tester.runAsync(
      () async => (await DriftMealRepository(
        db,
      ).watchMealsForDate(DateTime.now()).first).single,
    );
    final line = meal!.lines.single as RecipeLine;
    expect(line.entry.portions, 1.5);
    expect(line.entry.recipeId, recipeId);
    expect(line.items.single.gramsEquivalent, 75);

    await unmount(tester);
  });
}
