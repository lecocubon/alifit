import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/database_provider.dart';
import 'chile_food_seeder.dart';
import 'recipe_seeder.dart';
import 'sr_legacy_importer.dart';
import 'usda_importer.dart';

/// Importa el catálogo completo de USDA (básico + SR Legacy, como un único
/// catálogo sin activación manual), siembra la capa local chilena
/// (sinónimos y alimentos propios) y luego el recetario propio de la app,
/// en ese orden porque tanto los alias como las recetas dependen de que
/// los alimentos de USDA ya existan.
final catalogSetupProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await UsdaImporter(db).importIfNeeded();
  await SrLegacyImporter(db).importIfNeeded();
  await ChileFoodSeeder(db).seedIfNeeded();
  await RecipeSeeder(db).seedIfNeeded();
});

final usdaDatasetInfoProvider = FutureProvider<UsdaDatasetInfo>((ref) {
  return loadUsdaDatasetInfo();
});
