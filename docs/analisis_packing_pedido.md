# Análisis — Módulo Packing por Pedido

> Fecha: 2026-10-07 · Rama: `sumatec-dev`
> Ruta: `lib/src/presentation/views/wms_packing/presentation/packing`
> Alcance: bloc, repositorio API (`wms_packing_repository.dart`), repositorio SQLite (`productos_pedido_pack_repository.dart`) y lógica de división.

---

## 1. Flujo actual

| Pantalla | Rol |
|---|---|
| `screens/index.dart` | Lista de pedidos. Trae `transferencias/pack` → SQLite (limpia huérfanos, paquetes y líneas obsoletas, reconcilia cantidades) |
| `screens/sacn_screen.dart` | Escaneo: ubicación → producto → cantidad → `SetPickingsEvent` (completo) o `SetPickingSplitEvent` (dividido) |
| `tabs/tab2.dart` — Por hacer | Empaca sin certificar (`SetPackingsEvent`, `isCertificate=false`, envía `quantity`) |
| `tabs/tab3.dart` — Listos | Empaca lo certificado (envía `min(quantitySeparate, quantity)`) y permite deshacer (`DeleteProductFromTemporaryPackageEvent`) |
| `tabs/tab5.dart` — Paquetes | Desempacar línea (`transferencias/unpacking`) o eliminar paquete (`transferencias/delete_pack`); la cantidad vuelve a "por hacer" buscando por producto + lote + ubicación |
| `tabs/tab1.dart` | Validar / crear backorder (`CreateBackPackOrNot`, `ValidateConfirmEvent`) |

### Endpoints usados

| Acción | Endpoint |
|---|---|
| Listar pedidos | `GET transferencias/pack` |
| Crear paquete | `send_transfer/pack` o `send_cluster/pack` (según `configPacking == 'cluster'`) |
| Desempacar | `transferencias/unpacking` |
| Eliminar paquete | `transferencias/delete_pack` |
| Asignar ubicación a paquete | `assignLocationToPackage` |
| Validar / backorder | `confirmationValidate`, `validateTransfer` |

### Estados de una fila (`tblproductos_pedidos`, type `packing-pack`)

| Estado | `is_separate` | `is_certificate` | `is_package` |
|---|---|---|---|
| Por hacer | NULL / 0 | NULL | NULL |
| Listo (certificado, sin empacar) | 1 | 1 | 0 |
| Empacado | 1 | 1 / 0 | 1 |

---

## 2. Lógica de división actual

`packing_pedido_bloc.dart:1461` — `_onSetPickingsSplitEvent`

1. Sobre la fila pendiente (`is_certificate IS NULL`) escribe: `time_separate_end`, `observation='Producto dividido'`, `time_separate`, `is_separate=1`, `is_product_split=1`, `is_package=0`, `is_certificate=1`.
2. **La `quantity` de esa fila NO se modifica** → queda con el total original; solo `quantity_separate = X`.
3. Inserta fila duplicada (`insertDuplicateProductoPedido`) con el **mismo `idMove`**, `is_product_split=1`, `quantity = total - X`.
4. Odoo recién crea el move nuevo al empacar; la respuesta reemplaza las filas locales (`replacePackedRowsFromApi`).

Disparo desde UI (`sacn_screen.dart:833` `_validatebuttonquantity`):
- `cantidad == quantity` → `ChangeQuantitySeparate` → listener → `SetPickingsEvent`.
- `cantidad < quantity` → `DialogPackAdvetenciaCantidadScreen`:
  - **Aceptar** (requiere novedad) → `SetPickingsEvent` (backorder del resto).
  - **Dividir Cantidad** (visible si `cantidad >= 1`) → `ChangeQuantitySeparate` + `SetPickingSplitEvent` + `LoadPedidoAndProductsEvent`.
- `cantidad > quantity` → snackbar "Cantidad erronea".

---

## 3. Bugs confirmados

### 3.1 Deshacer una división duplica cantidad
`bloc:546` `_onDeleteProductFromTemporaryPackageEvent`

Caso: 10 unidades → divido 4 → separo las 6 restantes. Deshacer la fila de 4: no hay pendiente con ese `idMove`, entra a `revertProductFields`, que la devuelve a "por hacer" con `quantity=10` (nunca se redujo).
Resultado: **10 por hacer + 6 certificadas = 16**.

### 3.2 Decisión de deshacer sobre lista filtrada
La rama se decide con `listOfProductosProgress`, que el buscador sobrescribe (`bloc:2154`). Con un filtro activo que esconde la fila restante cae en el caso 3.1. Debe usar `listOfProductos`.

### 3.3 No se puede deshacer si la fila restante ya se empezó
`findAndAddQuantityAndDelete` exige `is_selected = 0` en la fila restante. Si el operario ya escaneó su ubicación lanza excepción y no hay salida.

### 3.4 UI vs BD desincronizadas al reentrar a una fila restante
`_onFetchProductEvent` (`bloc:1825`) pone `quantitySelected = 0` si `isProductSplit == 1`, pero en BD `quantity_separate` puede valer N. El siguiente escaneo suma sobre N → la pantalla muestra una cantidad y la BD guarda otra.

### 3.5 Sonido de error con escaneo correcto
`sacn_screen.dart:228-244` `validateScannedBarcode`: al sumar cantidad por barcode de empaque, el flujo sigue hasta `playErrorSound()` + `vibrate()` y retorna `false`. Siempre suena error.

### 3.6 Escaneo de producto en cantidad sin tope
`validateQuantity` (`sacn_screen.dart:176`) suma +1 sin comparar contra `quantity`. Escaneos mientras `SetPickingsEvent` está en curso dejan `quantity_separate > quantity`.

### 3.7 `updateConsecutivePackages` borra datos del paquete
`bloc:1000` arma un `Paquete` nuevo sin `packingBarcode`, `typePaquete`, `locationDestId/Name/Barcode`; `updatePackageById` (`package_repository.dart:277`) los escribe en null. Al eliminar una caja, las siguientes pierden barcode y ubicación destino. Usar `paquete.copyWith(consecutivo: ...)`.

### 3.8 Copy-paste en ubicación destino
`bloc:1133`: valida `producto.idLocation is int` y usa `producto.idLocationDest`.

---

## 4. Riesgos y carreras

- **Sin transacción**: la división son ~8 `UPDATE` + 1 `INSERT` sueltos. Si falla a mitad (ej. `DateTime.parse(timeSeparatStart)` con null) la fila queda certificada sin su restante → se pierde cantidad. Igual en `_onSetPickingsEvent`.
- **Eventos concurrentes en `onSplit`**: `ChangeQuantitySeparate`, `SetPickingSplitEvent` y `LoadPedidoAndProductsEvent` sin esperar uno a otro. El `Load` sobra (el bloc ya lo lanza). Si `quantity_separate` se escribe después de `is_certificate=1`, el filtro `IS NULL` no encuentra la fila y la escritura se pierde.
- **`LoadPedidoAndProductsEvent`** se lanza en ~10 sitios sin `restartable()` → cargas que se pisan.
- **Refresco API pisa filas divididas**: `insertProductosPedidos` hace upsert por `idMove` sin filtrar estado → `quantity = total API` en todas las filas del move. `_reconcileProductQuantities` solo corrige si pendiente > 0; si es ≤ 0, la restante queda con el total de la API.
- **`int.parse(loteId.toString())`** (`bloc:1129`): `insertDuplicateProductoPedido` guarda `loteId ?? ''`; si era null, empacar la restante revienta con "Ocurrió un error inesperado".
- **Certificar con cantidad 0**: "Aceptar con novedad" lo permite; `ChangeQuantitySeparate` ignora 0 → se empaca con `cantidadEnviada = 0`.
- **`incremenQtytProductSeparatePacking`**: `currentQty + quantity` sin null-check si `quantity_separate` es NULL.
- **`getProductoPedidoPendingById`**: si no hay pendiente cae a "cualquier fila con ese idMove" → puede calcular tiempos sobre una fila certificada.

---

## 5. Deuda técnica

- Bloc de ~2.700 líneas con `TextEditingController`, acceso directo a BD y estado público mutado desde la UI (`packingBloc.quantitySelected = ...`).
- `_onFilterUbicacionesEvent` no está registrado; `on<PackingPedidoEvent>((e, emit) {})` no hace nada.
- Repositorio apunta a filas por combinaciones de `is_certificate` / `is_package` (`setFieldTableProductosPedidos2/3`, `revert*`) en lugar de por PK → raíz de la mayoría de bugs de división.
- `setFieldTableProductosPedidos2String/3String` interpolan el valor en SQL (sin parámetros).

---

## 6. Recomendación

Antes de cambiar el funcionamiento, que la división trabaje por `id` (PK) y en **una sola transacción**:

1. Fila certificada: `quantity = X`, `quantity_separate = X`, flags y tiempos.
2. Insertar fila restante con `quantity = total - X` (y `loteId` sin convertir a `''`).
3. Deshacer = sumar X a la restante por PK (o restaurar la fila si no existe restante) y borrar la certificada por PK.

Esto cierra 3.1, 3.2, 3.4 y el riesgo de escrituras sin transacción.

### Prioridad sugerida

| # | Item | Impacto |
|---|---|---|
| 1 | División/deshacer por PK + transacción (3.1, 3.2, 3.3, 3.4) | Alto — cantidades incorrectas |
| 2 | `updateConsecutivePackages` con `copyWith` (3.7) | Alto — pérdida de datos de paquetes |
| 3 | Tope y sonido en escaneo de cantidad (3.5, 3.6) | Medio — UX / sobre-separación |
| 4 | `onSplit` sin eventos concurrentes + `restartable()` en Load | Medio |
| 5 | Validar cantidad 0 y `loteId` null | Medio |
| 6 | Copy-paste `idUbicacionDestino` (3.8) | Bajo |
