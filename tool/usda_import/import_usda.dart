// Herramienta de desarrollo: convierte el CSV oficial de USDA FoodData
// Central (Foundation Foods) en un asset JSON curado y normalizado que se
// empaqueta con la app. No se ejecuta en tiempo de ejecución de AliFit.
//
// Uso: dart run tool/usda_import/import_usda.dart
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

const _datasetDate = '2026-04-30';
// Se incrementa cuando cambia el pipeline (ej. traducciones) aunque el
// dataset de USDA siga siendo el mismo, para forzar reimportación en la app.
const _importVersion = '2026-07-23.2';
const _rawDir =
    'tool/usda_import/raw/FoodData_Central_foundation_food_csv_2026-04-30';
const _translationsPath = 'tool/usda_import/es_translations.json';
const _outputPath = 'assets/data/usda_foundation_foods.json';

// IDs de nutrientes USDA que nos interesan (ver nutrient.csv).
const _idCalories = '1008';
const _idProtein = '1003';
const _idFat = '1004';
const _idCarbs = '1005';
const _idFiber = '1079';
const _idSugarPrimary = '2000';
const _idSugarFallback = '1063';
const _idSodium = '1093';
const _idSaturatedFat = '1258';
const _idCholesterol = '1253';
const _idCalcium = '1087';
const _idIron = '1089';
const _idPotassium = '1092';

Future<List<List<dynamic>>> _readCsv(String path) async {
  final content = await File(path).readAsString();
  return csv.decode(content);
}

String _titleCase(String description) {
  // Normaliza espacios no separables/artefactos de codificación presentes
  // en algunas filas del CSV oficial y colapsa espacios repetidos.
  final cleaned = description
      .replaceAll(' ', ' ')
      .replaceAll('Â', '')
      .replaceAll(
        RegExp(
          r"\s*\(includes foods for usda'?s food distribution program\)",
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r' {2,}'), ' ')
      .trim();
  final lower = cleaned.toLowerCase();
  final buffer = StringBuffer();
  var capitalizeNext = true;
  for (final char in lower.split('')) {
    if (capitalizeNext && RegExp(r'[a-záéíóúñ]').hasMatch(char)) {
      buffer.write(char.toUpperCase());
      capitalizeNext = false;
    } else {
      buffer.write(char);
    }
    if (char == ' ' || char == ',' || char == '(') {
      capitalizeNext = true;
    }
  }
  return buffer.toString();
}

void main() async {
  stdout.writeln('Leyendo diccionario de traducciones...');
  final translations = (jsonDecode(await File(_translationsPath).readAsString())
          as Map<String, dynamic>)
      .cast<String, String>();

  stdout.writeln('Leyendo food_category.csv...');
  final categoryRows = await _readCsv('$_rawDir/food_category.csv');
  final categoryById = <String, String>{};
  for (final row in categoryRows.skip(1)) {
    categoryById[row[0].toString()] = row[2].toString();
  }

  stdout.writeln('Leyendo measure_unit.csv...');
  final measureRows = await _readCsv('$_rawDir/measure_unit.csv');
  final measureNameById = <String, String>{};
  for (final row in measureRows.skip(1)) {
    measureNameById[row[0].toString()] = row[1].toString();
  }

  stdout.writeln('Leyendo food.csv (filtrando foundation_food)...');
  final foodRows = await _readCsv('$_rawDir/food.csv');
  final fdcIds = <String>{};
  final foodMeta = <String, Map<String, String>>{};
  for (final row in foodRows.skip(1)) {
    if (row.length < 4 || row[1].toString() != 'foundation_food') {
      continue;
    }
    final fdcId = row[0].toString();
    fdcIds.add(fdcId);
    final nameEnglish = _titleCase(row[2].toString());
    foodMeta[fdcId] = {
      'nameEnglish': nameEnglish,
      'category': categoryById[row[3].toString()] ?? '',
    };
  }
  stdout.writeln('  -> ${fdcIds.length} alimentos foundation_food.');

  final missingTranslations = <String>{};
  for (final meta in foodMeta.values) {
    if (!translations.containsKey(meta['nameEnglish'])) {
      missingTranslations.add(meta['nameEnglish']!);
    }
  }
  if (missingTranslations.isNotEmpty) {
    stdout.writeln(
      '  ADVERTENCIA: ${missingTranslations.length} nombres sin traducción:',
    );
    for (final name in missingTranslations) {
      stdout.writeln('    - $name');
    }
  }

  stdout.writeln('Leyendo food_nutrient.csv...');
  final nutrientRows = await _readCsv('$_rawDir/food_nutrient.csv');
  final nutrientsByFood = <String, Map<String, double>>{};
  for (final row in nutrientRows.skip(1)) {
    final fdcId = row[1].toString();
    if (!fdcIds.contains(fdcId)) {
      continue;
    }
    final nutrientId = row[2].toString();
    final amount = double.tryParse(row[3].toString());
    if (amount == null) {
      continue;
    }
    (nutrientsByFood[fdcId] ??= {})[nutrientId] = amount;
  }

  stdout.writeln('Leyendo food_portion.csv...');
  final portionRows = await _readCsv('$_rawDir/food_portion.csv');
  final servingsByFood = <String, List<Map<String, Object>>>{};
  for (final row in portionRows.skip(1)) {
    final fdcId = row[1].toString();
    if (!fdcIds.contains(fdcId)) {
      continue;
    }
    final gramWeight = double.tryParse(row[7].toString());
    if (gramWeight == null || gramWeight <= 0) {
      continue;
    }
    final amount = row[3].toString();
    final measureId = row[4].toString();
    final description = row[5].toString();
    final modifier = row[6].toString();
    final unitName = measureNameById[measureId] ?? '';
    String label;
    if (description.trim().isNotEmpty) {
      label = description.trim();
    } else if (modifier.trim().isNotEmpty) {
      label = '$amount $modifier'.trim();
    } else {
      label = '$amount $unitName'.trim();
    }
    (servingsByFood[fdcId] ??= []).add({
      'label': _titleCase(label),
      'gramsEquivalent': gramWeight,
    });
  }

  double? nutrientValue(Map<String, double> nutrients, String id) =>
      nutrients[id];

  final foods = <Map<String, Object?>>[];
  for (final fdcId in fdcIds) {
    final nutrients = nutrientsByFood[fdcId] ?? {};
    final meta = foodMeta[fdcId]!;

    final reportedCalories = nutrientValue(nutrients, _idCalories);
    final protein = nutrientValue(nutrients, _idProtein);
    final fat = nutrientValue(nutrients, _idFat);
    final carbs = nutrientValue(nutrients, _idCarbs);
    final fiber = nutrientValue(nutrients, _idFiber);
    final sugar =
        nutrientValue(nutrients, _idSugarPrimary) ??
        nutrientValue(nutrients, _idSugarFallback);
    final sodium = nutrientValue(nutrients, _idSodium);

    // USDA no siempre reporta energía directamente para foundation_food;
    // cuando falta, se estima con factores Atwater generales (4/9/4
    // kcal por gramo de proteína/grasa/carbohidrato).
    final estimatedCalories = (protein != null && fat != null && carbs != null)
        ? protein * 4 + fat * 9 + carbs * 4
        : null;
    final calories = reportedCalories ?? estimatedCalories;

    final coreValues = [calories, protein, fat, carbs, fiber, sugar, sodium];
    final isComplete = coreValues.every((v) => v != null);

    // Sin energía (ni forma de estimarla) no es útil como alimento
    // registrable: se descarta.
    if (calories == null) {
      continue;
    }

    final nameEnglish = meta['nameEnglish']!;
    final nameEs = translations[nameEnglish] ?? nameEnglish;

    foods.add({
      'sourceId': fdcId,
      'name': nameEs,
      'nameEnglish': nameEnglish,
      'category': meta['category'],
      'baseUnit': 'g',
      'completeness': isComplete ? 'complete' : 'partial',
      'nutrition': {
        'calories': calories,
        'protein': protein ?? 0,
        'fat': fat ?? 0,
        'carbs': carbs ?? 0,
        'fiber': fiber ?? 0,
        'sugar': sugar ?? 0,
        'sodium': sodium ?? 0,
        'saturatedFat': nutrientValue(nutrients, _idSaturatedFat),
        'cholesterol': nutrientValue(nutrients, _idCholesterol),
        'calcium': nutrientValue(nutrients, _idCalcium),
        'iron': nutrientValue(nutrients, _idIron),
        'potassium': nutrientValue(nutrients, _idPotassium),
      },
      'servings': servingsByFood[fdcId] ?? [],
    });
  }

  foods.sort(
    (a, b) => (a['name'] as String).compareTo(b['name'] as String),
  );

  final output = {
    'source': 'usda',
    'dataset': 'FoodData Central - Foundation Foods',
    'datasetDate': _datasetDate,
    'importVersion': _importVersion,
    'attribution':
        'U.S. Department of Agriculture, Agricultural Research Service. '
        'FoodData Central. Dominio público (CC0 1.0). Nombres traducidos '
        'al español para esta app; los valores nutricionales no se '
        'modifican.',
    'foodCount': foods.length,
    'foods': foods,
  };

  final outFile = File(_outputPath);
  await outFile.create(recursive: true);
  await outFile.writeAsString(const JsonEncoder().convert(output));

  stdout.writeln(
    'Listo: ${foods.length} alimentos escritos en $_outputPath '
    '(${(await outFile.length()) ~/ 1024} KB).',
  );
}
