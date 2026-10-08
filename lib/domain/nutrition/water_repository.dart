abstract class WaterRepository {
  /// Total de mililitros registrados en [date].
  Stream<double> watchTotalForDate(DateTime date);

  Future<void> addWater({required DateTime date, required double milliliters});

  /// Quita el último registro de agua de [date] (si existe). Se usa para
  /// deshacer un "+" por error.
  Future<void> removeLastForDate(DateTime date);
}
