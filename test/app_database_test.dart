import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';

void main() {
  late Directory carpeta;
  late File archivo;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('gestor_tareas_test');
    archivo = File('${carpeta.path}/tareas.sqlite');
  });

  tearDown(() async {
    if (carpeta.existsSync()) {
      await carpeta.delete(recursive: true);
    }
  });

  test('los datos sobreviven al cerrar y reabrir la base', () async {
    final primera = AppDatabase.forTesting(NativeDatabase(archivo));
    final id = await primera.agregarTarea('Sobrevivir al reinicio');
    await primera.agregarTarea('Segunda tarea');
    await primera.cambiarEstado(id, completada: true);
    await primera.close();

    // Segunda conexión al mismo archivo.
    final segunda = AppDatabase.forTesting(NativeDatabase(archivo));
    addTearDown(segunda.close);
    final tareas = await segunda.observarTareas().first;

    expect(tareas.map((t) => t.titulo), ['Sobrevivir al reinicio', 'Segunda tarea']);
    expect(tareas.first.id, id);
    expect(tareas.first.completada, isTrue);
    expect(tareas.last.completada, isFalse);
  });

  test('actualizarTitulo cambia solo la fila indicada', () async {
    final db = AppDatabase.forTesting(NativeDatabase(archivo));
    addTearDown(db.close);

    final uno = await db.agregarTarea('Original uno');
    final dos = await db.agregarTarea('Original dos');

    expect(await db.actualizarTitulo(uno, 'Editada'), isTrue);

    final tareas = await db.observarTareas().first;
    expect(tareas.firstWhere((t) => t.id == uno).titulo, 'Editada');
    expect(tareas.firstWhere((t) => t.id == dos).titulo, 'Original dos');
  });

  test('cambiarEstado alterna completada y pendiente', () async {
    final db = AppDatabase.forTesting(NativeDatabase(archivo));
    addTearDown(db.close);

    final id = await db.agregarTarea('Con estado');

    expect(await db.cambiarEstado(id, completada: true), isTrue);
    expect((await db.observarTareas().first).single.completada, isTrue);

    expect(await db.cambiarEstado(id, completada: false), isTrue);
    expect((await db.observarTareas().first).single.completada, isFalse);
  });

  test('eliminarTarea borra por id y avisa si ya no existe', () async {
    final db = AppDatabase.forTesting(NativeDatabase(archivo));
    addTearDown(db.close);

    final uno = await db.agregarTarea('Se queda');
    final dos = await db.agregarTarea('Se va');

    expect(await db.eliminarTarea(dos), isTrue);
    expect(await db.eliminarTarea(dos), isFalse);

    final tareas = await db.observarTareas().first;
    expect(tareas.map((t) => t.id), [uno]);
  });
}
