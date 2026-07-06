# Prevención de memory leaks — wms_app

Guía resultado del análisis y las fases de corrección de memory leaks (2026-07).
Contexto: los leaks históricos del proyecto eran casi todos el mismo patrón —
`TextEditingController`/`FocusNode` creados en pantallas de escaneo sin
`dispose()`, y `addObserver` sin `removeObserver`.

## Defensas activas

| Defensa | Dónde | Qué atrapa |
|---|---|---|
| `DisposableControllersMixin` | `lib/shared/widgets/disposable_controllers_mixin.dart` | Controllers/nodes declarados en `disposables` se liberan solos; un solo lugar que mantener |
| `leak_tracker_flutter_testing` | `test/flutter_test_config.dart` (global) | Cualquier widget test que deje un ChangeNotifier sin dispose **falla** con stack trace de dónde se creó |
| Lints `close_sinks` + `cancel_subscriptions` | `analysis_options.yaml` | StreamController sin close, StreamSubscription sin cancel |
| Checklist de PR | `.github/PULL_REQUEST_TEMPLATE.md` | Revisión manual de los 5 patrones de leak |

## Reglas al escribir pantallas nuevas

1. Pantalla con controllers/nodes → usar `DisposableControllersMixin` y
   declararlos en el getter `disposables`. No escribir `.dispose()` manuales.
2. `WidgetsBinding.instance.addObserver(this)` en `initState` exige
   `removeObserver(this)` en `dispose()`.
3. `.listen()` siempre asignado a una `StreamSubscription` cancelada en
   `dispose()` (widgets) o `close()` (blocs).
4. `Timer`/debounce: campo `Timer? _debounce` + `_debounce?.cancel()` en `dispose()`.
5. Los Blocs **no** deben poseer `TextEditingController` (deuda legacy en 11
   blocs de `src/`; no replicar el patrón — al migrar un módulo a
   `features/`, los controllers pasan a la pantalla y el valor viaja en el evento).

## Verificación periódica con DevTools (cada release o sprint)

1. Correr la app en un dispositivo Zebra en modo profile:
   `flutter run --profile`
2. Abrir DevTools → pestaña **Memory** → sección **Diff Snapshots**.
3. Tomar snapshot inicial en el home.
4. Entrar y salir **10 veces** de una pantalla de escaneo de alto tráfico
   (scan de pick, batch, recepción).
5. Forzar GC (botón GC en DevTools) y tomar segundo snapshot.
6. En el diff, filtrar por `TextEditingController`, `FocusNode` y el nombre
   del State de la pantalla (ej. `_BatchDetailScreenState`).
   - **Esperado:** delta ≈ 0 instancias.
   - **Leak:** delta ≈ +10 (una por visita) → algo quedó fuera de
     `disposables` o hay un listener/observer reteniendo el State.
7. Complemento en dispositivo real durante jornada larga:
   `adb shell dumpsys meminfo <package>` al inicio y fin del turno.

## Fallos conocidos no relacionados

- `test/widget_test.dart` ("App starts with CheckAuthPage") falla desde antes
  de activar leak_tracker; pendiente de arreglar aparte.
