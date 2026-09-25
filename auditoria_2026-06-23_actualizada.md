# AUDITORÍA TÉCNICA ACTUALIZADA Y PLAN DE MEJORAS — WMS App Flutter
**Fecha:** 23/06/2026 (revisión de la auditoría del 23/05/2026)
**Branch:** clean-arquitecture
**Tamaño:** 688 archivos Dart · ~177.000 líneas
**`flutter analyze`:** 192 issues
**Autor:** Claude Code (Anthropic)

> Esta auditoría parte del documento `auditoria_y_plan_mejoras.md` (23/05) y verifica el estado
> real un mes después: qué se corrigió, qué sigue abierto y qué hallazgos **nuevos** aparecieron.

---

## 1. RESUMEN EJECUTIVO

El equipo avanzó bien en la Fase 0/1 de seguridad y memoria, pero quedan 3 críticos abiertos y
apareció **un bug funcional masivo nuevo**: la detección de "sin conexión" está **rota en toda la
app** por una migración de `connectivity_plus`. La deuda de God Objects no solo no bajó: **creció**.

Prioridad inmediata:
1. **N-01 — Detección de conexión rota en 75 puntos** (validación incorrecta crítica).
2. **C-03 — SSL bypass total** sigue aceptando cualquier certificado (MITM).
3. **C-04 — IP hardcodeada** sigue presente.

---

## 2. ESTADO DE LOS HALLAZGOS ANTERIORES

| ID | Hallazgo | Estado actual | Evidencia |
|----|----------|---------------|-----------|
| C-01 | Password en estado BLoC | ✅ **Corregido (parcial)** — fuera del estado; pero ahora se guarda en `SharedPreferences` en **texto plano** (`PrefUtils.setUserPass`), no en secure storage | `login_bloc.dart:60-61`, `pref_utils.dart:27` |
| C-02 | Controladores sin dispose | ✅ **Corregido** | `print_labels_bloc.dart:43-49` |
| C-03 | SSL completamente deshabilitado | ❌ **ABIERTO** — sigue `=> true` para todo host | `main.dart:75-76` |
| C-04 | IP hardcodeada en `postMultipartImage` | ❌ **ABIERTO** | `api_request_service.dart:158` |
| A-01 | God Objects | 🔴 **EMPEORÓ** — ver tabla §4 | varios |
| A-02 | 43 `print()` | ✅ **Corregido** — 0 `print()`; `avoid_print` activo | `analysis_options.yaml` |
| A-03 | Timeouts HTTP | ⚠️ **Parcial** — siguen 3 timeouts de 100s; la mayoría de métodos (`post`, `get`, `getInfo`, `postPacking`, `postPrint`, `getHistory`, `searchEnterprice`, multipart) **sin timeout** | `api_request_service.dart` |
| A-04 | `use_build_context_synchronously` suprimido | ❌ **ABIERTO y peor** — 96 archivos con el ignore; analyzer aún detecta 14 casos reales | grep |
| M-01 | WebSocket sin reconexión | ✅ **Corregido** — backoff exponencial + estado `reconnecting` | `websocket_service.dart:352-376` |
| M-02 | Queries BD secuenciales | ❌ **ABIERTO** — 0 usos de `Future.wait` en picking_cluster | grep |
| M-03 | Pantallas con lógica incrustada | 🔴 **EMPEORÓ** | §4 |
| M-04 | TODOs | ⚠️ 21 pendientes (eran 22) | grep |
| M-05 | Error handling en catch | ⚠️ Parcial | — |
| B-01 | Archivo PascalCase | ❌ Persiste; además **carpetas con espacios** `info rapida/`, `quick info/` (peor) | find |
| B-02/03/04 | Booleanos / validateBarcode / controllers | ⚠️ Sin cambios relevantes | — |

---

## 3. HALLAZGOS NUEVOS (no estaban en la auditoría anterior)

### N-01 ✅ RESUELTO (23/06/2026) — Detección de "sin conexión" rota en toda la app
> **Corregido:** creada extensión `ConnectivityResultListX` (`lib/core/network/connectivity_extensions.dart`)
> con `isOffline`/`isOnline`; reemplazados los 75 call sites en 10 archivos. `flutter analyze`: 192 → 181,
> sin errores de compilación. Pendiente de prueba funcional en dispositivo (modo avión).

- **Causa:** `connectivity_plus` migró `checkConnectivity()` a devolver `List<ConnectivityResult>`,
  pero el código sigue comparando contra un solo valor:
  ```dart
  var connectivityResult = await Connectivity().checkConnectivity(); // ahora es List
  if (connectivityResult == ConnectivityResult.none) { ... } // SIEMPRE false
  ```
- **Alcance:** **75 comparaciones** `== ConnectivityResult.none` en el código + 27 warnings
  `unrelated_type_equality_checks` del analyzer apuntando aquí.
- **Impacto:** La guarda de "no hay internet" **nunca se dispara**. La app intenta peticiones
  igual, el usuario ve errores genéricos/timeouts en vez del aviso de offline, y la lógica
  offline-first queda sin efecto. **Validación incorrecta sistémica.**
- **Corrección:**
  ```dart
  final result = await Connectivity().checkConnectivity();
  if (result.contains(ConnectivityResult.none) || result.isEmpty) { ... }
  ```
  Centralizar en `NetworkInfo` y reemplazar los 75 puntos para que usen un único helper
  `bool get isOffline`.

### N-02 🟠 ALTO — 49 `invalid_null_aware_operator` + 51 `dead_null_aware_expression`
- Operadores `?.` / `??` aplicados sobre valores **no nulables**, y `??` cuyo lado derecho
  **nunca se ejecuta** (lado izquierdo no puede ser null).
- **Impacto:** Código muerto en validaciones. Cada `dead_null_aware_expression` es un default
  que el dev creyó que protegía y **no protege nada** → posibles `null`/estados no contemplados
  donde se asumía un fallback. Probable efecto colateral de la misma migración de paquetes.
- **Corrección:** revisar caso por caso (la mayoría son del mismo patrón repetido en widgets).

### N-03 🟠 ALTO — Password en texto plano en `SharedPreferences`
- C-01 sacó el password del estado, pero `setUserPass` lo guarda sin cifrar.
  En Android sin root es relativamente seguro, pero en dispositivos comprometidos o backups
  queda expuesto. **Migrar a `flutter_secure_storage`.**

### N-04 🟡 MEDIO — Bugs concretos detectados por el analyzer
- `must_be_immutable` (2): widgets `@immutable` con campos mutables (`QuantityScannerWidget.isViewCant`)
  → rebuilds inconsistentes.
- `override_on_non_overriding_member` (4): getters en `*_state.dart` (packing_pedido, picking_pick)
  marcados `@override` que **no overridean nada** → posible refactor a medias en Equatable/props.
- `collection_methods_unrelated_type` (2): `.contains()`/`.remove()` con tipo equivocado → siempre falla.
- `dead_code` (1), `unused_*` (28: imports, fields, elements, locals): ruido que oculta bugs reales.

### N-05 🟡 MEDIO — Carpetas con espacios en el nombre
- `lib/src/presentation/views/info rapida/` y `.../quick info/` rompen convenciones, complican
  imports y pueden fallar en herramientas/CI. Renombrar a `info_rapida` / `quick_info`.

---

## 4. GOD OBJECTS — EVOLUCIÓN (empeoró)

| Archivo | Mayo | Hoy | Δ |
|---------|-----:|----:|---|
| picking_pick_bloc.dart | 2.181 | **2.444** | +263 |
| packing_pedido_bloc.dart | 2.128 | 2.123 | ≈ |
| conteo_bloc.dart | 1.680 | **1.892** | +212 |
| scan_product_screen.dart (Pick) | 1.608 | **1.846** | +238 |
| packing_consolidade_bloc.dart | 1.829 | 1.828 | ≈ |
| batch_bloc.dart | 1.668 | **1.816** | +148 |
| recepcion_bloc.dart | 1.804 | 1.800 | ≈ |
| cluster_picking_bloc.dart | 1.680 | 1.713 | +33 |
| devoluciones/index.dart | 1.471 | **1.712** | +241 |

Nuevos por encima de 1.300 que conviene vigilar: `database.dart` (1.672),
`transferencia_bloc.dart` (1.601), `wms_packing_repository.dart` (1.543).

---

## 5. PLAN DE MEJORA ACTUALIZADO

### FASE 0-bis — Críticos abiertos (esta semana)
| Tarea | Archivo | Est. |
|-------|---------|------|
| **F0b-1** Arreglar detección de conexión (N-01): centralizar en `NetworkInfo` con `.contains(none)` y reemplazar los 75 puntos | global + `core/network/network_info.dart` | 4-6h |
| **F0b-2** Restringir SSL bypass al host de Odoo (C-03) | `main.dart:75` | 1h |
| **F0b-3** IP hardcodeada → `PrefUtils.getEnterprise()` (C-04) | `api_request_service.dart:158` | 15min |
| **F0b-4** Password → `flutter_secure_storage` (N-03) | `pref_utils.dart`, `login_bloc.dart` | 3h |

### FASE 1-bis — Estabilidad y validaciones
| Tarea | Detalle | Est. |
|-------|---------|------|
| **F1b-1** Timeouts HTTP (A-03) | constantes `_kDefaultTimeout=30s` / `_kHeavyTimeout=60s`; aplicar a TODOS los métodos sin timeout; bajar los 100s a 60s | 3h |
| **F1b-2** Limpiar null-aware muerto (N-02) | resolver 49 `invalid_null_aware` + 51 `dead_null_aware` (mayoría patrón repetido) | 4-6h |
| **F1b-3** Bugs del analyzer (N-04) | `must_be_immutable`, `override_on_non_overriding_member`, `collection_methods_unrelated_type` | 3h |
| **F1b-4** Paralelizar queries picking (M-02) | `Future.wait` en cluster/pick | 2h |
| **F1b-5** Quitar ruido | 9 unused_import, 7 unused_local, 8 unused_element, dead_code | 2h |

### FASE 2-bis — Higiene y convenciones
- **F2b-1** Eliminar los `ignore_for_file: use_build_context_synchronously` (96 archivos) por tandas;
  resolver los 14 casos reales con `if (!mounted) return;`; luego activar la regla en el linter (A-04).
- **F2b-2** Renombrar carpetas con espacios (N-05) y archivo PascalCase (B-01).
- **F2b-3** Triage de los 21 TODOs (M-04); prioridad: `websocket_bloc.dart:40`.
- **F2b-4** Unificar booleanos / `validateBarcode()` (B-02/B-03).

### FASE 3-bis — God Objects (la deuda que sigue creciendo)
- Mismo enfoque que la auditoría original (extraer `*ValidationService` puro + mixins de escaneo),
  pero **empezar por los que más crecieron**: `picking_pick_bloc` (2.444), `conteo_bloc` (1.892),
  `scan_product_screen` Pick (1.846), `devoluciones/index` (1.712), `batch_bloc` (1.816).
- **Detener el sangrado primero:** ningún archivo por encima de 1.000 líneas debe recibir
  features nuevas sin extraer lógica. Considerar un check de tamaño en CI.

### FASE 4 — Calidad continua (sin cambios respecto al plan original)
- Certificado SSL válido en Odoo → eliminar `MyHttpOverrides`.
- Activar `use_build_context_synchronously`, migrar a `very_good_analysis`.
- CI con `flutter analyze` (umbral 0 issues) + `flutter test`.
- Firebase Performance en picking/envío/reconexión.

---

## 6. TABLA DE PRIORIDADES (actualizada)

| ID | Problema | Sev. | Fase | Esfuerzo |
|----|----------|------|------|----------|
| N-01 | Detección de conexión rota (75 puntos) | 🔴 CRÍTICO | 0-bis | 4-6h |
| C-03 | SSL bypass total | 🔴 CRÍTICO | 0-bis→4 | 1h→∞ |
| C-04 | IP hardcodeada | 🔴 CRÍTICO | 0-bis | 15min |
| N-03 | Password en texto plano | 🟠 ALTO | 0-bis | 3h |
| A-03 | Timeouts HTTP incompletos | 🟠 ALTO | 1-bis | 3h |
| N-02 | 100 null-aware muertos/ inválidos | 🟠 ALTO | 1-bis | 4-6h |
| A-01 | God Objects (creciendo) | 🟠 ALTO | 3-bis | 6 sprints |
| A-04 | BuildContext post-async (96 ignores) | 🟠 ALTO | 2-bis | 6h |
| N-04 | Bugs del analyzer | 🟡 MEDIO | 1-bis | 3h |
| M-02 | Queries secuenciales | 🟡 MEDIO | 1-bis | 2h |
| M-04 | 21 TODOs | 🟡 MEDIO | 2-bis | 4-8h |
| N-05 | Carpetas con espacios | 🟢 BAJO | 2-bis | 1h |

---

## 7. MÉTRICAS DE ÉXITO (delta)
- [ ] `flutter analyze`: de **192 → 0** issues.
- [ ] 0 comparaciones directas contra `ConnectivityResult` (todo vía `NetworkInfo`).
- [ ] 0 credenciales en texto plano (secure storage).
- [ ] SSL sin bypass global.
- [ ] Todos los métodos HTTP con timeout ≤ 60s.
- [ ] Ningún archivo nuevo > 1.000 líneas; God Objects en descenso.

*Generado el 23/06/2026. Reemplaza operativamente al plan del 23/05; conservar aquel como histórico.*





clister
Analicé el módulo picking_cluster. Funciona con caché local primero: descarga los batches del servidor a SQLite, se trabaja sobre esa copia local y cada
  producto separado se envía a Odoo, con reenvío automático si no había conexión. El flujo está bien armado, pero hay un riesgo serio de pérdida de datos en
  cómo se refresca la caché.

  Flujo

  1. Lista (PickingClusterListBloc): descarga los batches (GET api/cluster/picking_batchs), los guarda en SQLite y la pantalla lee de ahí. Al abrir un batch
     sin iniciar registra la hora de inicio y le pide los productos a ClusterPickingBloc.
  2. Escaneo (ClusterPickingBloc, 1.754 líneas): el operario confirma ubicación → producto → lote → cantidad → pedido. Al terminar un producto:
     - lo marca como separado, calcula el tiempo, lo envía (POST cluster/send_picking) y pasa al siguiente pendiente;
     - si el envío falla, deja la cantidad separada de ese producto en 0 y hay que volver a contarlo;
     - sin conexión lo guarda como pendiente (is_send_odoo = 0, incluido el lote) y lo reenvía solo cuando vuelve la conexión.
     - "Dejar pendiente" manda el producto al final de la lista.
  3. Detalle: muestra los mismos productos que tiene el BLoC en memoria. Permite editar cantidad, reenviar pendientes, ver la foto e imprimir.
  4. Validación (ValidateClusterBloc): se valida cada pedido escaneando el barcode del muelle o tocando "Validar" (POST cluster/validate_pedido/id). Antes
     intenta reenviar los pendientes de ese pedido y bloquea la validación si alguno sigue sin enviarse. "Cerrar batch" exige todos los pedidos validados y
     registra la hora de fin.

  Problemas encontrados

  🔴 Crítico: refrescar desde el servidor borra la copia local sin revisar si hay pendientes
  - cachePickingBatches ejecuta delePicking('cluster') antes de insertar. Eso borra todos los productos del cluster en SQLite, incluidos los que se separaron
    sin conexión y todavía no se enviaron.
  - Tres acciones disparan ese refresco:
    - el botón de refrescar de la lista;
    - "Salir al listado" en la validación;
    - RefreshPedidosValidateEvent, que se ejecuta antes de entrar a validar.
  - Ese último solo revisa los pendientes del batch actual. Si otro batch tiene productos sin enviar, se pierden.
  - Si el borrado se completa pero la inserción falla, el error solo se registra en el log y la lista queda vacía.

  🟠 Picking legacy y cluster se borran tablas entre sí
  - delePicking borra tblbatch_pedidos_validate y la tabla de submuelles sin filtrar por tipo.
  - Por eso, refrescar el picking por batch legacy (delePicking('batch')) borra los pedidos a validar del cluster. Después de eso:
    - la tarjeta muestra 0 pedidos (el conteo que agregamos antes);
    - al entrar al batch se ve "No hay pedidos para validar" hasta que se vuelva a consultar el servidor.
  - Y al revés: refrescar el cluster borra los submuelles del picking legacy.

  🟡 Menores
  - sendPickingProduct convierte cualquier error en 'Connection rejected', así que el operario no ve el motivo real.
  - En SendProductOdooUseCase, el tiempo total se calcula como now - now (siempre 0). Es código muerto: ese valor no se envía.
  - Al enviar con éxito, expire_date se guarda sin validar y puede quedar como "null" o "false". El camino sin conexión sí lo valida.
    - RefreshPedidosValidateEvent, que se ejecuta antes de entrar a validar.
  - Ese último solo revisa los pendientes del batch actual. Si otro batch tiene productos sin enviar, se pierden.
  - Si el borrado se completa pero la inserción falla, el error solo se registra en el log y la lista queda vacía.

  🟠 Picking legacy y cluster se borran tablas entre sí
  - delePicking borra tblbatch_pedidos_validate y la tabla de submuelles sin filtrar por tipo.
  - Por eso, refrescar el picking por batch legacy (delePicking('batch')) borra los pedidos a validar del cluster. Después de eso:
    - la tarjeta muestra 0 pedidos (el conteo que agregamos antes);
    - al entrar al batch se ve "No hay pedidos para validar" hasta que se vuelva a consultar el servidor.
  - Y al revés: refrescar el cluster borra los submuelles del picking legacy.

  🟡 Menores
  - sendPickingProduct convierte cualquier error en 'Connection rejected', así que el operario no ve el motivo real.
  - En SendProductOdooUseCase, el tiempo total se calcula como now - now (siempre 0). Es código muerto: ese valor no se envía.
  - Al enviar con éxito, expire_date se guarda sin validar y puede quedar como "null" o "false". El camino sin conexión sí lo valida.
  - _resendPendingProduct está duplicado en los dos BLoCs.
  - ClusterPickingBloc tiene unos 30 campos públicos que cambian desde la interfaz (por ejemplo bloc.isSearch = false) en vez de pasar por estados. La
    pantalla de escaneo tiene 1.517 líneas.

  Recomendación

  Corregir primero el crítico. Antes de delePicking('cluster'):
  - reenviar los pendientes, o no borrar si queda alguno (is_send_odoo = 0);
  - y dejar de borrar tablas compartidas sin filtrar por tipo.