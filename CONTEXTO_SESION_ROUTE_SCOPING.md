# Contexto completo de la sesión — Reducción de RAM en WMS app (route-scoping de blocs)

> Documento de traspaso de sesión, con TODO lo hablado desde que esta
> conversación arrancó (no solo lo de hoy). Objetivo: que una conversación
> nueva de Claude pueda leer esto y seguir el trabajo sin tener que
> redescubrir nada.
>
> Repo: `/Volumes/Baneste/appwms` (Flutter, BLoC + Clean Architecture +
> SQLite + Odoo backend). Branch de trabajo: `desarrollo`.
> Usuario: desarrollador mobile, prefiere respuestas cortas y directas,
> responder siempre en español, "una fase a la vez, con visto bueno".

---

## 0. El problema de fondo (por qué empezó todo esto)

La app corre en dispositivos de gama baja (PDAs/scanners Zebra/Chainway en
bodega). Con el tiempo se fueron agregando módulos y quedaron dos problemas
de RAM relacionados pero distintos:

1. **Duplicación de catálogos en memoria**: ~40 blocs, cada uno hacía su
   propia consulta SQLite y guardaba su propia copia de
   ubicaciones/productos/novedades/configuraciones/barcodes. Con 6000
   productos y 10 módulos leyendo ese catálogo, no había 6000 productos en
   RAM — había 6000 × 10.
2. **Esos mismos ~40 blocs vivían para siempre**: se proveían en la raíz
   (`main.dart`, `MultiBlocProvider`) y quedaban vivos desde el arranque de
   la app hasta que se cerraba, aunque el usuario nunca entrara a ese
   módulo en todo su turno.

---

## 1. Fase de caches compartidos (Fases 4 y 5, y cierre general) — ✅ COMPLETA

Ya estaba en curso antes de esta ventana de contexto (fases 1-3 se hicieron
en sesiones previas). En esta sesión se cerraron:

- **Fase 4** (Configuraciones/permisos, ~28 archivos) — aprobada por el
  usuario ("sigue con esa fase, los 26 archivos").
- **Fase 5** (Barcodes) — aprobada ("sigue con el barcode... dale").

Resultado final, commit **`b7d1c2e9`** (`perf: cache compartido de
catálogos`), ya pusheado a `origin/desarrollo`:

- Nuevos servicios `@lazySingleton`: `UbicacionesCacheService`,
  `ProductosCacheService` (dos slots: `getAll`/`getAllUnique`, dos queries
  distintas sobre `tbl_product`), `NovedadesCacheService`,
  `ConfiguracionCacheService` (por userId), `BarcodesInventarioCacheService`.
- `getAll()`/`getAllUnique()` devuelven `UnmodifiableListView` sobre la
  lista interna real — una sola lista en RAM para toda la app, no copias.
  Cualquier `.clear()/.add()/.sort()` accidental sobre el resultado tira
  `UnsupportedError` en vez de corromper el cache silenciosamente.
- ~30 blocs/datasources migrados a leer de estos caches.
- Hooks de `invalidate()` en los puntos de escritura real (sync post-login,
  `insertConfiguration`, descarga manual de novedades/barcodes).
- **WebSocket de productos** (`pda_product_catalog`): el usuario preguntó
  explícitamente por la propagación de actualizaciones de WS a los dos
  slots de productos, y pidió "arreglá el WS para que actualice los dos
  slots". Se implementó `ProductosCacheService.applyWsProductUpsert
  (productId, data)`: actualiza EN MEMORIA ambos slots (antes solo se
  actualizaba el que usaba `InfoRapidaBloc`, dejando desactualizados
  `CreateTransferBloc`/`ConteoBloc`/`InventarioLocalDataSource`). Si el
  producto no existe en un slot, lo agrega (alta) en vez de ignorarlo.
  `WebSocketService` ahora inserta el producto en SQLite si no existe
  (antes lo ignoraba, asumiendo que solo llegaban updates) e invalida
  `BarcodesInventarioCacheService` tras escribir barcodes nuevos/
  actualizados vía WS.
- Bonus de estabilidad: se agregó `if (mounted)` antes de `Navigator.pop
  (context)` en 4 pantallas de escaneo (picking_cluster, recepcion batchs,
  info_rapida transfer, transferencias transfer-interna) dentro de
  callbacks de `didChangeAppLifecycleState` — mismo bug de freeze/crash ya
  corregido antes en Home.

---

## 2. El giro arquitectónico: "¿por qué siguen vivos los blocs?"

Después de cerrar la Fase 5, el usuario preguntó explícitamente:
**"que problema seguimos teniendo con los bloc en el main?"**

Eso llevó a identificar el segundo problema (blocs viviendo para siempre en
`main.dart`) y a la pregunta clave del usuario:
**"como podemos resolver el punto 2 donde quiero que todos los bloc siempre
consulte es a una sola lista y que no se hagan copias"** — es decir, no
solo evitar duplicar la consulta SQLite (ya resuelto en fase 1), sino
además evitar que esos blocs vivan innecesariamente.

La respuesta / plan acordado: mover blocs de `BlocProvider` en `main.dart`
(root, viven para siempre) a `BlocProvider` escopeado a su propia ruta en
`app_router.dart` — Flutter los crea al entrar a la ruta y los descarta
automáticamente al salir, sin necesidad de `.close()` manual.

Esto se hizo **una fase (módulo) a la vez, con aprobación del usuario en
cada paso** — patrón repetido durante toda la sesión.

---

## 3. Patrones técnicos establecidos (válidos para todo el resto del trabajo)

1. **Ruta escopeada básica**: en `app_router.dart`, envolver la pantalla
   con `BlocProvider(create: (_) => getIt<XBloc>())` (si es `@injectable`
   / factory) o `XBloc()` directo (si no está en DI). Confirmado: TODOS los
   blocs tocados hasta ahora son `@injectable` o sin DI — nunca hizo falta
   tocar `injection_container`/build_runner.

2. **Bloc compartido entre rutas hermanas**: `pushReplacementNamed`/
   `pushNamed`/`showDialog` crean rutas HERMANAS en el `Overlay` de
   Flutter, no descendientes unas de otras. Un bloc escopeado a una ruta
   es invisible en la siguiente a menos que se pase explícito. Patrón:
   - Capturar `context.read<XBloc>()` en el sitio de navegación (un
     descendiente real del provider).
   - Pasarlo por `arguments: [...otrosArgs, bloc]` (los helpers
     `AppRoutes._args(context)` / `_arg<T>(args, index)` ya existían en el
     router para extraer argumentos posicionales tipados).
   - En el builder de la ruta destino: `final bloc = _arg<XBloc>(args, N)
     ?? XBloc();` (fallback crea uno nuevo para entradas realmente
     "en frío") y envolver con `BlocProvider<XBloc>.value(value: bloc,
     child: Pantalla(...))`.

3. **Diálogos (`showDialog`/`showModalBottomSheet`) NO heredan el
   BlocProvider de la ruta que los abre** — bug encontrado y corregido
   varias veces. Si el `builder: (context) => ...` del diálogo hace
   `context.read<XBloc>()` (con `context` SOMBREADO por el parámetro del
   builder, mismo nombre que el de afuera), hay que:
   - Capturar el bloc/valor necesario ANTES de llamar a `showDialog`, en
     una variable local, y usar esa variable adentro; o
   - Envolver el widget devuelto por el builder con
     `BlocProvider<XBloc>.value(value: blocCapturado, child: ...)`.
   Aplica también a niveles anidados (un diálogo que abre otro diálogo
   necesita el fix en AMBOS niveles).

4. **Widgets compartidos entre módulos que navegan internamente**: si un
   widget reusado por MÁS de un módulo (ej. `LoteScannerWidget`, usado por
   Conteo y por Crear Transferencia) hace su propio
   `Navigator.pushReplacementNamed` con argumentos fijos, y solo UNO de
   sus consumidores tiene un bloc escopeado, agregar un parámetro opcional
   (ej. `extraArguments: List<dynamic> = const []`) para no romper al otro
   consumidor que no lo necesita.

5. **"Resume state" en pantallas destruidas y recreadas**: cuando una
   pantalla "picker" (selección de lote/ubicación) hace
   `pushReplacementNamed` de vuelta a la pantalla de scan, esa pantalla fue
   DESTRUIDA (no pausada) — pierde su estado local. Solución: parámetros
   opcionales en el constructor (`initialProductValidated`,
   `initialProductValidatedAt`, `initialLote`, `initialUbicacionDest`,
   etc.) que `initState()` usa para restaurar el estado visual. Se creó
   además el patrón `_returnToScan()`/`_returnToDetail()`: un helper
   privado que centraliza el `pushReplacementNamed` de "volver", en vez de
   tener `Navigator.pop()` desperdigado.

6. **Overlay de carga declarativo en vez de `showDialog` +
   `Navigator.pop` imperativo**: el patrón viejo (mostrar diálogo, escuchar
   el siguiente estado, hacer pop) depende de que el listener siga vivo
   cuando termine un fetch largo — a veces no llegaba el segundo estado y
   el diálogo se quedaba pegado (bug real, ver sección 5). Reemplazo:
   ```dart
   Stack([
     _buildContent(context),
     BlocBuilder<X, State>(
       buildWhen: (p, c) => ...,
       builder: (context, state) {
         final stillLoading = ...;
         if (!stillLoading) return const SizedBox.shrink();
         return const Positioned.fill(
           child: AbsorbPointer(child: DialogLoading(message: '...')),
         );
       },
     ),
   ])
   ```
   Puramente reactivo al estado del bloc, inmune a timing de Navigator o
   de suscripciones de listener.

7. **"Borrador en curso" (holder estático)** — patrón nuevo, usado por
   ahora SOLO en Crear Transferencia, porque ahí el usuario espera que el
   trabajo en curso sobreviva salidas accidentales del módulo (a
   diferencia de Recepción/Transferencia Multiusuario/Expedición, donde
   volver a la lista resetea intencionalmente):
   ```dart
   static CreateTransferBloc? _draft;
   static CreateTransferBloc resumeOrCreate() => _draft ??= CreateTransferBloc();
   static void clearDraft() { _draft = null; }
   ```
   Los 5 route builders de Crear Transferencia usan
   `?? CreateTransferBloc.resumeOrCreate()` en vez de `?? CreateTransferBloc()`.
   `clearDraft()` se llama tras `CreateTransferSuccess`. Evaluar caso por
   caso si un módulo futuro necesita este patrón o no.

8. **Convención de navegación**: TODOS los módulos migrados usan
   `pushReplacementNamed` (nunca `pushNamed`/`Navigator.pop` para navegar
   "hacia adelante/atrás" dentro del mismo módulo) — coincide con la
   convención legacy que ya usaban Cluster Picking/Packing/Picking, evita
   acumulación de stack de rutas. Instrucción explícita del usuario:
   **"antes de pasar al cluster picking quiero que en los modulos de
   transferencia multiusuario y tranferencia multiusuario y expedicion no
   manjemos el pushNamed vamos a manejar el pushReplacementNamed"**, y
   sobre las pantallas picker: **"cuando viajasmo a las vista de lotes, la
   vista de ubicaciones, la vista de productos y nos devolvemos siempre
   nos devolvemos a la vista de scan product de ese modulo"**.

---

## 4. Módulos migrados a route-scoping, en orden cronológico

### 4.1 Recepción Multiusuario (6 blocs: List/Pool/MyClaims/Scan/Lote/LocationDest)
Conversión completa a `pushReplacementNamed`. 2 bugs de diálogo-sin-provider
corregidos (`recepcion_terminado_card_widget.dart` +
`recepcion_novedades_dialog_widget.dart`, 2 niveles anidados: "ver
detalles" → "deshacer").

### 4.2 Transferencia Multiusuario (6 blocs equivalentes + paso extra "origen")
Mismo patrón, mismos 2 archivos con el mismo bug de diálogo corregidos
(`transferencia_terminado_card_widget.dart` +
`transferencia_novedades_dialog_widget.dart`). Nota: se encontró y corrigió
un paréntesis de cierre sobrante introducido a mitad de edición en
`transferencia_terminado_card_widget.dart` (detectado por `flutter
analyze`).

### 4.3 Expedición (5 blocs: List/Assignment/Detail/Scan/Confirm)
Conversión a `pushReplacementNamed`. Se auditaron los diálogos propios del
módulo (`dialog_asignar_expedicion_widget.dart`,
`dialog_validar_expedicion_widget.dart`,
`expedicion_propietario_filter_sheet.dart`) — ninguno leía un bloc
route-scoped directamente, no necesitaron fix.

### 4.4 Información Rápida (`InfoRapidaBloc`, `TransferInfoBloc`)
El módulo más grande de esta ronda (10 rutas). Migración completa +
threading de bloc en TODAS las pantallas del módulo (list de productos/
ubicaciones, transferencia masiva, etc.).

**Auditoría de GetX**: antes de avanzar, el usuario pidió confirmar si
GetX seguía siendo necesario en la app (sospechaba que solo se usaba para
diálogos). Se confirmó que sí se usa activamente (snackbars, diálogos) —
no se removió, solo se reportó el hallazgo.

**2 bugs reales encontrados y corregidos, diagnosticados con logs de
consola pegados por el usuario** (un video `.mov` compartido no pudo
leerse — limitación dura del entorno: `cat`/`cp`/`ffmpeg` fallan sobre
archivos de video en este sandbox aunque `stat` sí funciona; se le pidió
al usuario el log de texto en su lugar, que sí resolvió el diagnóstico):

- **"al entrar a info rapida se queda cargando el dialogo de la
  interfaz"** — el diálogo imperativo de "Cargando interfaz..." dependía
  de que el `BlocConsumer` siguiera suscripto cuando terminara el fetch de
  ~7000 productos (~1-2s); el log mostró que el segundo estado
  (`InitInfoRapidaSuccess`) nunca llegaba al listener. Fix: overlay
  declarativo (patrón 6 de la sección 3), tratando también
  `InfoRapidaInitial` como "todavía cargando" para cerrar una ventana de
  1 frame.
- **"cuando salgo del modulo de informacion rapida y entro nuevmaente al
  listado de producto no cargan me toca salir... y volver a entrar"**
  (ubicaciones sí cargaban bien, solo productos fallaba) — el log mostró
  el MISMO bloc (mismo hashCode) llegando a `ListProductsScreen.build` con
  `isInitialized=false, productos=0` ANTES de que `InfoRapidaScreen.
  initState` alcanzara a disparar `InitInfoRapidaEvent` para esa
  instancia — una carrera de inicialización. Fix: `list_products_screen.
  dart` y `list_locations_screen.dart` ganaron su propio self-check
  (`if (!bloc.isInitialized) bloc.add(InitInfoRapidaEvent())`) + el mismo
  overlay declarativo, dejando de asumir que `InfoRapidaScreen` ya había
  inicializado todo. Usuario confirmó: **"quedo ok"**.

### 4.5 Print Labels (`PrintLabelsBloc`)
Sin DI (constructor plano). 3 rutas (`print-labels`, `-products`,
`-locations`), threading simple ida y vuelta en las 4 navegaciones
internas. `ModalPrintersList` (el modal de impresión) solo usa
`PrintingBloc` (Tier 1, global) — no necesitó fix de diálogo.

### 4.6 Login + Enterprise (`LoginBloc`, `EnterpriseBloc`)
Los dos más simples: puntos de entrada puros (login/logout/expiración de
sesión), sin estado que viajar entre rutas — no hizo falta threading de
argumentos. El bottom sheet de selección de base de datos en
`enterprise_page.dart` YA usaba `BlocProvider.value` para reinyectar
`EnterpriseBloc` en el `showModalBottomSheet` — no necesitó fix. Detalle
curioso encontrado: `LoginPage` no tenía import explícito en
`app_router.dart` porque llegaba vía un barrel file (`pages.dart`) ya
importado — no era un bug, solo un `unnecessary_import` al agregarlo
manual (se sacó).

### 4.7 PrintingBloc — reclasificado a Tier 1 (NO migrar)
Durante la búsqueda de "qué bloc sigue", se auditó `PrintingBloc`
pensando que era candidato (1 solo archivo consumidor aparente,
`modal_printers_list.dart`). Un grep más amplio mostró que ese modal se
invoca desde **~30 archivos** de módulos completamente distintos
(Recepción Multiusuario, Transferencia Multiusuario, Recepción individual,
WMS Picking, WMS Packing...). Es infraestructura cross-cutting global —
reclasificado a Tier 1, se queda en el root.

### 4.8 Crear Transferencia (`CreateTransferBloc`) — el más complejo
Auditoría previa a la implementación (pedida explícitamente por el
usuario: **"realiza auditoria de este bloc"**) encontró 3 complicaciones
que NO existían en los módulos anteriores:

1. **2 entry points externos ya asumían el bloc como global**: Home
   (`dialog_transferencia_widget.dart`, botón "Crear") y la lista de
   Transferencia Interna (`list_transferencias_screen.dart`, FAB "+")
   ambos hacían `context.read<CreateTransferBloc>()` y disparaban 4
   eventos de carga ANTES de navegar — desde una pantalla que NO sería
   descendiente de la ruta escopeada.
2. **2 diálogos con el bug de sección 3.3** (dialogo de barcodes en
   `product_dropdown_widget.dart`, diálogo de eliminar producto en
   `detail_create_tranfer_screen.dart`).
3. **Pregunta de producto abierta**: al aceptar el diálogo de éxito
   ("ACEPTAR" tras crear la transferencia), ¿debía volver con un bloc
   fresco o con el mismo? Se resolvió investigando el propio bloc: ya se
   auto-limpia (`ClearDataCreateTransferEvent(isClearProduct: false)`)
   justo después de `CreateTransferSuccess` — por lo tanto es seguro (y
   correcto) threadear el MISMO bloc.

**Implementación** (tras "procedamos con ese bloc de CreateTransferBloc"):
- 5 rutas (`create-transfer`, `detail-create-transfer`,
  `search-product-create-transfer`, `search-location-create-transfer`,
  `search-lote-create-transfer`) con `BlocProvider`/`BlocProvider.value`.
- 13 sitios de navegación interna threadeados.
- Los 2 entry points externos dejaron de leer el bloc directo; la carga
  inicial se movió al `initState()` de `CreateTransferScreen`
  (`scan_product_create_transfer_screen.dart`), con guard
  `bloc.ubicaciones.isEmpty` para no recargar en cada retorno.
- Los 2 bugs de diálogo corregidos con el patrón de captura previa.
- `main.dart` limpiado (import + provider removidos).

**Bug post-implementación reportado por el usuario** ("no se muestra el
diálogo de éxito, no sé si la transferencia se creó" / "los productos se
borran al salir del módulo"): investigado a fondo, causa real doble:

- **`LoteScannerWidget` (compartido con Conteo) no pasaba el bloc** al
  navegar a `search-lote-create-transfer` — solo pasaba `[currentProduct]`.
  Como esa ruta ahora crea un bloc FRESCO si no lo recibe, **cada vez que
  el usuario seleccionaba un lote se reseteaba TODO el progreso** de la
  transferencia en curso (ubicación origen/destino, productos ya
  agregados). Fix: parámetro opcional `extraArguments` agregado a
  `LoteScannerWidget` (sin romper su otro consumidor, Conteo, que sigue
  root-provided y no lo necesita); Crear Transferencia le pasa
  `[context.read<CreateTransferBloc>()]`.
- Complementario: se agregó el patrón "borrador en curso" (sección 3.7)
  para que salir del módulo por completo (ej. flecha atrás a Home) y
  volver a entrar tampoco pierda el progreso — antes de este fix, salir a
  Home destruía el bloc escopeado y el siguiente ingreso creaba uno
  totalmente vacío.

El diálogo de éxito en sí (`showDialog` con `AlertDialog`, nombre de
transferencia + total de ítems + botón ACEPTAR, en
`detail_create_tranfer_screen.dart`) NUNCA se tocó/rompió — el usuario
preguntó "¿es un diálogo o un snackbar?" y se confirmó: es un diálogo
modal (`barrierDismissible: false`), no un snackbar.

---

## 5. Preguntas de arquitectura respondidas durante la sesión

- **"que bloc me falto por hacer el proceso que llevamos?"** (repetida
  varias veces) — usada para ir armando la cola de trabajo pendiente.
- **"cuales son los blocs que se usan en el home?"** — respuesta
  completa: `HomeBloc`, `UserBloc`, `InventarioBloc`, `BatchBloc`,
  `PackingConsolidateBloc`, `PackingPedidoBloc`, `WmsPackingBloc` (en
  `index.dart`), y en los diálogos de selección de submódulo:
  `DevolucionesBloc`/`RecepcionBatchBloc`/`RecepcionBloc`
  (`dialog_devoluciones_widget.dart`), `ConteoBloc`/`InventarioBloc`
  (`dialog_inventario_widget.dart`), `RecepcionBloc`
  (`dialog_recepcion_widget.dart`), `TransferenciaBloc`/`UserBloc`
  (`dialog_transferencia_widget.dart`), `HomeBloc`
  (`update_app_dialog_widget.dart`). Todos Tier 1 (Home vive siempre
  montado).
- **"cuales son los bloc indispensables en el nivel mas alto... UserBloc
  por la config del usuario, InventarioBloc trae productos/ubicaciones o
  eso lo hace el BatchBloc?"** — aclarado: es `InventarioBloc` (dispara
  `GetProductsEvent`/`GetLocationsEvent`, y `PostLoginCoordinator` lo
  invoca justo después del login en `post_login_coordinator.dart:69`).
  `BatchBloc` es otra cosa — el bloc de la pantalla de "Batches" de WMS
  Picking (picking, muelles, novedades); NO carga catálogo, y de hecho es
  candidato a route-scoping, no Tier 1.
- **"en que porcentaje ha ayudado esto a mejorar la app?"** — respuesta
  honesta: no hay ninguna medición real (nunca se corrió un profiler de
  memoria antes/después), así que cualquier porcentaje sería inventado.
  Se explicó cualitativamente el impacto de cada fase y se ofreció dejar
  un checklist para medir con DevTools Memory en un dispositivo real
  (oferta no tomada aún).

---

## 6. Contenido para LinkedIn (creado a pedido del usuario)

El usuario pidió 2 posts (uno por cada "fase" del trabajo), cada uno con
texto de post + prompt de imagen. Quedaron redactados en el chat (no
guardados como archivo aparte salvo que se pida). Resumen de los conceptos
usados, por si se quiere retomar/ajustar el copy:

### Post 1 — Caches compartidos
Metáfora: "cada quien trae su propia copia" → duplicación de catálogos en
RAM. Insight: la solución no fue optimizar cada módulo, fue crear un único
punto de verdad compartido. Imagen pedida: antes = muchos íconos
duplicados/desordenados (rojo/naranja) fusionándose en un solo hub central
(azul/verde), antes/después dentro de UNA sola imagen, con textos cortos
tipo "x40" → "x1" (los generadores de IA no renderizan bien frases largas,
se recomendó agregar el titular como overlay en Canva por separado).

### Post 2 — Route-scoping de blocs
El usuario pidió explícitamente NO enfatizar el detalle técnico de "pasar
el bloc como argumento de ruta" — el foco debía ser la pregunta de
arquitectura: **qué blocs son realmente indispensables a nivel raíz vs.
cuáles deberían crearse/destruirse con el ciclo de vida de su pantalla**.
Metáfora usada: un edificio con cuartos — antes, TODAS las luces
encendidas 24/7 aunque los cuartos estén vacíos; ahora, solo se encienden
los cuartos ocupados (y unos pocos, como la recepción/lobby, quedan
siempre encendidos — los verdaderamente indispensables, ej. `UserBloc`/
`InventarioBloc`). Mismo formato antes/después dentro de una imagen,
overlay de texto sugerido para agregar en Canva: **"¿Por qué mantener las
luces encendidas en cuartos vacíos?"** / **"Antes: 40 módulos vivos todo
el día. Ahora: solo el que estás usando."**

---

## 7. Estado del repositorio / git

Dos commits de esta sesión, ambos ya pusheados a `origin/desarrollo`:

- **`b7d1c2e9`** — `perf: cache compartido de catálogos
  (ubicaciones/productos/novedades/config/barcodes)` (Fase 1 completa).
- **`53ec22c4`** — `feat(perf): route-scoping de blocs — de root global a
  ciclo de vida por ruta` (Fase 2, parcial — todos los módulos de la
  sección 4).

**Archivos sin trackear, NO se subieron, decisión pendiente del usuario:**
- `assets/Screen Recording 2026-09-13 at 10.49.56 AM.mov` — la grabación
  de pantalla compartida para debug de Info Rápida (no pudo leerse por
  limitación del entorno, se resolvió con logs de texto en su lugar).
  Probablemente no se quiere versionar.
- `android/build/reports/` — artefacto de build, debería ir a
  `.gitignore` (actualmente el `.gitignore` solo cubre `/build/` en la
  raíz, no `android/build/`).
- `docs/API_ENDPOINTS.md`, `docs/mapa_endpoints_wms.md` — no se confirmó
  si son intencionales para versionar.

---

## 8. Cola de trabajo pendiente (para la próxima sesión)

1. **`PackingConsolidateBloc`** — sin auditar todavía.
2. **`PickingPickBloc`** — comparte pantalla/ruta con `BatchBloc` (Tier 1,
   se queda en el root) — requiere revisar con cuidado la estructura de
   navegación compartida antes de tocarlo.
3. **Cluster Picking** — el módulo grande pendiente, sin empezar:
   `ClusterPickingBloc`, `PickingClusterListBloc`, `DetailClusterBloc`,
   `ValidateClusterBloc`, `LoteProductoBloc` (5 blocs). Complejidad
   comparable o mayor a Información Rápida.
4. Decidir qué hacer con los 3 grupos de archivos sin trackear (sección 7).
5. Si se quiere un número real de mejora de RAM: correr `flutter run
   --profile` + DevTools Memory, snapshot en frío en Home antes/después
   de loguear, comparar heap con la app en el estado previo a esta
   sesión (ej. usando el commit anterior a `b7d1c2e9`) vs. el estado
   actual.
6. Confirmar si se quiere retomar/publicar el contenido de LinkedIn de la
   sección 6 (posts + prompts de imagen ya redactados, no guardados en
   archivo).
