import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_nutri_guide_repository.dart';
import 'package:alifit/data/repositories/drift_nutrition_goals_repository.dart';
import 'package:alifit/domain/nutri_guide/nutri_guide.dart';
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

  test('acepta un perfil con solo metas o solo guía', () {
    final soloMetas = PersonalPlan.parse(
      withChanges((json) => json.remove('guiaNutri')),
    );
    expect(soloMetas.guide, isNull);
    expect(soloMetas.goals, isNotNull);

    final soloGuia = PersonalPlan.parse(
      withChanges((json) => json.remove('metas')),
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
            ..remove('guiaNutri'),
        ),
      ),
      throwsA(formatError('El perfil no trae metas ni guía.')),
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
    late DriftNutriGuideRepository guideRepository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      goalsRepository = DriftNutritionGoalsRepository(db);
      guideRepository = DriftNutriGuideRepository(db);
    });

    tearDown(() => db.close());

    test(
      'reemplaza las metas y guarda la guía, que luego se puede quitar',
      () async {
        expect(await guideRepository.watchGuide().first, isNull);

        await PersonalPlan.parse(exampleRaw).apply(
          goalsRepository: goalsRepository,
          guideRepository: guideRepository,
        );

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
