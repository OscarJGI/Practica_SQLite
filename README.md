# Gestor de tareas con SQLite

Aplicación Flutter de tareas personales con **persistencia local en SQLite**. Sin servidor,
sin API REST y sin conexión a internet. Proyecto individual de la materia *Programación de
Dispositivos Móviles* (UAA).

## Estado del proyecto

| Etapa | Contenido | Estado |
|---|---|---|
| 1 | Proyecto Flutter generado, código base y decisión de persistencia | hecha |
| 2 | Base de datos, tabla y operaciones de alta/consulta | pendiente |
| 3 | Edición, cambio de estado, eliminación y validación | pendiente |
| 4 | Compatibilidad web, pruebas y documentación | pendiente |

La versión base se conserva tal cual: la interfaz ya se puede ejecutar, pero el CRUD sigue
en `TODO` y no existe capa de datos todavía.

## Decisión de persistencia: Drift

Se eligió **Drift** (`drift` + `drift_flutter`) por encima de `sqflite` y de guardar JSON:

- **Una sola base de código para Android, Linux y web.** `sqflite` no funciona en navegador
  ni en escritorio sin paquetes extra; Drift cubre las tres plataformas con el mismo DAO.
- **Consultas tipadas y en tiempo de compilación.** El código generado por `drift_dev`
  evita errores por nombres de columna escritos a mano.
- **Consultas reactivas con `Stream`.** La interfaz se refresca sola al cambiar la tabla; no
  hace falta recargar la lista manualmente después de cada escritura.
- **Web real con WebAssembly.** En navegador usa `sqlite3.wasm` con
  `drift_worker.dart.js` como worker, y respalda los datos en IndexedDB/OPFS del origen.

Lo que la práctica descarta explícitamente (lista en memoria, JSON en `shared_preferences`,
API REST, MySQL) queda fuera por diseño.

## Esquema de la tabla

```sql
CREATE TABLE tareas (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  titulo     TEXT    NOT NULL,
  completada INTEGER NOT NULL DEFAULT 0, -- 0 = pendiente, 1 = completada
  creada_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

- `id`: llave primaria autoincremental administrada por SQLite.
- `titulo`: texto obligatorio; la validación rechaza cadenas vacías o solo espacios.
- `completada`: SQLite no tiene booleano, se guarda como entero 0/1 y Drift lo expone como
  `bool`.


## Entornos objetivo

| Entorno | Plataforma | Cómo se ejecuta |
|---|---|---|
| Web | navegador (Chrome) | `flutter run -d chrome` |
| Móvil | Android | `flutter run -d <emulador o dispositivo>` |
| Escritorio | Linux | `flutter run -d linux` |

## Requisitos

- Flutter 3.47 o superior (`flutter doctor -v` sin errores).
- Android SDK y un emulador para la variante móvil.
- Para Linux: `libsqlite3` disponible en el sistema.

## Ejecutar

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554   # Android, ajustar con flutter devices
flutter run -d linux           # escritorio
flutter run -d chrome          # web
```

### Web

El navegador no puede usar SQLite nativo: drift usa WebAssembly y un worker.
Los dos archivos viven en `web/` y deben coincidir con las versiones instaladas:

| Archivo | Origen |
|---|---|
| `web/sqlite3.wasm` | assets del release `drift-2.35.4` (SQLite compilado a wasm) |
| `web/drift_worker.js` | assets del release `drift-2.35.4` (worker de drift) |

Si se actualiza `drift` en `pubspec.yaml`, hay que reemplazar ambos archivos por los del
release correspondiente; si no, la base falla al abrir en el navegador.

Para probar el build de producción sin `flutter run`:

```bash
flutter build web
cd build/web && python3 -m http.server 8099
```

Luego abrir `http://localhost:8099`. Sin los encabezados de aislamiento
(`Cross-Origin-Opener-Policy` y `Cross-Origin-Embedder-Policy`) el navegador no ofrece OPFS y
drift cae a IndexedDB; los datos igual persisten en el mismo origen y perfil.

### Nota para NixOS

- Los tests necesitan `libsqlite3` visible:
  `LD_LIBRARY_PATH=/nix/store/...-sqlite-3.53.3/lib flutter test`.
- La app GTK necesita iconos y decodificadores de imagen de gdk-pixbuf; si el tema de iconos
  no está instalado, GTK aborta al arrancar. Se resuelve con `GDK_PIXBUF_MODULE_FILE` y un
  tema Adwaita/hicolor disponible, o ejecutando en otra distro. Es un problema del entorno,
  no del código.

## Pruebas

```bash
flutter test
```

Cubren la validación del título, el alta, la edición, el cambio de estado, la eliminación y la
persistencia con un archivo SQLite real que se cierra y se vuelve a abrir. Para comprobar la
persistencia a mano hay que **cerrar por completo la app y abrirla de nuevo**; el hot reload
no reinicia los procesos.

## Uso de IA

El diseño de la solución es mío: definí la estructura de la tabla `tareas` y el tipo de cada
columna, las reglas de validación del título, la organización de la pantalla, las consultas con
Drift (alta, `watch()`, `UPDATE` y `DELETE` por id) y los casos de prueba que debía cubrir.

La IA (OpenCode con DeepSeek) se usó como apoyo para llevar esas decisiones a código Dart,
rectificar detalles pequeños del esquema, generar borradores de pruebas y redactar este
README; también para dudas de configuración de Drift en la web.

Verifiqué por mi cuenta: ejecuté la app en el emulador Android y en el navegador, cerré y
reabrí para comprobar la persistencia, corrí `flutter analyze` y `flutter test`, y corregí los
errores encontrados.

`web/sqlite3.wasm` y `web/drift_worker.js` no son código mío ni de la IA: son binarios del
release oficial `drift-2.35.4`. `lib/data/app_database.g.dart` lo genera `build_runner` y no se
edita a mano.
