# Plan: migrar `PackingConsolidateBloc` (Packing Consolidado) a bloc escopeado

> Mismo esquema que `DevolucionesBloc` (bloc que nace al entrar al flujo, viaja
> como argumento entre pantallas y se cierra al salir). Objetivo: que el bloc
> y sus listas grandes **no vivan en memoria mientras el usuario está en el
> Home u otro módulo**.
>
> Primer paso de la cola pendiente de `CONTEXTO_SESION_ROUTE_SCOPING.md`
> ("`PackingConsolidateBloc` — sin auditar todavía"). Después de validar el
> patrón aquí, se repite para `PackingPedidoBloc` y `WmsPackingBloc`.

---

## 1. Estado actual (auditado)

**Bloc:** `packing-consolidade/bloc/packing_consolidade_bloc.dart` — 1961
líneas, 39 handlers. Hoy se provee en `main.dart` (vive toda la sesión) y
nunca se cierra.

**Qué retiene**
- 5 `TextEditingController` (`searchController`, `searchControllerPedido`,
  `searchControllerProduct`, `controllerTemperature`, `temperatureController`).
- Listas: `listOfBatchs`/`listOfBatchsDB`, `listOfProductos`,
  `listOfProductosProgress`, `productsDone`, `productsDonePacking`,
  `listOfProductsForPacking`, `productsPacking`, `listOfProductsName`,
  `positions`, `packages`, `listOfBarcodes`, `listAllOfBarcodes`, `novedades`.
- Estado de trabajo: `batch`, `pedido`, `currentProduct`, `oldLocation`,
  `completedProducts`, `quantitySelected`, `isSticker`, `resultTemperature`,
  flags de validación (`locationIsOk`, `productIsOk`, …).

**Dónde se persiste (SQLite = fuente de verdad)**
`db.productosPedidosRepository` (42 usos), `db.batchPackingConsolidateRepository`
(8), `db.packagesRepository` (7), `db.pedidosPackingConsolidateRepository` (2),
`db.barcodesPackagesRepository` (2).

**Quién lo usa**
- Solo las pantallas de `packing-consolidade/` y el Home.
- Home: `_openPacking` (`home/presentation/index.dart:129`) le dispara
  `LoadAllNovedadesPackingConsolidateEvent` antes de abrir `DialogPacking`.
- Entrada al flujo: `DialogPacking`
  (`packing/screens/widgets/dialog_packing_widget.dart:46`) →
  `'list-packing-consolidade'`.
- No hay consumidores en otros módulos (la mención en `tab1.dart:658` es un
  comentario).

**Rutas (4)** — `app_router.dart:693-725`

| Ruta | Pantalla | Args actuales |
|---|---|---|
| `list-packing-consolidade` | `ListPackingConsolidadeScreen` | — |
| `pedido-packing-consolidate-list` | `PackingConsolidateListScreen` | `[batch]` |
| `packing-consolidate-detail` | `PackingConsolidateDetailScreen` | `[pedido, batch, tabIndex]` |
| `scan-product-consolidate` | `ScanProductPackingConsolidateScreen` | `[pedido, batch]` |

**Navegación:** 11 `pushReplacementNamed` dentro de la carpeta (convención del
repo). Cada uno descarta la pantalla anterior → el bloc **no puede** cerrarse
en el `dispose` de una pantalla.

**Diálogos:** 22 `showDialog` en 7 archivos (`index_list_screen` 6,
`scan_product_screen` 5, `tab1` 4, `tab2` 3, `tab3` 2, `packing_consolidate_list_screen` 1,
`dropdowbutton_widget` 1). Los diálogos se montan en una ruta hermana y no ven
el `BlocProvider` de la pantalla.

---

## 2. Auditoría de estado solo-en-memoria (hacer ANTES de codificar)

Para cada campo decidir: **persistir**, **recalcular al entrar** o **aceptar
pérdida**.

| Campo | Se puebla desde | Propuesta inicial |
|---|---|---|
| `listOfProductos`, `packages`, `listOfBarcodes`, `positions` | SQLite al abrir pedido | Recalcular (ya pasa hoy al abrir cada pedido) |
| `novedades`, `configurations` | Cachés compartidos | Recalcular |
| `listOfProductsForPacking` | Selección del usuario (se resetea en l. ~1057) | **Verificar**: si el operario sale a mitad de selección, ¿es aceptable perderla? |
| `resultTemperature` | Resultado IA/manual por paquete | **Verificar**: ¿se guarda en el paquete antes de salir? |
| `currentProduct`, `oldLocation`, `quantitySelected`, flags `*IsOk` | Escaneo en curso | Aceptar pérdida (es del paso actual) |
| `batch`, `pedido` | Argumentos de ruta / lista | Recalcular desde los argumentos |
| Controllers | — | `dispose()` en `close()` |

**Entregable de esta fase:** tabla completada con la decisión por campo. Lo que
quede en "persistir" se vuelve una tarea extra antes de la Fase 3.

---

## 3. Fases

### Fase 0 (opcional) — Scope reutilizable
Hoy existe `DevolucionesScope` con contador de scopes (`attachScope` /
`detachScope`, cierre diferido de 500 ms). Para no duplicarlo en los 3 flujos de
packing:
- Extraer un mixin/interfaz (`ScopedFlowBloc`) con `attachScope`/`detachScope`.
- Un widget genérico `FlowBlocScope<B>` que reciba el bloc por argumento (o lo
  cree en el `State`) y lo exponga con `BlocProvider.value`.
- Migrar `DevolucionesScope` al genérico (sin cambio de comportamiento).

Si se prefiere no tocar devoluciones, copiar el patrón como
`PackingConsolidateScope` y generalizar después.

### Fase 1 — Bloc: ciclo de vida
En `packing_consolidade_bloc.dart`:
- Contador de scopes + `close()` diferido.
- `close()`: `dispose()` de los 5 controllers y vaciar listas grandes.
- Guards `if (isClosed) return;` antes de los `add(...)` internos que ocurren
  tras un `await` (llamadas a API) para no lanzar `StateError` si el bloc se
  cerró en vuelo.
- Evitar `debugPrint` de depuración en el commit final.

### Fase 2 — Rutas y navegación
- `app_router.dart`: las 4 rutas envuelven su pantalla en el scope y reciben el
  bloc **como último argumento** para no romper los índices existentes:

  | Ruta | Posición del bloc |
  |---|---|
  | `list-packing-consolidade` | `args[0]` |
  | `pedido-packing-consolidate-list` | `args[1]` (tras `batch`) |
  | `packing-consolidate-detail` | `args[3]` (tras `pedido, batch, tabIndex`) |
  | `scan-product-consolidate` | `args[2]` (tras `pedido, batch`) |

- Actualizar los 11 `pushReplacementNamed` para añadir
  `context.read<PackingConsolidateBloc>()` al final de `arguments`.
- Ojo con `tab1.dart:451`: navega a `list-packing-consolidade` con argumentos
  propios → revisar qué pasa y adaptar el índice.
- Entrada (`DialogPacking`, `dialog_packing_widget.dart:46`): crear
  `PackingConsolidateBloc()` al elegir "Consolidado" y pasarlo en `arguments`.
  Los otros dos modos del diálogo no se tocan en esta fase.
- Rutas sin bloc en argumentos (hot restart en medio del flujo): volver al
  Home con `_invalidArgs`, igual que devoluciones.

### Fase 3 — Diálogos
- Crear `showPackingConsolidateDialog(context:, builder:, barrierDismissible:)`
  que capture el bloc y lo re-exponga con `BlocProvider.value` (mismo diseño
  que `showDevolucionesDialog`).
- Reemplazar los 22 `showDialog` de la carpeta.
- Revisar diálogos anidados (diálogo que abre otro diálogo) y
  `showModalBottomSheet`/`Get.dialog` si los hubiera.
- Widgets que se montan en diálogos y leen el bloc: `dialog_temperature_widget`,
  `dialog_temperature_manual_widget`, `dropdowbutton_widget` (verificar que
  reciban el provider desde el helper).

### Fase 4 — Home y `main.dart`
- Quitar `BlocProvider(create: PackingConsolidateBloc())` de `main.dart`.
- Quitar de `_openPacking` el `LoadAllNovedadesPackingConsolidateEvent`; el
  bloc debe cargar novedades en el init del flujo (`NovedadesCacheService`).
  No tocar las líneas de `WmsPackingBloc` ni `PackingPedidoBloc` (siguen
  globales hasta migrarlos).
- Verificar que la pantalla inicial dispare las cargas que antes ya estaban
  hechas (config de usuario, novedades, lista de batches).

### Fase 5 — Verificación
Checklist manual (no hay tests del módulo):
1. Home → Packing → Consolidado: aparece `PackingConsolidateBloc` en el
   inspector; sin entrar, **no** debe aparecer.
2. Lista de batch → lista de pedidos → detalle (tabs 1-4) → escaneo →
   volver a detalle → volver a lista → salir al Home: el bloc pasa a CERRADO.
3. Empacar un pedido completo (con temperatura manual y por IA) y confirmar
   que los datos llegan al backend y a SQLite.
4. Salir a mitad de selección de productos y volver a entrar: comparar con lo
   decidido en la auditoría.
5. Botón atrás del sistema en cada pantalla; rotación/pausa de la app.
6. Salir mientras hay una petición en vuelo (empacar, desempacar): no debe
   quedar un diálogo de carga abierto ni lanzar excepción.
7. Entrar y salir dos veces seguidas: sin estado residual.
8. Medir tiempo de la primera pantalla (SQLite) en un dispositivo real y la
   memoria (RSS) del inspector en el Home antes/después.

---

## 4. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Estado solo en memoria perdido al salir | Auditoría (sec. 2); persistir lo necesario |
| Cierre con petición en vuelo (emit descartado, diálogo pegado) | Guards `isClosed`; overlay de carga declarativo (patrón 6 del doc de contexto) si algún diálogo depende de un segundo estado |
| `add()` tras cierre lanza `StateError` | Guards `isClosed` en handlers con `await` |
| Diálogos sin provider (`ProviderNotFound`) | Helper `showPackingConsolidateDialog` en los 22 sitios |
| Índices de argumentos rotos | Bloc siempre al final de `arguments`; revisar `tab1.dart:451` |
| Cierre prematuro en un dispositivo lento | Margen de 500 ms configurable; si falla, observer de navegación |
| Lectura de SQLite bloqueada por sync larga al entrar | Spinner existente; no hay pérdida de datos |
| Rama `desarrollo` con cambios sin commit | Commit por fase; no mezclar con otros archivos modificados |

---

## 5. Archivos a tocar (estimado: ~14)

- `lib/main.dart`
- `lib/core/routes/app_router.dart`
- `lib/features/home/presentation/index.dart`
- `lib/src/presentation/views/wms_packing/presentation/packing/screens/widgets/dialog_packing_widget.dart`
- `packing-consolidade/bloc/packing_consolidade_bloc.dart`
- `packing-consolidade/screens/index_list_screen.dart`
- `packing-consolidade/screens/packing_consolidate_list_screen.dart`
- `packing-consolidade/screens/packing_consolidade_detail_screen.dart`
- `packing-consolidade/screens/scan_product_screen.dart`
- `packing-consolidade/screens/tabs/tab1.dart` … `tab3.dart`
- `packing-consolidade/screens/widgets/others/dropdowbutton_widget.dart`
- Nuevos: `widgets/packing_consolidate_scope.dart` (o scope genérico),
  `widgets/show_packing_consolidate_dialog.dart`

## 6. Orden de commits sugerido

1. `refactor(packing-consolidado): ciclo de vida del bloc (close, guards)`
2. `refactor(packing-consolidado): scope + helper de diálogos`
3. `refactor(packing-consolidado): rutas con bloc por argumento`
4. `refactor(packing-consolidado): quitar bloc global de main y precarga del home`

## 7. Criterio de éxito

- En el Home no existe `PackingConsolidateBloc` en el inspector.
- Al entrar a Consolidado aparece; al salir pasa a CERRADO en ≤ 1 s.
- Flujo completo de empaque sin regresiones.
- Sin excepciones en consola al salir con operaciones en vuelo.
