# Plan de migración — Packing por Pedido → `features/packing_pedido`

> Fecha: 2026-10-07 · Rama base: `sumatec-dev`
> Origen: `lib/src/presentation/views/wms_packing/presentation/packing` (~11.300 líneas)
> Referencias: `lib/features/FEATURE_TEMPLATE.md`, patrón de `features/expedition` (blocs por pantalla), análisis previo en `docs/analisis_packing_pedido.md`

---

## 0. Objetivo y reglas

- Migrar a Clean Architecture **sin cambiar el comportamiento**, salvo los bugs documentados en el análisis (se corrigen en la fase 6, aparte).
- **El legacy sigue funcionando sin cambios** durante todo el desarrollo. El reemplazo (fase 7) es una decisión aparte, recién después de validar en PDA.
- Cada fase cierra con `flutter analyze` limpio y un commit propio.
- **Desarrollo aislado (ver §0.1):** el feature nuevo no modifica ningún archivo del módulo actual ni de los repositorios o tablas compartidos.
- Widgets nuevos en `presentation/widgets/` (no privados en la screen). Búsquedas con `DynamicSearchBar` y escaneo con `BarcodeScannerField`.

---

## 0.1 Aislamiento del módulo actual

**Requisito:** el desarrollo va aparte y no puede afectar al packing por pedido actual (ni a packing batch o consolidado).

### Git
- Rama propia: `feature/packing-pedido-v2`, creada desde `sumatec-dev` **después** de commitear o guardar los cambios pendientes (hoy hay unos 83 archivos modificados, entre ellos `wms_packing_repository.dart`, `main.dart` y `app_router.dart`).
- Opcional: worktree separado (`../appwms-packing-v2`) para trabajar sin tocar la copia de trabajo actual.
- Se mergea solo cuando pase las pruebas de PDA.

### Código: solo se agrega, nunca se modifica

| Permitido | Prohibido |
|---|---|
| Archivos nuevos en `lib/features/packing_pedido/` | Editar cualquier archivo de `wms_packing/presentation/packing/` |
| **Copiar** al feature los modelos y la lógica que hagan falta | Cambiar firmas o comportamiento de `WmsPackingRepository` |
| Usar `ApiRequestService`, `hasNetwork`, `PrefUtils` y los servicios de caché (solo lectura y llamadas) | Cambiar `ProductosPedidosRepository`, `PackageRepository`, `PedidoPackRepository` o `database.dart` |
| Puntos de entrada **aditivos**: ruta nueva, registro DI nuevo, módulo nuevo en el home | Reemplazar rutas, el `BlocProvider` o el acceso del home al packing actual |

- El remote datasource llama a los endpoints directo con `ApiRequestService` (`transferencias/pack`, `send_transfer/pack`, `send_cluster/pack`, `transferencias/unpacking`, `transferencias/delete_pack`, etc.), sin pasar por `WmsPackingRepository`.
- Las correcciones de bugs (fase 6) se hacen **solo en el feature nuevo**. El legacy queda como está.

### Datos locales: base SQLite propia
El módulo actual comparte tablas con batch y consolidado (`tblproductos_pedidos`, paquetes, barcodes y pedidos, esta última **sin** columna `type`). Si el feature nuevo usara las mismas tablas, cualquier escritura suya (flags `is_selected` o `is_terminate`, limpieza de huérfanos, reconciliación) alteraría lo que ve el módulo actual.

- **Archivo SQLite independiente** (`packing_pedido_v2.db`) con sus propias tablas: `pedidos`, `productos`, `paquetes`, `barcodes`. Esquema propio y versionado propio, sin tocar `database.dart`.
- Aprovechar para que `productos` use PK en toda operación y tenga un estado explícito (`por_hacer`, `listo`, `empacado`) en lugar de la combinación `is_separate`/`is_certificate`/`is_package`.
- Las ubicaciones de muelle sí se **leen** de la base compartida (`ubicacionesRepository`), en solo lectura.

### Convivencia en el backend
Los dos módulos pegan al **mismo Odoo**, y eso no se puede aislar. Mientras convivan:
- Un mismo pedido no debería trabajarse en los dos módulos a la vez. Cada módulo ve los cambios del otro al refrescar desde la API, que es la fuente de verdad.
- Probar primero con usuarios o PDAs de prueba y pedidos de prueba.

### Acceso para pruebas
- Nuevo `HomeModuleId` "Packing pedido (nuevo)", **oculto por defecto** y habilitable desde el editor de módulos en `user_page`, por dispositivo.
- El acceso actual al packing por pedido no cambia.

---

## 1. Puntos de contacto con el resto de la app

| Dónde | Uso actual | Acción |
|---|---|---|
| `main.dart:195` | `BlocProvider(create: (_) => PackingPedidoBloc())` global | **No se toca.** Los blocs nuevos se proveen por ruta vía `getIt` |
| `core/routes/app_router.dart:133-136, 743-752` | `ListPackingScreen`, `PackingPedidoDetailScreen`, `ScanPackScreen`, `LocationDestPackingScreen` | **No se tocan.** Se agregan rutas nuevas (`packingPedidoV2*`) |
| `features/home/presentation/index.dart:27-28, 133` | `LoadAllNovedadesPackEvent` y `dialog_packing_widget` | **No se toca** el acceso actual. Se agrega el módulo nuevo (oculto por defecto); novedades vía `NovedadesCacheService` |
| `core/services/novedades_cache_service.dart` | Solo comentario | Solo lectura |
| `features/expedition/.../expedition_repository_impl.dart:131` | Replica la lógica de asignar responsable e iniciar tiempo | No se toca |
| `WmsPackingRepository` | Compartido con packing batch y consolidado | **No se usa.** El remote datasource propio llama a los endpoints con `ApiRequestService` |
| `DataBaseSqlite` (`productosPedidosRepository`, `pedidoPackRepository`, `packagesRepository`, `barcodesPackagesRepository`) | Compartidos | **No se usan.** Base SQLite propia `packing_pedido_v2.db` |
| `ubicacionesRepository` | Ubicaciones de muelle | Solo lectura |

---

## 2. Estructura destino

```
lib/features/packing_pedido/
├── domain/
│   ├── entities/
│   │   ├── pedido_packing.dart          # PedidoPackingResult
│   │   ├── producto_pedido.dart         # ProductoPedido (estado derivado: porHacer/listo/empacado)
│   │   ├── paquete.dart
│   │   ├── barcode_producto.dart
│   │   └── packing_results.dart         # UnPack/DeletePack/SendPack result
│   ├── repositories/
│   │   └── packing_pedido_repository.dart
│   └── usecases/                        # ver §3
├── data/
│   ├── models/                          # copias propias de los modelos (fromMap/toMap)
│   ├── datasources/
│   │   ├── packing_pedido_remote_data_source.dart   # endpoints directos con ApiRequestService
│   │   ├── packing_pedido_local_data_source.dart    # sobre la base propia
│   │   └── local/packing_pedido_database.dart       # packing_pedido_v2.db: esquema y versión propios
│   ├── services/
│   │   └── packing_pedido_sync_service.dart         # sync API→SQLite (limpieza + reconciliación)
│   └── repositories/
│       └── packing_pedido_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── list/        # PackingPedidoListBloc
    │   ├── detail/      # PackingPedidoDetailBloc
    │   ├── scan/        # PackingPedidoScanBloc
    │   ├── packages/    # PackingPackagesBloc (paquetes, ubicación destino)
    │   └── confirm/     # PackingConfirmBloc
    ├── pages/
    │   ├── packing_pedido_list_page.dart
    │   ├── packing_pedido_detail_page.dart   # 5 tabs
    │   ├── packing_pedido_scan_page.dart
    │   └── packing_location_dest_page.dart
    └── widgets/
        ├── tabs/                         # tab1..tab5 como widgets
        └── dialogs/                      # backorder, advertencia cantidad, temperatura, delete package, confirm packing
```

**Modelos:** se **copian** al feature los modelos legacy (`lista_product_packing.dart`, `response_packing_pedido_model.dart`, etc.) conservando el parseo, que es frágil (valores `false` de Odoo, listas `[id, name]`), para no importarlos ni modificarlos. Las entities quedan limpias.

---

## 3. Casos de uso (mapeo desde el bloc legacy)

| Use case | Evento(s) legacy | Bloc nuevo |
|---|---|---|
| `SyncPedidosPacking` | `LoadAllPackingPedidoEvent` (+ `_cleanOrphanPedidos`, `_cleanStalePackages`, `_cleanStaleProducts`, `_reconcileProductQuantities`) | list |
| `GetPedidosPackingLocal` | `LoadPackingPedidoFromDBEvent` | list |
| `AsignarResponsablePedido` | `AssignUserToPedido` + `StartOrStopTimePedido` | list |
| `EnviarTiempoPedido` | `StartOrStopTimePedido`, `StartOrStopTimePack` | list / detail |
| `GetPedidoConProductos` | `LoadPedidoAndProductsEvent` | detail |
| `GetBarcodesProducto` | `FetchProductEvent` | scan |
| `MarcarUbicacionOk` / `MarcarProductoOk` / `ActualizarCantidadSeparada` | `ChangeLocationIsOkEvent`, `ChangeProductIsOkEvent`, `ChangeQuantitySeparate`, `AddQuantitySeparate`, `ChangeIsOkQuantity` | scan |
| `SepararProducto` | `SetPickingsEvent` | scan |
| `DividirProducto` | `SetPickingSplitEvent` | scan |
| `DeshacerSeparacion` | `DeleteProductFromTemporaryPackageEvent` | detail |
| `CrearPaquete` | `SetPackingsEvent` | detail |
| `DesempacarProducto` | `UnPackingEvent` | packages |
| `EliminarPaquete` | `DeletePackageEvent` | packages |
| `AsignarUbicacionPaquetes` | `AssignLocationToPackageEvent` | packages |
| `GetUbicacionesMuelle` | `LoadAllLocationsEvent` | packages |
| `ValidarPedido` / `CrearBackorder` | `ValidateConfirmEvent`, `CreateBackPackOrNot` | confirm |
| `ObtenerTemperaturaIA` / `EnviarTemperatura` / `EnviarTemperaturaManual` | `GetTemperatureEvent`, `SendTemperatureEvent`, `SendTemperatureManualPackEvent` | scan |
| `EnviarImagenNovedad` | `SendImageNovedad` | scan |
| `GetImagenProducto` | `ViewProductImageEvent` → reusar `GetUrlImagenProducto` de inventario | scan / detail |
| `GetConfiguracionUsuario` | `LoadConfigurationsUser` → `ConfiguracionCacheService` | list |

La búsqueda, el orden, la selección de productos y paquetes y el expandir paquete son estado de UI: viven en el bloc y no necesitan use case.

---

## 4. Fases

### Fase 1 — Dominio (sin dependencias de Flutter)
- Entities, contrato `PackingPedidoRepository` con `Either<Failure, T>` y todos los use cases con `@lazySingleton`.
- Getters de estado en `ProductoPedido` (`isPorHacer`, `isListo`, `isEmpacado`) para reemplazar las comparaciones `== 1 || == true` repetidas en tabs y bloc.
- **Commit:** `feat(packing_pedido): capa de dominio`

### Fase 2 — Datos
- `RemoteDataSource`: llama a los endpoints con `ApiRequestService` (mismo body que el legacy) y convierte respuestas no-200 en excepciones tipadas. Quitar los `Get.defaultDialog` (403 / sesión expirada) del camino del feature y llevarlos a la presentación vía `Failure`.
- Base propia `packing_pedido_v2.db` (tablas `pedidos`, `productos`, `paquetes`, `barcodes`) con PK en toda operación y estado explícito por fila.
- `LocalDataSource` sobre esa base. Las ubicaciones se leen de la base compartida, en solo lectura.
- `PackingPedidoSyncService`: mover tal cual el sync, la limpieza y la reconciliación.
- `RepositoryImpl`: control de red (`hasNetwork`) y mapeo de excepciones a `Failure`.
- `_rowFromApiMove`, `updateConsecutivePackages` y `_extraerNumeroConsecutivo` pasan a `data/` (mapper / helper).
- Registro en DI (`build_runner`).
- **Commit:** `feat(packing_pedido): capa de datos y sync`

### Fase 3 — Blocs
Dividir el bloc de 2.700 líneas en 5. Reglas:
- Sin `TextEditingController` ni `DataBaseSqlite` dentro del bloc; la UI no modifica campos del bloc (hoy hace `packingBloc.quantitySelected = ...`).
- Estados con `Equatable`, preferentemente un estado único con `copyWith` por bloc (como `EnterpriseBloc`).
- Transformers: `droppable()` en crear paquete, separar y dividir; `restartable()` en cargar pedido.
- Comunicación entre blocs: después de separar, empacar o desempacar, el detail recarga. Usar un callback o un listener en la page, no `add()` cruzado.

| Bloc | Responsabilidad |
|---|---|
| `PackingPedidoListBloc` | sync, lista local, búsqueda, orden, asignar responsable, configuración |
| `PackingPedidoDetailBloc` | pedido actual, listas derivadas (por hacer / listos / empacados), búsqueda de productos, selección, crear paquete, deshacer separación |
| `PackingPedidoScanBloc` | producto actual, validación ubicación → producto → cantidad, separar, dividir, temperatura, novedad |
| `PackingPackagesBloc` | paquetes, expandir y seleccionar, desempacar, eliminar, ubicaciones y asignar ubicación destino |
| `PackingConfirmBloc` | validar y backorder (incluye el caso `expiry.picking.confirmation`) |

- Tests de bloc (`bloc_test` + mocks de use cases) en `test/features/packing_pedido/`.
- **Commit:** `feat(packing_pedido): blocs de presentación`

### Fase 4 — Presentación
- Pages y tabs como widgets, diálogos en `widgets/dialogs/`.
- Escaneo con `BarcodeScannerField` (`clearOnScan` y `refocusOnScan` donde aplique). Cuidar el focus-steal en `didChangeDependencies` y listeners.
- Barra superior con `OnPointHeaderSurface`. Diálogos de carga con `LoadingDialogMixin`.
- Header y buscador ya rediseñados en el commit `1befe2c6`: portarlos tal cual.
- **Commit:** `feat(packing_pedido): pantallas y widgets`

### Fase 5 — Integración aditiva
- Solo se **agregan** cosas: rutas `packingPedidoV2*` en `app_router`, registro DI y un `HomeModuleId` nuevo oculto por defecto.
- Las rutas, el `BlocProvider` y el acceso del home actuales no se tocan.
- Verificar con `git diff` que ningún archivo del módulo actual ni de los repositorios compartidos aparezca modificado.
- **Commit:** `feat(packing_pedido): integración con router y home`

### Fase 6 — Correcciones (commits separados, uno por bug)
Del análisis (`docs/analisis_packing_pedido.md`):
1. División y deshacer **por PK en una transacción**, en el local datasource propio (`splitProductRow(id, cantidad)`, `undoSplitRow(certifiedId)`).
2. `updateConsecutivePackages` con `copyWith` para no perder barcode ni ubicación destino.
3. Escaneo de cantidad: tope contra `quantity` y sin sonido de error en el escaneo correcto por barcode de empaque.
4. `quantitySelected` sincronizado con la BD al reentrar a una fila restante.
5. Validar cantidad 0 y `loteId` null al crear paquete.
6. `idUbicacionDestino` (copy-paste).
7. Upsert de sync sin pisar `quantity` de filas divididas.

Cada fix lleva su test (repositorio SQLite con `sqflite_common_ffi` o use case con mocks).

### Fase 7 — Reemplazo (opcional, decisión aparte)
- Solo cuando el feature nuevo esté validado en producción con algunos dispositivos.
- Habilitar el módulo nuevo por defecto y ocultar el viejo. Después de un periodo de convivencia, quitar el `BlocProvider` legacy de `main.dart`.
- Borrar `wms_packing/presentation/packing/` y los modelos o métodos que queden sin uso (verificar con grep que packing batch y consolidado no los usen).
- **Commit:** `refactor(packing_pedido): eliminar módulo legacy`

---

## 5. Plan de pruebas en PDA (antes de la fase 7)

| # | Caso | Esperado |
|---|---|---|
| 1 | Sync con pedidos nuevos, cancelados en Odoo y con paquetes desempacados desde backend | Lista y paquetes coinciden con Odoo |
| 2 | Asignar responsable a un pedido ya tomado por otro usuario | Error claro, sin cambios locales |
| 3 | Separar producto completo por escaneo (+1 y barcode de empaque) | Pasa a Listos, sin beep de error, sin pasarse de la cantidad |
| 4 | Cantidad menor → Aceptar con novedad (con y sin foto) | Separado con novedad; el resto queda para backorder |
| 5 | Dividir 10 → 4 + 6, empacar la de 4, refrescar | Por hacer = 6; paquete con 4 y el move nuevo de Odoo |
| 6 | Dividir varias veces (10 → 4 → 3 → 3) y deshacer en distinto orden, con y sin búsqueda activa | Nunca suma más de 10 |
| 7 | Empacar sin certificar desde Por hacer (normal y cluster con peso y tipo de empaque) | Endpoint correcto según `configPacking` |
| 8 | Desempacar una línea de un producto dividido (filas gemelas) | Solo esa fila vuelve a Por hacer |
| 9 | Eliminar paquete intermedio (Caja2 de 3) | Caja3 → Caja2 conservando barcode y ubicación destino |
| 10 | Asignar ubicación destino a varios paquetes | Persistido local y en Odoo |
| 11 | Validar con y sin backorder, y con productos vencidos | Flujo de confirmación completo |
| 12 | Producto con temperatura (foto IA y manual) | Temperatura e imagen guardadas |
| 13 | Sin red al crear paquete, desempacar o validar | Mensaje y estado local intacto |
| 14 | Doble tap en APLICAR CANTIDAD, crear paquete y confirmar | Una sola petición, sin diálogos pegados |
| 15 | Con el módulo nuevo instalado, usar el packing por pedido actual, batch y consolidado | Comportamiento idéntico al de antes; sus datos locales no cambian |

---

## 6. Riesgos

| Riesgo | Mitigación |
|---|---|
| Afectar al módulo actual, batch o consolidado | Rama propia, base SQLite propia, sin editar archivos compartidos y con `git diff` de control en cada fase |
| Mismo pedido trabajado en los dos módulos a la vez | Pruebas con pedidos y PDAs de prueba; el módulo nuevo oculto por defecto |
| Diferencias sutiles de comportamiento en sync y desempaque | Mover esa lógica sin reescribirla (fase 2) y corregir aparte (fase 6) |
| Respuestas de Odoo con formas inconsistentes (`false`, `[id, name]`) | Copiar el parseo de los modelos legacy tal cual |
| Dos módulos para el mismo proceso por mucho tiempo | Fijar fecha de reemplazo tras validar; los fixes van solo al nuevo |
| Focus-steal en escaneo con PDA Zebra | `BarcodeScannerField` y revisar los listeners en la fase 4 |

---

## 7. Estimación

| Fase | Esfuerzo relativo |
|---|---|
| 1 Dominio | 10% |
| 2 Datos + sync | 25% |
| 3 Blocs + tests | 30% |
| 4 Presentación | 20% |
| 5 Integración | 5% |
| 6 Correcciones + tests | 10% |
| 7 Corte | — (después de validar en PDA) |

Total: 2 a 3 sesiones largas de desarrollo (la base SQLite propia suma un poco a la fase 2), más 1 a 2 días de pruebas en PDA con Odoo real.
