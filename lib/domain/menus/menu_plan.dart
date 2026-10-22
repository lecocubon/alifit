import '../../core/time/calendar_days.dart';

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

  DateTime get endDate => addDays(startDate, 6);
}
