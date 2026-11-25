/// Reglas de entrada del título de una tarea.
///
/// Devuelve `null` cuando el valor es válido o el mensaje que verá el usuario.
/// Se mantiene fuera de la interfaz para poder probarlo sin widgets y para que
/// la misma regla se aplique antes de llegar a SQLite.
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
