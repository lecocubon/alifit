import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/nutrition/nutrition_values.dart';
import '../../domain/openfoodfacts/off_client.dart';
import '../../domain/openfoodfacts/off_product.dart';

/// Cliente de Open Food Facts: solo lectura, sin credenciales. No escribe
/// productos ni sube fotografías (fuera de alcance del MVP).
class HttpOffClient implements OffClient {
  HttpOffClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _fields = 'product_name,brands,countries,nutriments';

  @override
  Future<OffProduct> fetchProduct(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
      '?fields=$_fields',
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'User-Agent': 'AliFit - Flutter - Android'})
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw OffNetworkException('No se pudo conectar con Open Food Facts: $e');
    }

    if (response.statusCode != 200) {
      throw OffNetworkException(
        'Open Food Facts respondió con un error (${response.statusCode}).',
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const OffNetworkException('Respuesta inválida de Open Food Facts.');
    }

    final product = body['product'] as Map<String, dynamic>?;
    if (body['status'] != 1 || product == null) {
      throw OffNotFoundException(barcode);
    }

    return _parseProduct(barcode, product);
  }

  OffProduct _parseProduct(String barcode, Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    final missing = <String>[];

    // Algunos productos traen los valores como texto ("12.5") o vacíos.
    double? readNutrient(String key, String label) {
      final value = switch (nutriments[key]) {
        final num number => number.toDouble(),
        final String text => double.tryParse(text.replaceAll(',', '.')),
        _ => null,
      };
      if (value == null) {
        missing.add(label);
      }
      return value;
    }

    // Open Food Facts entrega los nutrientes normalizados "por 100g/100ml"
    // bajo claves con sufijo "_100g".
    final calories = readNutrient('energy-kcal_100g', 'calorías');
    final carbs = readNutrient('carbohydrates_100g', 'carbohidratos');
    final protein = readNutrient('proteins_100g', 'proteínas');
    final fat = readNutrient('fat_100g', 'grasas');
    final fiber = readNutrient('fiber_100g', 'fibra');
    final sugar = readNutrient('sugars_100g', 'azúcares');
    final sodiumGrams = readNutrient('sodium_100g', 'sodio');

    final nutrition = NutritionValues(
      calories: calories ?? 0,
      carbs: carbs ?? 0,
      protein: protein ?? 0,
      fat: fat ?? 0,
      fiber: fiber ?? 0,
      sugar: sugar ?? 0,
      // La app guarda el sodio en mg; Open Food Facts lo entrega en g.
      sodium: sodiumGrams == null ? 0 : sodiumGrams * 1000,
    );

    final warning = _validate(calories, carbs, protein, fat);

    final rawName = _textOf(product['product_name'])?.trim();
    final hasName = rawName != null && rawName.isNotEmpty;
    if (!hasName) {
      missing.add('nombre');
    }

    return OffProduct(
      barcode: barcode,
      name: hasName ? rawName : 'Producto sin nombre',
      brand: _firstOf(_textOf(product['brands'])),
      country: _firstOf(_textOf(product['countries'])),
      nutritionPer100: nutrition,
      fetchedAt: DateTime.now(),
      missingFields: missing,
      inconsistencyWarning: warning,
    );
  }

  String? _textOf(Object? value) => value is String ? value : null;

  String? _firstOf(String? commaSeparated) {
    if (commaSeparated == null || commaSeparated.trim().isEmpty) {
      return null;
    }
    return commaSeparated.split(',').first.trim();
  }

  /// Reglas simples de validación (no considera todos los registros de
  /// Open Food Facts igualmente confiables, según lo pedido en la spec).
  String? _validate(
    double? calories,
    double? carbs,
    double? protein,
    double? fat,
  ) {
    if (calories != null && calories > 900) {
      return 'El valor calórico declarado (${calories.round()} kcal/100g) '
          'es inusualmente alto; revisa el dato antes de guardarlo.';
    }
    if (calories != null &&
        calories > 0 &&
        carbs != null &&
        protein != null &&
        fat != null) {
      final estimated = carbs * 4 + protein * 4 + fat * 9;
      final relativeDifference = (calories - estimated).abs() / calories;
      if (relativeDifference > 0.35) {
        return 'Las calorías declaradas no calzan con los macronutrientes '
            'informados; revisa el dato antes de guardarlo.';
      }
    }
    return null;
  }
}
