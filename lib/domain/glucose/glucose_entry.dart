import 'glucose_context.dart';

class GlucoseEntry {
  const GlucoseEntry({
    required this.id,
    required this.measuredAt,
    required this.value,
    required this.context,
    this.relatedMealId,
    this.relatedMealLabel,
    this.hoursAfterMeal,
    this.physicalActivity,
    this.symptoms,
    this.medicationNote,
    this.notes,
  });

  final int id;
  final DateTime measuredAt;

  /// mg/dL.
  final double value;
  final GlucoseContext context;
  final int? relatedMealId;
  final String? relatedMealLabel;
  final double? hoursAfterMeal;
  final String? physicalActivity;
  final String? symptoms;
  final String? medicationNote;
  final String? notes;
}

class GlucoseRange {
  const GlucoseRange({required this.low, required this.high});

  final double low;
  final double high;

  bool isWithinRange(double value) => value >= low && value <= high;
}

class GlucoseStats {
  const GlucoseStats({
    required this.average,
    required this.min,
    required this.max,
    required this.count,
  });

  const GlucoseStats.empty() : average = 0, min = 0, max = 0, count = 0;

  final double average;
  final double min;
  final double max;
  final int count;
}
