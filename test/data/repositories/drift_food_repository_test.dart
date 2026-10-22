import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/data/database/app_database.dart';
import 'package:alifit/data/repositories/drift_food_repository.dart';
import 'package:alifit/domain/nutrition/food_source.dart';
import 'package:alifit/domain/nutrition/nutrition_values.dart';

void main() {
  late AppDatabase db;
  late DriftFoodRepository repo;

  const nutrition = NutritionValues(
    calories: 50,
    carbs: 5,
    protein: 3,
    fat: 1,
    fiber: 0.5,
    sugar: 2,
    sodium: 20,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftFoodRepository(db);
  });

  tearDown(() => db.close());

  test(
    'crear un alimento sin especificar fuente usa "user" por defecto',
    () async {
      final id = await repo.createFood(
        name: 'Yogur casero',
        nutritionPer100: nutrition,
        baseUnit: 'g',
      );

      final food = await repo.getById(id);
      expect(food!.source, FoodSource.user);
    },
  );

  test('crear un alimento desde Open Food Facts guarda esa fuente', () async {
    final id = await repo.createFood(
      name: 'Producto envasado',
      nutritionPer100: nutrition,
      baseUnit: 'g',
      barcode: '7890000000001',
      source: FoodSource.openFoodFacts,
    );

    final food = await repo.getById(id);
    expect(food!.source, FoodSource.openFoodFacts);
    expect(food.barcode, '7890000000001');
  });

  test('getByBarcode encuentra un alimento por su código', () async {
    await repo.createFood(
      name: 'Producto envasado',
      nutritionPer100: nutrition,
      baseUnit: 'g',
      barcode: '7890000000001',
      source: FoodSource.openFoodFacts,
    );

    final found = await repo.getByBarcode('7890000000001');
    expect(found, isNotNull);
    expect(found!.name, 'Producto envasado');
  });

  test('getByBarcode no falla si dos alimentos tienen el mismo código: '
      'usa el más reciente', () async {
    await repo.createFood(
      name: 'Leche (Open Food Facts)',
      nutritionPer100: nutrition,
      baseUnit: 'g',
      barcode: '7800000000009',
    );
    await repo.createFood(
      name: 'Leche (creada a mano)',
      nutritionPer100: nutrition,
      baseUnit: 'g',
      barcode: '7800000000009',
    );

    final found = await repo.getByBarcode('7800000000009');
    expect(found!.name, 'Leche (creada a mano)');
  });

  test('getByBarcode retorna null si no hay coincidencia', () async {
    final found = await repo.getByBarcode('0000000000000');
    expect(found, isNull);
  });

  test('la búsqueda prioriza el nombre genérico sobre platos preparados '
      'o de marca que contienen la misma palabra', () async {
    // Se insertan en un orden donde el genérico NO es ni el primero ni
    // el que empieza con la búsqueda alfabéticamente, para asegurar que
    // el ranking (no el orden de inserción) es lo que decide.
    await repo.createFood(
      name: "Carrabba's Italian Grill, Pollo Parmesan Sin Pasta",
      nutritionPer100: nutrition,
      baseUnit: 'g',
    );
    await repo.createFood(
      name: 'Pasta Cuatro Quesos, Congelada, Preparada',
      nutritionPer100: nutrition,
      baseUnit: 'g',
    );
    await repo.createFood(
      name: 'Pasta',
      nutritionPer100: nutrition,
      baseUnit: 'g',
    );

    final results = await repo.search('pasta');

    expect(results.first.name, 'Pasta');
  });

  test(
    'la búsqueda con varias palabras las exige todas, en cualquier orden',
    () async {
      await repo.createFood(
        name: 'Pepitas de Zapallo (Semillas de Calabaza), Crudas',
        nutritionPer100: nutrition,
        baseUnit: 'g',
      );
      await repo.createFood(
        name: 'Zapallo italiano, crudo',
        nutritionPer100: nutrition,
        baseUnit: 'g',
      );

      final results = await repo.search('semillas zapallo');

      expect(results.map((f) => f.name), [
        'Pepitas de Zapallo (Semillas de Calabaza), Crudas',
      ]);
    },
  );
}
