import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/models/validacion_tarea.dart';

void main() {
  test('validarTitulo rechaza vacios y solo espacios', () {
    expect(validarTitulo(''), isNotNull);
    expect(validarTitulo('   '), isNotNull);
    expect(validarTitulo(null), isNotNull);
  });

  test('validarTitulo acepta texto normal y recortado', () {
    expect(validarTitulo('Comprar leche'), isNull);
    expect(validarTitulo('  Comprar leche  '), isNull);
  });

  test('validarTitulo limita a 200 caracteres', () {
    expect(validarTitulo('a' * 200), isNull);
    expect(validarTitulo('a' * 201), isNotNull);
  });
}
