# Plan de migración — Información Rápida → `features/info_rapida`

> Fecha: 2026-10-08 · Rama base: `desarrollo`
> Origen: `lib/src/presentation/views/info_rapida` (~11.800 líneas, 34 archivos)
> Referencias: `lib/features/FEATURE_TEMPLATE.md`, `docs/plan_migracion_packing_pedido.md` (mismo enfoque de aislamiento), uso de `GetUrlImagenProducto` de `features/inventario`

---

## 0. Objetivo y reglas

- Migrar a Clean Architecture **sin cambiar el comportamiento**, salvo los bugs listados en §4 fase 6 (se corrigen aparte, un commit por bug).
- **El legacy sigue funcionando sin cambios** durante todo el desarrollo. El reemplazo (fase 7) es una decisión aparte, recién después de validar en PDA.
- Cada fase cierra con `flutter analyze` limpio y un commit propio.
- **Desarrollo aislado (ver §0.1):** el feature nuevo no modifica ningún archivo del módulo actual ni de los repositorios compartidos.
- Widgets nuevos en `presentation/widgets/` (no privados en la screen). Búsquedas con `DynamicSearchBar`, escaneo con `BarcodeScannerField` y barra superior con `OnPointHeaderSurface` (el header actual de Info Rápida es la referencia del difuminado).

---

## 0.1 Aislamiento del módulo actual

**Requisito:** el desarrollo va aparte y no puede afectar a Información Rápida actual ni a los módulos que comparten sus maestras (Crear Transferencia, Conteo, Devoluciones, Print Labels).

### Git
- Rama propia: `feature/info-rapida-v2`, creada desde `desarrollo` **después** de commitear o guardar los cambios pendientes (hoy: `pubspec.yaml` y `.flutter-plugins-dependencies`).
- Opcional: worktree separado (`../appwms-info-rapida-v2`), igual que con packing pedido.
- Se mergea solo cuando pase las pruebas de PDA.

### Código: solo se agrega, nunca se modifica

| Permitido | Prohibido |
|---|---|
| Archivos nuevos en `lib/features/info_rapida/` | Editar cualquier archivo de `views/info_rapida/` |
| **Copiar** al feature los modelos y la lógica que hagan falta | Cambiar `InfoRapidaRepository`, `TransferenciasRepository` o `RecentQueriesStore` |
| Usar `ApiRequestService`, `hasNetwork`, `PrefUtils`, `UbicacionesCacheService`, `ProductosCacheService`, `ConfiguracionCacheService` e `IWebSocketService` (lectura y llamadas) | Cambiar `ProductoInventarioRepository`, `UbicacionesRepository`, `ProductCreateTransferRepository` o `database.dart` |
| Reusar `GetUrlImagenProducto` de `features/inventario` | Reemplazar rutas, `InfoRapidaScope`/`TransferInfoScope` o el acceso del home actual |
| Puntos de entrada **aditivos**: rutas nuevas, registro DI nuevo, módulo nuevo en el home | |

- El remote datasource llama a los endpoints directo con `ApiRequestService` (`transferencias/quickinfo`, `transferencias/quickinfo/id`, `crear_transferencia`, `transferencias/create_trasferencia`, `update_product`, `update_location`), sin pasar por `InfoRapidaRepository` ni `TransferenciasRepository`.
- Las correcciones de bugs (fase 6) se hacen **solo en el feature nuevo**. El legacy queda como está.

### Datos locales
A diferencia de packing, Info Rápida **no tiene tablas propias**: consulta siempre al backend y solo lee las maestras de productos y ubicaciones (vía los cache services) para las listas. No hace falta base SQLite propia.

| Dato | Legacy | Feature nuevo |
|---|---|---|
| Maestras productos / ubicaciones | `ProductosCacheService.getAllUnique()`, `UbicacionesCacheService.getAll()` | Igual, solo lectura (las listas en memoria se comparten con otros módulos) |
| Últimas consultas | `RecentQueriesStore` (SharedPreferences) | Store propio con **otra clave** (`info_rapida_v2_recent`), para no mezclar historiales mientras conviven |
| Producto editado | `productoInventarioRepository.updateProduct` | Actualizar vía `ProductosCacheService` (memoria + SQLite) para que las otras pantallas vean el cambio. Es la única escritura sobre datos compartidos y es intencional (igual que hoy) |
| Ubicación editada | `ubicacionesRepository.insertOrUpdateSingle` con solo `id/name/barcode` | Actualizar vía `UbicacionesCacheService` **conservando** el resto de campos (ver bug 3) |
| Tabla de Crear Transferencia | Se **vacía** al terminar una transferencia masiva | **No se toca** (ver bug 2) |

### Convivencia en el backend
Los dos módulos pegan al **mismo Odoo**. Info Rápida es mayormente de consulta, así que el riesgo se limita a las acciones de escritura (editar producto/ubicación, transferencia individual y masiva). Probar esas acciones con productos y ubicaciones de prueba.

### Acceso para pruebas
- Nuevo `HomeModuleId.infoRapidaV2` "Info Rápida (nuevo)", **oculto por defecto** y habilitable desde el editor de módulos en `user_page`, por dispositivo.
- El acceso actual (`HomeModuleId.infoRapida` → ruta `info-rapida`) no cambia.

---

## 1. Puntos de contacto con el resto de la app

| Dónde | Uso actual | Acción |
|---|---|---|
| `core/routes/app_router.dart:74-85, 255-266, 873-1030` | 10 rutas (`infoRapida`, `productInfo`, `locationInfo`, `paqueteInfo`, `transferInfo`, `listLocation`, `listProduct`, `searchLocationDestTransInfo`, `createMassTransfer`, `searchLocationCreateMassTransfer`) | **No se tocan.** Se agregan rutas `infoRapidaV2*` |
| `core/routes/app_router.dart:1091-1210` | `InfoRapidaScope` / `TransferInfoScope`: una instancia de bloc por entrada al módulo, pasada por argumentos entre rutas | **No se tocan.** El feature nuevo usa un scope propio (ver §4 fase 3) |
| `features/home/presentation/index.dart:217` y `home_module_catalog.dart:24` | `HomeModuleId.infoRapida` → `pushReplacementNamed('info-rapida')` | No se toca. Se agrega `infoRapidaV2` |
| `main.dart:188` | Comentario: los blocs ya no son globales | Nada |
| `providers/db/inventario/tbl_product/product_inventario_repository.dart:7` | Importa `UpdateProductRequest` del módulo legacy | No se toca. El feature tiene su propio request. **En la fase 7 hay que mover ese modelo antes de borrar el legacy** |
| `TransferenciasRepository.createTransfer` + modelos de `create-transfer` | Transferencia masiva | **No se usa.** Endpoint directo y modelos copiados |
| `IWebSocketService.messages` | `InfoRapidaBloc` escucha `notification/update` y llama `ProductosCacheService.applyWsProductUpsert` | Se mueve a un listener propio del feature (ver §3). Ojo: mientras convivan, los dos módulos aplican el mismo upsert (idempotente) |
| Widgets de `src/` (`dialog_loadingPorduct_widget`, `dialog_error_widget`, `dialog_view_img_temp_widget`, `LocationScanner_widget`, `warning_widget_cubit`) | Reusados desde otros módulos legacy | Reemplazar por `LoadingDialogMixin` y widgets de `shared/`. Lo que no exista, se copia al feature |

---

## 2. Estructura destino

```
lib/features/info_rapida/
├── domain/
│   ├── entities/
│   │   ├── info_rapida.dart              # resultado tipado: sealed InfoRapida → ProductoInfo | UbicacionInfo | PaqueteInfo
│   │   ├── producto_info.dart            # producto + ubicaciones donde está
│   │   ├── ubicacion_info.dart           # ubicación + productos que contiene
│   │   ├── paquete_info.dart
│   │   ├── recent_query.dart
│   │   └── transfer_results.dart
│   ├── repositories/
│   │   └── info_rapida_repository.dart
│   └── usecases/                         # ver §3
├── data/
│   ├── models/                           # copias de info_rapida_model, transfer_info_request, update_product_request, create_transfer
│   ├── datasources/
│   │   ├── info_rapida_remote_data_source.dart   # endpoints directos con ApiRequestService
│   │   └── recent_queries_local_data_source.dart # SharedPreferences, clave propia
│   ├── services/
│   │   └── info_rapida_ws_listener.dart          # WS → ProductosCacheService.applyWsProductUpsert
│   └── repositories/
│       └── info_rapida_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── scan/            # InfoRapidaScanBloc   (pantalla principal + últimas consultas)
    │   ├── product/         # ProductInfoBloc      (detalle, edición, imagen, orden de ubicaciones)
    │   ├── location/        # LocationInfoBloc     (detalle, edición, orden/búsqueda de productos, selección masiva)
    │   ├── catalog/         # CatalogSearchBloc    (listas de productos y ubicaciones, filtros por almacén)
    │   ├── transfer/        # TransferInfoBloc     (transferencia individual)
    │   └── mass_transfer/   # MassTransferBloc     (destino, validación de propietario, crear)
    ├── pages/
    │   ├── info_rapida_page.dart
    │   ├── product_info_page.dart
    │   ├── location_info_page.dart
    │   ├── paquete_info_page.dart
    │   ├── list_products_page.dart
    │   ├── list_locations_page.dart
    │   ├── transfer_info_page.dart
    │   ├── location_dest_page.dart        # unifica locations_dest_widget y location_search_widget
    │   └── mass_transfer_page.dart
    └── widgets/
        ├── cards/           # scan_hero, recent_queries, product_detail, location_detail, location, mass_transfer_product
        └── dialogs/         # dialog_info, dispositivo no autorizado, actualizar versión
```

**Modelos:** se **copian** al feature (`info_rapida_model.dart` es un modelo único con campos de producto, ubicación y paquete mezclados; el parseo de Odoo con `false` y `[id, name]` se conserva tal cual). Las entities sí se separan por tipo: hoy la UI decide por `result.type == 'product' | 'ubicacion' | 'paquete'` y lee campos que pueden no existir.

**Carpeta `quick info`:** el nombre con espacio obliga a importar con `%20`. En el feature nuevo no existe.

---

## 3. Casos de uso (mapeo desde los blocs legacy)

| Use case | Evento(s) legacy | Bloc nuevo |
|---|---|---|
| `ConsultarPorBarcode` | `GetInfoRapida(isManual: false)` → `transferencias/quickinfo` | scan |
| `ConsultarPorId` | `GetInfoRapida(isManual: true, isProduct)` → `transferencias/quickinfo/id` | scan / catalog / location (al tocar una fila) |
| `GetConsultasRecientes` / `GuardarConsultaReciente` / `BorrarConsultasRecientes` | `RecentQueriesStore` (llamado desde el bloc y la UI) | scan |
| `GetCatalogoProductos` | `GetProductsList`, `InitInfoRapidaEvent` → `ProductosCacheService.getAllUnique()` | catalog |
| `GetCatalogoUbicaciones` | `GetListLocationsEvent`, `LoadLocationsTransfer`, `InitInfoRapidaEvent` → `UbicacionesCacheService.getAll()` | catalog / transfer / mass_transfer |
| `GetConfiguracionUsuario` | `LoadConfigurationsUserInfo` → `ConfiguracionCacheService` (permisos de edición y transferencia) | scan (se pasa a las demás pages) |
| `ActualizarProducto` | `UpdateProductEvent` → `update_product` + update local | product |
| `ActualizarUbicacion` | `EditLocationEvent` → `update_location` + update local | location |
| `GetImagenProducto` | `ViewProductImageEvent` → reusar `GetUrlImagenProducto` de inventario | product |
| `CrearTransferenciaIndividual` | `SendTransferInfo` → `crear_transferencia` | transfer |
| `CrearTransferenciaMasiva` | `CreateNewMassTransferEvent` → `transferencias/create_trasferencia` | mass_transfer |

Estado de UI (sin use case, vive en el bloc): búsquedas (`SearchProductEvent`, `SearchLocationEvent`, `SearchProductLocationEvent`, `SearchLocationProductsEvent`), filtro por almacén, orden (`SortProductsEvent`, `SortLocationsEvent`), expandir (`ToggleProductExpansionEvent`), modo edición (`IsEditEvent`), selección masiva (`ToggleProductMassTransferEvent`, `SelectAllAvailableProductsEvent`, `RemoveProductFromMassTransferEvent`, regla de un solo propietario), validaciones de escaneo (`ValidateFieldsEvent`, `ChangeLocationIsOkEvent`, `ChangeProductIsOkEvent`, `ChangeLocationDestIsOkEventTransfer`) y fechas de inicio/fin.

La regla "no mezclar propietarios" (`_propietarioKey`) pasa a una función pura en `domain/` con test propio.

---

## 4. Fases

### Fase 1 — Dominio (sin dependencias de Flutter)
- Entities (sealed `InfoRapida` con sus tres variantes), contrato `InfoRapidaRepository` con `Either<Failure, T>` y use cases con `@lazySingleton`.
- Failures específicos: `DispositivoNoAutorizadoFailure` (403), `SesionExpiradaFailure` (error 100), `NoEncontradoFailure` (404), `ActualizarVersionFailure` (`update_version`), `SinConexionFailure`.
- Regla de propietario como función pura.
- **Commit:** `feat(info_rapida): capa de dominio`

### Fase 2 — Datos
- `RemoteDataSource`: mismos endpoints y body que el legacy (incluye `device_id` MAC/IMEI y `version_app`). Convierte cada `code` en excepción tipada. **Sin `Get.defaultDialog`**: la sesión expirada sube como `Failure` y la muestra la presentación.
- Unificar las dos variantes de consulta (`getInfoQuick` y `getInfoQuickManual` repiten ~100 líneas cada una) en un método con parámetros.
- `RecentQueriesLocalDataSource` con clave propia; `RecentQuery.fromResult` se mueve como mapper.
- `InfoRapidaWsListener` (`@lazySingleton`, arranca con el scope del módulo y se cancela al salir).
- `RepositoryImpl`: `hasNetwork` y mapeo de excepciones a `Failure`.
- Registro en DI (`build_runner`).
- **Commit:** `feat(info_rapida): capa de datos`

### Fase 3 — Blocs
Partir `InfoRapidaBloc` (1.006 líneas, 26 eventos) y `TransferInfoBloc` (259 líneas). Reglas:
- Sin `TextEditingController`, `FocusNode` ni `DataBaseSqlite` dentro del bloc. La UI no modifica campos del bloc (hoy `transfer_info_screen.dart:902,912` hace `bloc.quantitySelected = ...`).
- Estados con `Equatable`, un estado único con `copyWith` por bloc.
- Transformers: `restartable()` en consultas y búsquedas, `droppable()` en actualizar producto/ubicación y crear transferencias.
- Sin `add()` desde el propio bloc para encadenar flujos (hoy `CreateNewMassTransferEvent` dispara `GetInfoRapida` y la edición dispara `IsEditEvent`). La page escucha el éxito y decide.
- Hoy un mismo `InfoRapidaBloc` viaja por argumentos entre 8 rutas. En el feature, cada page crea su bloc vía `getIt` y recibe por argumento solo la entity que necesita (`ProductoInfo`, `UbicacionInfo`). Las maestras viven en los cache services, no en el bloc.

| Bloc | Responsabilidad |
|---|---|
| `InfoRapidaScanBloc` | consulta por barcode/id, últimas consultas, configuración, navegación según tipo, 403 y actualizar versión |
| `ProductInfoBloc` | producto actual, edición, imagen, búsqueda y orden de ubicaciones del producto |
| `LocationInfoBloc` | ubicación actual, edición, búsqueda y orden de productos, modo selección masiva |
| `CatalogSearchBloc` | listas de productos y ubicaciones, búsqueda, filtro por almacén |
| `TransferInfoBloc` | ubicación destino, cantidad, fechas, enviar transferencia individual |
| `MassTransferBloc` | productos seleccionados, destino, crear transferencia masiva |

- Tests de bloc (`bloc_test` + mocks de use cases) en `test/features/info_rapida/`.
- **Commit:** `feat(info_rapida): blocs de presentación`

### Fase 4 — Presentación
- Pages y widgets según §2. Portar tal cual el rediseño del commit `fa6f9336` (pantallas de ubicación y producto) y el header actual.
- Escaneo con `BarcodeScannerField` (`clearOnScan` en la pantalla principal). Cuidar el focus-steal: hoy el `FocusNode` del buscador de ubicaciones vive en el bloc porque `ProductInfoScreen` es `StatelessWidget`; en el feature va en el `State` de la page.
- Diálogos de carga con `LoadingDialogMixin` (reemplaza `dialog_loadingPorduct_widget` de batch).
- Unificar `locations_dest_widget.dart` (transfer) y `location_search_widget.dart` (masiva): son la misma pantalla de selección de destino.
- **Commit:** `feat(info_rapida): pantallas y widgets`

### Fase 5 — Integración aditiva
- Solo se **agregan** cosas: rutas `infoRapidaV2*` en `app_router`, registro DI y `HomeModuleId.infoRapidaV2` oculto por defecto.
- Verificar con `git diff` que ningún archivo de `views/info_rapida/` ni de los repositorios compartidos aparezca modificado.
- **Commit:** `feat(info_rapida): integración con router y home`

### Fase 6 — Correcciones (commits separados, uno por bug)
Detectados al relevar el legacy:
1. **404 emite el error dos veces** (`_onGetInfoRapida`: rama `else` + `if (code == 404)` posterior) → un solo estado de error.
2. **La transferencia masiva vacía la tabla de Crear Transferencia** (`deleteAllProductsCreateTransfer` en `_onCreateTransferEvent`): borra el borrador de otro módulo. En el feature no se toca esa tabla.
3. **Editar ubicación pisa campos**: `insertOrUpdateSingle` con `ConflictAlgorithm.replace` y solo `id/name/barcode` deja en null almacén, ubicación padre y `is_a_dock`. Actualizar con `copyWith` sobre la ubicación existente. Además, la edición no actualiza la memoria de `UbicacionesCacheService` ni `ProductosCacheService` → las listas muestran el dato viejo hasta reiniciar.
4. **Editar ubicación con error emite `UpdateProductFailure`** (copy-paste) → `EditLocationFailure`.
5. **Sin red se muestra "Error desconocido"**: `getInfoQuick`/`getInfoQuickManual` devuelven `InfoRapida()` vacío → mensaje de sin conexión.
6. **`update_version` no corta el flujo**: emite `NeedUpdateVersionState` y sigue hasta `InfoRapidaLoaded` (dos diálogos/navegaciones). Decidir con el usuario si bloquea o solo avisa.
7. **Rama "Caja" muerta**: ambas ramas llaman igual a `getInfoQuick` (una sin `trim()`). Unificar con `trim()`.
8. **`isLoadingDialog` ignorado** en `updateProduct`, `updateLocation` y `sendProductTransferInfo` (siempre `true`). Desaparece al sacar los diálogos del datasource.
9. `_onShowQuantityEvent` de `TransferInfoBloc` nunca se registra (código muerto): no se porta.

Cada fix lleva su test (use case o bloc con mocks; el 3 con `sqflite_common_ffi`).

### Fase 7 — Reemplazo (opcional, decisión aparte)
- Solo cuando el feature nuevo esté validado en producción con algunos dispositivos.
- Habilitar `infoRapidaV2` por defecto y ocultar el viejo. Tras un periodo de convivencia, apuntar `HomeModuleId.infoRapida` a la ruta nueva.
- Mover `UpdateProductRequest` fuera del legacy (lo importa `product_inventario_repository.dart`), quitar las 10 rutas, `InfoRapidaScope`/`TransferInfoScope` y borrar `views/info_rapida/`. Verificar con grep que nada más lo importe.
- Migrar o descartar el historial de `RecentQueriesStore` (clave vieja).
- **Commit:** `refactor(info_rapida): eliminar módulo legacy`

---

## 5. Plan de pruebas en PDA (antes de la fase 7)

| # | Caso | Esperado |
|---|---|---|
| 1 | Escanear barcode de producto, de ubicación y de paquete (`CAJA...`) | Abre el detalle correcto de cada tipo |
| 2 | Escanear barcode inexistente | Un solo mensaje de "no encontrado" |
| 3 | PDA no registrada (403) y sesión expirada | Diálogo de dispositivo no autorizado / aviso de sesión, sin pantallas pegadas |
| 4 | Backend pide actualizar versión | Un solo aviso, comportamiento acordado (bug 6) |
| 5 | Sin red al consultar, editar o transferir | Mensaje de sin conexión, nada cambia |
| 6 | Últimas consultas: guardar, repetir desde la tarjeta, borrar | Repite con los mismos parámetros; no aparecen las consultas internas del flujo de transferencia |
| 7 | Lista de productos y ubicaciones con búsqueda y filtro por almacén (maestras de miles de registros) | Respuesta inmediata, sin recargar en cada entrada |
| 8 | Editar producto (nombre, barcode, precio, peso, volumen) y volver a la lista | Persistido en Odoo y visible en la lista y en Crear Transferencia |
| 9 | Editar ubicación y revisar almacén/padre/muelle en otra pantalla | Nombre y barcode nuevos; el resto de campos intactos |
| 10 | Transferencia individual con escaneo de destino y cantidad parcial | Transferencia creada; se refresca la info del producto |
| 11 | Transferencia masiva: seleccionar todo, mezclar propietarios, quitar productos | Bloquea la mezcla con el mensaje correcto; crea la transferencia y muestra la ubicación destino |
| 12 | Transferencia masiva con un borrador abierto en Crear Transferencia | El borrador de Crear Transferencia sigue ahí |
| 13 | Producto actualizado por WebSocket con la lista abierta | La lista refleja el cambio |
| 14 | Doble tap en guardar edición y en confirmar transferencias | Una sola petición |
| 15 | Escaneo continuo en Zebra (pantalla principal y detalle con buscador) | El teclado no se cierra solo, el foco no salta |
| 16 | Con el módulo nuevo instalado, usar Info Rápida actual, Crear Transferencia, Conteo y Print Labels | Comportamiento idéntico al de antes |

---

## 6. Riesgos

| Riesgo | Mitigación |
|---|---|
| Afectar al módulo actual o a los que comparten maestras | Rama propia, sin editar archivos compartidos, solo lectura de los cache services y `git diff` de control en cada fase |
| Diferencias sutiles por separar el modelo único en tres entities | Copiar el parseo tal cual en `data/models` y mapear a entities con tests de mapper usando respuestas reales de Odoo |
| Doble aplicación del upsert por WebSocket mientras conviven | Es idempotente; verificarlo en la prueba 13 |
| Pérdida del estado al dejar de pasar un bloc único entre rutas | Cada page recibe la entity por argumento; los flujos de transferencia devuelven resultado con `Navigator.pop(result)` |
| Focus-steal en escaneo con PDA Zebra | `BarcodeScannerField` y `FocusNode` en el `State` de la page (fase 4) |
| Dos módulos para el mismo proceso por mucho tiempo | Fijar fecha de reemplazo tras validar; los fixes van solo al nuevo |

---

## 7. Estimación

| Fase | Esfuerzo relativo |
|---|---|
| 1 Dominio | 10% |
| 2 Datos | 15% |
| 3 Blocs + tests | 30% |
| 4 Presentación | 30% |
| 5 Integración | 5% |
| 6 Correcciones + tests | 10% |
| 7 Corte | — (después de validar en PDA) |

Total: 2 sesiones largas de desarrollo (sin base propia, la capa de datos es más liviana que en packing; el peso está en las 9 pantallas), más 1 día de pruebas en PDA con Odoo real.
