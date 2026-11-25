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
/// Elige el ejecutor según la plataforma: archivo nativo o WebAssembly.
@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_abrirConexion());

  /// Constructor para pruebas: recibe un ejecutor en memoria.
  AppDatabase.forTesting(super.ejecutor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _abrirConexion() {
    return driftDatabase(
      name: 'gestor_tareas',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  /// Todas las tareas, ordenadas por id.
  ///
  /// Emite la lista completa cada vez que cambia la tabla.
  Stream<List<Tarea>> observarTareas() {
    final consulta = select(tareas)..orderBy([(t) => OrderingTerm(expression: t.id)]);
    return consulta.watch();
  }

  /// Guarda una tarea nueva y devuelve el id asignado por SQLite.
  Future<int> agregarTarea(String titulo) {
    return into(tareas).insert(TareasCompanion.insert(titulo: titulo));
  }

  /// Cambia el título de una tarea existente.
  ///
  /// Devuelve `false` si el id ya no existe.
  Future<bool> actualizarTitulo(int id, String titulo) async {
    final filas = await (update(tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(titulo: Value(titulo)));
    return filas > 0;
  }

  /// Marca una tarea como completada o pendiente.
  Future<bool> cambiarEstado(int id, {required bool completada}) async {
    final filas = await (update(tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(completada: Value(completada)));
    return filas > 0;
  }

  /// Elimina por id.
  Future<bool> eliminarTarea(int id) async {
    final filas = await (delete(tareas)..where((t) => t.id.equals(id))).go();
    return filas > 0;
  }
}
