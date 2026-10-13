# Plan — Ubicaciones consultadas en SQLite (sin catálogo en memoria)

> Fecha: 2026-10-13 · Rama base: `fix/oom-catalogo-productos` (reutiliza su patrón y su regla de arquitectura)
> Relacionado: `docs/plan_fix_oom_catalogo_productos.md` (productos y terceros), `docs/plan_performance_pantallas.md`.

---

## 1. Diagnóstico

### 1.1 Estado actual
- `UbicacionesCacheService.getAll()` lee **toda** la tabla `tblUbicaciones` (`UbicacionesRepository.getAllUbicaciones`, un `db.query` sin `LIMIT`) y la guarda en un caché compartido. El cliente más grande tiene **19.336 ubicaciones** (9 columnas).
- **16 puntos de carga en ~13 módulos**, todos sobre esa lista en memoria:

| Módulo | Qué hace con la lista |
|---|---|
| Recepción individual / batch (legacy) | Búsqueda por texto, filtro por almacén, escaneo por barcode |
| Recepción multiusuario (destino) | Filtro por `warehouseName` + búsqueda |
| Transferencia interna / Crear transferencia (legacy) | Búsqueda, filtro por almacén, escaneo (origen y destino) |
| Transferencia multiusuario (destino) | Filtro por `warehouseName` + búsqueda |
| Conteo (legacy) | Maestra para los filtros `category`/`product`/`general` (por `idWarehouse`), búsqueda, escaneo |
| Devoluciones (legacy) | Búsqueda, filtro, escaneo |
| Inventario rápido | Escaneo (`firstWhere`), búsqueda (`InventarioLocalDataSource.getUbicaciones`), filtro por almacén |
| Impresión de etiquetas | Búsqueda, **rango por nombre** (prefijo o desde–hasta), orden por nombre |
| Info Rápida | `getCatalogoUbicaciones` (ubicación destino, transferencia masiva) y precarga |
| Packing v2 | Lista de muelles (`isADockAlter`) |

- **Escaneo de ubicación** con `firstWhere` sobre la lista en memoria en 8 pantallas (`inventario_page.dart:165`, `devoluciones/index.dart:191`, recepción individual y batch, transferencia interna, crear transferencia ×2, conteo).

### 1.2 Impacto
- **Memoria:** sin riesgo de cierre. Una lectura de ~3–4 MB (contra 33 MB del catálogo de productos), una sola vez, en un caché compartido. Sí deja ~19 mil objetos vivos toda la sesión.
- **Fluidez** (Firebase Performance, 7 días, p90): ninguna búsqueda de ubicación se congela (peor frame 67–119 ms), pero hay tirones al escribir porque cada tecla filtra las 19 mil en el hilo principal:

| Traza | Frames lentos |
|---|---|
| `search_location_recep` (Recepción) | ~25 % |
| `search_locations_dest_trans_info` (Info Rápida) | ~13 % |
| `search_location` (Inventario) | ~12 % |
| `locations_dest_packing` | ~10 % |
| `seacrh_locationsDest_trans`, `search_location_conteo` | ~9 % |

### 1.3 A favor
- La tabla **ya tiene índices** por `barcode` y por `name`, y el repositorio ya tiene `getUbicacionByBarcode`.
- Todas las listas ya se dibujan con `ListView.builder`.
- El patrón está probado con productos (Conteo, Crear Transferencia, Devoluciones, etiquetas) y terceros (322 mil filas: búsqueda sin coincidencias en 17 ms). 19 mil filas es una escala mucho menor.

---

## 2. Decisión de diseño

Igual que productos: **SQLite como fuente de verdad**, consultas paginadas e indexadas, sin lista maestra en memoria.

`UbicacionesRepository` (base inyectable para tests):

| Método | Uso | Consulta |
|---|---|---|
| `buscar({query, filtro, limit, offset})` | Pantallas de búsqueda | `name`/`barcode` `LIKE` sin distinguir mayúsculas, `ORDER BY name`, páginas de 50 |
| `getByBarcode(codigo)` | Escaneo | `barcode = ? COLLATE NOCASE LIMIT 1` (índice nuevo `NOCASE`) |
| `rango({desde, hasta, limit})` | Etiquetas por rango | `name >= ? AND name <= ?` o prefijo, `ORDER BY name`, con tope (p. ej. 1.000) y aviso si se supera |
| `muelles()` | Packing v2 | `WHERE is_a_dock_alter = 1` (pocas filas) |
| `contar({filtro})` | Estados "sin ubicaciones" | `COUNT(*)` |

`FiltroUbicaciones`: `warehouseId`, `warehouseName`, `ids` (ubicaciones de una orden), `soloMuelles`. Misma convención que `FiltroCatalogo`: `null` = sin restricción; set vacío = nada.

**Índices** (BD v71 en esta rama): `idx_tblUbicaciones_barcode_nocase (barcode COLLATE NOCASE)`; `idx_tblUbicaciones_warehouse (id_warehouse)` y `(warehouse_name)` para los filtros por almacén. El de `name` existente sirve para `ORDER BY name` y para los rangos.

---

## 3. Fases

### Fase U0 — Repositorio y tests (base de las demás)
1. Métodos de la sección 2 + `FiltroUbicaciones`, con la base inyectable.
2. Índices y migración v71 (`crearIndices`, idempotente).
3. Tests con sqflite_ffi: búsqueda, paginado, mayúsculas, filtros, rango (prefijo y desde–hasta), muelles. Benchmark con 20 mil filas.

### Fase U1 — Recepción (peor dato: ~25 %)
Recepción individual y batch (legacy) + Recepción multiusuario (destino).
- Búsqueda paginada con espera al escribir y carga al bajar; escaneo con `getByBarcode`; filtro por almacén en SQL.
- Recepción legacy (`src/`) y multiusuario (`features/`) tienen cada una su pantalla de destino: se migran las dos en esta fase, con el mismo repositorio.

### Fase U2 — Transferencias
Interna, Crear transferencia (origen y destino) y Transferencia multiusuario (destino). Mismo patrón que U1.

### Fase U3 — Conteo, Devoluciones e Inventario rápido
- Conteo: la "maestra de ubicaciones" de los filtros `category`/`product`/`general` pasa a `FiltroUbicaciones` (`warehouseId` en `general`); las ubicaciones propias de la orden (`location`/`combined`) ya son acotadas y se quedan.
- Devoluciones: búsqueda de destino y escaneo.
- Inventario rápido: `InventarioLocalDataSource.getUbicaciones` → búsqueda paginada; escaneo con `getByBarcode`.

### Fase U4 — Impresión de etiquetas, Info Rápida y Packing
- Etiquetas: búsqueda paginada y `rango()` con tope.
- Info Rápida: `getCatalogoUbicaciones` → búsqueda paginada en sus pantallas de destino; se quita `precargarCatalogos` de ubicaciones.
- Packing v2: `muelles()`.

### Fase U5 — Limpieza y prevención
1. Eliminar `UbicacionesCacheService` y `getAllUbicaciones`.
2. Agregar `tblUbicaciones` a `test/architecture/catalogo_sin_lecturas_completas_test.dart` (recién aquí: antes fallaría con los consumidores pendientes).
3. Revisar que la sincronización de ubicaciones (`syncUbicaciones`, `aplicarCambios`, WebSocket) ya no necesite invalidar ningún caché.

Cada fase en su commit, con tests del bloc del módulo (paginado, filtro, escaneo, "gana la última búsqueda") como en Conteo y Devoluciones.

---

## 4. Riesgos

- **Mayúsculas:** las pantallas comparan el barcode escaneado en minúsculas. `getByBarcode` y la búsqueda deben usar `NOCASE` (mismo problema que se resolvió en productos).
- **Semántica de cada filtro:** unos módulos filtran por `warehouseName` y otros por `idWarehouse`. Se respeta el campo que use cada uno.
- **Orden:** hoy algunas listas salen en el orden de la tabla y etiquetas por nombre. Por defecto se ordena por `name` (tiene índice); revisar en cada módulo si el orden anterior importaba.
- **Rango de etiquetas:** un rango amplio puede traer miles de ubicaciones; se acota con un tope y un aviso.
- **Selección por índice:** las pantallas que guardan la selección por posición deben descartarla al cambiar la búsqueda (como en Devoluciones).

---

## 5. Verificación

| Prueba | Criterio |
|---|---|
| Tests de repositorio y de cada bloc | Verde |
| Benchmark con 20 mil ubicaciones | Primera página y escaneo < 10 ms en Mac |
| PDA: buscar, bajar, filtrar por almacén y escanear en cada módulo | Sin pausas al escribir |
| Firebase Performance, una semana después | Trazas `search_location_*` con frames lentos < 10 % |

## 6. Orden de entrega

U0 → U1 → U2 → U3 → U4 → U5. U0 y U1 pueden salir juntas; el resto, de a uno o dos módulos por versión, para acotar el riesgo de cada publicación.
