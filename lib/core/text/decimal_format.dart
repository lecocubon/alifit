/// Lee un número escrito por el usuario aceptando coma o punto como
/// separador decimal ("13,4" y "13.4" dan lo mismo). Devuelve null si el
/// texto no es un número válido.
double? parseDecimalEs(String? text) {
  if (text == null) {
    return null;
  }
  return double.tryParse(text.trim().replaceAll(',', '.'));
}

/// Formatea un número con coma decimal (convención chilena) y sin ceros
/// sobrantes: 3 -> "3", 2.5 -> "2,5".
String formatDecimalEs(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
