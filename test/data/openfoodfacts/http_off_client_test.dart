import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:alifit/data/openfoodfacts/http_off_client.dart';
import 'package:alifit/domain/openfoodfacts/off_client.dart';

http.Response _jsonResponse(Map<String, dynamic> body, {int status = 200}) {
  return http.Response(jsonEncode(body), status);
}

void main() {
  test('parsea un producto completo correctamente', () async {
    final client = HttpOffClient(
      client: MockClient((request) async {
        expect(request.url.path, contains('7890123456789'));
        return _jsonResponse({
          'status': 1,
          'product': {
            'product_name': 'Leche Descremada',
            'brands': 'Soprole, Otra marca',
            'countries': 'Chile',
            'nutriments': {
              'energy-kcal_100g': 35,
              'carbohydrates_100g': 5,
              'proteins_100g': 3.4,
              'fat_100g': 0.1,
              'fiber_100g': 0,
              'sugars_100g': 5,
              'sodium_100g': 0.05,
            },
          },
        });
      }),
    );

    final product = await client.fetchProduct('7890123456789');

    expect(product.name, 'Leche Descremada');
    expect(product.brand, 'Soprole');
    expect(product.country, 'Chile');
    expect(product.nutritionPer100.calories, 35);
    // 0.05 g de sodio -> 50 mg.
    expect(product.nutritionPer100.sodium, 50);
    expect(product.missingFields, isEmpty);
    expect(product.isComplete, isTrue);
    expect(product.inconsistencyWarning, isNull);
  });

  test(
    'marca como faltantes los nutrientes que no vienen en la respuesta',
    () async {
      final client = HttpOffClient(
        client: MockClient((request) async {
          return _jsonResponse({
            'status': 1,
            'product': {
              'product_name': 'Producto incompleto',
              'nutriments': {'energy-kcal_100g': 100},
            },
          });
        }),
      );

      final product = await client.fetchProduct('123');

      expect(product.isComplete, isFalse);
      expect(product.missingFields, contains('carbohidratos'));
      expect(product.missingFields, contains('sodio'));
    },
  );

  test('lanza OffNotFoundException si el producto no existe', () async {
    final client = HttpOffClient(
      client: MockClient((request) async {
        return _jsonResponse({'status': 0});
      }),
    );

    expect(
      () => client.fetchProduct('000'),
      throwsA(isA<OffNotFoundException>()),
    );
  });

  test('lanza OffNetworkException si el servidor responde con error', () async {
    final client = HttpOffClient(
      client: MockClient((request) async {
        return http.Response('', 500);
      }),
    );

    expect(
      () => client.fetchProduct('000'),
      throwsA(isA<OffNetworkException>()),
    );
  });

  test('lanza OffNetworkException si no hay conexión', () async {
    final client = HttpOffClient(
      client: MockClient((request) async {
        throw Exception('Sin conexión');
      }),
    );

    expect(
      () => client.fetchProduct('000'),
      throwsA(isA<OffNetworkException>()),
    );
  });

  test('advierte si el valor calórico es inusualmente alto', () async {
    final client = HttpOffClient(
      client: MockClient((request) async {
        return _jsonResponse({
          'status': 1,
          'product': {
            'product_name': 'Dato sospechoso',
            'nutriments': {
              'energy-kcal_100g': 1200,
              'carbohydrates_100g': 10,
              'proteins_100g': 5,
              'fat_100g': 2,
              'fiber_100g': 1,
              'sugars_100g': 1,
              'sodium_100g': 0.01,
            },
          },
        });
      }),
    );

    final product = await client.fetchProduct('000');

    expect(product.inconsistencyWarning, isNotNull);
  });

  test('acepta nutrientes que vienen como texto o vacíos', () async {
    final client = HttpOffClient(
      client: MockClient((request) async {
        return _jsonResponse({
          'status': 1,
          'product': {
            'product_name': 'Galletas',
            'brands': 12345,
            'nutriments': {
              'energy-kcal_100g': '450',
              'carbohydrates_100g': '68,5',
              'proteins_100g': 7,
              'fat_100g': '',
              'fiber_100g': null,
              'sugars_100g': '30.2',
              'sodium_100g': '0.4',
            },
          },
        });
      }),
    );

    final product = await client.fetchProduct('111');

    expect(product.nutritionPer100.calories, 450);
    expect(product.nutritionPer100.carbs, 68.5);
    expect(product.nutritionPer100.sugar, 30.2);
    expect(product.nutritionPer100.sodium, closeTo(400, 0.001));
    expect(product.brand, isNull);
    expect(product.missingFields, containsAll(['grasas', 'fibra']));
  });
}
