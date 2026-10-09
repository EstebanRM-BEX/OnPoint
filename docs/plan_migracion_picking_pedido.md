# Plan de migración — Picking por Pedido (Pick) → `features/picking`

> Fecha: 2026-10-08 · Rama base: `desarrollo`
> Legacy: `lib/src/presentation/views/wms_picking/modules/Pick` (~13.000 líneas, 24 archivos)
> Avance existente: `lib/features/picking` (~7.000 líneas, 56 archivos, **sin conectar** a rutas)
> Referencias: `lib/features/FEATURE_TEMPLATE.md`, `docs/plan_migracion_packing_pedido.md`, patrón de `features/picking_cluster`

---

## 0. Objetivo y reglas

- **Regla principal:** se conserva el **diseño** (layout, tarjetas, colores, textos y orden de pasos) y la **funcionalidad principal** del Pick actual. La única pantalla que cambia de forma visible es la de **scan**, y solo con las mejoras de §5 (foco, feedback y validaciones), sin cambiar su estructura.
- Migrar a Clean Architecture sin cambiar el comportamiento, salvo los bugs de §4 fase 6 (un commit por bug).
- **El legacy sigue funcionando sin cambios** hasta el reemplazo (fase 7), que se decide después de validar en PDA.
- Se **continúa** el avance de `features/picking` (no se empieza de cero), pero la **fuente de verdad de comportamiento es el legacy**: tiene los fixes de sept/oct que el feature no tiene (ver §2.3).
- Cada fase cierra con `flutter analyze` limpio y un commit propio.
- Widgets nuevos en `presentation/widgets/`. Escaneo con `BarcodeScannerField`, diálogos de carga con `LoadingDialogMixin`.
- Mientras convivan, **todo fix del scan va en las dos versiones** (regla vigente de pantallas gemelas).

---

## 1. Análisis del legacy

### 1.1 Inventario

| Archivo | Líneas | Rol |
|---|---|---|
| `bloc/picking_pick_bloc.dart` | 2.766 | Bloc global (en `main.dart:193`) con **45 eventos**: lista, detalle, scan, envío a Odoo, cola offline, validación, muelles, historial **y picking de componentes** |
| `screens/scan_product_screen.dart` | 1.852 | Scan: ubicación → producto → cantidad → muelle |
| `screens/index_list_pick_screen.dart` | 1.476 | Lista de picks: búsqueda (`DynamicSearchBar`) + escáner, orden, asignar y tiempo de inicio |
| `screens/pick_detail_pick_screen.dart` | 1.379 | Detalle: productos, buscar, editar cantidad y reenviar a Odoo, imagen |
| `screens/history_pick/*` | 1.715 | Historial de picks hechos y su detalle |
| `data/picking_pick_repository.dart` | 596 | `transferencias/pick`, `transferencias/history_picking`, `picking/componentes`, `picking/componentes/history`, `transferencias/{id}` |
| `models/*` | 900 | `ResultPick`, `PickWithProducts`, `RespondePickDoneId`… |
| `widgets/*` | 1.700 | Tarjetas de ubicación/producto/muelle, diálogos (backorder, cantidad, incompleto, vencidos), submuelle, popup |

Endpoints que usa vía otros repositorios: `send_transfer/pick` (enviar producto), `transferencias/asignar`, `update_time_transfer`, validar y confirmar validación (`TransferenciasRepository`), `muelles` y `update_dock` (`WmsPickingRepository`).

### 1.2 Funcionalidad principal (a conservar)

1. Lista offline-first (SQLite) con refresco desde Odoo, búsqueda, orden y escaneo de pick.
2. Asignar responsable e iniciar tiempo al entrar a un pick.
3. Scan secuencial: ubicación origen → producto (barcode principal o alterno) → cantidad (escaneo +1, barcode de empaque con cantidad, o manual) → muelle / submuelle.
4. Cantidad menor a la pedida con advertencia y novedad; tope de exceso solo para componentes.
5. Envío por producto a Odoo (`send_transfer/pick`) con **cola offline**: si falla queda `is_send_odoo = 0` y `SyncPendingProductsPickEvent` reenvía todo lo pendiente al volver la red.
6. Cierre bloqueado mientras haya pendientes o envíos en vuelo (`_trackOdooWrite`, `_waitOdooWrites`, `PickingOkBlockedPendingSendPick`).
7. Validar con o sin backorder, confirmación de vencidos (`expiry.picking.confirmation`).
8. Detalle: editar cantidad y reenviar, buscar producto, ver imagen.
9. Historial por fecha y detalle de un pick hecho.

### 1.3 Acoplamientos importantes

| Acoplamiento | Impacto |
|---|---|
| **Picking de componentes (producción)** usa el mismo `PickingPickBloc` y las **mismas pantallas** de scan y detalle (`index_list_picking_componentes_screen.dart` navega a `scan-product-pick`; el scan decide con `typePick == 'pick'` adónde volver y si aplica el permiso de exceso) | El scan nuevo no puede reemplazar al legacy hasta que componentes también migre o tenga su propia ruta. Ver §4 fase 7 |
| Tablas compartidas por `type_pick` (`'pick'` / `'pick-componentes'`) en `pickRepository`, `pickProductsRepository`, `barcodesPackagesRepository` | El feature nuevo escribe en las **mismas filas** que el legacy (ver §3) |
| `novedades_cache_service.dart` referencia `PickingPickBloc` | Solo lectura |
| `providers/db/picking/*` importa modelos de `modules/Pick/models` | En la fase 7 hay que mover los modelos antes de borrar el legacy |
| Bloc global en `main.dart` | El estado del scan sobrevive entre pantallas por estar en memoria global; el feature lo maneja por ruta |

### 1.4 Problemas detectados en el scan legacy

1. **Foco frágil:** 6 `FocusNode` arbitrados en `didChangeDependencies` según 4 booleanos del bloc (`locationIsOk`, `productIsOk`, `quantityIsOk`, `locationDestIsOk`) + `viewQuantity`. Es la causa del focus-steal recurrente (teclado que se cierra, foco que salta al volver del background).
2. **Beep de error en un escaneo correcto:** en `validateScannedBarcode(isProduct: false)` el barcode de empaque suma la cantidad y después **cae** al `vibrate()` + `playErrorSound()` y devuelve `false`.
3. **Cantidad tope sin feedback:** si `quantitySelected == quantity`, `validateQuantity` hace `return` silencioso; el operario no sabe por qué no suma.
4. **Lógica de validación en la UI:** el match de barcode, barcodes alternos y la suma por empaque viven en la screen. Con barcode alterno la UI dispara 3 eventos seguidos (`ChangeQuantitySeparate(0)`, `ChangeProductIsOkEvent`, `ChangeIsOkQuantity`) y depende de su orden.
5. **Comparaciones de `double` con `==`** (`cantidad == currentProduct.quantity`) en cantidades con decimales.
6. **La UI escribe campos del bloc** (`batchBloc.oldLocation = ...`) y el bloc guarda `TextEditingController`s.
7. **Sin indicador de pendientes:** el operario solo se entera de que hay productos sin enviar cuando intenta cerrar.

---

## 2. Análisis del avance en `features/picking`

### 2.1 Qué hay

| Capa | Contenido | Estado |
|---|---|---|
| Dominio | Entities `Pick`, `PickFetchResult`, `ScanSendResult`; 3 repositorios (`picking`, `pick_scan`, `picking_components`); 24 use cases (fetch, asignar, tiempo, marcar ubicación/producto/cantidad/muelle, enviar a Odoo, validar, muelles, imagen, historial, componentes) | Bastante completo |
| Datos | 6 datasources + 3 repository impl con `NetworkInfo` y `Either` | **Envuelven a los repos legacy** (`PickingPickRepository`, `TransferenciasRepository`, `WmsPickingRepository`) y usan los modelos de `modules/Pick/models` |
| Blocs | `PickScanBloc` (934 líneas, 23 eventos, `@injectable`); `PickingListBloc` (394); `PickingComponentsBloc` (112) | `PickingListBloc` y `PickingComponentsBloc` **no están registrados** en DI |
| Pantallas | `index_list_pick_screen.dart` (1.132) y `scan_product_screen.dart` (1.595) | **Copias** del legacy (~1.400-1.700 líneas de diferencia), **sin ruta**. La lista todavía usa `PickingPickBloc` (`ppb.`) en 6 lugares |
| Detalle, historial | — | No migrados |
| Tests | — | No hay |

### 2.2 Qué falta respecto al legacy

- Cola offline: `SyncPendingProductsPickEvent`, suscripción a red, `_trackOdooWrite`/`_waitOdooWrites`, bloqueo de cierre con pendientes.
- `SendProductEditOdooEvent`, `LoadProductEditEvent` y búsqueda de productos (detalle).
- `LoadAllNovedadesPickEvent` → `NovedadesCacheService`; `LoadSelectedProductEvent`; historial por id.
- Pantallas de detalle e historial.
- Registro en DI de los blocs de lista y componentes, rutas y acceso desde el home.

### 2.3 Desfase con el legacy

Fixes aplicados al legacy después del fork que hay que **verificar o portar** al feature:
- `122de60c` validación colgada, parpadeo y pérdida de sesión en Pick.
- `4f46a2e6` porcentaje de unidades separadas siempre actualizado.
- `82029518` botón validar del historial según permiso y rango por fecha.
- `bf53244e` selección manual solo ofrece el producto/ubicación actual.
- `d76eaca6` watchdog de teclado del IME.

**Decisión:** se conservan el dominio, los use cases y los repository impl del feature. Las pantallas se **reconstruyen desde el legacy actual** (no desde las copias del feature) para no perder esos fixes ni el diseño vigente.

---

## 3. Aislamiento y datos

### Git
- Rama propia `feature/picking-pedido-v2` desde `desarrollo` (opcional worktree `../appwms-picking-v2`). Se mergea tras las pruebas de PDA.

### Código

| Permitido | Prohibido |
|---|---|
| Archivos nuevos o cambios dentro de `lib/features/picking/` | Editar `wms_picking/modules/Pick/` (salvo los fixes gemelos del scan) |
| Copiar al feature modelos y widgets del legacy | Cambiar `PickingPickBloc`, sus rutas o su `BlocProvider` en `main.dart` |
| Usar `ApiRequestService`, `NetworkInfo`, `PrefUtils`, cache services | Cambiar el esquema de `database.dart` |
| Rutas nuevas `pickV2*`, registro DI, `HomeModuleId` nuevo | Tocar el flujo de picking de componentes |

### Datos locales: tablas compartidas (a diferencia de packing)
Packing usó base propia porque el feature nuevo cambiaba el modelo de datos. Acá el modelo es el mismo, y la cola offline del legacy (`SyncPendingProductsPickEvent`) ya reenvía **todos** los `is_send_odoo = 0` de la tabla. Con tablas compartidas, un pendiente que quede del módulo nuevo lo reenvía cualquiera de los dos. Por eso:

- El feature usa las **mismas tablas** con `type_pick = 'pick'`, a través de los repos existentes, **sin cambiar el esquema**.
- Regla operativa: **un mismo pick no se trabaja en los dos módulos a la vez** en el mismo dispositivo.
- En la fase 2 se eliminan las dependencias del feature a **repos legacy de API** (`PickingPickRepository`, `TransferenciasRepository`, `WmsPickingRepository`): el remote datasource llama a los endpoints con `ApiRequestService`. Los repos SQLite sí se siguen usando.

### Acceso para pruebas
- `HomeModuleId.pickV2` "Picking pedido (nuevo)", **oculto por defecto**, habilitable por dispositivo desde `user_page`. El acceso actual (`dialog_picking_widget` → `pick`) no cambia.

---

## 4. Fases

### Fase 1 — Dominio (completar)
- Revisar los 24 use cases contra los 45 eventos del legacy (§6) y agregar los que faltan: `SincronizarPendientes`, `ContarPendientes`, `EditarCantidadYReenviar`, `GetNovedades`, `GetHistorialPickPorId`.
- **Nuevo:** `ValidarEscaneoPick` (función pura) que recibe el paso actual, el valor escaneado, el producto y sus barcodes y devuelve un resultado tipado (`UbicacionOk`, `ProductoOk(viaAlterno)`, `SumarCantidad(n)`, `CantidadTope`, `MuelleOk`, `NoCoincide`). Saca de la UI toda la lógica de §1.4 puntos 2-5.
- Comparaciones de cantidad con tolerancia (`(a - b).abs() < 1e-6`).
- Tests unitarios de `ValidarEscaneoPick` (barcode principal, alterno, empaque, tope, decimales).
- **Commit:** `feat(picking): completar dominio y validación de escaneo`

### Fase 2 — Datos
- Remote datasource con `ApiRequestService` directo (mismo body que el legacy). Sin `Get.defaultDialog` en datos: errores como `Failure`.
- Copiar al feature los modelos de `modules/Pick/models` que use, conservando el parseo de Odoo.
- `PickPendingSyncService` (`@lazySingleton`): mueve la cola offline del legacy (sync de pendientes, `_cantidadPermitida`, contador de envíos en vuelo) para que la usen el scan y el detalle.
- Registrar `PickingListBloc` en DI (`@injectable`).
- **Commit:** `feat(picking): capa de datos propia y cola offline`

### Fase 3 — Blocs
| Bloc | Responsabilidad | Base |
|---|---|---|
| `PickingListBloc` | lista, búsqueda, orden, asignar, tiempo, configuración | existente, quitar el uso de `PickingPickBloc` |
| `PickScanBloc` | scan secuencial con **paso explícito** (`enum PickScanStep { ubicacion, producto, cantidad, muelle, submuelle }`), envío por producto, cierre, validación | existente, agregar cola offline y `ValidarEscaneoPick` |
| `PickDetailBloc` | productos del pick, buscar, editar cantidad y reenviar, imagen | nuevo |
| `PickHistoryBloc` | historial por fecha y detalle por id | nuevo |

Reglas:
- Estado único con `copyWith` y `Equatable`. Sin `TextEditingController` ni `FocusNode` en el bloc; la UI no escribe campos del bloc.
- Un solo evento `PickScanReceived(String value)`: el bloc resuelve con `ValidarEscaneoPick` y emite el nuevo paso. Reemplaza las cadenas de 3 eventos de la UI.
- `droppable()` en enviar, validar, backorder y muelles (ya está en parte); `restartable()` en cargar pick.
- El scan y el detalle comparten el pick por **ruta** (argumentos) y repositorio, no por un bloc global.
- Tests con `bloc_test` en `test/features/picking/`.
- **Commit:** `feat(picking): blocs de lista, scan, detalle e historial`

### Fase 4 — Presentación (diseño igual al legacy)
- Lista, detalle e historial: **portar tal cual** el diseño del legacy actual. Solo se cambia de dónde salen los datos.
- Scan: mismo layout y mismas tarjetas (`LocationScannerWidget`, `ProductScannerWidget`, `LocationDestScannerWidget`, tarjeta de cantidad, popup y barra de progreso), con las mejoras de §5.
- Diálogos copiados a `widgets/dialogs/` (backorder, advertencia cantidad, incompleto, vencidos, submuelle).
- **Commit:** `feat(picking): pantallas`

### Fase 5 — Integración aditiva
- Rutas `pickV2`, `pickV2Detail`, `scanProductPickV2`, `pickV2History`; registro DI; `HomeModuleId.pickV2` oculto.
- Verificar con `git diff` que no cambió nada de `modules/Pick/` (salvo fixes gemelos) ni de picking de componentes.
- **Commit:** `feat(picking): integración con router y home`

### Fase 6 — Correcciones (en el feature; las del scan también en el legacy)
1. Beep de error en escaneo correcto por barcode de empaque.
2. Feedback (sonido y mensaje "Cantidad completa") al llegar al tope.
3. Comparaciones de cantidad con tolerancia.
4. Una sola transición por escaneo (sin cadenas de eventos desde la UI).
Cada fix con su test.

### Fase 7 — Reemplazo (decisión aparte)
- Requisito previo: **picking de componentes** pasa a usar el scan nuevo (parametrizado por `typePick`) o queda con su propia ruta al scan legacy. Sin esto no se puede quitar `PickingPickBloc`.
- Habilitar `pickV2` por defecto, ocultar el viejo y, tras convivencia, apuntar `pick` a la ruta nueva.
- Mover los modelos que importa `providers/db/picking/*`, quitar el `BlocProvider` de `main.dart` y borrar `modules/Pick/`.
- **Commit:** `refactor(picking): eliminar módulo legacy`

---

## 5. Mejoras de la pantalla de scan

Se mantiene el diseño; cambia el comportamiento interno y algunos indicadores.

| # | Mejora | Detalle |
|---|---|---|
| 1 | **Foco por paso, no por booleanos** | Un `FocusNode` por campo dueño de la page y un `ValueListener` sobre `state.step` que pide el foco una sola vez al cambiar de paso. Se elimina el arbitraje en `didChangeDependencies`. El campo de cantidad manual conserva `KeyboardWatchdog` |
| 2 | **Un solo punto de escaneo por paso** | `BarcodeScannerField` con `clearOnScan` y `refocusOnScan`; envía `PickScanReceived` y el bloc decide. Guard anti doble disparo incluido |
| 3 | **Feedback claro** | Error: sonido + vibración + mensaje corto del motivo ("Ubicación incorrecta", "Producto incorrecto", "Supera la cantidad", "Cantidad completa"). Acierto: sin beep de error |
| 4 | **Paso actual visible** | Resaltar la tarjeta del paso activo (borde de color de marca) con el mismo estilo actual; el resto queda atenuado como hoy |
| 5 | **Pendientes de envío** | Badge en el header con la cantidad de productos `is_send_odoo = 0` y reintento manual al tocarlo |
| 6 | **Barcode de empaque** | Mostrar "+N (empaque)" al sumar por empaque, para distinguirlo del +1 |
| 7 | **Volver del background** | Restaurar el foco del paso actual sin reconstruir la pantalla (hoy se re-arbitra todo) |
| 8 | **Doble tap** | `droppable()` y botón deshabilitado mientras se envía en APLICAR CANTIDAD y en confirmar |

---

## 6. Mapeo de eventos legacy → feature

| Evento legacy | Feature | Estado |
|---|---|---|
| `FetchPickingPickEvent`, `FetchPickingPickFromDBEvent`, `SearchPickEvent`, `SortPickListEvent` | `PickingListBloc` | Existe |
| `AssignUserToTransfer`, `StartOrStopTimeTransfer` | `PickingListBloc` / `PickScanBloc` | Existe |
| `LoadConfigurationsUser`, `LoadDataInfoEvent` | `GetPickConfigurations` | Existe |
| `FetchPickWithProductsEvent`, `FetchBarcodesProductEvent`, `ChangeCurrentProduct` | `PickScanBloc` | Existe |
| `ChangeLocationIsOkEvent`, `ChangeProductIsOkEvent`, `ChangeIsOkQuantity`, `ChangeLocationDestIsOkEvent`, `ValidateFieldsEvent`, `ChangeQuantitySeparate`, `AddQuantitySeparate`, `QuantityChanged` | `PickScanReceived` + `ValidarEscaneoPick` (los use cases `Mark*` quedan como pasos internos) | Rehacer |
| `ShowQuantityEvent`, `SetIsProcessingEvent` | Estado de UI del `PickScanBloc` | Existe |
| `SelectNovedadEvent`, `LoadAllNovedadesPickEvent` | `NovedadesCacheService` | Falta |
| `FetchMuellesEvent`, `SelectedSubMuelleEvent`, `AssignSubmuelleEvent` | `PickScanBloc` | Existe |
| `SendProductOdooPickEvent` | `SendProductToOdoo` + `PickPendingSyncService` | Parcial (sin cola) |
| `SyncPendingProductsPickEvent`, `ProductPendingEvent` | `PickPendingSyncService` | Falta |
| `PickingOkEvent`, `PickOkEvent` | `PickScanBloc` (con bloqueo por pendientes) | Parcial |
| `ValidateConfirmEvent`, `CreateBackOrderOrNot` | `PickScanBloc` | Existe |
| `LoadProductEditEvent`, `SendProductEditOdooEvent`, `SearchProductsPickEvent`, `ClearSearchProudctsPickEvent`, `LoadSelectedProductEvent`, `ViewProductImageEvent` | `PickDetailBloc` | Falta (imagen existe) |
| `LoadHistoryPickEvent`, `LoadHistoryPickIdEvent` | `PickHistoryBloc` | Parcial (fetch existe) |
| `FetchPickingComponentesEvent`, `FetchPickingComponentesFromDBEvent`, `LoadHistoryPickComponentEvent` | `PickingComponentsBloc` | Fuera de alcance (fase 7) |

---

## 7. Plan de pruebas en PDA

| # | Caso | Esperado |
|---|---|---|
| 1 | Lista offline, refrescar, buscar y escanear un pick | Igual que el legacy |
| 2 | Entrar a un pick sin responsable | Asigna, inicia tiempo y abre el scan |
| 3 | Scan completo con barcode principal | Pasa por ubicación → producto → cantidad → muelle sin perder foco |
| 4 | Producto por barcode alterno | Producto OK y cantidad habilitada en una sola transición |
| 5 | Cantidad por barcode de empaque | Suma N, **sin beep de error** |
| 6 | Escanear de más al llegar al tope | Mensaje "Cantidad completa" con sonido |
| 7 | Cantidad manual menor → advertencia y novedad | Separado con novedad |
| 8 | Teclado de cantidad manual en Zebra | No se cierra solo |
| 9 | Ir al background y volver en cada paso | Foco en el paso correcto, sin parpadeo |
| 10 | Separar sin red, volver la red | Badge de pendientes; se envían solos o con el reintento |
| 11 | Cerrar con pendientes o envíos en vuelo | Cierre bloqueado con el conteo |
| 12 | Validar con y sin backorder, y con vencidos | Flujo completo |
| 13 | Editar cantidad desde el detalle y reenviar | Persistido local y en Odoo |
| 14 | Historial por fecha y detalle | Igual que el legacy |
| 15 | Doble tap en APLICAR CANTIDAD y confirmar | Una sola petición |
| 16 | Con el módulo nuevo instalado, usar Pick actual y picking de componentes | Sin cambios de comportamiento |

---

## 8. Riesgos

| Riesgo | Mitigación |
|---|---|
| Romper picking de componentes, que comparte bloc y pantallas | No tocar el legacy; componentes queda fuera hasta la fase 7 |
| Mismo pick trabajado en los dos módulos (tablas compartidas) | Regla operativa + módulo nuevo oculto y en PDAs de prueba |
| Perder fixes recientes del legacy | Pantallas reconstruidas desde el legacy actual; checklist de §2.3 |
| Doble mantenimiento del scan | Regla de fixes gemelos hasta la fase 7; fecha de corte tras validar |
| Regresiones de foco en Zebra | Foco por paso + pruebas 3, 8 y 9 |
| Cola offline duplicada (legacy y nuevo reenvían los mismos pendientes) | El reenvío ya es idempotente (`ya fue procesada anteriormente` se toma como OK); verificar en la prueba 10 |

---

## 9. Estimación

| Fase | Esfuerzo relativo |
|---|---|
| 1 Dominio + validación de escaneo | 10% |
| 2 Datos + cola offline | 15% |
| 3 Blocs + tests | 30% |
| 4 Pantallas (scan con mejoras) | 30% |
| 5 Integración | 5% |
| 6 Correcciones | 10% |
| 7 Corte | — (después de validar en PDA, y con componentes resuelto) |

Total: 2 a 3 sesiones largas (el avance existente ahorra buena parte del dominio y los datos), más 1 a 2 días de pruebas en PDA con Odoo real.
