import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/validacion_tarea.dart';

/// Pantalla principal del gestor de tareas.
///
/// Etapa 3: alta y consulta desde SQLite. La lista se alimenta de un [Stream]
/// de Drift, por lo que se refresca sola después de cada escritura.
class TareasPage extends StatefulWidget {
  const TareasPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();
  late final Stream<List<Tarea>> _tareas;

  @override
  void initState() {
    super.initState();
    _tareas = widget.database.observarTareas();
  }

  Future<void> _agregarTarea() async {
    final error = validarTitulo(_tituloController.text);
    if (error != null) {
      _avisar(error);
      return;
    }

    try {
      await widget.database.agregarTarea(_tituloController.text.trim());
      _tituloController.clear();
    } catch (e) {
      _avisar('No se pudo guardar la tarea: $e');
    }
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    try {
      final actualizada = await widget.database.cambiarEstado(
        tarea.id,
        completada: completada,
      );
      if (!actualizada) {
        _avisar('Esa tarea ya no existe');
      }
    } catch (e) {
      _avisar('No se pudo cambiar el estado: $e');
    }
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final titulo = await _pedirTitulo(tarea.titulo);
    if (titulo == null) return;

    try {
      final actualizada = await widget.database.actualizarTitulo(
        tarea.id,
        titulo,
      );
      if (!actualizada) {
        _avisar('Esa tarea ya no existe');
      }
    } catch (e) {
      _avisar('No se pudo editar la tarea: $e');
    }
  }

  Future<String?> _pedirTitulo(String tituloActual) {
    final controller = TextEditingController(text: tituloActual);
    String? error;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void guardar() {
              final mensaje = validarTitulo(controller.text);
              if (mensaje != null) {
                setStateDialog(() => error = mensaje);
                return;
              }
              Navigator.of(context).pop(controller.text.trim());
            }

            return AlertDialog(
              title: const Text('Editar título'),
              content: TextField(
                controller: controller,
                autofocus: true,
                onSubmitted: (_) => guardar(),
                decoration: InputDecoration(
                  labelText: 'Título',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(onPressed: guardar, child: const Text('Guardar')),
              ],
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${tarea.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      final eliminada = await widget.database.eliminarTarea(tarea.id);
      if (!eliminada) {
        _avisar('Esa tarea ya no existe');
      }
    } catch (e) {
      _avisar('No se pudo eliminar la tarea: $e');
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    widget.database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _agregarTarea(),
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(child: _listaTareas()),
          ],
        ),
      ),
    );
  }

  Widget _listaTareas() {
    return StreamBuilder<List<Tarea>>(
      stream: _tareas,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error al leer la base: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tareas = snapshot.data!;
        if (tareas.isEmpty) {
          return const Center(child: Text('Todavía no hay tareas guardadas'));
        }

        return ListView.builder(
          itemCount: tareas.length,
          itemBuilder: (context, index) {
            final tarea = tareas[index];
            return Card(
              child: ListTile(
                leading: Checkbox(
                  value: tarea.completada,
                  onChanged: (valor) {
                    if (valor != null) {
                      _alternarCompletada(tarea, valor);
                    }
                  },
                ),
                title: Text(
                  tarea.titulo,
                  style: tarea.completada
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                subtitle: Text(
                  '${tarea.completada ? 'Completada' : 'Pendiente'} · ID ${tarea.id}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editarTarea(tarea),
                    ),
                    IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _eliminarTarea(tarea),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
