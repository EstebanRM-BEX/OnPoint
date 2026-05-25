# AUDITORÍA TÉCNICA Y PLAN DE MEJORAS — WMS App Flutter
**Fecha de auditoría:** 23/05/2026
**Branch analizado:** clean-arquitecture
**Líneas de código analizadas:** ~152.000
**Autor del informe:** Claude Code (Anthropic)

---

## ÍNDICE

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Hallazgos por Severidad](#2-hallazgos-por-severidad)
   - 2.1 [Críticos](#21-críticos)
   - 2.2 [Altos](#22-altos)
   - 2.3 [Medios](#23-medios)
   - 2.4 [Bajos](#24-bajos)
3. [Plan de Mejora por Fases](#3-plan-de-mejora-por-fases)
   - Fase 0 — Hotfixes de seguridad (Semana 1)
   - Fase 1 — Estabilidad y rendimiento base (Semanas 2-3)
   - Fase 2 — Deuda técnica estructural (Semanas 4-7)
   - Fase 3 — Arquitectura y escalabilidad (Semanas 8-14)
   - Fase 4 — Calidad continua (Semana 15 en adelante)
4. [Tabla de Prioridades](#4-tabla-de-prioridades)
5. [Métricas de Éxito](#5-métricas-de-éxito)

---

## 1. RESUMEN EJECUTIVO

La app WMS tiene una base sólida: Clean Architecture, BLoC, SQLite local, integración Odoo.
Sin embargo, la auditoría identifica 4 problemas críticos de seguridad y memoria, 4 problemas altos
de rendimiento y mantenibilidad, y una deuda técnica significativa en el tamaño de los BLoCs.

El riesgo más inmediato es la exposición del password en el estado BLoC y el bypass total de SSL,
que dejan la app vulnerable en entornos de red no confiables.

El riesgo de mantenibilidad más grave son los God Objects: 8 archivos superan las 1.600 líneas,
siendo picking_pick_bloc.dart el más crítico con 2.181 líneas. Esto hace que los bugs sean
difíciles de aislar y las pruebas casi imposibles de escribir.

---

## 2. HALLAZGOS POR SEVERIDAD

---

### 2.1 CRÍTICOS

---

#### C-01 | Password en texto plano dentro del estado BLoC
- **Archivo:** lib/features/login/presentation/bloc/login_state.dart:13-16
- **Archivo:** lib/features/login/presentation/bloc/login_bloc.dart:60
- **Impacto:** SEGURIDAD — el password queda en memoria accesible desde cualquier BlocListener.
  Si Crashlytics captura el estado en un crash, el password queda expuesto en los logs.

```dart
// ESTADO ACTUAL (INSEGURO):
class LoginSuccess extends LoginState {
  final String password;  // ← nunca debería estar en un estado
  LoginSuccess(this.user, this.password);
}

// EN EL BLOC:
emit(LoginSuccess(user, event.password));  // ← expone el password
```

**Corrección:**
- Eliminar el campo `password` de `LoginSuccess`.
- Guardar el password en `PrefUtils` dentro del handler del evento, antes de emitir el estado.
- El estado solo debe llevar `UserModel` o el ID de sesión.

---

#### C-02 | TextEditingController sin dispose en PrintLabelsBloc
- **Archivo:** lib/features/print_labels/presentation/bloc/print_labels_bloc.dart:19-22
- **Impacto:** MEMORY LEAK — cada navegación al módulo de etiquetas acumula 4 controladores
  sin liberar. En sesiones largas de almacén, la memoria crece hasta que la app se cierra.

```dart
// ESTADO ACTUAL (LEAK):
TextEditingController searchControllerLocation = TextEditingController();
TextEditingController searchControllerProducts = TextEditingController();
TextEditingController rangeStartController = TextEditingController();
TextEditingController rangeEndController = TextEditingController();
// No existe override de close()
```

**Corrección:**
```dart
@override
Future<void> close() {
  searchControllerLocation.dispose();
  searchControllerProducts.dispose();
  rangeStartController.dispose();
  rangeEndController.dispose();
  return super.close();
}
```

**Nota adicional:** Los TextEditingController son objetos de UI y no deberían vivir en un BLoC.
El patrón correcto es tenerlos en el State del widget y pasarle al BLoC solo el String del valor.
Esto se puede migrar en la Fase 2.

---

#### C-03 | SSL completamente deshabilitado — Vulnerable a MITM
- **Archivo:** lib/main.dart:54-61
- **Impacto:** SEGURIDAD CRÍTICA — la app acepta cualquier certificado SSL, incluyendo los
  falsos generados por un atacante en la misma red (ataque Man-in-the-Middle).
  En una red de almacén con WiFi compartido, esto es un riesgo real.

```dart
// ESTADO ACTUAL (INSEGURO):
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true; // acepta TODO
  }
}
```

**Corrección a corto plazo:** Restringir el bypass solo al host conocido del servidor Odoo:
```dart
..badCertificateCallback = (cert, host, port) =>
    host == 'mi-servidor-odoo.com'; // solo para el host específico
```

**Corrección definitiva:** Instalar un certificado SSL válido (Let's Encrypt es gratis)
en el servidor Odoo y eliminar MyHttpOverrides por completo.

---

#### C-04 | IP del servidor hardcodeada en postMultipartImage
- **Archivo:** lib/src/api/api_request_service.dart:155
- **Impacto:** Si la IP del servidor cambia, la subida de imágenes falla silenciosamente.
  Todos los demás métodos usan PrefUtils.getEnterprise() correctamente, este se quedó atrás.

```dart
// ESTADO ACTUAL:
const urlBase = 'http://34.127.73.152:5005'; // hardcodeada

// CORRECCIÓN:
final urlBase = await PrefUtils.getEnterprise(); // igual que los demás métodos
```

---

### 2.2 ALTOS

---

#### A-01 | God Objects — BLoCs con más de 1.600 líneas
- **Impacto:** Imposible testear unitariamente, los bugs son difíciles de aislar, el tiempo
  de compilación incremental es lento, y múltiples desarrolladores no pueden trabajar
  en el mismo archivo sin conflictos de merge.

| Archivo | Líneas |
|---------|--------|
| lib/.../wms_picking/modules/Pick/bloc/picking_pick_bloc.dart | 2.181 |
| lib/.../wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart | 2.128 |
| lib/.../packing-consolidade/bloc/packing_consolidade_bloc.dart | 1.829 |
| lib/.../recepcion/modules/individual/screens/bloc/recepcion_bloc.dart | 1.804 |
| lib/.../packing-batch/bloc/wms_packing_bloc.dart | 1.696 |
| lib/.../conteo/screens/bloc/conteo_bloc.dart | 1.680 |
| lib/.../cluster_picking/bloc/cluster_picking_bloc.dart | 1.680 |
| lib/.../Batchs/blocs/batch_bloc/batch_bloc.dart | 1.668 |

Adicionalmente, estas pantallas mezclan lógica de negocio con UI:
- lib/.../wms_picking/modules/Pick/screens/scan_product_screen.dart → 1.608 líneas
- lib/.../recepcion/modules/individual/screens/scan_product_screen.dart → 1.490 líneas
- lib/.../devoluciones/screens/index.dart → 1.471 líneas

**Plan de corrección:** Ver Fase 3.

---

#### A-02 | 43 sentencias print() en producción (no debugPrint)
- **Impacto:** Los print() se ejecutan en builds de release, generan overhead de I/O continuo
  y pueden revelar URLs, session IDs y datos de productos en los logs del dispositivo.

Archivos más afectados:
- lib/core/services/websocket_service.dart → 14 print() (imprime URL, session ID, datos raw)
- lib/features/printing/presentation/widgets/modal_printers_list.dart → 6 print()
- lib/features/print_labels/presentation/bloc/print_labels_bloc.dart
- lib/features/picking_cluster/presentation/bloc/cluster_picking_bloc.dart

**Corrección:** Reemplazar todos por debugPrint(). Los debugPrint() son eliminados
automáticamente en builds de release por el compilador de Flutter.

Comando para encontrarlos todos:
```
grep -rn "print(" lib/ --include="*.dart" | grep -v "debugPrint"
```

---

#### A-03 | Timeouts HTTP incorrectos o ausentes
- **Archivo:** lib/src/api/api_request_service.dart
- **Impacto:** El usuario puede quedar bloqueado indefinidamente si el servidor no responde.

| Situación | Líneas | Problema |
|-----------|--------|---------|
| Timeout de 100 segundos | 336, 712, 767 | Usuario espera hasta 1m40s antes de ver error |
| post() sin timeout | ~95 | Request puede colgar indefinidamente |
| get() sin timeout | varios | Idem |
| searchEnterprice() sin timeout | - | Idem |

**Corrección:**
```dart
// Para operaciones estándar
.timeout(const Duration(seconds: 30))

// Para operaciones pesadas (inventario, picking masivo)
.timeout(const Duration(seconds: 60))
```

---

#### A-04 | use_build_context_synchronously suprimido en archivos críticos
- **Impacto:** Oculta casos donde Navigator o ScaffoldMessenger se usan después de un await
  sin verificar if (mounted), produciendo excepciones en producción cuando el usuario
  navega rápidamente.

Archivos con el ignore activo:
- lib/main.dart (línea 1)
- lib/features/home/presentation/bloc/home_bloc.dart (línea 1)
- lib/features/home/presentation/index.dart (línea 1)
- lib/features/home/presentation/widgets/update_app_dialog_widget.dart (línea 1)
- lib/features/home/presentation/widgets/close_session_widget.dart (línea 1)
- lib/features/picking_cluster/presentation/screens/picking_cluster/index.dart (línea 1)

**Corrección:** Eliminar los ignore y resolver cada warning individualmente con:
```dart
if (!mounted) return;
Navigator.of(context).pushNamed(...);
```

---

### 2.3 MEDIOS

---

#### M-01 | WebSocket sin reconexión automática
- **Archivo:** lib/core/services/websocket_service.dart
- **Impacto:** Si la red cae momentáneamente (wifi inestable en almacén, servidor reiniciado),
  el WebSocket queda muerto silenciosamente. El usuario no ve error y los datos dejan
  de actualizarse en tiempo real sin que lo sepa.

**Corrección:** Implementar reconnect con backoff exponencial en el callback onDone/onError:
```dart
int _reconnectAttempts = 0;

void _scheduleReconnect() {
  final delay = Duration(seconds: min(30, pow(2, _reconnectAttempts).toInt()));
  _reconnectAttempts++;
  Future.delayed(delay, () => connect());
}
```

---

#### M-02 | Llamadas a base de datos secuenciales donde podrían ser paralelas
- **Archivo:** lib/features/picking_cluster/presentation/bloc/cluster_picking_bloc.dart:1346-1384
- **Impacto:** El tiempo de carga del módulo de picking es la suma de 3 queries en lugar
  del máximo de ellas.

```dart
// ESTADO ACTUAL — secuencial (~3x lento):
final resultProducts = await getLocalBatchProductsData(...);
final config = await getUserConfiguration(...);
final novelties = await getUserNovelties(...);

// CORRECCIÓN — paralelo:
final results = await Future.wait([
  getLocalBatchProductsData(...),
  getUserConfiguration(...),
  getUserNovelties(...),
]);
```

---

#### M-03 | Pantallas con lógica de negocio incrustada
- **Archivos:**
  - lib/.../wms_picking/modules/Pick/screens/scan_product_screen.dart (1.608 líneas)
  - lib/.../recepcion/modules/individual/screens/scan_product_screen.dart (1.490 líneas)
  - lib/.../devoluciones/screens/index.dart (1.471 líneas)

La lógica de validación de escaneos, cálculo de cantidades y llamadas a repositorios está
mezclada con la construcción de widgets. Esto impide testear la lógica sin levantar la UI.

---

#### M-04 | 22 TODOs sin resolver en el código
Incluye:
- lib/features/websocket/presentation/bloc/websocket_bloc.dart:40
  `// TODO: Add specific logic based on message type`
  → El manejo de mensajes WebSocket por tipo está incompleto.
- lib/core/utils/prefs/pref_utils.dart:58
  → Datos de PDA pendientes de implementar.

---

#### M-05 | Manejo de errores incompleto en catch blocks
- **Archivo:** lib/core/services/websocket_service.dart:192, 127
- Los errores de conexión WebSocket solo hacen debugPrint, no emiten un estado de error
  al BLoC. La UI no puede reaccionar a los fallos de conexión.

---

### 2.4 BAJOS

---

#### B-01 | Nombre de archivo con PascalCase (violación de convención Dart)
- **Archivo:** lib/features/home/presentation/widgets/Dialog_ProductsNotSends.dart
- En Linux (servidores CI/CD), los sistemas de archivos son case-sensitive.
  Un archivo mal nombrado puede causar que el build falle en CI aunque funcione en Mac.
- **Corrección:** Renombrar a `dialog_products_not_sends.dart`.

---

#### B-02 | Variables booleanas con prefijos inconsistentes
- **Archivo:** lib/features/picking_cluster/presentation/bloc/cluster_picking_bloc.dart:65-81
- Mezcla de `isLocationOk`, `locationIsOk`, `isProductOk`, `productIsOk`.
  Puede llevar a usar la variable equivocada en una condición.

---

#### B-03 | Método validateBarcode() vacío sin implementar
- **Archivo:** lib/features/picking_cluster/presentation/screens/picking_cluster/index.dart:32
- `void validateBarcode(String value, BuildContext context) {}` — declarado pero sin cuerpo.

---

#### B-04 | TextEditingController en BLoCs (antipatrón general)
Los controladores de texto son objetos de la capa de presentación (UI) y no deben vivir
en un BLoC. El patrón correcto es mantenerlos en el StatefulWidget y pasarle al BLoC
solo el valor String cuando cambia.
Afecta: PrintLabelsBloc, ClusterPickingBloc.

---

## 3. PLAN DE MEJORA POR FASES

---

### FASE 0 — Hotfixes de Seguridad y Memoria
**Duración estimada:** 1 semana
**Objetivo:** Cerrar vulnerabilidades críticas sin cambiar la arquitectura.

#### Tarea F0-1: Eliminar password del estado BLoC (C-01)
- Editar `login_state.dart`: eliminar campo `password` de `LoginSuccess`.
- Editar `login_bloc.dart`: guardar el password en `PrefUtils` antes del emit.
- Buscar todos los lugares que leen `state.password` y migrarlos a `PrefUtils.getPassword()`.
- **Estimado:** 2-3 horas
- **Riesgo:** Bajo — cambio localizado en el módulo de login.

#### Tarea F0-2: Agregar dispose() en PrintLabelsBloc (C-02)
- Editar `print_labels_bloc.dart`: agregar override de `close()` con dispose de los 4 controladores.
- **Estimado:** 30 minutos
- **Riesgo:** Ninguno.

#### Tarea F0-3: Corregir URL hardcodeada en postMultipartImage (C-04)
- Editar `api_request_service.dart:155`: reemplazar `const urlBase = 'http://34.127.73.152:5005'`
  por `final urlBase = await PrefUtils.getEnterprise()`.
- **Estimado:** 15 minutos
- **Riesgo:** Ninguno — patrón idéntico al resto de métodos.

#### Tarea F0-4: Mitigar SSL bypass (C-03)
- Editar `main.dart`: cambiar el callback para que solo acepte el host del servidor Odoo.
- Documentar en comentario que esto es temporal hasta tener certificado válido.
- **Estimado:** 1 hora (incluye verificar el hostname correcto)
- **Riesgo:** Bajo — si el hostname es incorrecto, la app no conecta. Probar en staging.

#### Tarea F0-5: Reemplazar los 43 print() por debugPrint() (A-02)
- Ejecutar búsqueda masiva y reemplazar:
  ```
  grep -rn "print(" lib/ --include="*.dart" | grep -v "debugPrint"
  ```
- Revisar cada uno — algunos pueden necesitar eliminarse directamente.
- **Estimado:** 2 horas
- **Riesgo:** Ninguno.

**Criterio de salida de Fase 0:**
- [ ] Login no expone password en estado
- [ ] PrintLabelsBloc libera controladores en close()
- [ ] postMultipartImage usa PrefUtils.getEnterprise()
- [ ] SSL bypass restringido al host conocido
- [ ] 0 print() sin debug en producción

---

### FASE 1 — Estabilidad y Rendimiento Base
**Duración estimada:** 2 semanas
**Objetivo:** Hacer la app más estable bajo condiciones reales de almacén.

#### Tarea F1-1: Unificar y corregir timeouts HTTP (A-03)
- Crear una constante central en `api_request_service.dart`:
  ```dart
  static const _kDefaultTimeout = Duration(seconds: 30);
  static const _kHeavyTimeout = Duration(seconds: 60);
  ```
- Aplicar `_kDefaultTimeout` a todos los métodos sin timeout.
- Reemplazar los timeouts de 100s por `_kHeavyTimeout` donde corresponda.
- **Estimado:** 3 horas
- **Riesgo:** Bajo — asegurarse de que operaciones de inventario masivo no queden cortadas.

#### Tarea F1-2: Implementar reconexión automática en WebSocket (M-01)
- Editar `websocket_service.dart`: agregar lógica de backoff exponencial en los
  callbacks `onDone` y `onError`.
- Agregar un estado `WebSocketReconnecting` al bloc para informar a la UI.
- Resetear el contador de intentos cuando la conexión sea exitosa.
- **Estimado:** 4-6 horas
- **Riesgo:** Medio — probar que no genere bucles de reconexión infinitos.

#### Tarea F1-3: Resolver warnings use_build_context_synchronously (A-04)
- Eliminar los `ignore_for_file` de los 6 archivos afectados.
- Revisar cada warning generado y agregar `if (!mounted) return;` donde corresponda.
- **Estimado:** 4-6 horas (hay que revisar caso por caso)
- **Riesgo:** Medio — algunos flujos pueden cambiar comportamiento.

#### Tarea F1-4: Paralelizar queries en _onFetchBatchProducts (M-02)
- Editar `cluster_picking_bloc.dart:1346-1384`: reemplazar las 3 llamadas secuenciales
  con `Future.wait()`.
- Medir el tiempo de carga antes y después para confirmar mejora.
- **Estimado:** 2 horas
- **Riesgo:** Bajo — las 3 queries son independientes entre sí.

#### Tarea F1-5: Completar manejo de errores en WebSocket (M-05)
- Editar `websocket_service.dart`: en los catch blocks, emitir un estado de error
  en lugar de solo hacer debugPrint.
- La UI del picking debe mostrar un aviso si el WebSocket está desconectado.
- **Estimado:** 3 horas

**Criterio de salida de Fase 1:**
- [ ] Todos los métodos HTTP tienen timeout ≤ 60s
- [ ] WebSocket se reconecta automáticamente tras caída de red
- [ ] 0 warnings de use_build_context_synchronously
- [ ] Carga de picking al menos 30% más rápida (medida con stopwatch)
- [ ] La UI informa al usuario si el WebSocket está desconectado

---

### FASE 2 — Deuda Técnica Puntual
**Duración estimada:** 2 semanas
**Objetivo:** Resolver todos los problemas medios y bajos antes de atacar la arquitectura.

#### Tarea F2-1: Mover TextEditingController de BLoCs a widgets (B-04 + C-02)
- `PrintLabelsBloc`: mover los 4 controladores al StatefulWidget correspondiente.
  El BLoC recibe eventos con el String del valor, no el controlador.
- `ClusterPickingBloc`: mover `editProductController` al widget scan.
- **Estimado:** 4-6 horas
- **Riesgo:** Medio — requiere coordinar entre widget y BLoC.

#### Tarea F2-2: Renombrar archivo con PascalCase (B-01)
- Renombrar `Dialog_ProductsNotSends.dart` → `dialog_products_not_sends.dart`.
- Actualizar todos los imports que lo referencian.
- **Estimado:** 30 minutos
- **Riesgo:** Ninguno (IDE refactor automático).

#### Tarea F2-3: Unificar convención de variables booleanas (B-02)
- En `cluster_picking_bloc.dart`: estandarizar al prefijo `is` (isLocationOk, isProductOk).
- Hacer búsqueda global para identificar otros casos similares.
- **Estimado:** 1 hora

#### Tarea F2-4: Implementar validateBarcode() (B-03)
- Definir con el equipo qué debe hacer este método o eliminarlo si no se usa.
- **Estimado:** 1-2 horas

#### Tarea F2-5: Resolver los 22 TODOs (M-04)
- Revisar cada TODO y decidir: implementar, eliminar, o convertir en ticket de backlog.
- El TODO de websocket_bloc.dart:40 sobre tipos de mensajes es el más importante.
- **Estimado:** 4-8 horas (depende de cuántos requieren implementación real)

#### Tarea F2-6: Mejorar error handling en catch blocks (M-05)
- Auditar todos los catch(e) que solo hacen print/debugPrint.
- Clasificar: ¿debe emitirse un estado de error? ¿debe reintentarse? ¿debe loguearse?
- **Estimado:** 4-6 horas

**Criterio de salida de Fase 2:**
- [ ] 0 controladores de UI en BLoCs
- [ ] Todos los nombres de archivo en snake_case
- [ ] 0 TODOs sin decisión tomada
- [ ] Todos los catch blocks tienen manejo explícito

---

### FASE 3 — Refactorización de God Objects
**Duración estimada:** 6 semanas
**Objetivo:** Dividir los BLoCs gigantes en unidades mantenibles y testeables.

Esta es la fase más importante para la salud a largo plazo del proyecto.
Se trabaja un módulo por sprint para no desestabilizar la app completa.

#### Sprint 3A — picking_pick_bloc.dart (2.181 líneas)
Dividir en:
- `PickingPickBloc` — coordinador de estado principal (eventos de navegación)
- `PickingScanBloc` o Mixin — lógica de escaneo de producto/ubicación
- `PickingBatchBloc` o UseCase — gestión de lotes (lotes, novedades)
- `PickingValidationService` — reglas de negocio puras (sin emit), fácil de testear

#### Sprint 3B — packing_pedido_bloc.dart (2.128 líneas)
Dividir en:
- `PackingPedidoBloc` — estado de la orden de packing
- `PackingScanMixin` — escaneo de productos/cajas
- `PackingValidationService` — reglas de validación

#### Sprint 3C — recepcion_bloc.dart y wms_packing_bloc.dart
Mismo patrón de división.

#### Sprint 3D — conteo_bloc.dart y cluster_picking_bloc.dart
Mismo patrón de división.

#### Sprint 3E — Limpiar pantallas con lógica incrustada
- Extraer lógica de `scan_product_screen.dart` hacia el BLoC correspondiente.
- La pantalla solo construye widgets y despacha eventos.
- Meta: ninguna pantalla supera 400 líneas.

#### Sprint 3F — Escribir tests unitarios para la nueva estructura
Una vez divididos los BLoCs, escribir tests de los casos críticos:
- Escaneo de producto correcto / incorrecto
- Validación de cantidades
- Manejo de errores de red

**Criterio de salida de Fase 3:**
- [ ] Ningún BLoC supera 600 líneas
- [ ] Ninguna pantalla supera 400 líneas
- [ ] Cobertura de tests > 40% en la lógica de negocio
- [ ] Tiempo de compilación incremental reducido

---

### FASE 4 — Calidad Continua (Permanente)
**Duración:** Desde semana 15 en adelante — proceso continuo.

#### F4-1: Instalar certificado SSL válido en el servidor Odoo
- Eliminar `MyHttpOverrides` de `main.dart` completamente.
- Configurar Let's Encrypt o certificado corporativo.
- **Dependencia:** Equipo de infraestructura.

#### F4-2: Configurar linter estricto
Agregar a `analysis_options.yaml`:
```yaml
linter:
  rules:
    - avoid_print: true
    - use_build_context_synchronously: true
    - close_sinks: true
    - cancel_subscriptions: true
```
Esto hace que los problemas de las fases anteriores no vuelvan a aparecer.

#### F4-3: Integrar flutter_lints o very_good_analysis
Subir el nivel de análisis estático para detectar problemas antes del commit.

#### F4-4: CI/CD con análisis automático
Agregar en el pipeline:
```
flutter analyze
flutter test
dart run dart_code_metrics:metrics analyze lib
```

#### F4-5: Monitoreo de rendimiento con Firebase Performance
Agregar trazas en las operaciones críticas:
- Tiempo de carga del picking
- Tiempo de envío a Odoo
- Tiempo de reconexión WebSocket

---

## 4. TABLA DE PRIORIDADES

| ID | Problema | Severidad | Fase | Esfuerzo | Impacto |
|----|----------|-----------|------|----------|---------|
| C-01 | Password en estado BLoC | CRÍTICO | 0 | 3h | Seguridad |
| C-02 | Controladores sin dispose | CRÍTICO | 0 | 30min | Memoria |
| C-03 | SSL completamente deshabilitado | CRÍTICO | 0→4 | 1h→∞ | Seguridad |
| C-04 | IP hardcodeada en postMultipartImage | CRÍTICO | 0 | 15min | Estabilidad |
| A-01 | God Objects (8 BLoCs gigantes) | ALTO | 3 | 6 sprints | Mantenibilidad |
| A-02 | 43 print() en producción | ALTO | 0 | 2h | Rendimiento |
| A-03 | Timeouts HTTP incorrectos | ALTO | 1 | 3h | Estabilidad |
| A-04 | BuildContext post-async sin mounted | ALTO | 1 | 6h | Crashes |
| M-01 | WebSocket sin reconexión | MEDIO | 1 | 6h | Fiabilidad |
| M-02 | Queries BD secuenciales | MEDIO | 1 | 2h | Rendimiento |
| M-03 | Pantallas con lógica incrustada | MEDIO | 3 | 3 sprints | Mantenibilidad |
| M-04 | 22 TODOs sin resolver | MEDIO | 2 | 4-8h | Completitud |
| M-05 | Error handling en catch blocks | MEDIO | 1-2 | 6h | Fiabilidad |
| B-01 | Nombre de archivo PascalCase | BAJO | 2 | 30min | CI/CD |
| B-02 | Variables booleanas inconsistentes | BAJO | 2 | 1h | Legibilidad |
| B-03 | validateBarcode() vacío | BAJO | 2 | 1-2h | Completitud |
| B-04 | TextEditingController en BLoCs | BAJO | 2 | 6h | Arquitectura |

---

## 5. MÉTRICAS DE ÉXITO

Al completar todas las fases, la app debería cumplir:

### Seguridad
- [ ] Ninguna credencial expuesta en estados de BLoC
- [ ] SSL con certificado válido y sin bypass
- [ ] 0 datos sensibles en logs de producción

### Rendimiento
- [ ] Tiempo de carga del módulo de picking < 1 segundo
- [ ] 0 print() ejecutándose en builds de release
- [ ] Todos los requests HTTP tienen timeout ≤ 60 segundos

### Estabilidad
- [ ] WebSocket se reconecta automáticamente en < 30 segundos
- [ ] 0 crasheos por BuildContext post-async
- [ ] 0 memory leaks detectados en sesiones de 8+ horas

### Mantenibilidad
- [ ] Ningún archivo supera 600 líneas
- [ ] Ninguna pantalla supera 400 líneas
- [ ] Cobertura de tests > 40% en lógica de negocio
- [ ] 0 TODOs sin decisión tomada
- [ ] flutter analyze sin warnings en CI

### Observabilidad
- [ ] Firebase Performance con trazas en operaciones críticas
- [ ] WebSocket emite estados diferenciados (conectado / reconectando / error)
- [ ] La UI informa al usuario el estado de la conexión

---

*Documento generado el 23/05/2026. Revisarlo cada trimestre y actualizar el estado de cada tarea.*
