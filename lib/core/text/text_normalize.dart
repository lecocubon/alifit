const _accented = 'áàäâãéèëêíìïîóòöôõúùüûñç';
const _plain = 'aaaaaeeeeiiiiooooouuuunc';

/// Normaliza texto para comparación/búsqueda: minúsculas y sin tildes.
String normalizeForSearch(String input) {
  final lower = input.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final index = _accented.indexOf(char);
    buffer.write(index == -1 ? char : _plain[index]);
  }
  return buffer.toString();
}
