import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_meal_plan_repository.dart';
import 'package:alifit/data/repositories/drift_nutri_guide_repository.dart';
import 'package:alifit/data/repositories/drift_nutrition_goals_repository.dart';
import 'package:alifit/domain/nutri_guide/nutri_guide.dart';
import 'package:alifit/domain/nutrition/meal_type.dart';
import 'package:alifit/domain/personal_plan/personal_plan.dart';

void main() {
  final exampleRaw = File(
    'test/fixtures/perfil_ejemplo.json',
  ).readAsStringSync();

  String withChanges(void Function(Map<String, dynamic> json) change) {
    final json = jsonDecode(exampleRaw) as Map<String, dynamic>;
    change(json);
    return jsonEncode(json);
  }

  Matcher formatError(String message) =>
      isA<FormatException>().having((e) => e.message, 'message', message);

  test('lee metas y guía del archivo de perfil', () {
    final plan = PersonalPlan.parse(exampleRaw);

    expect(plan.label, 'Perfil de ejemplo');
    expect(plan.goals!.calories, 1900);
    expect(plan.goals!.protein, 120);

    final guide = plan.guide!;
    expect(guide.groups.map((g) => g.name), [
      'Cereales / carbohidratos',
      'Verduras',
      'Azúcar',
    ]);
    expect(guide.foodCount, 6);

    final cereales = guide.groups.first.subgroups.single.blocks.single;
    expect(cereales.quality, NutriQuality.igModerado);
    expect(cereales.foods[1].measureText, '3/4 taza (100 g)');
    expect(cereales.foods[3].measureText, '35 g');
    final ajo = guide.groups[1].subgroups.single.blocks.single.foods.single;
    expect(ajo.measureText, '8 unidades');
  });

  test('lee el plan de comidas del perfil', () {
    final mealPlan = PersonalPlan.parse(exampleRaw).mealPlan!;

    expect(mealPlan.title, 'Plan de ejemplo');
    expect(mealPlan.controlDate, DateTime(2026, 11, 10));
    expect(mealPlan.meals.map((m) => m.type), [
      MealType.desayuno,
      MealType.colacion,
    ]);

    final desayuno = mealPlan.mealFor(MealType.desayuno)!;
    expect(desayuno.time, '8:00');
    expect(desayuno.target!.calories, 500);
    expect(desayuno.portions[1].amountText, '2 porciones');
    expect(desayuno.portions[2].amountText, '0,5 porciones');
    expect(desayuno.portionsSummary, 'Cereales 1 · Proteína 2 · Lípidos 0,5');
    expect(desayuno.examples, hasLength(2));
    expect(mealPlan.mealFor(MealType.cena), isNull);
    expect(mealPlan.supplements, ['Tomar agua.']);
    expect(mealPlan.sportTips.single.title, 'Día de gimnasio');
  });

  test('acepta un perfil con solo metas, solo plan o solo guía', () {
    Map<String, dynamic> only(Map<String, dynamic> json, String key) => json
      ..removeWhere(
        (k, _) =>
            const ['metas', 'planComidas', 'guiaNutri'].contains(k) && k != key,
      );

    final soloMetas = PersonalPlan.parse(withChanges((j) => only(j, 'metas')));
    expect(soloMetas.goals, isNotNull);
    expect(soloMetas.mealPlan, isNull);
    expect(soloMetas.guide, isNull);

    final soloPlan = PersonalPlan.parse(
      withChanges((j) => only(j, 'planComidas')),
    );
    expect(soloPlan.goals, isNull);
    expect(soloPlan.mealPlan, isNotNull);

    final soloGuia = PersonalPlan.parse(
      withChanges((j) => only(j, 'guiaNutri')),
    );
    expect(soloGuia.goals, isNull);
    expect(soloGuia.guide, isNotNull);
  });

  test('rechaza archivos que no son un perfil de AliFit', () {
    const notAProfile = 'El archivo no es un perfil de AliFit.';
    expect(() => PersonalPlan.parse('hola'), throwsA(formatError(notAProfile)));
    expect(
      () => PersonalPlan.parse('[1, 2]'),
      throwsA(formatError(notAProfile)),
    );
    expect(
      () => PersonalPlan.parse(withChanges((json) => json['tipo'] = 'otro')),
      throwsA(formatError(notAProfile)),
    );
  });

  test('rechaza perfiles incompletos o con datos inválidos', () {
    expect(
      () => PersonalPlan.parse(
        withChanges(
          (json) => json
            ..remove('metas')
            ..remove('planComidas')
            ..remove('guiaNutri'),
        ),
      ),
      throwsA(formatError('El perfil no trae metas, plan ni guía.')),
    );
    expect(
      () => PersonalPlan.parse(
        withChanges(
          (json) =>
              ((json['planComidas'] as Map)['comidas'] as List).first['tipo'] =
                  'brunch',
        ),
      ),
      throwsA(formatError('Comida desconocida en el plan: "brunch".')),
    );
    expect(
      () => PersonalPlan.parse(
        withChanges((json) => (json['planComidas'] as Map).remove('comidas')),
      ),
      throwsA(formatError('El perfil está incompleto o dañado.')),
    );
    expect(
      () => PersonalPlan.parse(
        withChanges((json) => (json['metas'] as Map)['calorias'] = 0),
      ),
      throwsA(formatError('Las metas del perfil no son válidas.')),
    );
    expect(
      () => PersonalPlan.parse(
        withChanges((json) => (json['metas'] as Map).remove('grasas')),
      ),
      throwsA(formatError('El perfil está incompleto o dañado.')),
    );
    expect(
      () => PersonalPlan.parse(
        withChanges((json) => (json['guiaNutri'] as Map).remove('groups')),
      ),
      throwsA(formatError('El perfil está incompleto o dañado.')),
    );
  });

  group('al aplicarlo', () {
    late AppDatabase db;
    late DriftNutritionGoalsRepository goalsRepository;
    late DriftMealPlanRepository mealPlanRepository;
    late DriftNutriGuideRepository guideRepository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      goalsRepository = DriftNutritionGoalsRepository(db);
      mealPlanRepository = DriftMealPlanRepository(db);
      guideRepository = DriftNutriGuideRepository(db);
    });

    tearDown(() => db.close());

    test(
      'reemplaza las metas y guarda plan y guía, que luego se pueden quitar',
      () async {
        expect(await guideRepository.watchGuide().first, isNull);
        expect(await mealPlanRepository.watchPlan().first, isNull);

        await PersonalPlan.parse(exampleRaw).apply(
          goalsRepository: goalsRepository,
          mealPlanRepository: mealPlanRepository,
          guideRepository: guideRepository,
        );

        final mealPlan = await mealPlanRepository.watchPlan().first;
        expect(mealPlan!.meals, hasLength(2));
        await mealPlanRepository.clearPlan();
        expect(await mealPlanRepository.watchPlan().first, isNull);

        final goals = await goalsRepository.watchGoals().first;
        expect(goals.calories, 1900);
        expect(goals.protein, 120);
        final guide = await guideRepository.watchGuide().first;
        expect(guide!.title, 'Guía de ejemplo');
        expect(guide.foodCount, 6);

        await guideRepository.clearGuide();
        expect(await guideRepository.watchGuide().first, isNull);
        expect((await goalsRepository.watchGoals().first).calories, 1900);
      },
    );
  });
}
