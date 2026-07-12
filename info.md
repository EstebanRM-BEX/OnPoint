Reporte de Memory Leaks — wms_app

  Inventario con ripgrep + verificación archivo por archivo completados. Lo importante: streams y timers están bien manejados; el problema real y repetido son los
  TextEditingController/FocusNode sin dispose, tanto en screens como dentro de Blocs globales.

  Tabla resumen de hallazgos

  #: 1
  Cat: 2
  Archivo: conteo/screens/new_product_screen.dart:41-52
  Fragmento: 5 FocusNode + 5 controllers
  Sev: Alta
  Problema: No existe dispose() en absoluto. Leak completo en cada visita a la pantalla
  ────────────────────────────────────────
  #: 2
  Cat: 2
  Archivo: wms_picking/modules/Batchs/screens/batch_screen.dart:63-68
  Fragmento: 6 TextEditingController
  Sev: Alta
  Problema: dispose() libera los 6 FocusNode pero ningún controller
  ────────────────────────────────────────
  #: 3
  Cat: 2
  Archivo: transferencias/.../scan_product_create_transfer_screen.dart:41-56
  Fragmento: 6 FocusNode + ~6 controllers
  Sev: Alta
  Problema: dispose() solo libera focusNodeSegundaUnidad; el resto queda vivo
  ────────────────────────────────────────
  #: 4
  Cat: 2
  Archivo: devoluciones/screens/index.dart:39-43
  Fragmento: 5 TextEditingController
  Sev: Alta
  Problema: Dispone los FocusNode pero ningún controller
  ────────────────────────────────────────
  #: 5
  Cat: 2
  Archivo: conteo/screens/scan_product_screen.dart:55-59
  Fragmento: 5 controllers + focusNode5
  Sev: Alta
  Problema: Controllers sin dispose; focusNode5 tampoco está en la lista del dispose
  ────────────────────────────────────────
  #: 6
  Cat: 2
  Archivo: Pantallas gemelas de pick: wms_picking/modules/Pick/screens/scan_product_screen.dart, features/picking/.../scan_product_screen.dart,
    features/picking_cluster/.../scan_product_scree.dart
  Fragmento: ~5 controllers c/u
  Sev: Alta
  Problema: Las 3 disponen solo FocusNodes. Fix debe ir en las 3 versiones (pantallas gemelas)
  ────────────────────────────────────────
  #: 7
  Cat: 2
  Archivo: recepcion/modules/batchs/screens/scan_product_screen.dart
  Fragmento: 8 objetos creados, 2 dispuestos
  Sev: Alta
  Problema: Solo focusNode2 y focusNode3 se liberan
  ────────────────────────────────────────
  #: 8
  Cat: 2
  Archivo: Screens de packing: sacn_screen.dart, packing-consolidade/.../scan_product_screen.dart, packing-batch/.../packing.dart
  Fragmento: ~4 controllers c/u
  Sev: Alta
  Problema: Disponen FocusNodes, no controllers
  ────────────────────────────────────────
  #: 9
  Cat: 2/Bloc
  Archivo: recepcion_bloc.dart:81-91 (11), devoluciones_bloc.dart (9), packing_pedido_bloc (6), crate_transfer_bloc (6), recepcion_batch_bloc (6), packing_consolidade_bloc (5),
    wms_packing_bloc (5), picking_pick_bloc (3), transferencia_bloc (3), batch_bloc (2), wms_picking_bloc (2)
  Fragmento: Controllers como campos del Bloc, sin close() que los libere
  Sev: Media
  Problema: Los Blocs son globales (viven toda la app), así que el leak es acotado — pero es UI state retenido para siempre + antipatrón de capas
  ────────────────────────────────────────
  #: 10
  Cat: Bloc
  Archivo: main.dart:144-193
  Fragmento: 35 BlocProvider en la raíz
  Sev: Media
  Problema: Todos los Blocs son de vida infinita; estado de trabajo (listas de productos, batches) nunca se libera al salir del módulo — presión de memoria constante
  ────────────────────────────────────────
  #: 11
  Cat: Bloc
  Archivo: ~20 sitios: devoluciones/index.dart:780,798,1011…, wms_packing/packing/screens/index.dart:227,1260, conteo/scan_product_screen.dart:381, diálogos de backorder/advertencia
  Fragmento: context.read<X>().add(...) dentro de build()
  Sev: Media
  Problema: Eventos re-disparados en cada rebuild — trabajo duplicado y posible acumulación de estado
  ────────────────────────────────────────
  #: 12
  Cat: 5
  Archivo: ~10 archivos (tab2.dart de varios módulos, inventario_page.dart, transfer_info_screen.dart)
  Fragmento: Future.delayed que usa Navigator/context
  Sev: Media
  Problema: Verificar guard mounted — riesgo de use-after-dispose del context, no leak permanente
  ────────────────────────────────────────
  #: 13
  Cat: 4
  Archivo: pubspec.yaml:100
  Fragmento: cached_network_image: ^3.3.1
  Sev: Baja
  Problema: Declarado pero sin ningún uso en lib/ — peso muerto, remover
  ────────────────────────────────────────
  #: 14
  Cat: 4
  Archivo: Diálogos de temperatura/foto (6 archivos, ej. dialog_view_img_temp_widget.dart)
  Fragmento: Image.memory(base64Decode(...)) en build()
  Sev: Baja
  Problema: Re-decodifica el base64 en cada rebuild; decodificar una vez en initState

  Verificado y limpio (sin falsos positivos):
  - Cat 1 (streams): los 9 .listen() del proyecto se guardan en StreamSubscription y se cancelan en close()/dispose() (connection_status_cubit, websocket_bloc, network_info,
  network_quality_overlay, batch_bloc, info_rapida_bloc, cluster_picking_bloc, websocket_service). ✅
  - Cat 3 (listeners): DynamicSearchBar, validate_screen y los widgets de lote tienen removeListener simétrico. Los listeners anónimos sobre focusNodeSegundaUnidad (3 pantallas) no se
  remueven, pero el node sí se dispone → no es leak. ✅
  - Cat 5 (timers): los 14 widgets con _debounce lo cancelan en dispose(); session_timeout_manager cancela _timer; websocket_service cancela _reconnectTimer. ✅

  Análisis general

  La situación es moderada y muy focalizada: no hay leaks de streams, timers ni listeners (eso ya está bien resuelto, probablemente por los fixes previos de performance). El patrón
  que se repite en ~15 pantallas es idéntico: el dispose() libera los FocusNodes pero olvida los TextEditingControllers — parece copy-paste de una plantilla incompleta. Los módulos
  más afectados son conteo (una pantalla sin dispose en absoluto), picking (las 3 pantallas gemelas de scan), batch, transferencias, devoluciones y packing — justo las pantallas de
  escaneo de alto tráfico en las Zebras, donde el operario entra y sale decenas de veces por turno. Cada visita fuga ~5-6 controllers con sus TextEditingValue y listeners internos:
  individualmente pequeño, pero acumulativo en jornadas de 8h sin reiniciar la app.

  El segundo patrón es arquitectónico: los 35 Blocs globales en main.dart que además contienen controllers de UI. No crece indefinidamente, pero significa que el estado de trabajo de
  todos los módulos convive en memoria siempre.

  Plan de mejora priorizado

  Fase 1 — Quick wins (1-2 días):
  1. Agregar dispose() completo en new_product_screen.dart (hallazgo #1, el peor).
  2. Completar los dispose() de las ~14 pantallas de scan (#2-#8) agregando los .dispose() de controllers faltantes — mecánico, bajo riesgo. Recordar aplicar en las 3 gemelas de pick.
  3. Remover cached_network_image del pubspec (#13).

  Fase 2 — Estructural (1-2 sprints):
  1. Crear un mixin DisposableControllersMixin (lista de controllers/nodes que se auto-disponen) y migrar las pantallas de scan — elimina la clase de bug de raíz.
  2. Sacar los TextEditingController de los Blocs (#9): moverlos al State de la pantalla que los usa; el Bloc solo recibe strings en eventos.
  3. Mover los add() de build() a initState/didChangeDependencies con guard (#11).
  4. Evaluar acotar el scope de Blocs de módulo (proveerlos en la ruta del módulo en app_router.dart en vez de la raíz) — aprovechando la migración a Clean Architecture ya en curso.

  Fase 3 — Prevención:
  1. Activar leak_tracker_flutter_testing en los widget tests (detecta controllers sin dispose automáticamente).
  2. Lint: flutter_lints + regla always_declare_return_types ya no cubre esto; agregar en el checklist de PR: "¿todo controller/node/subscription creado tiene su dispose/cancel?".
  3. Sesión periódica con DevTools → Memory (diff de snapshots entrando/saliendo 10 veces de una pantalla de scan) para validar que el conteo de TextEditingController no crece.

  Herramientas para medir impacto: Flutter DevTools Memory tab (snapshot diff), paquete leak_tracker/leak_tracker_flutter_testing, flutter analyze, y en Zebras reales adb shell
  dumpsys meminfo <package> antes/después de la Fase 1.

  ¿Quieres que aplique los fixes de la Fase 1 directamente (los dispose() faltantes en las ~15 pantallas + quitar cached_network_image)?




  2.1 — Mixin DisposableControllersMixin (~16 archivos)
  - Nuevo: lib/shared/mixins/disposable_controllers_mixin.dart
  - Migrar las 15 pantallas que toqué en Fase 1 (las de scan de pick ×3, batch, conteo ×2, devoluciones, recepción ×2, packing ×3, transferencias ×2, create-transfer)

  2.2 — Sacar controllers de los Blocs (el punto más grande: ~29 archivos)
  - Los 11 Blocs: recepcion_bloc, devoluciones_bloc, packing_pedido_bloc, crate_transfer_bloc, recepcion_batch_bloc, packing_consolidade_bloc, wms_packing_bloc,
  picking_pick_bloc, transferencia_bloc, wms_picking_bloc, batch_bloc
  - Más los 18 archivos de UI que hoy referencian bloc.xxxController (acabo de verificar): los index/list screens de packing, picking, recepción y transferencias, los
  diálogos de editar producto, new_lote_widget, etc. Cada uno pasa a tener su controller local

  2.3 — Mover add() fuera de build() (~12 archivos)
  - devoluciones/index.dart, wms_packing/packing/screens/index.dart, packing_detail.dart, tab1.dart, conteo/scan_product_screen.dart, new_lote_widget.dart,
  devoluciones/lote_screen.dart, y los diálogos dialog_backorder_widget, dialog_packing_advetencia_cantidad_widget, dialog_delete_product_widget, entre otros

  2.4 — Acotar scope de Blocs por módulo (2 archivos + ruteo)
  - lib/main.dart (los 35 BlocProvider de la raíz)
  - lib/core/routes/app_router.dart (envolver rutas de módulo con su provider)
  - Riesgo: pantallas que asumen estado persistente entre navegaciones — requiere probar módulo por módulo

  Recomendación de orden: 2.2 primero solo para los Blocs de módulos ya migrados a Clean Architecture, 2.1 después (el mixin deja de tener sentido si luego reescribes las
  pantallas), 2.3 es mecánico y seguro, y 2.4 al final porque es el de mayor riesgo funcional. ¿Arranco con alguno?