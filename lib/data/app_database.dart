import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Tabla de tareas.
///
/// SQLite no tiene un tipo booleano nativo: [completada] se guarda como entero
/// 0/1 y Drift lo expone como `bool`. El `id` es autoincremental y lo asigna la
/// base de datos.
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get titulo => text().withLength(min: 1, max: 200)();

  BoolColumn get completada => boolean().withDefault(const Constant(false))();

  DateTimeColumn get creadaEn => dateTime().withDefault(currentDateAndTime)();
}

/// Base de datos local de la aplicación.
///
/// Una sola clase sirve para Android, Linux y web: `driftDatabase` elige el
/// motor adecuado en cada plataforma (archivo SQLite nativo o WebAssembly con
/// respaldo en el navegador).
@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_abrirConexion());

  /// Constructor para pruebas: recibe un ejecutor en memoria.
  AppDatabase.forTesting(super.ejecutor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _abrirConexion() {
    return driftDatabase(name: 'gestor_tareas');
  }
}
