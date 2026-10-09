# Plan — Sincronización incremental de `product_quants`

Fecha: 2026-10-09. Base: propuesta `docs/propuesta_sync_incremental_product_quants.pdf`
y respuesta del backend (endpoint con `since`/`scope`, `full`, `deleted_product_ids`,
`active_product_ids`; `scope` = huella de los almacenes permitidos).

## Objetivo

- Primer login por catálogo: descarga completa (igual que hoy).
- Relogins y cambios de usuario con almacenes ya conocidos: solo lo que cambió.
- La PDA nunca se queda sin catálogo por un fallo de red a mitad de la descarga.

## Estado actual (lo que hay que cambiar)

| Punto | Dónde | Problema |
|---|---|---|
| Borrado previo | `inventario_repository_impl.dart:46` (`Future.wait([deleteInventario(), syncProductos()])`) | Borra el catálogo en paralelo con la descarga: si falla, la PDA queda vacía. |
| Logout borra catálogo | `database.dart:2121` (`deleteBDCloseSession` → `deleInventario`) | Cada relogin vuelve a pedir ~74 mil productos. |
| Otros borrados | `dialog_dispositivo_no_autorizado_widget.dart:61`, `update_app_dialog_widget.dart:96`, `update_required_screen.dart:61`, `packing_preservation.dart:43`, `user_page.dart:366` | Llaman `deleteBDCloseSession` directo. |
| Request | `api_request_service.dart:930` (`getInventario`) | `GET` con `{"params": {}}` fijo. |
| Parseo | `inventario_remote_data_source.dart` (`_parseProductosIsolate`) | No lee `server_time`, `scope`, `full`, ids. |
| Prefs | `PrefUtils.clearPrefs()` | No hay claves de catálogo; habrá que excluirlas. |

Lectores de las tablas del catálogo (`ProductInventarioTable`, `BarcodesInventarioTable`):
`product_inventario_repository.dart`, `barcodes_inventario_repository.dart`,
`websocket_service.dart` (actualizaciones en tiempo real), `database.dart`. El diseño
mantiene esas tablas como "catálogo activo" para no tocar a ningún lector.

---

## Fase 0 — Pendientes del backend (no bloquea la Fase 1)

1. Texto completo de `active_product_ids` y del paso 3 de "Cómo aplicar".
2. Confirmar que todo viene dentro de `result` y los valores de `code` para error y
   sesión expirada.
3. **`expiration_date` en la fila**: la app ya lo lee
   (`producto_inventario_model.dart:78` y `:89`). Confirmar si viaja hoy; si no, que lo agreguen.
4. Tiempo actual de la descarga completa (timeout de 100 s).

## Fase 1 — Catálogo que sobrevive (sale sin backend nuevo)

Objetivo: dejar de perder el catálogo. Se puede publicar sola.

1. **Reemplazo atómico en la descarga completa.** Descargar y parsear primero; luego,
   en una transacción, cargar en tablas staging (`..._new`) y hacer el swap
   (`DROP` de la vieja + `ALTER TABLE ... RENAME`). Si algo falla, el catálogo anterior
   queda intacto. Se elimina el `deleteInventario()` en paralelo.
2. **Logout no borra el catálogo**: sacar `deleInventario()` de `deleteBDCloseSession()`
   y revisar los 5 llamadores directos (se mantiene el borrado total solo en
   "Eliminar base de datos" del perfil, que es explícito).
3. **Clave del catálogo**: guardar `catalogEnterprise` (URL + BD) en prefs fuera de
   `clearPrefs()`. Si al hacer login la empresa difiere, se borran el catálogo y la metadata.
4. Invalidar `ProductosCacheService` y avisar al websocket tras el swap (hoy ya se
   invalida en `ProductosSyncService.download`).

Tests: el repositorio conserva el catálogo si la descarga falla; el logout no
borra las tablas; un cambio de empresa sí las borra.

## Fase 2 — Protocolo incremental (un catálogo)

1. **Request**: `getInventario` pasa a `POST` con body JSON-RPC y acepta
   `params` (`since`, `scope`). Sin metadata se mandan `{}`.
2. **Parseo en el isolate**: leer `server_time`, `scope`, `full`,
   `deleted_product_ids`, `active_product_ids`, `data`. Si no viene `server_time`,
   es el backend antiguo: se trata como completa y no se guarda `lastSync`.
3. **Aplicar**:
   - `full: true` → reemplazo atómico de la Fase 1.
   - `full: false` → una transacción:
     1. `DELETE` filas y barcodes de los `product_id` de `data` y de `deleted_product_ids`
        (en tandas, por el límite de variables de SQLite).
     2. `INSERT` de `data`.
     3. Cargar `active_product_ids` en una tabla temporal y
        `DELETE ... WHERE product_id NOT IN (SELECT id FROM temp)`. No usar un `IN`
        con ~74 mil parámetros.
4. **Metadata** (`catalogLastSync`, `catalogScope`): se guarda solo si la
   transacción terminó bien; en error se conservan los valores anteriores.
5. **Errores**: `status: "error"` o `code` de error → no se toca nada. La sesión
   expirada sigue el flujo actual (`SessionExpiredFailure`).
6. La app siempre envía `since`/`scope` si los tiene; la regla de antigüedad
   (30 días) la decide el servidor.

Tests (con respuestas JSON de ejemplo):
- completa, incremental, borrado por `deleted_product_ids` y por `active_product_ids`;
- backend antiguo sin `server_time`;
- error a mitad (rollback y metadata sin cambios);
- más de 999 ids.

## Fase 3 — Varios catálogos por `scope` (máximo 3)

Diseño: el catálogo **activo** vive en las tablas actuales (los lectores no cambian).
Los inactivos se guardan en archivos SQLite aparte, `catalog_<scope>.db`.

1. **Metadata por empresa** (prefs, fuera de `clearPrefs`):
   - lista de catálogos `{scope, lastSync, lastUsed}`;
   - `scope` del catálogo activo;
   - mapa `userId → scope`.
2. **Selección al hacer login**:
   - usuario conocido → catálogo de su `scope`;
   - usuario nuevo → catálogo usado más recientemente (si coincide el `scope`, la
     carga es incremental; si no, el servidor responde `full: true`).
3. **Swap**: si el catálogo elegido no es el activo, se guarda el activo en su
   archivo y se carga el elegido (`ATTACH` + `INSERT ... SELECT`, en transacción).
4. **Aplicar la respuesta**:
   - siempre guardar `userId → scope` devuelto;
   - `full: true` con un `scope` distinto al enviado → catálogo nuevo (si ya hay 3, se
     descarta el de `lastUsed` más viejo y se borra su archivo);
   - `full: true` con el mismo `scope` → reemplazar ese catálogo;
   - `full: false` → incremental sobre el activo.
5. Espacio: medir el tamaño real de un catálogo en una PDA antes de fijar el límite de 3.

Tests: alternancia de 2 usuarios con almacenes distintos (una sola descarga
completa por `scope`), usuario nuevo con mismos almacenes (incremental),
expulsión del cuarto catálogo.

## Fase 4 — Mejoras opcionales

- Sincronizar en segundo plano si ya hay catálogo local, sin bloquear el Home.
- Trace en Firebase Performance: tipo (completa/incremental), filas, duración.

## Orden de despliegue

1. **Fase 1** en la próxima versión: no depende del backend y elimina el riesgo de
   quedarse sin catálogo.
2. **Fase 2** cuando el backend esté en producción. Es compatible: con el backend
   antiguo se comporta como completa.
3. **Fase 3** después de medir cuántas PDAs alternan usuarios con almacenes
   distintos (si es poco frecuente, se puede posponer).

## Riesgos

- **Websocket escribiendo mientras se aplica el sync**: las transacciones de sqflite
  se serializan. Lo que llega por websocket después de `server_time` se reaplica
  en el siguiente incremental (es idempotente).
- **Catálogo viejo tras un cambio global de unidades de peso o volumen**: limitación
  conocida del backend; se corrige en la siguiente descarga completa.
- **Fase 3 y espacio en disco**: decenas de MB por catálogo.
