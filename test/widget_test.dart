import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/main.dart';
import 'package:gestor_tareas_local/models/validacion_tarea.dart';

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(GestorTareasApp(database: db));
    await tester.pumpAndSettle();

    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(EditableText), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);

    // Al desmontar la pantalla se cancelan los streams de Drift; los pumps
    // extra dejan correr los temporizadores pendientes y evitan el falso fallo.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  test('validarTitulo rechaza vacios y solo espacios', () {
    expect(validarTitulo(''), isNotNull);
    expect(validarTitulo('   '), isNotNull);
    expect(validarTitulo(null), isNotNull);
    expect(validarTitulo('Comprar leche'), isNull);
    expect(validarTitulo('  Comprar leche  '), isNull);
  });

  test('agregarTarea guarda y devuelve un id', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final id = await db.agregarTarea('Estudiar SQLite');
    final tareas = await db.observarTareas().first;

    expect(id, greaterThan(0));
    expect(tareas, hasLength(1));
    expect(tareas.single.titulo, 'Estudiar SQLite');
    expect(tareas.single.completada, isFalse);
  });
}
