import 'package:drift/drift.dart';

extension WatchTables on GeneratedDatabase {
  /// Emite al suscribirse y cada vez que cambia alguna de [tables].
  ///
  /// Sirve para consultas que arman su resultado leyendo varias tablas
  /// (una comida con sus alimentos, una receta con sus ingredientes): un
  /// `select(...).watch()` normal solo reacciona a la tabla principal.
  ///
  /// Drift comparte entre sí las consultas en vivo que tienen el mismo SQL,
  /// sin mirar `readsFrom`. Por eso el SQL lleva los nombres de las tablas:
  /// si fuera siempre el mismo, dos pantallas que observan tablas distintas
  /// terminarían usando un solo stream y una de ellas dejaría de
  /// actualizarse.
  Stream<void> watchTables(Set<ResultSetImplementation> tables) {
    final names = tables.map((t) => t.entityName).toList()..sort();
    return customSelect(
      "SELECT '${names.join(',')}' AS tablas",
      readsFrom: tables,
    ).watch().map((_) {});
  }
}
