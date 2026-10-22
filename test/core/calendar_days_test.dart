import 'package:flutter_test/flutter_test.dart';

import 'package:alifit/core/time/calendar_days.dart';

void main() {
  test('avanza el sábado de 25 horas de abril (fin del horario de verano)', () {
    expect(addDays(DateTime(2027, 4, 3), 1), DateTime(2027, 4, 4));
  });

  test('retrocede sin saltarse el domingo de septiembre (inicio del horario '
      'de verano)', () {
    final previous = addDays(DateTime(2026, 9, 7), -1);
    expect((previous.year, previous.month, previous.day), (2026, 9, 6));
  });

  test('cruza meses y años', () {
    expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
    expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
  });

  test('descarta la hora', () {
    expect(addDays(DateTime(2026, 10, 22, 18, 30), 0), DateTime(2026, 10, 22));
  });
}
