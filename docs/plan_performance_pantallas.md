# Plan — Rendimiento de pantallas (frames lentos y congelados)

> Fecha: 2026-10-12 · Rama base: `desarrollo`
> Fuente: Firebase Performance, trazas `screen_*` de `JankMonitor` (últimos 7 días, todas las versiones, percentil 90).
> Relacionado: `docs/plan_fix_oom_catalogo_productos.md` (rama `fix/oom-catalogo-productos`).

---

## 1. Diagnóstico (datos)

`JankMonitor` abre una traza `screen_<ruta>` por pantalla con `frames_total`, `frames_slow` (> 16 ms: tirones), `frames_frozen` (> 700 ms: la app se traba) y `frame_max_ms`. Las proporciones de abajo comparan percentiles 90 tomados por separado: son aproximadas.

### 1.1 Congelamientos

| Pantalla (traza) | Peor frame | Congelados | Estado |
|---|---|---|---|
| `search_product_create_transfer` | 3,9 s | 4 | **Resuelto**: rama `fix/oom-catalogo-productos` (búsqueda paginada y tarjetas que se arman solo al mostrarse) y contención en `desarrollo` |
| `search_product` (Inventario rápido, buscar producto) | 2,2 s | 6 | **Fase 1** |
| `inventario` (Inventario rápido) | ~1 s | 1 | **Fase 1** |

### 1.2 Tirones (proporción de frames lentos)

| Pantalla | Muestras | Lentos | Estado |
|---|---|---|---|
| `detail_packing_pedido` (Packing legacy) | 13 mil | ~50 % | **Resuelto**: el legacy se retiró en la 1.7.6 (`b246f0c6`); Packing v2 (`packing_pedido_v2`) está en ~6 %. Los datos vienen de PDAs en 1.7.4/1.7.5 |
| `scan_pack` (Packing legacy) | 11 mil | ~27 % | Igual que el anterior |
| `batch` (Picking por batch, legacy) | 563 | ~30 % | **Fase 3** |
| `home` | 11 mil | ~25 % | **Fase 2** |
| `auth` (login) | 1.300 | ~24 % | **Fase 2** |
| `expedition_detail`, `conteo`, `transferencias` | — | 14–16 % | Fuera de alcance por ahora |

Referencia de pantallas fluidas (ya migradas a SQLite paginado): Info Rápida ~2 %, Detalle de producto ~4 %, Detalle de ubicación ~3 %.

### 1.3 Causas probables (revisión del código, a confirmar perfilando)

**Inventario rápido** (`lib/features/inventario/presentation/`)
- `inventario_page.dart` tiene **1.346 líneas** dentro de un solo `BlocConsumer<InventarioBloc>` **sin `buildWhen`** (0 en todo el archivo): cada estado que emite el bloc (escaneo, lote, cantidad, diálogos, búsqueda) redibuja la pantalla completa.
- Ir a buscar producto y volver es con **`pushReplacementNamed`** en ambos sentidos (`inventario_page.dart:743`, `product_search_widget.dart:242/295`). Cada selección **destruye y vuelve a crear** la página de inventario: `initState`, `didChangeDependencies` con manejo de foco, diálogo "Espere un momento…" y el primer build de las 1.346 líneas, todo justo en la transición. Ese frame cae en la traza de la pantalla que se está cerrando (`search_product`), lo que explica que una pantalla de búsqueda ya paginada y perezosa marque 2,2 s.
- La búsqueda en sí (`product_search_widget.dart`) ya está bien: tiene espera mientras se escribe, `buildWhen`, carga paginada y `ListView.builder`.

**Home y login** (`lib/features/home/presentation/index.dart`, `login`)
- `_buildSummary()` usa `BlocBuilder<UserBloc>` **sin `buildWhen`**, más un `ListenableBuilder` sobre `PreloadStatus` y `ProductosSyncService`. Se redibuja con cada estado del `UserBloc`, que es global y muy usado.
- La sincronización posterior al login (catálogo de ~72 mil filas, ubicaciones, novedades) corre **mientras el operario está en el login o el Home**. Parte del trabajo ocurre en el hilo principal:
  - `reemplazarCatalogo` → `construirInserts` hace `compute(_processProductsRawArgs, productosList)`: **enviar 72 mil objetos al isolate los copia**, y esa copia la paga el hilo principal.
  - La conversión `ProductoInventarioModel` → `Product` legacy y la escritura en lotes también reparten trabajo en el hilo principal.
- Hipótesis: buena parte del ~25 % de frames lentos del Home y el login coincide con la sincronización. Ya existe la traza `catalogo_sync` (`catalogo_sync_trace.dart`) con sus tiempos para correlacionar.

**Picking por batch legacy** (`lib/src/presentation/views/wms_picking/modules/Batchs/screens/batch_screen.dart`)
- 1.310 líneas, 3 `BlocBuilder`/`BlocConsumer` y **0 `buildWhen`**. Es el mismo patrón que Inventario.

---

## 2. Método (igual para cada fase)

1. **Medir antes** en una PDA real (CT58 o DT50), con `flutter run --profile` y Flutter DevTools:
   - *Performance → Timeline*: qué frames pasan de 16 ms y qué hay en ellos (build, layout, paint, raster, trabajo de Dart).
   - *Track widget rebuilds*: cuántas veces se reconstruye cada widget por acción.
   - Guardar el timeline exportado como evidencia.
2. **Corregir** solo lo que la medición confirme.
3. **Medir después** con el mismo guion de uso.
4. **Validar en producción** con las trazas `screen_*` una semana después de publicar.

**Criterio de éxito por pantalla:** `frames_frozen` = 0, `frame_max_ms` < 700 y frames lentos < 10 % (p90).

> Antes de instalar en una PDA con la app ya instalada, verificar que la firma coincide: si no, `flutter run` desinstala la app y borra sus datos.

---

## 3. Fases

### Fase 0 — Instrumentación (bajo riesgo, va primero)
`lib/core/utils/performance/jank_monitor.dart`
1. Atributo `sync_activo` (`si`/`no`) en cada traza `screen_*`: `si` si hubo una sincronización de catálogo o ubicaciones durante la vida de la traza (`ProductosSyncService.isLoading` o `PreloadStatus`). Así se confirma o descarta la hipótesis del Home y el login separando los frames lentos con y sin sincronización.
2. Métrica `frames_build_heavy`: frames cuyo *build* supera 16 ms (`FrameTiming.buildDuration`), para distinguir reconstrucción de widgets de pintado.
3. Test unitario del cálculo de métricas.

**Commit:** `feat(performance): separar frames lentos por sincronización y por build`

### Fase 1 — Inventario rápido (los congelamientos pendientes)
`inventario_page.dart`, `product_search_widget.dart`, `location_search_widget.dart`, `inventario_bloc.dart`
1. **Perfilar** el flujo escanear ubicación → buscar producto → seleccionar → cantidad → enviar.
2. **Navegación sin recrear la página:** buscar producto y buscar ubicación se abren con `pushNamed` y vuelven con `pop(resultado)`. La página de inventario queda viva debajo y no se reconstruye desde cero.
   - Riesgo conocido: el "robo de foco" al volver (ver los bugs de focus-steal ya vistos en otras pantallas de escaneo). El foco se pide **una sola vez** al recibir el resultado del `pop`, no en `didChangeDependencies`.
3. **Reconstrucción por secciones:** partir la página en widgets por sección (ubicación, producto, lote, cantidad y botones) en `presentation/widgets/`, cada uno con `BlocSelector` o `BlocBuilder` + `buildWhen` sobre los campos que muestra. El `BlocConsumer` raíz queda solo como `BlocListener`, para diálogos y navegación.
4. Quitar el diálogo "Espere un momento…" al volver de la búsqueda (ya no hace falta si la página no se recrea).
5. Tests de widget: al seleccionar un producto, la sección de ubicación no se reconstruye (contador de builds) y el foco termina en cantidad o lote.

**Commit(s):** `perf(inventario): volver de la búsqueda sin recrear la página` · `perf(inventario): reconstruir por sección con buildWhen`

### Fase 2 — Home y login
`home/presentation/index.dart`, `operational_summary_card.dart`, `inventario_local_data_source.dart`, `product_inventario_repository.dart`, `productos_sync_service.dart`
1. Con los datos de la Fase 0, **confirmar** si los frames lentos del Home y el login coinciden con `sync_activo = si`.
2. **Resumen del Home:**
   - `BlocBuilder<UserBloc>` con `buildWhen` solo para los estados de conteos y carga.
   - Separar cada métrica en su propio widget, para que un cambio de progreso de productos no redibuje las otras.
3. **Sincronización fuera del hilo principal**, si la Fase 0 la confirma:
   - Armar los `INSERT` en el mismo isolate que parsea el JSON (`_parseProductosIsolate`) y devolver directamente las sentencias. Así se evita el viaje de 72 mil objetos de ida y vuelta entre isolates.
   - Escribir en SQLite por lotes, cediendo el hilo entre lotes.
   - Medir con la traza `catalogo_sync` (los tiempos de guardado no deberían empeorar).
4. **Login:** no tiene animaciones ni desenfoques (revisado: sin `BackdropFilter`, `AnimationController` ni Lottie). Si la Fase 0 muestra frames lentos sin sincronización activa, perfilar el flujo empresa → login → Home (el `PostLoginCoordinator` dispara varias cargas a la vez).

**Commit(s):** `perf(home): resumen operativo con buildWhen por métrica` · `perf(sync): armar inserts del catálogo en el isolate del parseo`

### Fase 3 — Picking por batch legacy
`batch_screen.dart`
- Primero decidir con el equipo si este módulo se migra a `features/` (como Picking por pedido, `docs/plan_migracion_picking_pedido.md`). **Si se migra, no optimizar el legacy**: el diseño nuevo nace con `buildWhen` y listas perezosas.
- Si sigue en uso por un tiempo largo, solo cambios baratos: `buildWhen` en los 3 builders y `ListView.builder` donde haya listas armadas por adelantado.

### Fase 4 — Prevención
1. **Guía corta** en `docs/` (o en `FEATURE_TEMPLATE.md`):
   - Ninguna pantalla con `BlocBuilder`/`BlocConsumer` raíz sin `buildWhen`.
   - Listas siempre con `ListView.builder`, con la tarjeta armada dentro del `itemBuilder`.
   - Sub-pantallas de selección con `push`/`pop(resultado)`, no `pushReplacementNamed` de ida y vuelta.
   - Datos grandes paginados en SQLite (regla ya automatizada para catálogo y terceros).
2. **Alertas en Firebase Performance** sobre las trazas `screen_*` más usadas (`home`, `inventario`, `packing_pedido_v2`, `scan_product_cluster`): avisar si `frames_frozen` p90 > 0 o `frame_max_ms` > 700.
3. **Revisión mensual** de la tabla de la sección 1 con los datos del mes.

---

## 4. Orden de entrega

1. **Fase 0** (instrumentación): pequeña; conviene publicarla junto con la rama `fix/oom-catalogo-productos` para tener datos lo antes posible.
2. **Fase 1** (Inventario rápido): son los congelamientos que quedan.
3. **Fase 2** (Home y login): la de más usuarios; depende de los datos de la Fase 0.
4. **Fases 3 y 4** según la decisión sobre el Picking por batch.

Cada fase en un worktree propio, con medición antes y después en la PDA, y validada con Firebase Performance una semana después de publicar.
