// Herramienta de desarrollo: convierte el CSV oficial de USDA SR Legacy
// (paquete ampliado, ~7.800 alimentos) en un asset JSON, traduciendo los
// nombres al español mediante diccionario (frases exactas conocidas +
// traducción palabra por palabra). No es tan precisa como la traducción a
// mano de Foundation Foods, pero da cobertura completa. Este asset se
// empaqueta en la app pero solo se importa si el usuario activa el
// "catálogo ampliado" desde Configuración (no se descarga aparte porque
// el proyecto no cuenta con hosting propio; ver justificación en el
// informe de la sesión).
//
// Uso: dart run tool/usda_import/import_sr_legacy.dart
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

const _datasetDate = '2018-04-01';
const _importVersion = '2026-07-23.1';
const _rawDir = 'tool/usda_import/raw_sr_legacy/FoodData_Central_sr_legacy_food_csv_2018-04';
const _phraseDictPath = 'tool/usda_import/es_translations.json';
const _wordDictPath = 'tool/usda_import/es_word_dictionary.json';
const _outputPath = 'assets/data/usda_sr_legacy_extended.json';

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

String _cleanRaw(String description) {
  return description
      .replaceAll(' ', ' ')
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
}

String _titleCase(String cleaned) {
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

/// Traductor por diccionario: intenta frases completas conocidas primero,
/// luego traduce segmento por segmento (separados por coma) probando
/// coincidencias de frase (2-3 palabras) antes de palabra por palabra.
/// Palabras sin traducción conocida quedan en inglés (mejor que perderlas).
class DictionaryTranslator {
  DictionaryTranslator(this._phrases, this._words);

  final Map<String, String> _phrases;
  final Map<String, String> _words;

  String translate(String englishNameCleaned) {
    final exact = _phrases[englishNameCleaned];
    if (exact != null) {
      return exact;
    }

    final segments = englishNameCleaned.split(',').map((s) => s.trim());
    final translatedSegments = segments
        .where((s) => s.isNotEmpty)
        .map(_translateSegment);
    return _titleCase(translatedSegments.join(', '));
  }

  String _translateSegment(String segment) {
    final lower = segment.toLowerCase().replaceAll(RegExp(r'["]'), '');
    final words = lower.split(RegExp(r'\s+'));
    final result = <String>[];
    var i = 0;
    while (i < words.length) {
      var matched = false;
      // Intenta ventanas de 3, luego 2, luego 1 palabra.
      for (final windowSize in [3, 2, 1]) {
        if (i + windowSize > words.length) continue;
        final window = words.sublist(i, i + windowSize).join(' ');
        final translation = _words[window];
        if (translation != null) {
          result.add(translation);
          i += windowSize;
          matched = true;
          break;
        }
      }
      if (!matched) {
        // Sin traducción conocida: se deja la palabra original.
        result.add(words[i]);
        i++;
      }
    }
    return result.join(' ');
  }
}

void main() async {
  stdout.writeln('Leyendo diccionarios de traducción...');
  final phrases = (jsonDecode(await File(_phraseDictPath).readAsString())
          as Map<String, dynamic>)
      .cast<String, String>();
  final words = (jsonDecode(await File(_wordDictPath).readAsString())
          as Map<String, dynamic>)
      .cast<String, String>();
  final translator = DictionaryTranslator(phrases, words);

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

  stdout.writeln('Leyendo food.csv (filtrando sr_legacy_food)...');
  final foodRows = await _readCsv('$_rawDir/food.csv');
  final fdcIds = <String>{};
  final foodMeta = <String, Map<String, String>>{};
  for (final row in foodRows.skip(1)) {
    if (row.length < 4 || row[1].toString() != 'sr_legacy_food') {
      continue;
    }
    final fdcId = row[0].toString();
    fdcIds.add(fdcId);
    final nameEnglish = _titleCase(_cleanRaw(row[2].toString()));
    foodMeta[fdcId] = {
      'nameEnglish': nameEnglish,
      'category': categoryById[row[3].toString()] ?? '',
    };
  }
  stdout.writeln('  -> ${fdcIds.length} alimentos sr_legacy_food.');

  stdout.writeln('Leyendo food_nutrient.csv (puede tardar)...');
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
      'label': _titleCase(_cleanRaw(label)),
      'gramsEquivalent': gramWeight,
    });
  }

  double? nutrientValue(Map<String, double> nutrients, String id) =>
      nutrients[id];

  final foods = <Map<String, Object?>>[];
  var translatedByPhrase = 0;
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

    final estimatedCalories = (protein != null && fat != null && carbs != null)
        ? protein * 4 + fat * 9 + carbs * 4
        : null;
    final calories = reportedCalories ?? estimatedCalories;

    final coreValues = [calories, protein, fat, carbs, fiber, sugar, sodium];
    final isComplete = coreValues.every((v) => v != null);

    if (calories == null) {
      continue;
    }

    final nameEnglish = meta['nameEnglish']!;
    if (phrases.containsKey(nameEnglish)) {
      translatedByPhrase++;
    }
    final nameEs = translator.translate(nameEnglish);

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

  foods.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

  final output = {
    'source': 'usda',
    'dataset': 'FoodData Central - SR Legacy (paquete ampliado)',
    'datasetDate': _datasetDate,
    'importVersion': _importVersion,
    'attribution':
        'U.S. Department of Agriculture, Agricultural Research Service. '
        'FoodData Central, SR Legacy (abril 2018, última versión de este '
        'dataset). Dominio público (CC0 1.0). Nombres traducidos al '
        'español mediante diccionario automático (no revisado a mano '
        'como el catálogo básico); los valores nutricionales no se '
        'modifican.',
    'foodCount': foods.length,
    'foods': foods,
  };

  final outFile = File(_outputPath);
  await outFile.create(recursive: true);
  await outFile.writeAsString(const JsonEncoder().convert(output));

  stdout.writeln(
    'Listo: ${foods.length} alimentos escritos en $_outputPath '
    '(${(await outFile.length()) ~/ 1024} KB). '
    '$translatedByPhrase con traducción exacta conocida, '
    '${foods.length - translatedByPhrase} vía diccionario de palabras.',
  );
}
