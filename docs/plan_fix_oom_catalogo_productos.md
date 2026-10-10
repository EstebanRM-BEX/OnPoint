# Plan — Cierre en primer plano / OutOfMemoryError por catálogo en memoria

> Fecha: 2026-10-10 · Rama base: `desarrollo`
> Issues Crashlytics:
> - `a1f0c160d10c61a8fdd988bd72990fec`: `ExitDiagnostics._reportPreviousSession`, "Cierre en primer plano". 19 eventos / 6 usuarios en 24 h (1.7.4 y 1.7.6; Motorola, Chainway, Urovo)
> - `bcf7e387be99f9371ffcaad79fba59fa`: `java.lang.OutOfMemoryError` en `StandardMethodCodec.encodeSuccessEnvelope` (Urovo DT50, Android 13, 1.7.4)

---

## 1. Diagnóstico

### 1.1 Qué es el issue
"Cierre en primer plano" **no es un error**. Es el aviso de `ExitDiagnostics`: al arrancar detecta que la sesión anterior murió con la app a la vista (`resumed`/`inactive`). El aviso agrupa causas muy distintas en un solo issue.

### 1.2 Causa principal: OOM del heap Java por una consulta gigante de sqflite
Evento del 7 oct, 09:32 (DT50). Registro de la sesión siguiente:
```
reason: CRASH  importance: 100 (primer plano)  rss_kb: 327632
screen: checkout rss_mb: 183 ... ultimo_latido: 2026-10-07T09:32:10
```
Stack del crash:
```
java.lang.OutOfMemoryError: Failed to allocate a 33048415 byte allocation
  with 25165824 free bytes ... growth limit 134217728
  java.nio.ByteBuffer.allocateDirect
  io.flutter.plugin.common.StandardMethodCodec.encodeSuccessEnvelope
  com.tekartik.sqflite.Database.doQuery
```
sqflite serializa **todo** el resultado de la consulta en un solo `ByteBuffer` de 33 MB para pasarlo por el canal hacia Dart. En equipos con un heap de 128 MB (DT50) no entra y el proceso muere.

**Consulta culpable:** `ProductInventarioRepository.getAllProducts()`, un `SELECT *` sin `LIMIT` sobre `tblproductos_inventario` (tabla de **stock**: una fila por producto+lote+ubicación, ~72 mil filas × 25 columnas). La variante `getAllUniqueProducts()` (`SELECT * … GROUP BY product_id`) tiene el mismo problema.

**Quién la dispara:**

| Consumidor | Disparo | Uso real de la lista |
|---|---|---|
| `ConteoBloc` (**global**, vive toda la sesión) | `dialog_inventario_widget.dart:42` (al entrar a Conteo desde **/home**), `new_product_screen.dart:78`, `conteo_bloc.dart:536` | Filtros por `filterType` (categoría, productos de la orden, todo), búsqueda `contains` en memoria |
| `CreateTransferBloc` | `scan_product_create_transfer_screen.dart:101`, `product_search_widget.dart:36`, `product_dropdown_widget.dart:24` | Búsqueda `contains` en memoria |
| `DevolucionesBloc` | `GetProductsList` → `getAllUnique()` | `firstWhere` por barcode/code/id al escanear (`devoluciones_bloc.dart:1102-1166`); además carga `allBarcodeInventario` completo |

Coincide con los eventos del issue: `screen=/home rss_mb=337` y `stack=new-product-conteo`.

Además, `ProductosCacheService` **retiene** el resultado (`_cacheAll`, `_cacheUnique`) y `ConteoBloc` guarda su propia copia (`productos`). Como el bloc es global, esa copia sigue viva después de salir del módulo y la RSS se queda alta el resto del turno.

### 1.3 Falsas alarmas
- **Apagado o falta de batería:** eventos con `ultimo_latido` horas o días antes del reporte (p. ej. 4 oct → 10 oct, 16 h de diferencia). El latido es cada minuto, así que una diferencia grande significa que el equipo se apagó con la app abierta, no un fallo de la app.
- **`exit(0)` en `main.dart:123`** (diálogo "Cerrar la app"): sale con el estado en `resumed` y se reporta como cierre anómalo.

---

## 2. Decisión de diseño

**SQLite pasa a ser la fuente de verdad del catálogo:** consultas indexadas y paginadas, y nunca la tabla completa en memoria. Mismo patrón que Info Rápida v2 e `InventarioLocalDataSource.buscarProductos`.

- Escaneo exacto (barcode/code/id): consulta con índice, `LIMIT 1`, ~1–5 ms.
- Búsqueda por texto: `LIKE '%q%'` con `LIMIT 50` y debounce (~50–150 ms en PDA). Si no alcanza → FTS5 (fuera de este plan).
- Caché **acotado** (LRU de ~200 productos) solo para repetir escaneos sin ir a la base.
- Regla: **ninguna consulta a `tblproductos_inventario` sin `LIMIT`** desde la UI o los blocs.

---

## 3. Fases

### Fase 0 — Contención del diagnóstico (bajo riesgo, va en 1.7.7)
`lib/core/utils/diagnostics/exit_diagnostics.dart` + `main.dart`
1. `ExitDiagnostics.markIntentionalExit()`: guarda `diag_last_state = 'exit'`. Llamarlo antes de `exit(0)` en `main.dart:123`.
2. Clasificar en `_reportPreviousSession`:
   - Diferencia entre `ultimo_latido` y el arranque > 5 min → `Exception('Apagado con la app abierta')` (issue aparte, sin ruido).
   - Si `getExitInfo` trae un motivo de la misma sesión → incluirlo en el mensaje: `Cierre en primer plano [CRASH]`, `[LOW_MEMORY]`, `[ANR]`, `[SIGNALED]`. Crashlytics los separa en issues por causa.
   - Orden: primero leer `ApplicationExitInfo`, después reportar la sesión previa con ese dato.
3. Test unitario de la clasificación (función pura: estado, diferencia y motivo → título).

**Commit:** `fix(diagnostics): separar cierres por causa y no reportar salidas intencionales`

### Fase 1 — Base de datos: consultas acotadas (base de las fases 2–4)
`product_inventario_repository.dart`, `product_inventario_table.dart`, `database.dart`
1. Nuevos métodos en `ProductInventarioRepository`:
   - `Future<Product?> getByCodigo(String codigo)`: `barcode = ? OR code = ?`, y si no aparece, `tbl_barcodes_inventario` → `product_id`. `LIMIT 1`.
   - `Future<Product?> getUniqueByProductId(int id)`.
   - `Future<List<Product>> buscar({String query, int limit = 50, int offset = 0, Set<int>? productIds, Set<String>? categorias})`: una fila por producto, filtros opcionales por los IDs de la orden o por categoría (para Conteo).
   - `Future<int> contar({...mismos filtros})` para el estado "sin productos".
2. Índice nuevo `idx_inv_code ON (code)` y `idx_inv_category ON (category)`. Subir la versión de la base **68 → 69** (`onUpgrade` → `crearIndices`).
3. `getAllProducts()` / `getAllUniqueProducts()` → `@Deprecated`, y que lean por bloques (`LIMIT 2000 OFFSET n`) mientras quede algún consumidor. Así ninguna llamada al canal pasa de ~2–3 MB.
4. Tests con sqflite_ffi: búsqueda, paginado, `getByCodigo` con barcode alterno, filtros.

**Commit:** `feat(inventario): consultas paginadas e indexadas del catálogo`

### Fase 2 — Conteo (el que más eventos genera)
`conteo_bloc.dart`, `dialog_inventario_widget.dart`, `new_product_screen.dart`
1. Quitar `GetProductsFromDBEvent` de `_goToConteo` (home) y de `conteo_bloc.dart:536`.
2. Reemplazar `productos` / `productosFilters` / `productosFiltersSearch` por una búsqueda paginada según `filterType`:
   - `general`, `location` → `buscar(query)`
   - `category` → `buscar(query, categorias: …)`
   - `product` → `buscar(query, productIds: productosOrdenConteo ids)`
   - `combined` → `buscar(query, productIds: …, categorias: …)` (unión)
3. El escaneo en `new_product_screen` usa `getByCodigo` + validación contra el filtro de la orden.
4. Lista con scroll infinito (página de 50) y búsqueda con debounce de 300 ms. Mantener `DynamicSearchBar` y que el buscador no pierda el foco (ver los bugs de focus-steal).
5. Al salir del módulo: limpiar las listas del bloc (es global).
6. **Pantallas gemelas:** revisar si hay versión legacy en `src/` y en `features/`; el arreglo va en ambas.

**Commit:** `fix(conteo): no cargar el catálogo completo en memoria`

### Fase 3 — Crear Transferencia
`crate_transfer_bloc.dart` y widgets `product_search_widget`, `product_dropdown_widget`, `scan_product_create_transfer_screen`
1. `GetProductsFromDBEvent` deja de cargar la lista; `SearchProductEvent` llama a `buscar(query, limit: 50)`.
2. Escaneo → `getByCodigo`.
3. Quitar la espera al sync (`while productosSync.isLoading`) y cambiarla por un estado "catálogo sincronizando" si `contar() == 0`.

**Commit:** `fix(transferencias): búsqueda de productos paginada en crear transferencia`

### Fase 4 — Devoluciones
`devoluciones_bloc.dart`
1. `_onGetProductsBD`: ya no trae el catálogo; solo `productosDevolucion` (los propios de la devolución).
2. `firstWhere` de las líneas 1102-1166 → `getByCodigo` / `getUniqueByProductId`.
3. `allBarcodeInventario` completo → lo resuelve la misma `getByCodigo` (barcodes alternos en SQL).
4. Búsqueda manual → `buscar`.

**Commit:** `fix(devoluciones): resolver productos por consulta indexada`

### Fase 5 — Limpieza y prevención
1. `ProductosCacheService`: eliminar `_cacheAll` / `_cacheUnique` / `getAll` / `getAllUnique`. Dejar solo un **LRU acotado** (`maxEntries: 200`) para escaneos repetidos. `applyWsProductUpsert` actualiza el LRU (SQLite ya lo escribe `WebSocketService`).
2. Borrar `getAllProducts` / `getAllUniqueProducts` del repositorio cuando queden en 0 los consumidores.
3. Auditar las mismas consultas sin `LIMIT` en tablas que pueden crecer: `ubicaciones_repository.getAllUbicaciones`, `productTransferenciaRepository.getAllProducts` (`transferencia_bloc.dart:1591`), `pick_products_repository:153`. Medir cuántas filas tienen en un cliente grande y decidir por cada una.
4. **Regla automática:** test de arquitectura (`test/architecture/no_unbounded_catalog_queries_test.dart`) que falla si aparece `db.query(ProductInventarioTable.tableName)` o `FROM tblproductos_inventario` sin `LIMIT` fuera del repositorio.
5. **Alerta temprana de memoria:** en el latido de `ExitDiagnostics`, si `rss_mb > 300` registrar un no fatal `Memoria alta` (una vez por sesión) con pantalla y stack.

**Commit:** `refactor(productos): catálogo sin caché completo en memoria`

---

## 4. Verificación

| Prueba | Dónde | Criterio |
|---|---|---|
| Entrar a Conteo desde /home, abrir "nuevo producto", buscar y escanear | **Urovo DT50** (heap 128 MB) con el catálogo completo (~72 mil filas) | Sin OOM; RSS < 250 MB; la búsqueda responde en < 300 ms |
| Igual en Crear Transferencia y Devoluciones | DT50 + Chainway | Igual |
| Turno largo (2 h usando Conteo → Transferencia → Devoluciones) | PDA real | La RSS no crece de forma sostenida |
| `flutter test` (fases 0, 1 y 5) | CI | Verde |
| Crashlytics 7 días después de 1.7.7 | Consola | OOM `bcf7e387…` = 0; "Cierre en primer plano" solo con motivo real, ninguno `[CRASH]` en Conteo, Transferencia o Devoluciones |

---

## 5. Orden de entrega

1. **1.7.7 (hotfix):** fases 0 + 1 + 2 (Conteo concentra los eventos).
2. **1.7.8:** fases 3 + 4.
3. **1.7.9:** fase 5.

Cada fase en un commit separado, validado en un worktree limpio antes del push (en `desarrollo` hay trabajo ajeno sin commitear).

---

## 6. Notas de implementación (2026-10-10)

Lo que cambió respecto a este plan al implementarlo:

- **Fase 0:** el "apagado" no se decide por la diferencia de latidos (> 5 min), sino por la ausencia de registro de salida en Android 11+. Una app que se cae y se reabre 10 minutos después no debe contarse como apagado. Cada causa lleva una pila sintética propia porque Crashlytics agrupa por pila, no por mensaje.
- **Fase 1/2:** `getByCodigo` no distingue mayúsculas (índices `COLLATE NOCASE`): Conteo y Devoluciones comparan o mandan el código cambiado de mayúsculas. `buscar` también devuelve **filas de stock** (`porProducto: false`) porque Conteo y Crear Transferencia preseleccionan el lote de la fila elegida.
- **Fase 2:** el escaneo por código alterno ahora también valida el filtro de la orden (antes solo el barcode principal lo validaba).
- **Fase 4:** `GetProductEvent` pasa a `sequential()`: al ser asíncrono, dos escaneos rápidos podían resolverse desordenados.
- **Fase 5:** **no se hizo el LRU.** Con el escaneo por índice en 1–5 ms no aporta y agrega riesgo de datos viejos. `ProductosCacheService` se eliminó completo; Info Rápida ya leía de SQLite y solo lo mantenía al día por WebSocket.
- **Impresión de etiquetas** (`getProductLabelRows`) también leía el catálogo completo en una consulta: ahora lee en tandas de 5.000.
- **Regla automática:** `test/architecture/catalogo_sin_lecturas_completas_test.dart` (exige `LIMIT`/`limit:`/`COUNT(` o `// lectura-acotada: <motivo>`). Verificado contra el código original: detecta las 3 lecturas completas.

### Pendiente

- Auditar con datos de un cliente grande las otras lecturas completas que siguen en memoria: `UbicacionesCacheService` (`getAllUbicaciones`), `BarcodesInventarioCacheService`, `productTransferenciaRepository.getAllProducts` (`transferencia_bloc.dart:1591`) y `pick_products_repository:153`. Con pocas miles de filas no son riesgo; decidir por cada una.
- Impresión de etiquetas sigue teniendo la lista completa en memoria de Dart (sin riesgo de OOM del canal, pero conviene paginarla).
- Prueba en PDA (sección 4) antes de publicar.
