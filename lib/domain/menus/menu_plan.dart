class MenuPlan {
  const MenuPlan({
    required this.id,
    required this.label,
    required this.startDate,
    required this.createdAt,
  });

  final int id;
  final String label;
  final DateTime startDate;
  final DateTime createdAt;

  DateTime get endDate => startDate.add(const Duration(days: 6));
}
