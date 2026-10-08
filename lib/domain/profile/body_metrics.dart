import 'dart:math';

import 'biological_sex.dart';

class BodyMetrics {
  BodyMetrics._();

  static double? bmi({required double? heightCm, required double? weightKg}) {
    if (heightCm == null || weightKg == null || heightCm <= 0) {
      return null;
    }
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Peso normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  /// % de grasa corporal por el método de circunferencias de la Marina de
  /// EE. UU. (Navy method). Todas las medidas en centímetros.
  static double? bodyFatPercentNavy({
    required BiologicalSex sex,
    required double heightCm,
    required double neckCm,
    required double waistCm,
    double? hipCm,
  }) {
    if (heightCm <= 0 || neckCm <= 0 || waistCm <= 0) {
      return null;
    }
    if (sex == BiologicalSex.male) {
      if (waistCm <= neckCm) {
        return null;
      }
      final value =
          495 /
              (1.0324 -
                  0.19077 * log(waistCm - neckCm) / ln10 +
                  0.15456 * log(heightCm) / ln10) -
          450;
      return value;
    }

    if (hipCm == null || (waistCm + hipCm) <= neckCm) {
      return null;
    }
    final value =
        495 /
            (1.29579 -
                0.35004 * log(waistCm + hipCm - neckCm) / ln10 +
                0.22100 * log(heightCm) / ln10) -
        450;
    return value;
  }

  static String bodyFatCategory(BiologicalSex sex, double percent) {
    final thresholds = sex == BiologicalSex.male
        ? const [5.0, 13.0, 17.0, 24.0]
        : const [13.0, 20.0, 24.0, 31.0];
    const labels = [
      'Grasa esencial',
      'Nivel atlético',
      'Nivel fitness',
      'Aceptable',
      'Sobre lo recomendado',
    ];
    for (var i = 0; i < thresholds.length; i++) {
      if (percent < thresholds[i]) {
        return labels[i];
      }
    }
    return labels.last;
  }
}
