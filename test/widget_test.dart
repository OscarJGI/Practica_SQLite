import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/main.dart';

/// Base en memoria para las pruebas de interfaz.
Future<AppDatabase> montarApp(WidgetTester tester) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await tester.pumpWidget(GestorTareasApp(database: db));
  await tester.pumpAndSettle();
  return db;
}

/// Desmonta la pantalla y espera a que drift cierre sus streams.
Future<void> desmontar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    await montarApp(tester);

    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(EditableText), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);

    await desmontar(tester);
  });

  testWidgets('Un titulo vacio no crea tarea y muestra aviso', (tester) async {
    final db = await montarApp(tester);

    await tester.enterText(find.byType(TextField), '    ');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe un título para la tarea'), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
    final tareas = await tester.runAsync(() => db.observarTareas().first);
    expect(tareas, isEmpty);

    await desmontar(tester);
  });

  testWidgets('Agregar desde la interfaz muestra la tarea en la lista',
      (tester) async {
    final db = await montarApp(tester);

    await tester.enterText(find.byType(TextField), 'Estudiar SQLite');
    await tester.tap(find.text('Agregar tarea'));
    await tester.pumpAndSettle();

    expect(find.text('Estudiar SQLite'), findsOneWidget);
    expect(find.textContaining('Pendiente'), findsOneWidget);
    final tareas = await tester.runAsync(() => db.observarTareas().first);
    expect(tareas, hasLength(1));

    await desmontar(tester);
  });
}
