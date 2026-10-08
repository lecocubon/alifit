import 'shopping_category.dart';

/// Clasifica un alimento en una categoría de compras a partir de palabras
/// clave en su nombre (reglas simples, sin IA).
ShoppingCategory categorizeFood(String foodName) {
  final normalized = foodName.toLowerCase();
  bool has(List<String> keywords) => keywords.any(normalized.contains);

  if (has(['congelad'])) {
    return ShoppingCategory.congelados;
  }
  if (has([
    'pollo',
    'carne',
    'vacuno',
    'cerdo',
    'pescado',
    'atún',
    'atun',
    'pavo',
    'jamón',
    'jamon',
    'vienesa',
    'longaniza',
    'chorizo',
    'salmón',
    'salmon',
    'merluza',
    'huevo',
  ])) {
    return ShoppingCategory.carnes;
  }
  if (has([
    'leche',
    'queso',
    'yogur',
    'yoghurt',
    'mantequilla',
    'crema',
    'manjar',
  ])) {
    return ShoppingCategory.lacteos;
  }
  if (has([
    'pan',
    'marraqueta',
    'hallulla',
    'amasado',
    'tortilla',
    'sopaipilla',
  ])) {
    return ShoppingCategory.panaderia;
  }
  if (has([
    'manzana',
    'plátano',
    'platano',
    'naranja',
    'palta',
    'tomate',
    'lechuga',
    'zanahoria',
    'cebolla',
    'papa',
    'zapallo',
    'choclo',
    'fruta',
    'verdura',
    'espinaca',
    'brócoli',
    'brocoli',
    'pepino',
    'limón',
    'limon',
    'uva',
    'sandía',
    'sandia',
    'melón',
    'melon',
  ])) {
    return ShoppingCategory.frutasYVerduras;
  }
  if (has([
    'arroz',
    'fideo',
    'tallarin',
    'tallarín',
    'lenteja',
    'poroto',
    'garbanzo',
    'avena',
    'harina',
    'azúcar',
    'azucar',
    'aceite',
    'sal',
    'condimento',
    'conserva',
  ])) {
    return ShoppingCategory.despensa;
  }
  return ShoppingCategory.otros;
}
