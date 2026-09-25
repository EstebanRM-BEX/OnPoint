# Mapeo de endpoints — App WMS (On Point)

Documento generado a partir del código fuente de la aplicación (rama `desarrollo`).
Cubre **todos los endpoints HTTP que la app invoca hoy**, el módulo que los consume,
la replicación entre módulos, el body enviado con sus tipos de datos y la forma de la
respuesta tal como la parsean los modelos de la app.

---

## 1. Capa de transporte

Toda llamada pasa por `ApiRequestService` (`lib/src/api/api_request_service.dart`),
un singleton inicializado en `lib/main.dart:115` con `unencodePath: '/api'`.

### 1.1 Construcción de la URL

`{base}` = URL de la instancia Odoo, guardada en preferencias (`PrefUtils.getEnterprise()`),
capturada en la pantalla de selección de empresa.

| Método del cliente | Verbo HTTP real | URL resultante |
|---|---|---|
| `post` | POST | `{base}/api/{endpoint}` si `isunecodePath: true`, si no `{base}/{endpoint}` |
| `postPicking` | POST | igual que `post` |
| `postPacking` | POST | **siempre** `{base}/api/{endpoint}` |
| `postPrint` | POST | **siempre** `{base}/{endpoint}` |
| `get` | GET | `{base}/api/{endpoint}` si `isunecodePath: true`, si no `{base}/{endpoint}` |
| `getValidation` | GET | igual que `get` |
| `getInfo` | GET | **siempre** `{base}/api/{endpoint}` |
| `getHistory` | GET | igual que `get` |
| `getInventario` | GET | `{base}/op/api/{endpoint}` si `isunecodePath: true` |
| `postInventario` | **GET** | `{base}/op/api/{endpoint}` — *ver nota 1.4* |
| `postMultipart*` | POST (multipart) | `{base}/api/{endpoint}` |
| `postMultipartImage` | POST (multipart) | `https://apitemperature.360software.com.co/{endpoint}` |
| `searchEnterprice` | POST | `{url_introducida}/web/database/list` |

### 1.2 Autenticación

- El login (`/web/session/authenticate`) devuelve la cabecera `set-cookie`, que se
  persiste completa en preferencias.
- El resto de llamadas envían **solo el fragmento `session_id=...`** extraído de esa
  cookie, en la cabecera `Cookie`.
- Los métodos `get`, `getValidation`, `getInventario` y `postInventario` **abortan
  localmente** (respuesta sintética 404) si el `session_id` está vacío.
- Cabeceras estándar: `Content-Type: application/json` + `Cookie: session_id=...`.

### 1.3 Envoltura de request y response (JSON-RPC de Odoo)

Todos los bodies (salvo multipart) van envueltos en `params`:

```json
{ "params": { "campo": "valor" } }
```

Los métodos `get`, `getInventario` y `postInventario` (sin body propio) envían
`{"params":{}}`. `getValidation` añade siempre identificación de dispositivo:

```json
{ "params": { "device_id": "AA:BB:CC:DD:EE:FF", "version_app": "1.4.2" } }
```

> `device_id` = MAC del PDA; si la MAC es `02:00:00:00:00:00` (Android la enmascara)
> se envía el IMEI en su lugar. `version_app` sale de `PackageInfo`.

`getHistory` envía un único filtro de fecha: `{"params": {"<field>": "<date>"}}`.

**Respuesta exitosa** (todos los endpoints Odoo):

```json
{
  "jsonrpc": "2.0",
  "id": null,
  "result": { "code": 200, "msg": "Ok", "result": [] }
}
```

**Respuesta de error de negocio**: HTTP 200 con `result.code != 200` y `result.msg`
con el texto que se muestra al operario.

**Respuesta de error de sesión**: HTTP 500 con body JSON-RPC
`{"error": {"code": 100, ...}}` → la app lo interpreta como *sesión expirada* y
fuerza re-login.

### 1.4 Notas de implementación relevantes para el backend

1. **`postInventario` emite un `GET` con body**, pese al nombre. Afecta a
   `quant_post`. Lo mismo ocurre con `getInfo` (`quickinfo`, `validar_stock`) y
   `getHistory`: son **GET con cuerpo JSON**.
2. **Timeout**: 100 s en `postPicking`, `postPacking`, `getInventario` y
   `postInventario`. El resto no tiene timeout explícito.
3. **Prefijo `/op/api`**: exclusivo del módulo `inventario` (Clean Architecture).
4. Sin conexión, el cliente sintetiza respuestas locales (404 «Error de red»,
   408 timeout) con body JSON-RPC válido; nunca llegan al backend.

---

## 2. Índice de endpoints por módulo

Ruta completa = `{base}` + la columna «Ruta».

### 2.1 Sesión y dispositivo

| # | Verbo | Ruta | Módulo | Replicado en |
|---|---|---|---|---|
| 1 | POST | `/web/database/list` | Enterprise (selección de instancia) | — |
| 2 | POST | `/web/session/authenticate` | Login | — |
| 3 | GET | `/api/configurations` | User (permisos y config) | — |
| 4 | GET | `/api/ubicaciones` | User | — |
| 5 | GET | `/api/picking_novelties` | User (catálogo de novedades) | — |
| 6 | POST | `/api/pda/register` | User (registro de PDA) | — |
| 7 | GET | `/api/last-version` | Home (control de versión) | — |

### 2.2 Maestros compartidos

| # | Verbo | Ruta | Módulo principal | Replicado en |
|---|---|---|---|---|
| 8 | GET | `/api/lotes/{product_id}` | Inventario | Recepción, Devoluciones, Picking cluster |
| 9 | POST | `/api/create_lote` | Inventario | Recepción, Devoluciones, Picking cluster |
| 10 | GET | `/api/get_imagen_product/{product_id}` | Inventario | Picking cluster, Picking pick (vía caso de uso) |
| 11 | GET | `/api/get_packaging_types` | Packaging types (Packing) | — |
| 12 | GET | `/api/terceros` | Devoluciones | — |
| 13 | GET | `/api/muelles` | Picking batch | Picking pick (scan) |
| 14 | POST | `/api/printer_details` | Printing | — |
| 15 | POST | `/direct-print/print-report` | Printing | — |

### 2.3 Recepción

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 16 | GET | `/api/recepciones` | — |
| 17 | GET | `/api/recepciones/devs` | — |
| 18 | GET | `/api/recepciones/batchs` | — |
| 19 | POST | `/api/asignar_responsable` | — |
| 20 | POST | `/api/asignar_responsable/batch` | — |
| 21 | POST | `/api/send_recepcion` | — |
| 22 | POST | `/api/send_recepcion/batch` | — |
| 23 | POST | `/api/update_recepcion` | — |
| 24 | POST | `/api/complete_recepcion` | — |
| 25 | POST | `/api/complete_recepcion/expire` | — |
| 26 | POST | `/api/update_time_reception` | — |
| 27 | POST | `/api/send_image_linea_recepcion` *(multipart)* | Packing usa la variante `/batch` |
| 28 | POST | `/api/send_imagen_observation` *(multipart)* | Packing usa la variante `/batch` |

### 2.4 Devoluciones

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 29 | POST | `/api/crear_devs` | — |

> Devoluciones reutiliza además `/api/terceros`, `/api/lotes/{id}` y `/api/create_lote`.

### 2.5 Transferencias

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 30 | GET | `/api/transferencias` | — |
| 31 | GET | `/api/transferencias/producto_terminado` | — |
| 32 | GET | `/api/transferencias/{id_picking}` | — |
| 33 | POST | `/api/transferencias/asignar` | **Packing** (mismo body) |
| 34 | POST | `/api/send_transfer` | — |
| 35 | POST | `/api/send_transfer/pick` | Picking pick (scan, vía `TransferenciasRepository`) |
| 36 | POST | `/api/complete_transfer` | **Packing**, Picking pick |
| 37 | POST | `/api/complete_transfer/expire` | **Packing**, Picking pick |
| 38 | POST | `/api/comprobar_disponibilidad` | — |
| 39 | POST | `/api/transferencias/delete_line` | — |
| 40 | POST | `/api/transferencias/create_trasferencia` | — |
| 41 | GET | `/api/validar_stock` *(GET con body)* | — |
| 42 | POST | `/api/update_time_transfer` | **Packing** (pedido y batch), Picking pick |

### 2.6 Picking — batch y componentes

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 43 | GET | `/api/batchs` | — |
| 44 | GET | `/api/batchs/componentes` | — |
| 45 | GET | `/api/batchs_done` *(GET con body de fecha)* | — |
| 46 | GET | `/api/batch/{batch_id}` | — |
| 47 | POST | `/api/send_batch` | — |
| 48 | POST | `/api/send_batch/componentes` | — |
| 49 | POST | `/api/update_dock` | Picking pick (scan) |
| 50 | POST | `/api/start_time_batch_user` | **Packing**, Picking cluster |
| 51 | POST | `/api/end_time_batch_user` | **Packing**, Picking cluster |
| 52 | POST | `/api/update_start_time` | **Packing**, Picking cluster |
| 53 | POST | `/api/update_end_time` | **Packing**, Picking cluster |

### 2.7 Picking — pick (transferencias de salida)

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 54 | GET | `/api/transferencias/pick` | — |
| 55 | GET | `/api/transferencias/history_picking` *(GET con body de fecha)* | — |
| 56 | GET | `/api/picking/componentes` | — |
| 57 | GET | `/api/picking/componentes/history` *(GET con body de fecha)* | — |

> El módulo `lib/features/picking` (Clean Architecture) **no abre conexiones propias**:
> delega en `PickingPickRepository`, `WmsPickingRepository` y `TransferenciasRepository`
> del código legacy. Son pantallas gemelas sobre los mismos endpoints.

### 2.8 Picking — cluster

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 58 | GET | `/api/cluster/picking_batchs` | — |
| 59 | POST | `/api/cluster/send_picking` | — |
| 60 | POST | `/api/cluster/validate_pedido/id` | — |

### 2.9 Packing

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 61 | GET | `/api/batch_packing` | — |
| 62 | GET | `/api/batch_packing_unificado` | — |
| 63 | GET | `/api/transferencias/pack` | — |
| 64 | POST | `/api/send_packing` | — |
| 65 | POST | `/api/send_pack_unified` | — |
| 66 | POST | `/api/send_cluster/pack` | — |
| 67 | POST | `/api/send_transfer/pack` | — |
| 68 | POST | `/api/unpacking` | — |
| 69 | POST | `/api/unpack_unified` | — |
| 70 | POST | `/api/transferencias/unpacking` | — |
| 71 | POST | `/api/cluster/packing/ubicacion` | — |
| 72 | POST | `/api/send_image_linea_recepcion/batch` *(multipart)* | Variante batch del #27 |
| 73 | POST | `/api/send_imagen_observation/batch` *(multipart)* | Variante batch del #28 |

> Packing reutiliza además `/api/transferencias/asignar`, `/api/complete_transfer`,
> `/api/complete_transfer/expire`, `/api/update_time_transfer` y los cuatro endpoints
> de tiempo de picking (#50–#53).

### 2.10 Expedición

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 74 | GET | `/api/transferencias/out` | — |
| 75 | POST | `/api/send_out` | — |
| 76 | POST | `/api/out_return` | — |
| 77 | POST | `/api/complete_out` | — |

### 2.11 Conteo (inventario cíclico)

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 78 | GET | `/api/inventory/all_orders` | — |
| 79 | POST | `/api/inventory/send_inventory` | — |
| 80 | POST | `/api/inventory/delete_line` | — |
| 81 | POST | `/api/inventory/remove_line` | — |

### 2.12 Inventario (módulo Clean Architecture, prefijo `/op/api`)

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 82 | GET | `/op/api/product_quants` | — |
| 83 | GET | `/op/api/quant_post` *(GET con body)* | — |

> Inventario reutiliza además `/api/lotes/{id}`, `/api/create_lote` y
> `/api/get_imagen_product/{id}` (prefijo `/api`, no `/op/api`).

### 2.13 Info rápida

| # | Verbo | Ruta | Replicado en |
|---|---|---|---|
| 84 | GET | `/api/transferencias/quickinfo` *(GET con body)* | — |
| 85 | GET | `/api/transferencias/quickinfo/id` *(GET con body)* | — |
| 86 | POST | `/api/crear_transferencia` | — |
| 87 | POST | `/api/update_product` | — |
| 88 | POST | `/api/update_location` | — |

---

## 3. Detalle de bodies

Tipos expresados como Dart → JSON. `dynamic` indica que la app acepta `int`, `double`
o `String` según el origen del dato (con coerción a número donde el backend hace
`float()`).

### 3.1 Sesión y dispositivo

#### `POST /web/database/list`
Sin autenticación. Devuelve la lista de bases de datos de la instancia.

```json
{ "params": {} }
```

#### `POST /web/session/authenticate`

| Campo | Tipo Dart | Tipo JSON | Obligatorio |
|---|---|---|---|
| `login` | `String` | string | sí |
| `password` | `String` | string | sí |
| `db` | `String` | string | sí |

```json
{ "params": { "login": "operario1", "password": "••••••", "db": "onpoint_prod" } }
```

**Respuesta**: objeto de sesión de Odoo (`result` con `uid`, `name`, `username`,
`company_id`, …) + cabecera `set-cookie` con `session_id`. Un `error` en la respuesta
se traduce a mensaje de credenciales inválidas.

#### `GET /api/configurations`
Body `{"params":{}}`. **Respuesta**: `result.code` + `result.result` con la
configuración del usuario. Si `code != 200` la app bloquea el acceso con el `msg`
devuelto («No tienes permisos para acceder a la aplicación»).

#### `GET /api/ubicaciones`
Body `{"params":{}}`. **Respuesta**: `result.result` = array de ubicaciones.

#### `GET /api/picking_novelties`
Body `{"params":{}}`. **Respuesta**: `result.result` = array de novedades.

#### `POST /api/pda/register`

| Campo | Tipo Dart | Tipo JSON | Obligatorio |
|---|---|---|---|
| `device_id` | `String` | string | sí |
| `device_name` | `String` | string | sí |
| `device_model` | `String` | string | sí |
| `version_app` | `String` | string | sí |

```json
{ "params": { "device_id": "AA:BB:CC:DD:EE:FF", "device_name": "TC21-01",
              "device_model": "Zebra TC21", "version_app": "1.4.2" } }
```

**Respuesta**: `result.code == 200` + `result.data` con el registro del dispositivo.

#### `GET /api/last-version`
Body `{"params":{}}`. **Respuesta**: versión mínima requerida y URL de descarga.
`error.code == 100` → sesión expirada.

---

### 3.2 Maestros compartidos

#### `GET /api/lotes/{product_id}`
`product_id` en la ruta (`int`). Body `{"params":{}}`.
**Respuesta**: `result.result` = array de lotes (`id`, `name`, `expiration_date`, …).

*Consumido por*: Inventario, Recepción, Devoluciones, Picking cluster.

#### `POST /api/create_lote`

| Campo | Tipo Dart | Tipo JSON | Obligatorio |
|---|---|---|---|
| `id_producto` | `int` | number | sí |
| `nombre_lote` | `String` | string | sí |
| `fecha_vencimiento` | `String` (`yyyy-MM-dd`) | string | sí (`""` si no aplica) |
| `priority_expiration` | `bool` | boolean | sí |

```json
{ "params": { "id_producto": 4821, "nombre_lote": "L-2026-08-14",
              "fecha_vencimiento": "2027-02-01", "priority_expiration": true } }
```

> **Variación**: Picking cluster envía este endpoint **sin** `priority_expiration`
> y omite `fecha_vencimiento` cuando es nula.

**Respuesta**: `result.result` = array con el lote creado.

#### `GET /api/get_imagen_product/{product_id}`
Body `{"params":{}}`.
**Respuesta**: `result.result.url` = `String` con la URL de la imagen. La imagen se
descarga después con `GET {url}` enviando la cookie de sesión y
`Accept: image/png, image/jpeg, image/*;q=0.8`; si el servidor responde `text/html`
la app lo trata como fallo de autenticación.

#### `GET /api/get_packaging_types`
Body `{"params":{}}`. **Respuesta**: `result.result` = array de tipos de empaque.

#### `GET /api/terceros`
Body `{"params":{}}`. **Respuesta**: `result.result` = array de proveedores/terceros.

#### `GET /api/muelles`
Body `{"params":{}}`. **Respuesta**: `result.result` = array de muelles.

#### `POST /api/printer_details`
Body `{}` (sin envoltura `params`).
**Respuesta**: `result.result` = array de impresoras.

#### `POST /direct-print/print-report`
Único endpoint que envía el sobre JSON-RPC completo desde la app.

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `jsonrpc` | `String` | `"2.0"` |
| `method` | `String` | `"call"` |
| `params.action.type` | `String` | `"ir.actions.report"` |
| `params.action.nameEE` | `String` | string |
| `params.action.report_name` | `String` | string |
| `params.action.context.active_model` | `String` | string |
| `params.action.context.active_ids` | `List<int>` | array de number |
| `params.action.context.active_id` | `int` | number |
| `params.action.context.allowed_company_ids` | `List<int>` | array de number |
| `params.action.context.printer_id` | `int` | number |
| `params.options` | `Map` | `{}` |

---

### 3.3 Recepción

#### `GET /api/recepciones` · `GET /api/recepciones/devs` · `GET /api/recepciones/batchs`
Body de `getValidation`: `{"params": {"device_id": String, "version_app": String}}`.
**Respuesta**: `result.result` = array de recepciones / devoluciones / batches.

#### `POST /api/asignar_responsable`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_recepcion` | `int` | number |
| `id_responsable` | `int` | number |

#### `POST /api/asignar_responsable/batch`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_batch` | `int` | number |
| `id_responsable` | `int` | number |

#### `POST /api/send_recepcion`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_recepcion` | `int` | number |
| `list_items` | `List<ListItem>` | array de objeto |

`list_items[]`:

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| `id_producto` | `int` | number | |
| `id_move` | `int` | number | |
| `lote_producto` | `int` | number | |
| `ubicacion_destino` | `int` | number | |
| `cantidad_separada` | `dynamic` → `num` | number | coaccionado a número; nunca `null` |
| `id_operario` | `int` | number | |
| `fecha_transaccion` | `String` | string | |
| `observacion` | `String` | string | |
| `time_line` | `int` | number | segundos |
| `quantity_segunda_unidad` | `double` | number | por defecto `0.0` |

```json
{
  "params": {
    "id_recepcion": 1032,
    "list_items": [
      { "id_producto": 4821, "id_move": 99213, "lote_producto": 771,
        "ubicacion_destino": 18, "cantidad_separada": 12,
        "id_operario": 7, "fecha_transaccion": "2026-08-14 09:31:02",
        "observacion": "Sin novedad", "time_line": 34,
        "quantity_segunda_unidad": 0.0 }
    ]
  }
}
```

#### `POST /api/send_recepcion/batch`
Idéntico al anterior salvo que la clave del documento es `id_batch` (`int`).

#### `POST /api/update_recepcion`
Borrado de línea en Odoo.

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_recepcion` | `int` | number |
| `list_items` | `List<Map>` | array de objeto (mismo formato que `send_recepcion`) |

#### `POST /api/complete_recepcion`

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| `id_recepcion` | `int` | number | |
| `crear_backorder` | `bool` | boolean | |
| `forzar_lote_vencido` | `bool` | boolean | **solo se envía si es `true`** |

#### `POST /api/complete_recepcion/expire`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_recepcion` | `int` | number |
| `crear_backorder` | `bool` | boolean |
| `confirmar_caducados` | `bool` | boolean (siempre `true`) |

#### `POST /api/update_time_reception`

| Campo | Tipo Dart | Tipo JSON | Valores |
|---|---|---|---|
| `reception_id` | `int` | number | |
| `time` | `String` | string | `yyyy-MM-dd HH:mm:ss` |
| `field_name` | `String` | string | `start_time_reception` \| `end_time_reception` |

#### `POST /api/send_image_linea_recepcion` *(multipart/form-data)*

| Parte | Tipo | Contenido |
|---|---|---|
| `image_data` | file | JPEG o PNG (opcional: la variante «manual» no envía archivo) |
| `move_line_id` | field (string) | id de la línea |
| `temperatura` | field (string) | temperatura leída |

> La variante manual (`postMultipartManual`) envía los mismos campos **sin** el archivo.
> Cabecera `Cookie` con la cookie completa (no solo `session_id`).

#### `POST /api/send_imagen_observation` *(multipart/form-data)*

| Parte | Tipo | Contenido |
|---|---|---|
| `image_data` | file | JPEG o PNG |
| `id_move` | field (string) | id del movimiento |

---

### 3.4 Devoluciones

#### `POST /api/crear_devs`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `device_id` | `String` | string |
| `id_almacen` | `int` | number |
| `id_proveedor` | `int` | number |
| `id_ubicacion_destino` | `int` | number |
| `id_responsable` | `int` | number |
| `fecha_inicio` | `String` | string |
| `fecha_fin` | `String` | string |
| `id_propietario` | `int` | number |
| `list_items` | `List<ProductRequest>` | array de objeto |

`list_items[]`:

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_producto` | `int` | number |
| `id_lote` | `dynamic` | number \| string |
| `ubicacion_destino` | `int` | number |
| `cantidad_enviada` | `dynamic` | number |
| `id_operario` | `int` | number |
| `time_line` | `int` | number |
| `fecha_transaccion` | `String` | string |
| `observacion` | `String` | string |
| `quantity_segunda_unidad` | `double` | number |

---

### 3.5 Transferencias

#### `GET /api/transferencias` · `GET /api/transferencias/producto_terminado`
Body de `getValidation` (`device_id` + `version_app`).

#### `GET /api/transferencias/{id_picking}`
`id_picking` en la ruta (`int`). Body `{"params":{}}`.

#### `POST /api/transferencias/asignar`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_transferencia` | `int` | number |
| `id_responsable` | `int` | number |

*Replicado en*: Packing (`assignUserToTransfer`, body idéntico).

#### `POST /api/send_transfer` y `POST /api/send_transfer/pick`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_transferencia` | `int` | number |
| `list_items` | `List<ListItem>` | array de objeto |

`list_items[]`:

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| `id_move` | `int` | number | |
| `id_producto` | `int` | number | |
| `id_lote` | `int` | number | |
| `id_ubicacion_origen` | `int?` | number \| null | puede ir nulo |
| `id_ubicacion_destino` | `int` | number | |
| `cantidad_enviada` | `dynamic` → `num` | number | coaccionado; nunca `null` |
| `id_operario` | `int` | number | |
| `time_line` | `dynamic` | number | |
| `fecha_transaccion` | `String` | string | |
| `observacion` | `String` | string | |
| `dividida` | `bool` | boolean | |
| `quantity_segunda_unidad` | `double` | number | |

#### `POST /api/complete_transfer` y `POST /api/complete_transfer/expire`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_transferencia` | `int` | number |
| `crear_backorder` | `bool` | boolean |

*Replicado en*: Packing (pedido) y Picking pick (validación de confirmación).

#### `POST /api/comprobar_disponibilidad`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_transferencia` | `int` | number |

#### `POST /api/transferencias/delete_line`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_linea` | `int` | number |

#### `POST /api/transferencias/create_trasferencia`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `date_start` | `String` | string |
| `date_end` | `String` | string |
| `id_almacen` | `int` | number |
| `id_ubicacion_origen` | `int` | number |
| `id_ubicacion_destino` | `int` | number |
| `id_operario` | `int` | number |
| `fecha_transaccion` | `String` | string |
| `list_items` | `List<ListItem>` | array de objeto |

`list_items[]`: `id_producto` (`int`), `cantidad_enviada` (`double`), `id_lote` (`int`),
`time_line` (`int`), `id_propietario` (`int`), `quantity_segunda_unidad` (`double`).

#### `GET /api/validar_stock` *(GET con body)*

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_producto` | `int` | number |
| `id_ubicacion` | `int` | number |
| `id_lote` | `int` | number |
| `cantidad_requerida` | `dynamic` | number |

#### `POST /api/update_time_transfer`

| Campo | Tipo Dart | Tipo JSON | Valores |
|---|---|---|---|
| `transfer_id` | `int` | number | |
| `time` | `String` | string | `yyyy-MM-dd HH:mm:ss` |
| `field_name` | `String` | string | `start_time_transfer` \| `end_time_transfer` |

*Replicado en*: Packing (pedido y batch) y Picking pick.

---

### 3.6 Picking — batch y componentes

#### `GET /api/batchs` · `GET /api/batchs/componentes`
Body de `getValidation` (`device_id` + `version_app`).

#### `GET /api/batchs_done` *(GET con body)*

```json
{ "params": { "fecha_batch": "2026-08-14" } }
```

#### `GET /api/batch/{batch_id}`
`batch_id` en la ruta (`int`). Body `{"params":{}}`.

#### `POST /api/send_batch` y `POST /api/send_batch/componentes`
La app elige la ruta según `tipoPicking == 'batch'`.

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_batch` | `int` | number |
| `time_total` | `double` | number |
| `cant_items_separados` | `int` | number |
| `list_item` | `List<Item>` | array de objeto |

`list_item[]`:

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_move` | `int` | number |
| `product_id` | `int` | number |
| `lote` | `String` | string |
| `cantidad` | `dynamic` | number |
| `novedad` | `String` | string |
| `time_line` | `double` | number |
| `muelle` | `int` | number |
| `id_operario` | `int` | number |
| `fecha_transaccion` | `String` | string |

#### `POST /api/update_dock`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `muelle_id` | `int` | number |
| `is_full` | `bool` | boolean |

#### `POST /api/start_time_batch_user` y `POST /api/end_time_batch_user`
Tiempo por **usuario**.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| `id_batch` | `String` | string | id numérico serializado como string |
| `user_id` | `String` | string | id numérico serializado como string |
| *(campo dinámico)* | `String` | string | clave = `start_time` o `end_time`; valor = fecha |
| `operation_type` | `String` | string | `"picking"` o `"packing"` |

```json
{ "params": { "id_batch": "412", "user_id": "7",
              "start_time": "2026-08-14 09:00:00", "operation_type": "picking" } }
```

#### `POST /api/update_start_time` y `POST /api/update_end_time`
Tiempo por **batch**.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| `picking_id` | `String` | string | id numérico serializado como string |
| *(campo dinámico)* | `String` | string | clave = `start_time` o `end_time`; valor = fecha |
| `field_name` | `String` | string | `start_time_pick`, `end_time_pick`, `start_time_pack`, `end_time_pack` |

*Replicado en*: Packing (`operation_type: "packing"`, `field_name` `*_pack`) y
Picking cluster (mismos endpoints vía casos de uso).

---

### 3.7 Picking — pick

#### `GET /api/transferencias/pick` · `GET /api/picking/componentes`
Body de `getValidation` (`device_id` + `version_app`).

#### `GET /api/transferencias/history_picking` · `GET /api/picking/componentes/history`
*(GET con body)*

```json
{ "params": { "fecha_picking": "2026-08-14" } }
```

---

### 3.8 Picking — cluster

#### `GET /api/cluster/picking_batchs`
Body `{"params":{}}`. **Respuesta**: `result.result` = array de batches de cluster.

#### `POST /api/cluster/send_picking`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_batch` | `int` | number |
| `list_item` | `List<Map>` | array de objeto (siempre 1 elemento) |

`list_item[]`:

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| `id_move` | `int` | number | |
| `product_id` | `int` | number | |
| `id_lote` | `int` | number | |
| `cantidad_separada` | `double` | number | topada a la cantidad solicitada si hay exceso |
| `observacion` | `String` | string | `"Sin novedad"` por defecto |
| `time_line` | `double` | number | `10.0` por defecto |
| `id_operario` | `int` | number | |
| `fecha_transaccion` | `String` | string | |

#### `POST /api/cluster/validate_pedido/id`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_pedido` | `int` | number |
| `id_location` | `int` | number |
| `list_items` | `List<Map>` | array de `{"id": int}` |

```json
{ "params": { "id_pedido": 5521, "id_location": 18,
              "list_items": [{"id": 99213}, {"id": 99214}] } }
```

---

### 3.9 Packing

#### `GET /api/batch_packing` · `GET /api/batch_packing_unificado` · `GET /api/transferencias/pack`
Body de `getValidation` (`device_id` + `version_app`).

#### `POST /api/send_packing`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_batch` | `int` | number |
| `is_sticker` | `bool` | boolean |
| `is_certificate` | `bool` | boolean |
| `tipo_paquete` | `String` | string |
| `peso_caja` | `dynamic` | number |
| `peso_total_paquete` | `dynamic` | number |
| `list_item` | `List<ListItem>` | array de objeto |

`list_item[]`:

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_move` | `int` | number |
| `product_id` | `int` | number |
| `lote` | `String` | string |
| `location_id` | `int` | number |
| `cantidad_separada` | `dynamic` | number |
| `observacion` | `String` | string |
| `unidad_medida` | `String` | string |
| `id_operario` | `int` | number |
| `fecha_transaccion` | `String` | string |
| `time_line` | `dynamic` | number |
| `dividir` | `bool` | boolean |

#### `POST /api/send_pack_unified`
Igual que `send_packing` pero **sin** `tipo_paquete` ni `peso_caja`.

#### `POST /api/send_cluster/pack` y `POST /api/send_transfer/pack`
La app elige la ruta según si el pedido es de cluster (`isCluster`).

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_transferencia` | `int` | number |
| `is_sticker` | `bool` | boolean |
| `is_certificate` | `bool` | boolean |
| `tipo_paquete` | `String` | string |
| `peso_caja` | `dynamic` | number |
| `peso_total_paquete` | `dynamic` | number |
| `list_items` | `List<ListItemPack>` | array de objeto |

`list_items[]`: `id_move` (`int`), `id_producto` (`int`), `cantidad_enviada` (`dynamic`),
`id_ubicacion_origen` (`int`), `id_ubicacion_destino` (`int`), `id_lote` (`int`),
`id_operario` (`int`), `fecha_transaccion` (`String`), `time_line` (`dynamic`),
`observacion` (`String`).

#### `POST /api/unpacking` y `POST /api/unpack_unified`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_batch` | `int` | number |
| `id_paquete` | `int` | number |
| `list_item` | `List<ListItemUnpack>` | array de objeto |

`list_item[]`: `id_move` (`int`), `product_id` (`int`), `lote` (`dynamic`),
`location_id` (`int`), `cantidad_separada` (`dynamic`), `observacion` (`String`),
`id_operario` (`int`).

#### `POST /api/transferencias/unpacking`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_transferencia` | `int` | number |
| `id_paquete` | `int` | number |
| `list_items` | `List<ListItemUnpack>` | array de `{"id_move": int, "observacion": String, "id_operario": int}` |

#### `POST /api/cluster/packing/ubicacion`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `movimientos` | `List<MovimientoPack>` | array de objeto |

`movimientos[]`: `id_transferencia` (`int`), `id_paquete` (`int`),
`id_ubicacion_destino` (`int`).

```json
{ "params": { "movimientos": [
    { "id_transferencia": 5521, "id_paquete": 88, "id_ubicacion_destino": 18 } ] } }
```

#### `POST /api/send_image_linea_recepcion/batch` y `POST /api/send_imagen_observation/batch`
*(multipart/form-data)* — mismas partes que sus equivalentes de Recepción (#27, #28),
salvo que la observación usa el campo `move_line_id` en lugar de `id_move`.

---

### 3.10 Expedición

#### `GET /api/transferencias/out`
Body de `getValidation` (`device_id` + `version_app`).
**Respuesta**: `code` + `msg` + listado de expediciones.

#### `POST /api/send_out` y `POST /api/out_return`
Mismo body: validar y deshacer paquete o ítem suelto.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| `device_id` | `String` | string | MAC o IMEI |
| `expedition_id` | `int` | number | |
| `packing_id` | `List<int>` | array de number | 1 elemento en validación individual; N en múltiple |

```json
{ "params": { "device_id": "AA:BB:CC:DD:EE:FF", "expedition_id": 771,
              "packing_id": [88, 89, 90] } }
```

> Estos dos endpoints se llaman con el snackbar de red desactivado: si no hay
> conexión, la app valida en local y encola el envío.

#### `POST /api/complete_out`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_transferencia` | `int` | number |
| `crear_backorder` | `bool` | boolean |

> El `msg` de la respuesta se propaga literal: si contiene
> `expiry.picking.confirmation` la UI ofrece reintentar forzando productos vencidos.

---

### 3.11 Conteo

#### `GET /api/inventory/all_orders`
Body de `getValidation` (`device_id` + `version_app`).

#### `POST /api/inventory/send_inventory`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `order_id` | `int` | number (`0` si es nulo) |
| `list_items` | `List<Map>` | array de objeto (siempre 1 elemento) |

`list_items[]`:

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| `line_id` | `String` | string | id serializado como string |
| `quantity_counted` | `dynamic` | number | |
| `observation` | `String` | string | actualmente se envía siempre `""` |
| `time_line` | `dynamic` | number | |
| `fecha_transaccion` | `String` | string | |
| `id_operario` | `int` | number | |
| `product_id` | `int` | number | |
| `location_id` | `dynamic` | number \| `""` | `""` cuando el id es `0` |
| `lote_id` | `dynamic` | number \| `""` | `""` cuando es nulo |

#### `POST /api/inventory/delete_line` y `POST /api/inventory/remove_line`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `line_id` | `int` | number |

---

### 3.12 Inventario (`/op/api`)

#### `GET /op/api/product_quants`
Body `{"params":{}}`. Respuesta grande: se parsea en un isolate.
**Respuesta**: productos + códigos de barras para sincronización local.

#### `GET /op/api/quant_post` *(GET con body)*

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `location_id` | `dynamic` | number |
| `product_id` | `dynamic` | number |
| `lot_id` | `dynamic` | number \| null |
| `quantity` | `dynamic` | number |
| `user_id` | `int` | number |

---

### 3.13 Info rápida

#### `GET /api/transferencias/quickinfo` *(GET con body)*

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `device_id` | `String` | string |
| `barcode` | `String` | string |
| `version_app` | `String` | string |

#### `GET /api/transferencias/quickinfo/id` *(GET con body)*
El body cambia según lo que se consulte:

```json
{ "params": { "device_id": "…", "id_product": 4821, "version_app": "1.4.2" } }
```
```json
{ "params": { "device_id": "…", "id_location": 18, "version_app": "1.4.2" } }
```

#### `POST /api/crear_transferencia`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `id_almacen` | `int` | number |
| `id_move` | `int` | number |
| `id_producto` | `int` | number |
| `id_propietario` | `int` | number |
| `id_lote` | `int` | number |
| `id_ubicacion_origen` | `int` | number |
| `id_ubicacion_destino` | `int` | number |
| `cantidad_enviada` | `dynamic` | number |
| `id_operario` | `int` | number |
| `time_line` | `dynamic` | number |
| `fecha_transaccion` | `String` | string |
| `observacion` | `String` | string |
| `date_start` | `String` | string |
| `date_end` | `String` | string |

#### `POST /api/update_product`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `product_id` | `int` | number |
| `default_code` | `String` | string |
| `name` | `String` | string |
| `barcode` | `String` | string |
| `list_price` | `double` | number |
| `weight` | `double` | number |
| `volume` | `double` | number |

#### `POST /api/update_location`

| Campo | Tipo Dart | Tipo JSON |
|---|---|---|
| `location_id` | `int` | number |
| `name` | `String` | string |
| `barcode` | `String` | string |

---

## 4. Matriz de replicación

Endpoints consumidos desde más de un módulo:

| Ruta | Módulos que lo consumen |
|---|---|
| `/api/lotes/{product_id}` | Inventario · Recepción · Devoluciones · Picking cluster |
| `/api/create_lote` | Inventario · Recepción · Devoluciones · Picking cluster |
| `/api/get_imagen_product/{product_id}` | Inventario · Picking cluster · Picking pick |
| `/api/muelles` | Picking batch · Picking pick |
| `/api/transferencias/asignar` | Transferencias · Packing |
| `/api/complete_transfer` | Transferencias · Packing · Picking pick |
| `/api/complete_transfer/expire` | Transferencias · Packing · Picking pick |
| `/api/update_time_transfer` | Transferencias · Packing (pedido y batch) · Picking pick |
| `/api/send_transfer/pick` | Transferencias · Picking pick |
| `/api/update_dock` | Picking batch · Picking pick |
| `/api/start_time_batch_user` | Picking batch · Picking cluster · Packing |
| `/api/end_time_batch_user` | Picking batch · Picking cluster · Packing |
| `/api/update_start_time` | Picking batch · Picking cluster · Packing |
| `/api/update_end_time` | Picking batch · Picking cluster · Packing |
| `/api/send_image_linea_recepcion` ↔ `/batch` | Recepción individual ↔ Packing / Recepción batch |
| `/api/send_imagen_observation` ↔ `/batch` | Recepción individual ↔ Packing / Recepción batch |

**Nota de arquitectura**: el módulo `lib/features/picking` (Clean Architecture) y las
pantallas legacy de `lib/src/presentation/views/wms_picking` son *pantallas gemelas*
sobre los mismos repositorios. No duplican endpoints: la versión nueva delega en los
repositorios legacy.

---

## 5. Anexo — servicios que no son el backend Odoo

| Servicio | URL | Uso |
|---|---|---|
| Lectura de temperatura por imagen | `POST https://apitemperature.360software.com.co/extract-temp-humidity` | Recepción y Packing. Multipart con la parte `image` (JPEG/PNG). Sin cookie de sesión; cabecera `Accept: application/json`. |
| WebSocket de notificaciones | `wss://{base}/websocket` | Notificaciones en tiempo real. Deriva de la URL de la instancia sustituyendo `https://` por `wss://`. |

---

## 6. Códigos de estado y errores

| Situación | Cómo llega | Cómo la interpreta la app |
|---|---|---|
| Éxito | HTTP 200 · `result.code == 200` | Continúa el flujo |
| Rechazo de negocio | HTTP 200 · `result.code != 200` · `result.msg` | Muestra `msg` al operario |
| Sesión expirada | HTTP 500 · `error.code == 100` | Cierra sesión y fuerza re-login |
| Error de Odoo | HTTP 500 · `error.message` | Muestra el mensaje |
| Sin conexión | Respuesta sintética local 404 «Error de red» | Snackbar de red (salvo expedición, que encola) |
| Timeout | Respuesta sintética local 408 | Mensaje de tiempo de espera agotado |
| Ruta inexistente | HTTP 404 real | Mensaje indicando revisar el backend |

---

## 7. Respuestas por endpoint (modelos Dart)

Cada bloque muestra las clases Dart que parsean la respuesta. El comentario junto a
cada campo es la clave JSON que llega del backend. La envoltura JSON-RPC es común:

```dart
class Envelope {
  String? jsonrpc;   // "jsonrpc"  siempre "2.0"
  dynamic id;        // "id"       siempre null
  Result? result;    // "result"
}
```

### 7.1 Sesión y dispositivo

#### 1 · `POST /web/database/list`

```dart
class EnterpriseModel {
  List<String> databases;   // "result"  ej. ["onpoint_prod", "onpoint_test"]
}
```

#### 2 · `POST /web/session/authenticate`

```dart
class UserModel {
  int uid;                // result.uid
  String name;            // result.name
  String username;        // result.username
  String? db;             // result.db
  String? serverVersion;  // result.server_version
  String? webBaseUrl;     // result["web.base.url"]
}
// Además: cabecera set-cookie con el session_id que usa el resto de la app.
// Si llega un objeto "error", la app lo traduce a credenciales inválidas.
```

#### 3 · `GET /api/configurations`

```dart
class UserConfigurationModel {
  UserConfigurationResultModel? result;   // "result"
}
class UserConfigurationResultModel {
  int? code;                 // "code"    debe ser 200 o la app bloquea el acceso
  String? msg;               // "msg"     motivo del bloqueo
  UserProfileModel? result;  // "result"  ver §7 · UserProfileModel (50+ banderas)
}
```

#### 4 · `GET /api/ubicaciones`

```dart
// result.result -> List<UserLocationModel>
class UserLocationModel {
  int? id;                // "id"
  String? name;           // "name"
  int? idWarehouse;       // "warehouse_id"[0], o "id_warehouse" si no es lista
  String? barcode;        // "barcode"
  int? locationId;        // "location_id"
  String? locationName;   // "location_name"
  String? warehouseName;  // "warehouse_name"
  bool? isADockAlter;     // "is_a_dock_alter"
}
```

#### 5 · `GET /api/picking_novelties`

```dart
// result.result -> List<UserNoveltyModel>
class UserNoveltyModel {
  int id;       // "id"
  String name;  // "name"
  String code;  // "code"
}
```

#### 6 · `POST /api/pda/register`

```dart
// result.data -> DeviceRegistrationModel
class DeviceRegistrationModel {
  String deviceId;         // "device_id"
  String deviceName;       // "device_name"
  dynamic isAuthorized;    // "is_authorized"
  bool isActive;           // "is_active"
  int totalConnections;    // "total_connections"
  int monthlyConnections;  // "monthly_connections"
  String deviceModel;      // "device_model"
  String versionApp;       // "version_app"
  bool needsAuthorization; // "needs_authorization"
}
```

#### 7 · `GET /api/last-version`

```dart
class AppVersionModel {
  String? jsonrpc;                // "jsonrpc"
  dynamic id;                     // "id"
  String message;                 // "message"
  AppVersionResultModel? result;  // "result"
}
class AppVersionResultModel {
  int? code;                  // "code"
  VersionResultModel? result; // "result"
}
class VersionResultModel {
  int? id;                // "id"
  String? version;        // "version"
  DateTime? releaseDate;  // "release_date"
  List<String>? notes;    // "notes"
  String? urlDownload;    // "url_download"
}
// error.code == 100 -> SessionExpiredException
```

### 7.2 Maestros compartidos

#### 8 · `GET /api/lotes/{product_id}`

```dart
// result.result -> List<LotesProduct>
class LotesProduct {
  int? id;                  // "id"
  String? name;             // "name"
  dynamic quantity;         // "quantity"
  dynamic expirationDate;   // "expiration_date"
  int? productId;           // "product_id"
  String? productName;      // "product_name"
}
```

#### 9 · `POST /api/create_lote`

```dart
class ResponseNewLote {
  String? jsonrpc;
  dynamic id;
  ResponseNewLoteResult? result;
}
class ResponseNewLoteResult {
  int? code;             // "code"
  String? msg;           // "msg"
  LotesProduct? result;  // "result"  el lote creado (ver endpoint 8)
}
// Inventario lo parsea como ResultadoCrearLoteModel (code / msg / lote),
// y Picking cluster como LoteProductoResponse -> List<LotesProduct>.
```

#### 10 · `GET /api/get_imagen_product/{product_id}`

```dart
// La respuesta solo transporta la URL; la app descarga la imagen aparte.
class RespuestaImagen {
  int? code;     // result.code   200 si hay imagen
  String? msg;   // result.msg    motivo cuando no la hay
  String? url;   // result.result.url
}
```

#### 11 · `GET /api/get_packaging_types`

```dart
// result.result -> List<PackagingTypeModel>
class PackagingTypeModel {
  int id;                  // "id"
  String name;             // "name"
  String barcode;          // "barcode"
  double maxWeight;        // "max_weight"
  double height;           // "height"
  double width;            // "width"
  double packagingLength;  // "packaging_length"
  String size;             // "tamaño"
  String carrier;          // "transportista"   "none" por defecto
}
```

#### 12 · `GET /api/terceros`

```dart
// result.result -> List<Terceros>
class Terceros {
  int? id;            // "id"
  String? document;   // "document"
  String? sucursal;   // "sucursal"
  dynamic name;       // "name"
  String? almacen;    // "almacen"
}
```

#### 13 · `GET /api/muelles`

```dart
// result.result -> List<Muelles>
class Muelles {
  int? id;               // "id"
  String? name;          // "name"
  String? completeName;  // "complete_name"
  int? locationId;       // "location_id"
  String? barcode;       // "barcode"
}
```

#### 14 · `POST /api/printer_details`

```dart
// result.result -> List<PrinterModel>
class PrinterModel {
  int printerId;                       // "printer_id"
  String printerName;                  // "printer_name"
  String printerType;                  // "printer_type"
  String hostmachine;                  // "hostmachine"
  List<PrinterReport> availableReports; // "available_reports"
}
```

#### 15 · `POST /direct-print/print-report`

```dart
// La app solo comprueba el código de estado HTTP y result.code.
class Envelope { int? code; String? msg; }
```

### 7.3 Recepción

#### 16 · `GET /api/recepciones`

```dart
class Recepcionresponse {
  String? jsonrpc;
  dynamic id;
  RecepcionresponseResult? result;
}
class RecepcionresponseResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  bool? updateVersion;          // "update_version"  fuerza actualizar la app
  List<ResultEntrada>? result;  // "result"  ver §7 · ResultEntrada
}
```

#### 17 · `GET /api/recepciones/devs`

```dart
// Mismo modelo que el endpoint 16.
class Recepcionresponse {
  RecepcionresponseResult? result;   // code / msg / update_version
}                                    // result.result -> List<ResultEntrada>
```

#### 18 · `GET /api/recepciones/batchs`

```dart
class ResponseReceptionBatchs {
  String? jsonrpc;
  dynamic id;
  ResponseReceptionBatchsResult? result;
}
class ResponseReceptionBatchsResult {
  int? code;                     // "code"
  String? msg;                   // "msg"
  bool? updateVersion;           // "update_version"
  List<ReceptionBatch>? result;  // "result"  ver §7 · ReceptionBatch
}
```

#### 19 · `POST /api/asignar_responsable`

```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 20 · `POST /api/asignar_responsable/batch`

```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 21 · `POST /api/send_recepcion`

```dart
class ResponSendRecepcion {
  String? jsonrpc;
  dynamic id;
  ResponSendRecepcionResult? result;
}
class ResponSendRecepcionResult {
  int? code;                   // "code"
  String? msg;                 // "msg"
  List<ResultElement>? result; // "result"
}
class ResultElement {
  int? id;                   // "id"
  String? producto;          // "producto"
  dynamic cantidad;          // "cantidad"
  dynamic lote;              // "lote"
  int? ubicacionDestino;     // "ubicacion_destino"
  String? fechaTransaccion;  // "fecha_transaccion"
  String? dateTransaction;   // "date_transaction"
  String? newObservation;    // "new_observation"
  dynamic time;              // "time"
  dynamic userOperatorId;    // "user_operator_id"
  bool? isDoneItem;          // "is_done_item"
}
```

#### 22 · `POST /api/send_recepcion/batch`

```dart
// Mismo modelo que el endpoint 21 (ResponSendRecepcion).
class ResponSendRecepcionResult {
  int? code;                   // "code"
  String? msg;                 // "msg"
  List<ResultElement>? result; // "result"  líneas procesadas
}
```

#### 23 · `POST /api/update_recepcion`

```dart
class DeletedProduct {
  String? jsonrpc;
  dynamic id;
  DeletedProductResult? result;
}
class DeletedProductResult {
  int? code;                     // "code"
  String? mensaje;               // "msg"
  List<ProductDeleted>? result;  // "result"
}
class ProductDeleted {
  bool? error;         // "error"
  String? mensaje;     // "mensaje"
  String? producto;    // "producto"
  dynamic cantidad;    // "cantidad"
  int? idMove;         // "id_move"
  int? idProducto;     // "id_producto"
  int? idMoveDeleted;  // "id_move_deleted"
}
```

#### 24 · `POST /api/complete_recepcion`

```dart
class ResponseValidate {
  String? jsonrpc;
  dynamic id;
  ResultValidate? result;
}
class ResultValidate {
  int? code;                        // "code"
  String? msg;                      // "msg"
  String? tipoError;                // "tipo_error"
  List<DetalleValidate>? detalles;  // "detalles"
}
class DetalleValidate {
  String? producto;         // "producto"
  String? lote;             // "lote"
  String? fechaVencimiento; // "fecha_vencimiento"
  double? cantidad;         // "cantidad"
}
// tipo_error + detalles alimentan el diálogo de lotes vencidos,
// que reintenta contra complete_recepcion/expire (endpoint 25).
```

#### 25 · `POST /api/complete_recepcion/expire`

```dart
// Mismo modelo que el endpoint 24 (ResponseValidate / ResultValidate).
class ResultValidate {
  int? code;                        // "code"
  String? msg;                      // "msg"
  String? tipoError;                // "tipo_error"
  List<DetalleValidate>? detalles;  // "detalles"
}
```

#### 26 · `POST /api/update_time_reception`

```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 27 · `POST /api/send_image_linea_recepcion`

```dart
class TemperatureSend {
  int? code;            // "code"
  String? msg;          // "msg"
  String? result;       // "result"
  int? lineId;          // "line_id"
  double? temperature;  // "temperature"
  String? filename;     // "filename"
  int? imageSize;       // "image_size"
  String? imageUrl;     // "image_url"
  String? jsonUrl;      // "json_url"
  String? productName;  // "product_name"
}
```

#### 28 · `POST /api/send_imagen_observation`

```dart
class ImageSendNovedad {
  int? code;             // "code"
  String? result;        // "result"
  int? stockMoveId;      // "stock_move_id"
  int? stockMoveLineId;  // "stock_move_line_id"
  String? imageUrl;      // "image_url"
  String? filename;      // "filename"
  String? msg;           // "msg"
}
```

### 7.4 Devoluciones

#### 29 · `POST /api/crear_devs`

```dart
class ResponseDevolucion {
  String? jsonrpc;
  dynamic id;
  ResultDevolucion? result;
}
class ResultDevolucion {
  int? code;                          // "code"
  String? msg;                        // "msg"
  int? devolucionId;                  // "devolucion_id"
  String? nombreDevolucion;           // "nombre_devolucion"
  String? estado;                     // "estado"
  DateTime? fechaCreacion;            // "fecha_creacion"
  int? almacenId;                     // "almacen_id"
  String? almacenNombre;              // "almacen_nombre"
  int? ubicacionDestinoId;            // "ubicacion_destino_id"
  String? ubicacionDestinoNombre;     // "ubicacion_destino_nombre"
  int? responsableId;                 // "responsable_id"
  int? proveedorId;                   // "proveedor_id"
  String? proveedorNombre;            // "proveedor_nombre"
  String? propietarioNombre;          // "propietario_nombre"
  dynamic totalItems;                 // "total_items"
  dynamic totalItemsOriginales;       // "total_items_originales"
  List<ItemsProcesado>? itemsProcesados; // "items_procesados"
}
class ItemsProcesado {
  int? idProducto;                 // "id_producto"
  String? nombreProducto;          // "nombre_producto"
  dynamic cantidadTotal;           // "cantidad_total"
  dynamic cantidadItemsOriginales; // "cantidad_items_originales"
  int? moveId;                     // "move_id"
  dynamic lote;                    // "lote"
  String? loteNombre;              // "lote_nombre"
  String? observacion;             // "observacion"
  String? claveUnica;              // "clave_unica"
  int? moveLineId;                 // "move_line_id"
}
```

### 7.5 Transferencias

#### 30 · `GET /api/transferencias`

```dart
class ResponseTransferencias {
  String? jsonrpc;
  dynamic id;
  ResponseTransferenciasResult? result;
}
class ResponseTransferenciasResult {
  int? code;                            // "code"
  dynamic msg;                          // "msg"
  bool? updateVersion;                  // "update_version"
  List<ResultTransFerencias>? result;   // "result"  ver §7 · ResultTransFerencias
}
```

#### 31 · `GET /api/transferencias/producto_terminado`

```dart
// Mismo modelo que el endpoint 30.
class ResponseTransferenciasResult {
  int? code;                           // "code"
  bool? updateVersion;                 // "update_version"
  List<ResultTransFerencias>? result;  // "result"  ver §7
}
```

#### 32 · `GET /api/transferencias/{id_picking}`

```dart
class RespondePickDoneId {
  String? jsonrpc;
  dynamic id;
  RespondePickDoneIdResult? result;
}
class RespondePickDoneIdResult {
  int? code;             // "code"
  ResultResult? result;  // "result"
}
class ResultResult {
  int? id;                       // "id"
  String? name;                  // "name"
  dynamic fechaCreacion;         // "fecha_creacion"
  int? locationId;               // "location_id"
  String? locationName;          // "location_name"
  String? locationBarcode;       // "location_barcode"
  int? locationDestId;           // "location_dest_id"
  String? locationDestName;      // "location_dest_name"
  String? locationDestBarcode;   // "location_dest_barcode"
  String? proveedor;             // "proveedor"
  String? numeroTransferencia;   // "numero_transferencia"
  dynamic pesoTotal;             // "peso_total"
  dynamic numeroItems;           // "numero_items"
  String? state;                 // "state"
  String? createBackorder;       // "create_backorder"
  String? origin;                // "origin"
  String? priority;              // "priority"
  int? warehouseId;              // "warehouse_id"
  String? warehouseName;         // "warehouse_name"
  int? responsableId;            // "responsable_id"
  String? responsable;           // "responsable"
  String? pickingType;           // "picking_type"
  dynamic startTimeTransfer;     // "start_time_transfer"
  dynamic endTimeTransfer;       // "end_time_transfer"
  int? backorderId;              // "backorder_id"
  String? backorderName;         // "backorder_name"
  bool? showCheckAvailability;   // "show_check_availability"
  String? muelle;                // "muelle"
  int? muelleId;                 // "muelle_id"
  int? idMuellePadre;            // "id_muelle_padre"
  String? barcodeMuelle;         // "barcode_muelle"
  String? zonaEntrega;           // "zona_entrega"
  dynamic quantityDone;          // "quantity_done"
}
```

#### 33 · `POST /api/transferencias/asignar`

```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 34 · `POST /api/send_transfer`

```dart
class ResponseSenTransfer {
  String? jsonrpc;
  dynamic id;
  ResponseSenTransferResult? result;
}
class ResponseSenTransferResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"  líneas procesadas
}
```

#### 35 · `POST /api/send_transfer/pick`

```dart
// Mismo modelo que el endpoint 34 (ResponseSenTransfer).
class ResponseSenTransferResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"
}
```

#### 36 · `POST /api/complete_transfer`

```dart
// Mismo modelo que el endpoint 24 (ResponseValidate).
class ResultValidate {
  int? code;                       // "code"
  String? msg;                     // "msg"
  String? tipoError;               // "tipo_error"
  List<DetalleValidate>? detalles; // "detalles"
}
```

#### 37 · `POST /api/complete_transfer/expire`

```dart
// Mismo modelo que el endpoint 24 (ResponseValidate).
class ResultValidate {
  int? code;                       // "code"
  String? msg;                     // "msg"
  String? tipoError;               // "tipo_error"
  List<DetalleValidate>? detalles; // "detalles"
}
```

#### 38 · `POST /api/comprobar_disponibilidad`

```dart
class CheckAvailabilityResponse {
  String? jsonrpc;
  dynamic id;
  CheckAvailabilityResponseResult? result;
}
class CheckAvailabilityResponseResult {
  int? code;                       // "code"
  String? msg;                     // "msg"
  ResultTransFerencias? result;    // "result"  documento recalculado, ver §7
}
```

#### 39 · `POST /api/transferencias/delete_line`

```dart
class ResponseDeleteLine {
  String? jsonrpc;
  dynamic id;
  ResponseDeleteLineResult? result;
}
class ResponseDeleteLineResult {
  int? code;             // "code"
  String? msg;           // "msg"
  ResultResult? result;  // "result"  la línea eliminada, con producto,
}                        //           ubicaciones y cantidades
```

#### 40 · `POST /api/transferencias/create_trasferencia`

```dart
class RespondeCreateTransfer {
  String? jsonrpc;
  dynamic id;
  Result? result;
}
class Result {
  int? code;                              // "code"
  String? msg;                            // "msg"
  int? transferenciaId;                   // "transferencia_id"
  String? nombreTransferencia;            // "nombre_transferencia"
  int? totalItems;                        // "total_items"
  List<ItemsProcesado>? itemsProcesados;  // "items_procesados"
  List<dynamic>? correccionesRealizadas;  // "correcciones_realizadas"
  dynamic totalCorrecciones;              // "total_correcciones"
  int? ubicacionOrigenId;                 // "ubicacion_origen_id"
  int? ubicacionDestinoId;                // "ubicacion_destino_id"
}
class ItemsProcesado {
  int? lineaId;           // "linea_id"
  int? productoId;        // "producto_id"
  String? productoNombre; // "producto_nombre"
  dynamic cantidad;       // "cantidad"
  int? loteId;            // "lote_id"
  String? observacion;    // "observacion"
}
```

#### 41 · `GET /api/validar_stock`

```dart
class RespondeValidateStock {
  String? jsonrpc;
  dynamic id;
  ResultValidateStock? result;
}
class ResultValidateStock {
  int? code;                                        // "code"
  String? msg;                                      // "msg"
  Consulta? consulta;                               // "consulta"
  ResumenStock? resumenStock;                       // "resumen_stock"
  List<dynamic>? correccionesRealizadas;            // "correcciones_realizadas"
  List<DetalleQuantsEncontrado>? detalleQuantsEncontrados; // "detalle_quants_encontrados"
}
```

#### 42 · `POST /api/update_time_transfer`

```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

### 7.6 Picking — batch y componentes

#### 43 · `GET /api/batchs`

```dart
class BatchModelResponse {
  String? jsonrpc;
  dynamic id;
  DataBatch? result;
}
class DataBatch {
  int? code;                  // "code"
  String? msg;                // "msg"
  bool? updateVersion;        // "update_version"
  List<BatchsModel>? result;  // "result"  ver §7 · BatchsModel
}
```

#### 44 · `GET /api/batchs/componentes`

```dart
// Mismo modelo que el endpoint 43.
class DataBatch {
  int? code;                  // "code"
  String? msg;                // "msg"
  bool? updateVersion;        // "update_version"
  List<BatchsModel>? result;  // "result"  ver §7 · BatchsModel
}
```

#### 45 · `GET /api/batchs_done`

```dart
// result.result -> List<HistoryBatch>
class HistoryBatch {
  int? id;                       // "id"
  String? name;                  // "name"
  String? userName;              // "user_name"
  int? userId;                   // "user_id"
  String? rol;                   // "rol"
  String? orderBy;               // "order_by"
  String? orderPicking;          // "order_picking"
  dynamic scheduleddate;         // "scheduleddate"
  String? state;                 // "state"
  String? pickingTypeId;         // "picking_type_id"
  String? observation;           // "observation"
  bool? isWave;                  // "is_wave"
  String? muelle;                // "muelle"
  dynamic idMuelle;              // "id_muelle"
  int? countItems;               // "count_items"
  dynamic totalQuantityItems;    // "total_quantity_items"
  dynamic itemsSeparado;         // "items_separado"
}
```

#### 46 · `GET /api/batch/{batch_id}`

```dart
class HistorBatchId {
  String? jsonrpc;
  dynamic id;
  HistorBatchIdResult? result;
}
class HistorBatchIdResult {
  int? code;                // "code"
  HistoryBatchId? result;   // "result"
}
class HistoryBatchId {
  int? id;                     // "id"
  String? name;                // "name"
  String? userName;            // "user_name"
  int? userId;                 // "user_id"
  String? rol;                 // "rol"
  String? orderBy;             // "order_by"
  String? orderPicking;        // "order_picking"
  DateTime? scheduleddate;     // "scheduleddate"
  String? state;               // "state"
  String? pickingTypeId;       // "picking_type_id"
  String? observation;         // "observation"
  String? muelle;              // "muelle"
  dynamic idMuelle;            // "id_muelle"
  dynamic countItems;          // "count_items"
  dynamic totalQuantityItems;  // "total_quantity_items"
  dynamic itemsSeparado;       // "items_separado"
  dynamic startTimePick;       // "start_time_pick"
  dynamic endTimePick;         // "end_time_pick"
  String? zonaEntrega;         // "zona_entrega"
  List<ListItem>? listItems;   // "list_items"  líneas del batch
}
```

#### 47 · `POST /api/send_batch`

```dart
class SendPickingResponse {
  String? jsonrpc;
  dynamic id;
  Data? result;
}
class Data {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"
}
class ResultElement {
  String? error;    // "error"      vacío si la línea entró bien
  int? idMove;      // "id_move"
  int? idBatch;     // "id_batch"
  int? idProduct;   // "id_product"
  String? complete; // "complete"
}
```

#### 48 · `POST /api/send_batch/componentes`

```dart
// Mismo modelo que el endpoint 47 (SendPickingResponse).
class Data {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"  una entrada por línea enviada
}
```

#### 49 · `POST /api/update_dock`

```dart
class OcuparMuelle {
  String? jsonrpc;
  dynamic id;
  Result? result;    // "result"  code + msg; la app solo lee code == 200
}
```

#### 50 · `POST /api/start_time_batch_user`

```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 51 · `POST /api/end_time_batch_user`

```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 52 · `POST /api/update_start_time`

```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 53 · `POST /api/update_end_time`

```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

### 7.7 Picking — pick

#### 54 · `GET /api/transferencias/pick`

```dart
class ResponsePick {
  String? jsonrpc;
  dynamic id;
  ResponsePickResult? result;
}
class ResponsePickResult {
  int? code;                // "code"
  String? msg;              // "msg"
  bool? updateVersion;      // "update_version"
  List<ResultPick>? result; // "result"  ver §7 · ResultPick
}
```

#### 55 · `GET /api/transferencias/history_picking`

```dart
// result.result -> List<ResultPick>   (ver §7 · ResultPick)
class ResponsePickResult {
  int? code;                 // "code"
  String? msg;               // "msg"
  List<ResultPick>? result;  // "result"  picks cerrados en la fecha
}
```

#### 56 · `GET /api/picking/componentes`

```dart
// Mismo modelo que el endpoint 54.
class ResponsePickResult {
  int? code;                 // "code"
  String? msg;               // "msg"
  bool? updateVersion;       // "update_version"
  List<ResultPick>? result;  // "result"  ver §7 · ResultPick
}
```

#### 57 · `GET /api/picking/componentes/history`

```dart
// result.result -> List<ResultPick>   (ver §7 · ResultPick)
class ResponsePickResult {
  int? code;                 // "code"
  List<ResultPick>? result;  // "result"  picks de componentes cerrados
}
```

### 7.8 Picking — cluster

#### 58 · `GET /api/cluster/picking_batchs`

```dart
class PickingClusterModel {
  String? jsonrpc;
  dynamic id;
  PickingClusterResult? result;
}
class PickingClusterResult {
  int? code;                        // "code"
  String? msg;                      // "msg"
  List<ResultElementModel>? result; // "result"  ver §7 · ResultElementModel
}
```

#### 59 · `POST /api/cluster/send_picking`

```dart
// El datasource devuelve el cuerpo crudo; el caso de uso lo decodifica.
class Envelope {
  int? code;    // result.code  == 200 -> "Ok"
  String? msg;  // result.msg   motivo del rechazo
}
```

#### 60 · `POST /api/cluster/validate_pedido/id`

```dart
// La app lee result.code == 200; si no, lanza result.msg.
// Un objeto "error" se propaga como error.message.
class Envelope { int? code; String? msg; }
```

### 7.9 Packing

#### 61 · `GET /api/batch_packing`

```dart
class PackingModelResponse {
  String? jsonrpc;
  dynamic id;
  PackingModelResponseResult? result;
}
class PackingModelResponseResult {
  int? code;                        // "code"
  String? msg;                      // "msg"
  bool? updateVersion;              // "update_version"
  List<BatchPackingModel>? result;  // "result"  ver §7 · BatchPackingModel
}
```

#### 62 · `GET /api/batch_packing_unificado`

```dart
// Mismo modelo que el endpoint 61.
class PackingModelResponseResult {
  int? code;                        // "code"
  bool? updateVersion;              // "update_version"
  List<BatchPackingModel>? result;  // "result"  ver §7 · BatchPackingModel
}
```

#### 63 · `GET /api/transferencias/pack`

```dart
class PackingPedido {
  String? jsonrpc;
  dynamic id;
  PackingPedidoResult? result;
}
class PackingPedidoResult {
  int? code;                          // "code"
  String? msg;                        // "msg"
  bool? updateVersion;                // "update_version"
  List<PedidoPackingResult>? result;  // "result"  ver §7 · PedidoPackingResult
}
```

#### 64 · `POST /api/send_packing`

```dart
class ResponseSendPacking {
  String? jsonrpc;
  dynamic id;
  ResponseSendPackingResult? result;
}
class ResponseSendPackingResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"
}
class ResultElement {
  int? idPaquete;                     // "id_paquete"
  String? namePaquete;                // "name_paquete"
  int? idBatch;                       // "id_batch"
  int? cantidadProductosEnElPaquete;  // "cantidad_productos_en_el_paquete"
  bool? isSticker;                    // "is_sticker"
  bool? isCertificate;                // "is_certificate"
  dynamic peso;                       // "peso"
  dynamic consecutivo;                // "consecutivo"
  dynamic tipoPaquete;                // "tipo_paquete"
  dynamic pesoCaja;                   // "peso_caja"
  List<ListItem>? listItem;           // "list_item"  líneas empacadas
}
```

#### 65 · `POST /api/send_pack_unified`

```dart
// Mismo modelo que el endpoint 64 (ResponseSendPacking).
class ResponseSendPackingResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"  paquete creado y sus líneas
}
```

#### 66 · `POST /api/send_cluster/pack`

```dart
class ResponseSendPack {
  String? jsonrpc;
  dynamic id;
  ResponseSendPackResult? result;
}
class ResponseSendPackResult {
  int? code;                        // "code"
  String? msg;                      // "msg"
  List<ResultElementPack>? result;  // "result"
}
class ResultElementPack {
  int? idPaquete;                     // "id_paquete"
  String? namePaquete;                // "name_paquete"
  int? idBatch;                       // "id_batch"
  int? cantidadProductosEnElPaquete;  // "cantidad_productos_en_el_paquete"
  bool? isSticker;                    // "is_sticker"
  bool? isCertificate;                // "is_certificate"
  dynamic peso;                       // "peso"
  dynamic consecutivo;                // "consecutivo"
  String? packingBarcode;             // "packing_barcode"
  List<ListItem>? listItem;           // "list_item"
}
```

#### 67 · `POST /api/send_transfer/pack`

```dart
// Mismo modelo que el endpoint 66 (ResponseSendPack).
class ResponseSendPackResult {
  int? code;                        // "code"
  String? msg;                      // "msg"
  List<ResultElementPack>? result;  // "result"  paquete creado
}
```

#### 68 · `POST /api/unpacking`

```dart
class UnPacking {
  String? jsonrpc;
  dynamic id;
  UnPackingResult? result;
}
class UnPackingResult {
  int? code;                       // "code"
  String? msg;                     // "msg"
  List<UnPackingElement>? result;  // "result"
}
class UnPackingElement {
  int? idPaquete;                     // "id_paquete"
  String? namePaquete;                // "name_paquete"
  int? idBatch;                       // "id_batch"
  int? cantidadProductosEnElPaquete;  // "cantidad_productos_en_el_paquete"
  List<ListItemUnPacking>? listItem;  // "list_item"  líneas devueltas
}
```

#### 69 · `POST /api/unpack_unified`

```dart
// Mismo modelo que el endpoint 68 (UnPacking).
class UnPackingResult {
  int? code;                       // "code"
  String? msg;                     // "msg"
  List<UnPackingElement>? result;  // "result"
}
```

#### 70 · `POST /api/transferencias/unpacking`

```dart
// Mismo modelo que el endpoint 68 (UnPacking).
class UnPackingResult {
  int? code;                       // "code"
  String? msg;                     // "msg"
  List<UnPackingElement>? result;  // "result"
}
```

#### 71 · `POST /api/cluster/packing/ubicacion`

```dart
class ResponseAssignLocationPack {
  String? jsonrpc;
  dynamic id;
  ResultAssignLocation? result;
}
class ResultAssignLocation {
  int? code;                        // "code"
  String? msg;                      // "msg"
  List<ResultDataAssign>? result;   // "result"
}
class ResultDataAssign {
  String? paquete;          // "paquete"
  String? nuevaUbicacion;   // "nueva_ubicacion"
  int? lineasActualizadas;  // "lineas_actualizadas"
}
```

#### 72 · `POST /api/send_image_linea_recepcion/batch`

```dart
// Mismo modelo que el endpoint 27 (TemperatureSend).
class TemperatureSend {
  int? code;            // "code"
  String? msg;          // "msg"
  int? lineId;          // "line_id"
  double? temperature;  // "temperature"
  String? imageUrl;     // "image_url"
  String? jsonUrl;      // "json_url"
  String? filename;     // "filename"
  int? imageSize;       // "image_size"
  String? productName;  // "product_name"
}
```

#### 73 · `POST /api/send_imagen_observation/batch`

```dart
// Mismo modelo que el endpoint 28 (ImageSendNovedad).
class ImageSendNovedad {
  int? code;             // "code"
  String? msg;           // "msg"
  int? stockMoveId;      // "stock_move_id"
  int? stockMoveLineId;  // "stock_move_line_id"
  String? imageUrl;      // "image_url"
  String? filename;      // "filename"
}
```

### 7.10 Expedición

#### 74 · `GET /api/transferencias/out`

```dart
// El modelo aplana el sobre: lee directamente dentro de "result".
class ExpedicionResponseModel {
  int? code;                             // result.code
  bool? updateVersion;                   // result.update_version
  String? msg;                           // result.msg
  List<ExpedicionPedidoModel> result;    // result.result  ver §7
}
```

#### 75 · `POST /api/send_out`

```dart
// La app lee result.code == 200; result.msg lleva el motivo del rechazo.
// Un HTTP >= 400 se trata como fallo de red y dispara la cola offline.
class Envelope { int? code; String? msg; }
```

#### 76 · `POST /api/out_return`

```dart
// La app lee result.code == 200; result.msg lleva el motivo del rechazo.
class Envelope { int? code; String? msg; }
```

#### 77 · `POST /api/complete_out`

```dart
// Sin cuerpo tipado: la app solo comprueba result.code == 200.
// Si falla, propaga literal result.msg (o error.message).
class Envelope { int? code; String? msg; }
// msg con "expiry.picking.confirmation" -> la UI ofrece forzar vencidos.
```

### 7.11 Conteo

#### 78 · `GET /api/inventory/all_orders`

```dart
class ResponseConteo {
  String? jsonrpc;
  dynamic id;
  ResultConteo? result;
}
class ResultConteo {
  int? code;                 // "code"
  String? msg;               // "msg"
  bool? updateVersion;       // "update_version"
  List<DatumConteo>? data;   // "data"  ver §7 · DatumConteo
}
```

#### 79 · `POST /api/inventory/send_inventory`

```dart
class ResponseSendProductConteo {
  String? jsonrpc;
  dynamic id;
  ResponseSendProductResult? result;
}
class ResponseSendProductResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"
  Data? data;                   // "data"
}
class ResultElement {
  int? lineId;                // "line_id"
  int? productId;             // "product_id"
  dynamic quantityCounted;    // "quantity_counted"
  String? observation;        // "observation"
  int? userOperatorId;        // "user_operator_id"
  DateTime? dateTransaction;  // "date_transaction"
}
```

#### 80 · `POST /api/inventory/delete_line`

```dart
class ResponseDeleteProduct {
  String? jsonrpc;
  dynamic id;
  ResponseDeleteProductResult? result;
}
class ResponseDeleteProductResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"  línea afectada
}
```

#### 81 · `POST /api/inventory/remove_line`

```dart
// Mismo modelo que el endpoint 80 (ResponseDeleteProduct).
class ResponseDeleteProductResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"
}
```

### 7.12 Inventario

#### 82 · `GET /op/api/product_quants`

```dart
// Respuesta grande: se decodifica en un isolate y se reparte en dos listas.
class ProductosSyncResult {
  List<ProductoInventarioModel> productos;
  List<BarcodeProductoModel> barcodes;
}
class ProductoInventarioModel {
  int? productId;                        // "product_id"
  String? name;                          // "name"
  String? code;                          // "code"
  String? category;                      // "category"
  dynamic lotId;                         // "lot_id"
  String? lotName;                       // "lot_name"
  String? barcode;                       // "barcode"
  List<BarcodeProducto>? otherBarcodes;  // "other_barcodes"
  List<BarcodeProducto>? productPacking; // "product_packing"
  String? tracking;                      // "tracking"
  dynamic useExpirationDate;             // "use_expiration_date"
  dynamic expirationTime;                // "expiration_time"
  double? weight;                        // "weight"
  String? weightUomName;                 // "weight_uom_name"
  double? volume;                        // "volume"
}
class BarcodeProductoModel {
  dynamic barcode;    // "barcode"
  dynamic idProduct;  // "id_product"
  dynamic cantidad;   // "cantidad"
}
```

#### 83 · `GET /op/api/quant_post`

```dart
class ResultadoEnvioInventarioModel {
  String? status;   // result.status
  String? message;  // result.message
  int? data;        // result.data
}
// error.code == 100 -> SessionExpiredException
```

### 7.13 Info rápida

#### 84 · `GET /api/transferencias/quickinfo`

```dart
class InfoRapida {
  String? jsonrpc;
  dynamic id;
  InfoRapidaResult? result;
}
class InfoRapidaResult {
  int? code;            // "code"
  String? type;         // "type"   distingue producto de ubicación
  String? msg;          // "msg"
  bool? updateVersion;  // "update_version"
  InfoResult? result;   // "result"  ver §7 · InfoResult
}
```

#### 85 · `GET /api/transferencias/quickinfo/id`

```dart
// Mismo modelo que el endpoint 84 (InfoRapida).
class InfoRapidaResult {
  int? code;            // "code"
  String? type;         // "type"
  String? msg;          // "msg"
  InfoResult? result;   // "result"  ver §7 · InfoResult
}
```

#### 86 · `POST /api/crear_transferencia`

```dart
class SendTransferResponse {
  String? jsonrpc;
  dynamic id;
  Result? result;
}
class Result {
  int? code;                    // "code"
  String? msg;                  // "msg"
  dynamic transferenciaId;      // "transferencia_id"
  String? nombreTransferencia;  // "nombre_transferencia"
  dynamic lineaId;              // "linea_id"
  dynamic cantidadEnviada;      // "cantidad_enviada"
  dynamic idProducto;           // "id_producto"
  String? nombreProducto;       // "nombre_producto"
  String? ubicacionOrigen;      // "ubicacion_origen"
  String? ubicacionDestino;     // "ubicacion_destino"
  String? fechaTransaccion;     // "fecha_transaccion"
  String? observacion;          // "observacion"
  dynamic timeLine;             // "time_line"
  dynamic userOperatorId;       // "user_operator_id"
  String? userOperatorName;     // "user_operator_name"
  dynamic idLote;               // "id_lote"
}
```

#### 87 · `POST /api/update_product`

```dart
// Devuelve el mismo modelo de consulta, con el producto ya actualizado.
class InfoRapidaResult {
  int? code;           // "code"
  String? msg;         // "msg"
  InfoResult? result;  // "result"  ver §7 · InfoResult
}
```

#### 88 · `POST /api/update_location`

```dart
// Devuelve el mismo modelo de consulta, con la ubicación ya actualizada.
class InfoRapidaResult {
  int? code;           // "code"
  String? msg;         // "msg"
  InfoResult? result;  // "result"  ver §7 · InfoResult
}
```

---

## 8. Estructuras Dart compartidas

Modelos que aparecen en varias respuestas. Las fichas de §7 remiten aquí en lugar de repetirlos.

### ResultEntrada

Elemento de `result.result` en **/api/recepciones** y **/api/recepciones/devs** (endpoints 16 y 17).

```dart
class ResultEntrada {
  int? id;                          // "id"
  String? name;                     // "name"
  String? fechaCreacion;            // "fecha_creacion"
  dynamic proveedorId;              // "proveedor_id"
  dynamic proveedor;                // "proveedor"
  int? locationDestId;              // "location_dest_id"
  String? locationDestName;         // "location_dest_name"
  String? locationDestBarode;       // "location_dest_barode"
  int? purchaseOrderId;             // "purchase_order_id"
  String? purchaseOrderName;        // "purchase_order_name"
  String? numeroEntrada;            // "numero_entrada"
  double? pesoTotal;                // "peso_total"
  dynamic numeroLineas;             // "numero_lineas"
  dynamic numeroItems;              // "numero_items"
  String? state;                    // "state"
  String? origin;                   // "origin"
  String? priority;                 // "priority"
  int? warehouseId;                 // "warehouse_id"
  String? warehouseName;            // "warehouse_name"
  int? locationId;                  // "location_id"
  String? locationName;             // "location_name"
  int? responsableId;               // "responsable_id"
  String? responsable;              // "responsable"
  String? pickingType;              // "picking_type"
  dynamic startTimeReception;       // "start_time_reception"
  dynamic endTimeReception;         // "end_time_reception"
  dynamic isSelected;               // "is_selected"
  dynamic isStarted;                // "is_started"
  dynamic isFinish;                 // "is_finish"
  dynamic backorderName;            // "backorder_name"
  dynamic backorderId;              // "backorder_id"
  dynamic manejaTemperatura;        // "maneja_temperatura"
  dynamic temperatura;              // "temperatura"
  String? type;                     // "type"
  String? propietario;              // "propietario"
  dynamic manejoPropietario;        // "manejo_propietario"
  String? createBackorder;          // "create_backorder"
  List<LineasTransferencia>? lineasRecepcion;  // "lineas_recepcion"
}
```

### LineasTransferencia

Línea de documento en recepción individual. Es la estructura de línea más completa del sistema.

```dart
class LineasTransferencia {
  int? id;                        // "id"
  dynamic productId;              // "product_id"
  dynamic idRecepcion;            // "id_recepcion"
  dynamic idMove;                 // "id_move"
  String? productName;            // "product_name"
  String? productCode;            // "product_code"
  String? productBarcode;         // "product_barcode"
  String? productTracking;        // "product_tracking"
  String? fechaVencimiento;       // "fecha_vencimiento"
  dynamic diasVencimiento;        // "dias_vencimiento"
  List<Barcodes>? otherBarcodes;  // "other_barcodes"
  List<Barcodes>? productPacking; // "product_packing"
  dynamic quantityOrdered;        // "quantity_ordered"
  dynamic quantityToReceive;      // "quantity_to_receive"
  dynamic quantityDone;           // "quantity_done"
  String? uom;                    // "uom"
  int? locationDestId;            // "location_dest_id"
  String? locationDestName;       // "location_dest_name"
  String? locationDestBarcode;    // "location_dest_barcode"
  int? locationId;                // "location_id"
  String? locationName;           // "location_name"
  String? locationBarcode;        // "location_barcode"
  double? weight;                 // "weight"
  int? loteId;                    // "lote_id"
  String? lotName;                // "lot_name"
  String? loteDate;               // "lote_date"
  dynamic productIsOk;            // "product_is_ok"
  dynamic isQuantityIsOk;         // "is_quantity_is_ok"
  dynamic quantitySeparate;       // "quantity_separate"
  dynamic isSelected;             // "is_selected"
  dynamic isSeparate;             // "is_separate"
  dynamic isProductSplit;         // "is_product_split"
  String? observation;            // "observation"
  dynamic dateSeparate;           // "date_separate"
  dynamic dateStart;              // "date_start"
  dynamic dateEnd;                // "date_end"
  dynamic time;                   // "time"
  dynamic isDoneItem;             // "is_done_item"
  dynamic dateTransaction;        // "date_transaction"
  dynamic isPrincipalItem;        // "is_principal_item"
  dynamic cantidadFaltante;       // "cantidad_faltante"
  String? type;                   // "type"
  dynamic manejaTemperatura;      // "maneja_temperatura"
  dynamic temperatura;            // "temperatura"
  dynamic image;                  // "image"
  dynamic imageNovedad;           // "image_novedad"
  dynamic useExpirationDate;      // "use_expiration_date"
  dynamic manejaSegundaUnidad;    // "maneja_segunda_unidad"
  String? uomSegundaUnidad;       // "uom_segunda_unidad"
  double? quantitySegundaUnidad;  // "quantity_segunda_unidad"
}
```

### ReceptionBatch

Elemento de `result.result` en **/api/recepciones/batchs** (endpoint 18).

```dart
class ReceptionBatch {
  int? id;                       // "id"
  String? name;                  // "name"
  String? orderBy;               // "order_by"
  String? orderPicking;          // "order_picking"
  String? fechaCreacion;         // "fecha_creacion"
  String? state;                 // "state"
  int? pickingTypeId;            // "picking_type_id"
  String? pickingType;           // "picking_type"
  String? pickingTypeCode;       // "picking_type_code"
  String? observation;           // "observation"
  int? locationId;               // "location_id"
  String? locationName;          // "location_name"
  String? locationBarcode;       // "location_barcode"
  int? warehouseId;              // "warehouse_id"
  String? warehouseName;         // "warehouse_name"
  dynamic numeroLineas;          // "numero_lineas"
  dynamic numeroItems;           // "numero_items"
  String? startTimeReception;    // "start_time_reception"
  String? endTimeReception;      // "end_time_reception"
  String? priority;              // "priority"
  String? zonaEntrega;           // "zona_entrega"
  int? responsableId;            // "responsable_id"
  String? responsable;           // "responsable"
  int? proveedorId;              // "proveedor_id"
  String? proveedor;             // "proveedor"
  int? locationDestId;           // "location_dest_id"
  String? locationDestName;      // "location_dest_name"
  int? purchaseOrderId;          // "purchase_order_id"
  String? purchaseOrderName;     // "purchase_order_name"
  dynamic showCheckAvailability; // "show_check_availability"
  dynamic isSelected;            // "isSelected"
  dynamic isStarted;             // "isStarted"
  dynamic isFinish;              // "isFinish"
  String? propietario;           // "propietario"
  dynamic manejoPropietario;     // "manejo_propietario"
  List<LineasRecepcionBatch>? lineasRecepcion;          // "lineas_recepcion"
  List<LineasRecepcionBatch>? lineasRecepcionEnviadas;  // "lineas_recepcion_enviadas"
}
```

### LineasRecepcionBatch

Línea de documento en recepción por lote. Igual que LineasTransferencia salvo los campos marcados.

```dart
class LineasRecepcionBatch {
  int? id;                        // "id"
  int? idMove;                    // "id_move"
  int? idRecepcion;               // "id_recepcion"
  String? state;                  // "state"          solo en batch
  dynamic productId;              // "product_id"
  String? productName;            // "product_name"
  String? productCode;            // "product_code"
  String? productBarcode;         // "product_barcode"
  String? productTracking;        // "product_tracking"
  String? fechaVencimiento;       // "fecha_vencimiento"
  dynamic diasVencimiento;        // "dias_vencimiento"
  List<Barcodes>? otherBarcodes;  // "other_barcodes"
  List<Barcodes>? productPacking; // "product_packing"
  dynamic quantityOrdered;        // "quantity_ordered"
  dynamic cantidadFaltante;       // "cantidad_faltante"
  dynamic quantityToReceive;      // "quantity_to_receive"
  dynamic quantityDone;           // "quantity_done"
  String? uom;                    // "uom"
  int? locationDestId;            // "location_dest_id"
  String? locationDestName;       // "location_dest_name"
  String? locationDestBarcode;    // "location_dest_barcode"
  int? locationId;                // "location_id"
  String? locationName;           // "location_name"
  dynamic locationBarcode;        // "location_barcode"
  double? weight;                 // "weight"
  int? rimovalPriority;           // "rimoval_priority"  solo en batch
  int? lotId;                     // "lot_id"
  String? lotName;                // "lot_name"
  String? zonaEntrega;            // "zona_entrega"      solo en batch
  int? idZonaEntrega;             // "id_zona_entrega"   solo en batch
  int? pickingId;                 // "picking_id"        solo en batch
  String? pickingName;            // "picking_name"      solo en batch
  String? origin;                 // "origin"
  dynamic observation;            // "observation"
  String? dateTransaction;        // "date_transaction"
  dynamic time;                   // "time"
  dynamic isDoneItem;             // "is_done_item"
  dynamic isSelected;             // "isSelected"
  dynamic isSeparate;             // "isSeparate"
  dynamic isProductSplit;         // "isProductSplit"
  dynamic dateStart;              // "date_start"
  dynamic dateEnd;                // "date_end"
  dynamic manejaTemperatura;      // "maneja_temperatura"
  dynamic temperatura;            // "temperatura"
  String? image;                  // "image"
  dynamic useExpirationDate;      // "use_expiration_date"
  dynamic manejaSegundaUnidad;    // "maneja_segunda_unidad"
  String? uomSegundaUnidad;       // "uom_segunda_unidad"
  double? quantitySegundaUnidad;  // "quantity_segunda_unidad"
}
```

### ResultTransFerencias

Elemento de `result.result` en **/api/transferencias**, **/api/transferencias/producto_terminado** y **/api/comprobar_disponibilidad** (endpoints 30, 31 y 38).

```dart
class ResultTransFerencias {
  int? id;                        // "id"
  String? name;                   // "name"
  String? fechaCreacion;          // "fecha_creacion"
  int? locationId;                // "location_id"
  String? locationName;           // "location_name"
  int? locationDestId;            // "location_dest_id"
  String? locationDestName;       // "location_dest_name"
  String? numeroTransferencia;    // "numero_transferencia"
  double? pesoTotal;              // "peso_total"
  dynamic numeroLineas;           // "numero_lineas"
  dynamic numeroItems;            // "numero_items"
  String? state;                  // "state"
  String? origin;                 // "origin"
  String? priority;               // "priority"
  int? warehouseId;               // "warehouse_id"
  String? warehouseName;          // "warehouse_name"
  int? responsableId;             // "responsable_id"
  String? responsable;            // "responsable"
  String? pickingType;            // "picking_type"
  dynamic startTimeTransfer;      // "start_time_transfer"
  dynamic endTimeTransfer;        // "end_time_transfer"
  dynamic isSelected;             // "is_selected"
  dynamic isStarted;              // "is_started"
  dynamic isFinish;               // "is_finish"
  dynamic backorderName;          // "backorder_name"
  dynamic backorderId;            // "backorder_id"
  dynamic showCheckAvailability;  // "show_check_availability"
  dynamic proveedor;              // "proveedor"
  String? type;                   // "type"
  String? createBackorder;        // "create_backorder"
  String? propietario;            // "propietario"
  dynamic manejoPropietario;      // "manejo_propietario"
  List<LineasTransferenciaTrans>? lineasTransferencia;  // "lineas_transferencia"
}
// LineasTransferenciaTrans tiene los mismos campos que LineasTransferencia.
```

### ResultPick

Elemento de `result.result` en los cuatro endpoints de picking pick (54–57).

```dart
class ResultPick {
  int? id;                      // "id"
  String? name;                 // "name"
  String? observacion;          // "observacion"
  String? fechaCreacion;        // "fecha_creacion"
  int? locationId;              // "location_id"
  String? locationName;         // "location_name"
  String? locationBarcode;      // "location_barcode"
  int? locationDestId;          // "location_dest_id"
  String? locationDestName;     // "location_dest_name"
  String? locationDestBarcode;  // "location_dest_barcode"
  String? proveedor;            // "proveedor"
  String? numeroTransferencia;  // "numero_transferencia"
  int? pesoTotal;               // "peso_total"
  dynamic numeroLineas;         // "numero_lineas"
  dynamic numeroItems;          // "numero_items"
  String? state;                // "state"
  String? origin;               // "origin"
  String? priority;             // "priority"
  int? warehouseId;             // "warehouse_id"
  String? warehouseName;        // "warehouse_name"
  int? responsableId;           // "responsable_id"
  String? responsable;          // "responsable"
  String? pickingType;          // "picking_type"
  String? startTimeTransfer;    // "start_time_transfer"
  String? endTimeTransfer;      // "end_time_transfer"
  int? backorderId;             // "backorder_id"
  String? backorderName;        // "backorder_name"
  dynamic showCheckAvailability;// "show_check_availability"
  dynamic isSeparate;           // "is_separate"
  dynamic isSelected;           // "is_selected"
  String? zonaEntrega;          // "zona_entrega"
  String? muelle;               // "muelle"
  String? barcodeMuelle;        // "barcode_muelle"
  dynamic muelleId;             // "muelle_id"
  dynamic idMuellePadre;        // "id_muelle_padre"
  int? indexList;               // "index_list"
  String? isSendOdoo;           // "is_send_odoo"
  String? isSendOdooDate;       // "is_send_odoo_date"
  String? observation;          // "observation"
  String? referencia;           // "referencia"
  dynamic orderPicking;         // "order_picking"
  String? typePick;             // "type_pick"
  String? productoFinalNombre;  // "producto_final_nombre"
  String? productoFinalReferencia; // "producto_final_referencia"
  String? createBackorder;      // "create_backorder"
  dynamic quantityDone;         // "quantity_done"
  dynamic quantityOrdered;      // "quantity_ordered"
  String? propietario;          // "propietario"
  dynamic manejoPropietario;    // "manejo_propietario"
  List<ProductsBatch>? lineasTransferencia;          // "lineas_transferencia"
  List<ProductsBatch>? lineasTransferenciaEnviadas;  // "lineas_transferencia_enviadas"
}
```

### BatchsModel

Elemento de `result.result` en **/api/batchs** y **/api/batchs/componentes** (endpoints 43 y 44).

```dart
class BatchsModel {
  int? id;                     // "id"
  String? name;                // "name"
  String? type;                // "type"
  dynamic scheduleddate;       // "scheduleddate"
  dynamic pickingTypeId;       // "picking_type_id"
  String? muelle;              // "muelle"
  String? barcodeMuelle;       // "barcode_muelle"
  dynamic idMuelle;            // "id_muelle"
  dynamic idMuellePadre;       // "id_muelle_padre"
  String? state;               // "state"
  dynamic userId;              // "user_id"
  String? userName;            // "user_name"
  int? countItems;             // "count_items"
  dynamic totalQuantityItems;  // "total_quantity_items"
  int? indexList;              // "index_list"
  dynamic isWave;              // "is_wave"
  int? isSeparate;             // "is_separate"
  dynamic isSelected;          // "is_selected"
  int? productSeparateQty;     // "product_separate_qty"
  double? timeSeparateTotal;   // "time_separate_total"
  String? isSendOdoo;          // "is_send_odoo"
  String? isSendOdooDate;      // "is_send_odoo_date"
  String? observation;         // "observation"
  dynamic orderBy;             // "order_by"
  dynamic orderPicking;        // "order_picking"
  dynamic startTimePick;       // "start_time_pick"
  dynamic endTimePick;         // "end_time_pick"
  String? zonaEntrega;         // "zona_entrega"
  String? propietario;         // "propietario"
  List<Origin>? origin;        // "origin"
}
```

### ProductsBatch

Línea de producto en picking (batch y pick).

```dart
class ProductsBatch {
  int? id;                        // "id"
  dynamic rimovalPriority;        // "rimoval_priority"
  dynamic expireDate;             // "expire_date"
  dynamic batchId;                // "batch_id"
  String? type;                   // "type"
  String? pedido;                 // "pedido"
  int? pedidoId;                  // "pedido_id"
  int? orderProduct;              // "order_product"
  int? idProduct;                 // "id_product"
  dynamic productId;              // "product_id"
  dynamic origin;                 // "origin"
  int? muelleId;                  // "muelle_id"
  int? idMove;                    // "id_move"
  String? productTracking;        // "product_tracking"
  dynamic barcodeLocation;        // "barcode_location"
  dynamic barcodeLocationDest;    // "barcode_location_dest"
  dynamic lotId;                  // "lot_id"
  dynamic loteId;                 // "lote_id"
  dynamic lote;                   // "lote"
  List<Barcodes>? productPacking; // "product_packing"
  List<Barcodes>? otherBarcode;   // "other_barcode"
  dynamic locationId;             // "location_id"
  dynamic locationDestId;         // "location_dest_id"
  dynamic idLocationDest;         // "id_location_dest"
  dynamic quantity;               // "quantity"
  dynamic barcode;                // "barcode"
  String? name;                   // "name"
  dynamic weight;                 // "weight" / "weigth"
  String? unidades;               // "unidades"
  dynamic quantitySeparate;       // "quantity_separate"
  dynamic isSelected;             // "is_selected"
  int? isSeparate;                // "is_separate"
  int? isPending;                 // "is_pending"
  dynamic timeSeparate;           // "time_separate"
  String? timeSeparateStart;      // "time_separate_start"
  String? timeSeparateEnd;        // "time_separate_end"
  String? observation;            // "observation"
  int? isMuelle;                  // "is_muelle"
  dynamic isLocationIsOk;         // "is_location_is_ok"
  dynamic productIsOk;            // "product_is_ok"
  dynamic locationDestIsOk;       // "location_dest_is_ok"
  dynamic isQuantityIsOk;         // "is_quantity_is_ok"
  int? isSendOdoo;                // "is_send_odoo"
  String? isSendOdooDate;         // "is_send_odoo_date"
  String? fechaTransaccion;       // "fecha_transaccion"
  String? typePick;               // "type_pick"
  dynamic productCode;            // "product_code"
}
```

### ResultElementModel

Elemento de `result.result` en **/api/cluster/picking_batchs** (endpoint 58).

```dart
class ResultElementModel {
  int? id;                       // "id"
  String? name;                  // "name"
  String? userName;              // "user_name"
  int? userId;                   // "user_id"
  String? rol;                   // "rol"
  String? orderBy;               // "order_by"
  String? orderPicking;          // "order_picking"
  String? scheduleddate;         // "scheduleddate"  false se normaliza a ""
  String? state;                 // "state"
  String? pickingTypeId;         // "picking_type_id"
  String? observation;           // "observation"
  bool? isWave;                  // "is_wave"
  String? muelle;                // "muelle"
  dynamic idMuelle;              // "id_muelle"
  dynamic idMuellePadre;         // "id_muelle_padre"
  String? barcodeMuelle;         // "barcode_muelle"
  int? countItems;               // "count_items"
  dynamic totalQuantityItems;    // "total_quantity_items"
  int? completedItems;           // "completed_items"
  dynamic progressPercentage;    // "progress_percentage"
  dynamic startTimePick;         // "start_time_pick"
  dynamic endTimePick;           // "end_time_pick"
  int? productSeparateQty;       // "product_separate_qty"
  String? zonaEntrega;           // "zona_entrega"
  String? propietario;           // "propietario"  false se normaliza a null
  dynamic manejoPropietario;     // "manejo_propietario"
  List<PedidoValidateModel>? pedidosValidate;  // "pedidos_validate"
  List<ListItem>? listItems;                   // "list_items"
}
```

### BatchPackingModel

Elemento de `result.result` en **/api/batch_packing** y **/api/batch_packing_unificado** (endpoints 61 y 62).

```dart
class BatchPackingModel {
  int? id;                        // "id"
  String? name;                   // "name"
  dynamic scheduleddate;          // "scheduleddate"
  dynamic pickingTypeId;          // "picking_type_id"
  String? state;                  // "state"
  dynamic userId;                 // "user_id"
  String? userName;               // "user_name"
  int? cantidadPedidos;           // "cantidad_pedidos"
  int? isSeparate;                // "is_separate"
  dynamic isSelected;             // "is_selected"
  dynamic isPacking;              // "is_packing"
  int? pedidoSeparateQty;         // "pedido_separate_qty"
  double? timeSeparateTotal;      // "time_separate_total"
  String? timeSeparateStart;      // "time_separate_start"
  String? timeSeparateEnd;        // "time_separate_end"
  String? zonaEntrega;            // "zona_entrega"
  String? zonaEntregaTms;         // "zona_entrega_tms"
  dynamic startTimePack;          // "start_time_pack"
  dynamic endTimePack;            // "end_time_pack"
  String? origins;                // "origins"
  dynamic cantidadTotalPedidos;   // "cantidad_total_pedidos"
  dynamic cantidadTotalProductos; // "cantidad_total_productos"
  dynamic unidadesProductos;      // "unidades_productos"
  List<Origin>? origin;           // "origin"
  List<PedidoPacking>? listaPedidos;  // "lista_pedidos"
}
```

### PedidoPackingResult

Elemento de `result.result` en **/api/transferencias/pack** (endpoint 63).

```dart
class PedidoPackingResult {
  int? batchId;                  // "batch_id"
  int? id;                       // "id"
  String? name;                  // "name"
  String? observacion;           // "observacion"
  dynamic fechaCreacion;         // "fecha_creacion"
  dynamic configPacking;         // "config_packing"
  int? locationId;               // "location_id"
  String? locationName;          // "location_name"
  String? locationBarcode;       // "location_barcode"
  int? locationIdCluster;        // "location_id_cluster"
  String? locationNameCluster;   // "location_name_cluster"
  String? locationBarcodeCluster;// "location_barcode_cluster"
  int? locationDestId;           // "location_dest_id"
  String? locationDestName;      // "location_dest_name"
  String? locationDestBarcode;   // "location_dest_barcode"
  String? proveedor;             // "proveedor"
  String? numeroTransferencia;   // "numero_transferencia"
  int? pesoTotal;                // "peso_total"
  int? numeroLineas;             // "numero_lineas"
  dynamic numeroItems;           // "numero_items"
  String? state;                 // "state"
  String? referencia;            // "referencia"
  String? contacto;              // "contacto"
  String? contactoName;          // "contacto_name"
  int? cantidadProductos;        // "cantidad_productos"
  int? cantidadProductosTotal;   // "cantidad_productos_total"
  String? priority;              // "priority"
  int? warehouseId;              // "warehouse_id"
  String? warehouseName;         // "warehouse_name"
  int? responsableId;            // "responsable_id"
}
```

### ExpedicionPedidoModel

Elemento de `result.result` en **/api/transferencias/out** (endpoint 74). El modelo reparte los ítems en cuatro listas según su estado de validación.

```dart
class ExpedicionPedidoModel {
  int? expeditionId;          // "expedition_id"
  String? nombre;             // "nombre"
  DateTime? fecha;            // "fecha"
  String? cliente;            // "cliente"
  String? documentoOrigen;    // "documento_origen"
  int? numeroLineas;          // "numero_lineas"
  int? totalCantidades;       // "total_cantidades"
  int? numeroPaquetes;        // "numero_paquetes"
  int? productoSueltos;       // "producto_sueltos"
  double? totalPeso;          // "total_peso"
  String? observacion;        // "observacion"
  bool? manejoPropietario;    // "manejo_propietario"
  String? propietario;        // "propietario"
  String? estado;             // "estado"
  int? warehouseId;           // "warehouse_id"
  String? warehouseName;      // "warehouse_name"
  int? responsableId;         // "responsable_id"
  String? responsable;        // "responsable"
  String? pickingType;        // "picking_type"
  String? startTimeTransfer;  // "start_time_transfer"
  String? endTimeTransfer;    // "end_time_transfer"
  String? zonaEntrega;        // "zona_entrega"
  bool? isTerminated;         // "is_terminated"
  int? backorderId;           // "backorder_id"
  String? backorderName;      // "backorder_name"
  List<PaqueteExpedicion> itemsPackValidados;   // derivado de "packing"
  List<PaqueteExpedicion> itemsPackPendientes;  // derivado de "packing"
  List<ItemSueltoExpedicion> itemsValidados;    // derivado de "items"
  List<ItemSueltoExpedicion> itemsPendientes;   // derivado de "items"
}
class PaqueteExpedicion {
  int? expeditionId;             // "expedition_id"
  int? packingId;                // "packing_id"
  String? packageName;           // "package_name"
  String? packingBarcode;        // "packing_barcode"
  String? packingType;           // "packing_type"
  int? orderPacking;             // "order_packing"
  bool? isValidate;              // "is_validate"
  List<ItemExpedicion> items;    // "items"
}
class ItemExpedicion {
  int? productoId;         // "producto_id"
  String? productName;     // "product_name"
  String? productCode;     // "product_code"
  String? barcode;         // "barcode"
  dynamic quantity;        // "quantity"
  String? uom;             // "uom"
  String? tracking;        // "tracking"
  dynamic diasVencimiento; // "dias_vencimiento"
  bool? isValidate;        // "is_validate"
}
```

### DatumConteo

Elemento de `result.data` en **/api/inventory/all_orders** (endpoint 78).

```dart
class DatumConteo {
  int? id;                      // "id"
  String? name;                 // "name"
  String? state;                // "state"
  int? warehouseId;             // "warehouse_id"
  String? warehouseName;        // "warehouse_name"
  int? responsableId;           // "responsable_id"
  String? responsableName;      // "responsable_name"
  dynamic createDate;           // "create_date"
  dynamic dateCount;            // "date_count"
  dynamic mostrarCantidad;      // "mostrar_cantidad"
  String? countType;            // "count_type"
  String? numberCount;          // "number_count"
  int? numeroLineas;            // "numero_lineas"
  int? numeroItemsContados;     // "numero_items_contados"
  String? filterType;           // "filter_type"
  dynamic enableAllLocations;   // "enable_all_locations"
  dynamic enableAllProducts;    // "enable_all_products"
  String? observationGeneral;   // "observation_general"
  dynamic isDoneItem;           // "is_done_item"
  dynamic isSelected;           // "is_selected"
  dynamic isStarted;            // "is_started"
  dynamic isFinished;           // "is_finished"
  String? startTimeOrden;       // "start_time_orden"
  String? endTimeOrden;         // "end_time_orden"
  List<Allowed>? allowedCategories; // "allowed_categories"
  List<Allowed>? allowedLocations;  // "allowed_locations"
  List<Allowed>? allowedProducts;   // "allowed_products"
  List<CountedLine>? countedLines;      // "counted_lines"
  List<CountedLine>? countedLinesDone;  // "counted_lines_done"
}
class CountedLine {
  int? id;                        // "id"
  int? orderId;                   // "order_id"
  int? productId;                 // "product_id"
  String? productName;            // "product_name"
  String? productCode;            // "product_code"
  String? productBarcode;         // "product_barcode"
  String? productTracking;        // "product_tracking"
  List<Barcodes>? otherBarcodes;  // "other_barcodes"
  List<Barcodes>? productPacking; // "product_packing"
  int? locationId;                // "location_id"
  String? locationName;           // "location_name"
  String? locationBarcode;        // "location_barcode"
  dynamic quantityInventory;      // "quantity_inventory"
  dynamic quantityCounted;        // "quantity_counted"
  dynamic differenceQty;          // "difference_qty"
  String? uom;                    // "uom"
  dynamic weight;                 // "weight"
  String? dateTransaction;        // "date_transaction"
  String? observation;            // "observation"
  dynamic time;                   // "time"
  int? userOperatorId;            // "user_operator_id"
  String? userOperatorName;       // "user_operator_name"
  int? categoryId;                // "category_id"
  String? categoryName;           // "category_name"
  int? lotId;                     // "lot_id"
  String? lotName;                // "lot_name"
  String? fechaVencimiento;       // "fecha_vencimiento"
  dynamic idMove;                 // "id_move"
  dynamic isOriginal;             // "is_original"
  dynamic isDoneItem;             // "is_done_item"
  dynamic isSelected;             // "is_selected"
  dynamic isSeparate;             // "is_separate"
  dynamic productIsOk;            // "product_is_ok"
  dynamic isQuantityIsOk;         // "is_quantity_is_ok"
  dynamic isLocationIsOk;         // "is_location_is_ok"
  dynamic useExpirationDate;      // "use_expiration_date"
}
```

### InfoResult

Cuerpo de `result.result` en los dos endpoints de consulta rápida (84 y 85) y en las dos ediciones de maestros (87 y 88). El campo `type` del nivel superior indica si viene un producto o una ubicación.

```dart
class InfoResult {
  int? id;                      // "id"
  String? nombre;               // "nombre"
  dynamic precio;               // "precio"
  String? referencia;           // "referencia"
  dynamic peso;                 // "peso"
  dynamic volumen;              // "volumen"
  dynamic codigoBarras;         // "codigo_barras"
  dynamic cantidadDisponible;   // "cantidad_disponible"
  dynamic previsto;             // "previsto"
  String? categoria;            // "categoria"
  String? unidadMedida;         // "unidad_medida"
  dynamic isSticker;            // "is_sticker"
  dynamic isCertificate;        // "is_certificate"
  String? fechaEmpaquetado;     // "fecha_empaquetado"
  String? ubicacionPadre;       // "ubicacion_padre"
  String? tipoUbicacion;        // "tipo_ubicacion"
  dynamic numeroPedidos;        // "numero_pedidos"
  dynamic totalProductos;       // "total_productos"
  dynamic numeroProductos;      // "numero_productos"
  String? nombreAlmacen;        // "nombre_almacen"
  String? nombreCompleto;       // "nombre_completo"
  String? propietario;          // "propietario"
  int? idPropietario;           // "id_propietario"
  dynamic manejoPropietario;    // "manejo_propietario"
  List<Ubicacion>? ubicaciones; // "ubicaciones"  cuando se consulta un producto
  List<Producto>? productos;    // "productos"    cuando se consulta una ubicación
}
class Ubicacion {
  int? idMove;                // "id_move"
  int? idAlmacen;             // "id_almacen"
  int? idUbicacion;           // "id_ubicacion"
  String? ubicacion;          // "ubicacion"
  dynamic cantidad;           // "cantidad"
  dynamic reservado;          // "reservado"
  dynamic cantidadMano;       // "cantidad_mano"
  String? codigoBarras;       // "codigo_barras"
  String? lote;               // "lote"
  dynamic loteId;             // "lote_id"
  String? fechaEliminacion;   // "fecha_eliminacion"
  String? fechaCaducidad;     // "fecha_caducidad"
  String? fechaEntrada;       // "fecha_entrada"
  String? unidadMedida;       // "unidad_medida"
  bool? packing;              // "packing"
  String? nombrePaquete;      // "nombre_paquete"
  String? propietario;        // "propietario"
  int? idPropietario;         // "id_propietario"
  dynamic manejoPropietario;  // "manejo_propietario"
}
class Producto {
  int? id;                    // "id"
  String? producto;           // "producto"
  dynamic cantidad;           // "cantidad"
  dynamic reservado;          // "reservado"
  dynamic cantidadMano;       // "cantidad_mano"
  dynamic codigoBarras;       // "codigo_barras"
  dynamic loteId;             // "lote_id"
  String? lote;               // "lote"
  String? unidadMedida;       // "unidad_medida"
  String? pedido;             // "pedido"
  String? origin;             // "origin"
  String? tercero;            // "tercero"
  String? numeroCaja;         // "numero_caja"
  String? nombreAlmacen;      // "nombre_almacen"
  dynamic operador;           // "operador"
  String? fechaVencimiento;   // "fecha_vencimiento"
  bool? packing;              // "packing"
  String? nombrePaquete;      // "nombre_paquete"
  String? propietario;        // "propietario"
  int? idPropietario;         // "id_propietario"
  dynamic manejoPropietario;  // "manejo_propietario"
}
```

### UserProfileModel

Cuerpo de `result.result` en **/api/configurations** (endpoint 3). Es el interruptor maestro de la app: cada bandera habilita o esconde una parte de la interfaz.

```dart
class UserProfileModel {
  String? name;    // "name"
  String? email;   // "email"
  String? lastName;// "last_name"
  int? id;         // "id"
  String? rol;     // "rol"
  String? muelleOption;                 // "muelle_option"
  String? returnsLocationDestOption;    // "returns_location_dest_option"
  List<AllowedWarehouse>? allowedWarehouses;  // "allowed_warehouses"

  // Validación de documentos
  bool? hideValidatePicking;      // "hide_validate_picking"
  bool? hideValidateReception;    // "hide_validate_reception"
  bool? hideValidatePacking;      // "hide_validate_packing"
  bool? hideValidateExpedition;   // "hide_validate_expedition"
  bool? hideValidateTransfer;     // "hide_validate_transfer"
  bool? hideValidateItemExpedition; // "hide_validate_item_expedition"
  bool? allowValidateMultiple;      // "allow_validate_multiple"
  bool? showButtonValidateClusterPicking; // "show_button_validate_cluster_picking"

  // Captura manual por módulo
  bool? locationPickingManual;          // "location_picking_manual"
  bool? manualProductSelection;         // "manual_product_selection"
  bool? manualQuantity;                 // "manual_quantity"
  bool? manualSpringSelection;          // "manual_spring_selection"
  bool? locationPackManual;             // "location_pack_manual"
  bool? manualProductSelectionPack;     // "manual_product_selection_pack"
  bool? manualQuantityPack;             // "manual_quantity_pack"
  bool? manualSpringSelectionPack;      // "manual_spring_selection_pack"
  bool? manualProductReading;           // "manual_product_reading"
  bool? manualSourceLocation;           // "manual_source_location"
  bool? manualSourceLocationTransfer;   // "manual_source_location_transfer"
  bool? manualDestLocationTransfer;     // "manual_dest_location_transfer"
  bool? manualQuantityTransfer;         // "manual_quantity_transfer"
  bool? manualProductSelectionTransfer; // "manual_product_selection_transfer"
  bool? locationManualInventory;        // "location_manual_inventory"
  bool? manualProductSelectionInventory;// "manual_product_selection_inventory"

  // Escaneo y detalle
  bool? scanProduct;                        // "scan_product"
  bool? scanDestinationLocationReception;   // "scan_destination_location_reception"
  bool? showDetallesPicking;                // "show_detalles_picking"
  bool? showDetallesPack;                   // "show_detalles_pack"
  bool? showNextLocationsInDetails;         // "show_next_locations_in_details"
  bool? showNextLocationsInDetailsPack;     // "show_next_locations_in_details_pack"
  bool? hideExpectedQty;                    // "hide_expected_qty"
  bool? showOwnerField;                     // "show_owner_field"
  bool? showPhotoTemperature;               // "show_photo_temperature"

  // Excesos, inventario y vencimientos
  bool? allowMoveExcess;                    // "allow_move_excess"
  bool? allowMoveExcessProduction;          // "allow_move_excess_production"
  bool? accessProductionModule;             // "access_production_module"
  bool? countQuantityInventory;             // "count_quantity_inventory"
  bool? updateItemInventory;                // "update_item_inventory"
  bool? updateLocationInventory;            // "update_location_inventory"
  bool? allowPriorExpirationDate;           // "allow_prior_expiration_date"
  bool? manageExpirationDateWithoutLot;     // "manage_expiration_date_without_lot"
}
```

