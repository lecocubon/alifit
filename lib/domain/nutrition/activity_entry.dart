class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.date,
    required this.name,
    required this.minutes,
    required this.kcal,
  });

  final int id;
  final DateTime date;
  final String name;
  final int minutes;
  final double kcal;
}

/// Actividades comunes con un gasto calórico aproximado para 30 minutos
/// (valores referenciales basados en tablas MET típicas para una persona
/// de contextura media; el gasto real varía según peso e intensidad).
class ActivityPreset {
  const ActivityPreset({required this.name, required this.kcalPer30Min});

  final String name;
  final double kcalPer30Min;

  static const List<ActivityPreset> all = [
    ActivityPreset(name: 'Caminata', kcalPer30Min: 120),
    ActivityPreset(name: 'Caminata rápida', kcalPer30Min: 150),
    ActivityPreset(name: 'Trote / correr', kcalPer30Min: 300),
    ActivityPreset(name: 'Bicicleta', kcalPer30Min: 220),
    ActivityPreset(name: 'Natación', kcalPer30Min: 230),
    ActivityPreset(name: 'Pesas / musculación', kcalPer30Min: 180),
    ActivityPreset(name: 'Yoga', kcalPer30Min: 95),
    ActivityPreset(name: 'Baile', kcalPer30Min: 200),
    ActivityPreset(name: 'Fútbol', kcalPer30Min: 260),
    ActivityPreset(name: 'Tareas del hogar', kcalPer30Min: 100),
  ];
}
