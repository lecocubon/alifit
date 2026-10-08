import 'package:flutter/material.dart';

import '../../domain/nutri_guide/nutri_guide.dart';

Color nutriQualityColor(BuildContext context, NutriQuality quality) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (quality) {
    NutriQuality.saludable =>
      dark ? Colors.green.shade300 : Colors.green.shade700,
    NutriQuality.igModerado =>
      dark ? Colors.amber.shade300 : Colors.amber.shade800,
    NutriQuality.igAlto =>
      dark ? Colors.deepOrange.shade300 : Colors.deepOrange.shade700,
    NutriQuality.pocoSaludable =>
      dark ? Colors.red.shade300 : Colors.red.shade700,
    NutriQuality.altoRiesgo =>
      dark ? Colors.purple.shade200 : Colors.purple.shade800,
  };
}

IconData nutriQualityIcon(NutriQuality quality) => switch (quality) {
  NutriQuality.saludable => Icons.check_circle_outline,
  NutriQuality.igModerado => Icons.error_outline,
  NutriQuality.igAlto => Icons.error,
  NutriQuality.pocoSaludable => Icons.warning_amber_rounded,
  NutriQuality.altoRiesgo => Icons.dangerous_outlined,
};

/// Etiqueta de color con ícono para una [NutriQuality].
class QualityBadge extends StatelessWidget {
  const QualityBadge({super.key, required this.quality});

  final NutriQuality quality;

  @override
  Widget build(BuildContext context) {
    final color = nutriQualityColor(context, quality);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(nutriQualityIcon(quality), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            quality.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
