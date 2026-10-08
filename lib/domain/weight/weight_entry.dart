class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.measuredAt,
    required this.weightKg,
    this.notes,
  });

  final int id;
  final DateTime measuredAt;
  final double weightKg;
  final String? notes;
}
