import 'dart:math';

/// Una versión de AliFit publicada para descargar.
class AppRelease {
  const AppRelease({required this.version, required this.apkUrl, this.notes});

  /// Sin la "v" inicial, ej. "1.2.0".
  final String version;
  final String apkUrl;
  final String? notes;
}

/// true si [candidate] es una versión más nueva que [current]. Acepta "v"
/// inicial y número de compilación ("v1.2.0", "1.1.0+2").
bool isNewerVersion(String candidate, String current) {
  List<int> parts(String version) => version
      .replaceFirst(RegExp(r'^v'), '')
      .split('+')
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();

  final a = parts(candidate);
  final b = parts(current);
  for (var i = 0; i < max(a.length, b.length); i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) {
      return x > y;
    }
  }
  return false;
}
