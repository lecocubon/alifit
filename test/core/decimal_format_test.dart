import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/core/text/decimal_format.dart';

void main() {
  group('parseDecimalEs', () {
    test('acepta coma y punto como separador decimal', () {
      expect(parseDecimalEs('13,4'), 13.4);
      expect(parseDecimalEs('13.4'), 13.4);
    });

    test('ignora espacios y acepta enteros', () {
      expect(parseDecimalEs('  89,5 '), 89.5);
      expect(parseDecimalEs('160'), 160);
    });

    test('devuelve null si no es un número', () {
      expect(parseDecimalEs(null), isNull);
      expect(parseDecimalEs(''), isNull);
      expect(parseDecimalEs('abc'), isNull);
    });
  });

  group('formatDecimalEs', () {
    test('usa coma decimal y omite los ceros sobrantes', () {
      expect(formatDecimalEs(3), '3');
      expect(formatDecimalEs(2.5), '2,5');
      expect(formatDecimalEs(13.4), '13,4');
    });
  });
}
