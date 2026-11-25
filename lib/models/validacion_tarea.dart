/// Reglas de entrada del título de una tarea.
///
/// Devuelve `null` cuando el valor es válido o el mensaje que verá el usuario.
String? validarTitulo(String? valor) {
  final titulo = valor?.trim() ?? '';

  if (titulo.isEmpty) {
    return 'Escribe un título para la tarea';
  }
  if (titulo.length > 200) {
    return 'El título no puede pasar de 200 caracteres';
  }
  return null;
}
