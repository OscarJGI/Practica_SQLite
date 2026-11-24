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

Detalle de la investigación: [REPORTE.md](REPORTE.md) (se completará en la etapa 4).

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
flutter run -d linux    # escritorio
flutter run -d chrome   # web
flutter run -d emulator-5554  # Android, ajustar con flutter devices
```

## Pruebas

```bash
flutter test
```

Las pruebas automatizadas de validación y de almacenamiento se agregan en la etapa 4. Para
comprobar la persistencia real hay que **cerrar por completo la app y abrirla de nuevo**; el
hot reload no reinicia los procesos y por lo tanto no demuestra nada.
