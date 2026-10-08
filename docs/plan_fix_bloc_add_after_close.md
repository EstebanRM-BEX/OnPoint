# Plan — "Cannot add new events after calling close" (Crashlytics #3)

> Fecha: 2026-10-08 · Rama base: `desarrollo`
> Issue: `06aae1e92fb3d791468aec5be294ff8f` · 1.7.1 – 1.7.5 · recurrente
> Último evento: Urovo DT50, 1.7.5 (16), 8 oct 2026 00:58

---

## 1. Diagnóstico

**Stack:**
```
Bad state: Cannot add new events after calling close
  _BroadcastStreamController.add (dart:async)
  Bloc.add (bloc.dart:97)
  PackingPedidoListBloc._onIniciada (packing_pedido_list_bloc.dart:79)
```

**Secuencia:**
1. El operario entra a la lista de packing por pedido → `ListaPackIniciada`.
2. `_onIniciada` hace dos `await` (`getConfig`, `getPedidosLocal`). En una PDA con SQLite ocupado (sync de login), eso puede tardar segundos.
3. El operario sale de la pantalla (atrás o al home). El `BlocProvider` de la ruta cierra el bloc (`close()`).
4. Termina el `await` y la línea 79 hace `add(const ListaPackSincronizada())` → el controlador de eventos ya está cerrado → `StateError`.
5. El handler relanza el error, `FlutterError.onError` lo registra como **fatal** y la app muestra la pantalla de error.

**Por qué solo `add` revienta:** `emit()` después de `close()` se ignora en silencio (la librería cancela los emitters), pero `add()` lanza la excepción. Todo `add()` que corre **después de un `await`** o **desde un callback asíncrono** (stream, `Future.then`, `Timer`, listener) puede fallar si la pantalla se cerró antes.

**Por qué no alcanza con `isClosed`:** el proyecto usa bloc **9.2.0**. Ahí `isClosed` mira el controlador de **estados**, que se cierra al final de `close()`, después de esperar a los handlers en curso. El controlador de **eventos** se cierra al principio. Durante ese intervalo `isClosed` es `false` pero `add()` lanza la excepción, que es justo el caso del reporte (el test lo reproduce). Por eso el mixin marca `isClosing` al empezar `close()`. (En 9.2.1 `isClosed` ya mira el controlador de eventos; con el mixin no hace falta subir de versión.)

---

## 2. Alcance

Blocs que hacen `add()` sobre sí mismos (`grep -E "^\s+add\(" *_bloc.dart`): 23 archivos, 181 llamadas. El riesgo real depende de **si el bloc se cierra**:

| Riesgo | Blocs | Motivo |
|---|---|---|
| **Alto** (por ruta, se cierran al salir) | `PackingPedidoListBloc` (1) ← **el del reporte**, `PickScanBloc` (12), `InventarioBloc` (9), `InfoRapidaBloc` (7, además escucha WebSocket), `DevolucionesBloc` (13), `CreateTransferBloc` (11), `PickingListBloc` (2), `PickingComponentsBloc` (1), `TransferInfoBloc` (1), `PackingConsolidadeBloc` (1), `EnterpriseBloc` (3) | Se crean por ruta (`getIt` factory o `BlocProvider` local) |
| **Bajo** (globales en `main.dart`, viven toda la sesión) | `PickingPickBloc`, `RecepcionBloc`, `TransferenciaBloc`, `WMSPickingBloc`, `BatchBloc`, `WmsPackingBloc`, `RecepcionBatchBloc`, `ConteoBloc`, `ClusterPickingBloc`, `UserBloc`, `HomeBloc`, `WebSocketBloc` | Solo se cierran al matar la app. Igual quedan cubiertos por la prevención de §4 |

Además del `add()` interno, hay que revisar:
- **Suscripciones** que llaman `add` (`InfoRapidaBloc` con el WebSocket, `PickingPickBloc` con la red): se cancelan en `close()`, pero un mensaje que ya estaba en la cola puede llegar después.
- **UI que hace `await` y después `context.read<X>().add(...)`**: falla con otro error (contexto desmontado). Se cubre con `mounted` y queda fuera de este plan.

---

## 3. Arreglo inmediato (hotfix)

`packing_pedido_list_bloc.dart:78-80`:
```dart
// Primera vez sin datos locales: se trae de Odoo.
if (!isClosing && (event.sincronizar || state.pedidos.isEmpty)) {
  add(const ListaPackSincronizada());
}
```

- `PackingPedidoListBloc` usa `SafeBlocMixin` (§4.1) para tener `isClosing`.
- Test: el use case de pedidos locales tarda (Completer), se llama `bloc.close()` antes de completarlo y se espera que **no** lance error ni sincronice.
- **Commit:** `fix(packing_pedido): no encolar sync si la lista ya se cerró`
- Va en el próximo build (1.7.6).

---

## 4. Prevención

### 4.1 `SafeBlocMixin` (red de seguridad para todos los blocs)

`lib/core/bloc/safe_bloc_mixin.dart`: sobrescribe `close()` para marcar `isClosing` desde el inicio y `add()` para descartar (con log en Crashlytics) los eventos que llegan con el bloc cerrándose o cerrado.

- Uso: `class PackingPedidoListBloc extends Bloc<...> with SafeBlocMixin<...>`.
- Se aplica primero a los blocs de **riesgo alto** (§2) y después a los globales.
- Queda **también** el `if (!isClosing)` explícito en los handlers que se arreglen: el mixin es una red, no reemplaza leer el código.
- Test unitario del mixin: `close()` + `add()` no lanza error y no procesa el evento.

### 4.2 Auditoría de `add()` diferidos (riesgo alto)

En cada bloc de riesgo alto, revisar cada `add()` y clasificarlo:

| Patrón | Acción |
|---|---|
| `add()` después de un `await` dentro de un handler | `if (!isClosing)` + mixin |
| `add()` para encadenar flujos (ej. al terminar crear, `add(Recargar)`) | Preferir que la page escuche el éxito y dispare el siguiente evento; si se mantiene, `if (!isClosing)` |
| `add()` en `listen` de stream, `Timer`, `Future.then` | Cancelar en `close()` (verificar que exista) + mixin |
| `add()` en el constructor | Sin riesgo (el bloc está abierto) |

Orden sugerido (por uso en PDA y cantidad de `add`): `PackingPedidoListBloc` → `PickScanBloc` → `InventarioBloc` → `InfoRapidaBloc` → `DevolucionesBloc` → `CreateTransferBloc` → el resto.

### 4.3 Regla para código nuevo

Agregar a `lib/features/FEATURE_TEMPLATE.md`:
- Todo bloc nuevo usa `with SafeBlocMixin`.
- No encadenar eventos con `add()` después de un `await`; si hace falta, `if (!isClosing)`.
- Toda suscripción del bloc se cancela en `close()`.

### 4.4 Detección

- `AppBlocObserver` (`core/utils/diagnostics/bloc_registry.dart`): en `onError`, si el error es `StateError` con "after calling close", agregar como clave de Crashlytics el nombre del bloc y del último evento, para encontrar rápido cualquier caso que quede sin cubrir.
- Después de 1.7.6, revisar en Crashlytics que el issue `06aae1e9…` no vuelva a aparecer. Si aparece desde otro bloc, el stack dirá cuál y se aplica §4.2 a ese bloc.

---

## 5. Pruebas

| # | Caso | Esperado |
|---|---|---|
| 1 | Test: `close()` durante `getPedidosLocal` en `PackingPedidoListBloc` | Sin excepción, sin sync |
| 2 | Test del mixin: `add()` después de `close()` | Sin excepción, evento descartado |
| 3 | PDA (Urovo DT50): entrar a Packing pedido y salir de inmediato, 10 veces seguidas, con y sin datos locales | La app no se cae |
| 4 | PDA: igual que el 3 justo después del login (sync masiva corriendo, SQLite lento) | La app no se cae |
| 5 | Info Rápida: salir con un mensaje WebSocket entrando | La app no se cae |
| 6 | Uso normal de packing (sync al entrar sin datos, refresco manual) | Igual que antes |

---

## 6. Fases y commits

| Fase | Contenido | Commit |
|---|---|---|
| 1 | Hotfix en `PackingPedidoListBloc` + test | `fix(packing_pedido): no encolar sync si la lista ya se cerró` |
| 2 | `SafeBlocMixin` + test, aplicado a los 11 blocs de riesgo alto | `feat(core): SafeBlocMixin para add() después de close` |
| 3 | Auditoría §4.2 en los blocs de riesgo alto (`if (!isClosing)` y suscripciones) | `fix(blocs): proteger add() diferidos` |
| 4 | Mixin en los blocs globales + regla en `FEATURE_TEMPLATE.md` + claves en `AppBlocObserver` | `chore(blocs): SafeBlocMixin global y detección en observer` |
| 5 | Pruebas 3-6 en PDA y seguimiento en Crashlytics tras publicar 1.7.6 | — |

Las fases 1 y 2 alcanzan para cortar el crash en producción; 3 y 4 son prevención.
