# Mapa de Endpoints WMS

**Aplicación WMS · Integración Odoo**

Inventario completo de las rutas HTTP que consume la aplicación móvil de bodega: qué módulo llama a cada una, dónde se replica entre módulos, y el cuerpo exacto que se envía con los tipos de dato de cada campo.

- **96** rutas únicas
- **14** módulos
- **16** rutas compartidas
- Rama **desarrollo**
- Extraído del código fuente · septiembre 2026

## Tabla de contenido

- [§1. Capa de transporte](#1-capa-de-transporte)
- [§2. Índice completo](#2-índice-completo)
- [§3. Detalle por módulo](#3-detalle-por-módulo)
  - [Sesión y dispositivo (1–7)](#sesión-y-dispositivo)
  - [Maestros compartidos (8–15)](#maestros-compartidos)
  - [Recepción (16–28)](#recepción)
  - [Devoluciones (29)](#devoluciones)
  - [Transferencias (30–42)](#transferencias)
  - [Picking — batch y componentes (43–53)](#picking--batch-y-componentes)
  - [Picking — pick (54–57)](#picking--pick)
  - [Picking — cluster (58–60)](#picking--cluster)
  - [Packing (61–73)](#packing)
  - [Expedición (74–77)](#expedición)
  - [Conteo (78–81)](#conteo)
  - [Inventario (82–83)](#inventario)
  - [Info rápida (84–88)](#info-rápida)
  - [Recepción multiusuario (89–96)](#recepción-multiusuario)
- [§4. Matriz de replicación](#4-matriz-de-replicación)
- [§5. Servicios que no son el backend Odoo](#5-servicios-que-no-son-el-backend-odoo)
- [§6. Códigos y manejo de errores](#6-códigos-y-manejo-de-errores)
- [§7. Estructuras Dart compartidas](#7-estructuras-dart-compartidas)

---

## §1. Capa de transporte

Toda llamada pasa por un único cliente HTTP (`ApiRequestService`). Sus variantes determinan el prefijo de la URL, las cabeceras y el verbo real que llega al servidor.

### Construcción de la URL

`{base}` es la URL de la instancia Odoo, capturada en la pantalla de selección de empresa y persistida en el dispositivo.

| Método del cliente | Verbo real | URL resultante |
|---|---|---|
| `post` | POST | `{base}/api/{endpoint}` · o `{base}/{endpoint}` |
| `postPicking` | POST | `{base}/api/{endpoint}` · o `{base}/{endpoint}` |
| `postPacking` | POST | `{base}/api/{endpoint}` — siempre |
| `postPrint` | POST | `{base}/{endpoint}` — sin prefijo |
| `get` · `getValidation` · `getHistory` | GET | `{base}/api/{endpoint}` · o `{base}/{endpoint}` |
| `getInfo` | GET | `{base}/api/{endpoint}` — siempre |
| `getInventario` | GET | `{base}/op/api/{endpoint}` |
| `postInventario` | GET | `{base}/op/api/{endpoint}` — **verbo GET pese al nombre** |
| `postMultipart` · `…Manual` · `…Dynamic` | POST | `{base}/api/{endpoint}` — multipart/form-data |
| `postMultipartImage` | POST | `https://apitemperature.360software.com.co/{endpoint}` |
| `searchEnterprice` | POST | `{url_introducida}/web/database/list` |

### Autenticación

- El login devuelve la cabecera `set-cookie`; se persiste completa en el dispositivo.
- El resto de llamadas envían **solo el fragmento `session_id=…`** en la cabecera `Cookie`. Las cargas multipart son la excepción: envían la cookie completa.
- Cabeceras estándar: `Content-Type: application/json` + `Cookie: session_id=…`
- `get`, `getValidation`, `getInventario` y `postInventario` abortan localmente si el `session_id` está vacío — la petición no sale del dispositivo.

### Envoltura JSON-RPC

Todos los cuerpos, salvo los multipart, van envueltos en `params`. Los métodos sin cuerpo propio envían `{"params":{}}`. Tres rutas son la excepción y mandan el sobre completo `jsonrpc / method / params`: `/direct-print/print-report` y los dos cierres de recepción multiusuario (`/done` y `/undo`).

```json
// petición estándar
{ "params": { "campo": "valor" } }

// respuesta exitosa
{ "jsonrpc": "2.0", "id": null,
  "result": { "code": 200, "msg": "Ok", "result": [] } }
```

`getValidation` añade siempre identificación de dispositivo, y `getHistory` un único filtro de fecha:

```json
// getValidation
{ "params": { "device_id": "AA:BB:CC:DD:EE:FF", "version_app": "1.4.2" } }

// getHistory
{ "params": { "fecha_batch": "2026-08-14" } }
```

> **device_id** es la MAC del terminal. Cuando Android la enmascara como `02:00:00:00:00:00`, la app envía el IMEI en su lugar. **version_app** proviene del manifiesto de la aplicación.

### Detalles que afectan al backend

- **GET con cuerpo JSON**: `getInfo`, `getHistory`, `getInventario` y `postInventario` emiten un GET que lleva cuerpo. Afecta a `quickinfo`, `validar_stock`, los históricos y ambos endpoints de inventario.
- **Timeout de 100 s** en `postPicking`, `postPacking`, `getInventario` y `postInventario`. El resto no declara timeout.
- **Prefijo `/op/api`**: exclusivo del módulo de inventario.
- Sin conexión, el cliente sintetiza respuestas locales (404 de red, 408 de timeout) con cuerpo JSON-RPC válido. Nunca llegan al servidor.

---

## §2. Índice completo

Las 96 rutas, con el módulo que las consume y los módulos donde se replican.

| # | Verbo | Ruta | Módulo | También en |
|---|---|---|---|---|
| 1 | POST | `/web/database/list` | Enterprise | — |
| 2 | POST | `/web/session/authenticate` | Login | — |
| 3 | GET | `/api/configurations` | User | — |
| 4 | GET | `/api/ubicaciones` | User | — |
| 5 | GET | `/api/picking_novelties` | User | — |
| 6 | POST | `/api/pda/register` | User | — |
| 7 | GET | `/api/last-version` | Home | — |
| 8 | GET | `/api/lotes/{product_id}` | Inventario | Recepción · Recepción multiusuario · Devoluciones · Picking cluster |
| 9 | POST | `/api/create_lote` | Inventario | Recepción · Recepción multiusuario · Devoluciones · Picking cluster |
| 10 | GET | `/api/get_imagen_product/{product_id}` | Inventario | Picking cluster · Picking pick |
| 11 | GET | `/api/get_packaging_types` | Packaging types | — |
| 12 | GET | `/api/terceros` | Devoluciones | — |
| 13 | GET | `/api/muelles` | Picking batch | Picking pick |
| 14 | POST | `/api/printer_details` | Printing | — |
| 15 | POST | `/direct-print/print-report` | Printing | — |
| 16 | GET | `/api/recepciones` | Recepción | — |
| 17 | GET | `/api/recepciones/devs` | Recepción | — |
| 18 | GET | `/api/recepciones/batchs` | Recepción | — |
| 19 | POST | `/api/asignar_responsable` | Recepción | — |
| 20 | POST | `/api/asignar_responsable/batch` | Recepción | — |
| 21 | POST | `/api/send_recepcion` | Recepción | — |
| 22 | POST | `/api/send_recepcion/batch` | Recepción | — |
| 23 | POST | `/api/update_recepcion` | Recepción | — |
| 24 | POST | `/api/complete_recepcion` | Recepción | — |
| 25 | POST | `/api/complete_recepcion/expire` | Recepción | — |
| 26 | POST | `/api/update_time_reception` | Recepción | — |
| 27 | POST | `/api/send_image_linea_recepcion` | Recepción | Packing usa la variante /batch |
| 28 | POST | `/api/send_imagen_observation` | Recepción | Packing usa la variante /batch |
| 29 | POST | `/api/crear_devs` | Devoluciones | — |
| 30 | GET | `/api/transferencias` | Transferencias | — |
| 31 | GET | `/api/transferencias/producto_terminado` | Transferencias | — |
| 32 | GET | `/api/transferencias/{id_picking}` | Transferencias | — |
| 33 | POST | `/api/transferencias/asignar` | Transferencias | Packing |
| 34 | POST | `/api/send_transfer` | Transferencias | — |
| 35 | POST | `/api/send_transfer/pick` | Transferencias | Picking pick |
| 36 | POST | `/api/complete_transfer` | Transferencias | Packing · Picking pick |
| 37 | POST | `/api/complete_transfer/expire` | Transferencias | Packing · Picking pick |
| 38 | POST | `/api/comprobar_disponibilidad` | Transferencias | — |
| 39 | POST | `/api/transferencias/delete_line` | Transferencias | — |
| 40 | POST | `/api/transferencias/create_trasferencia` | Transferencias | — |
| 41 | GET | `/api/validar_stock` | Transferencias | — |
| 42 | POST | `/api/update_time_transfer` | Transferencias | Packing (pedido y batch) · Picking pick |
| 43 | GET | `/api/batchs` | Picking batch | — |
| 44 | GET | `/api/batchs/componentes` | Picking batch | — |
| 45 | GET | `/api/batchs_done` | Picking batch | — |
| 46 | GET | `/api/batch/{batch_id}` | Picking batch | — |
| 47 | POST | `/api/send_batch` | Picking batch | — |
| 48 | POST | `/api/send_batch/componentes` | Picking batch | — |
| 49 | POST | `/api/update_dock` | Picking batch | Picking pick |
| 50 | POST | `/api/start_time_batch_user` | Picking batch | Picking cluster · Packing |
| 51 | POST | `/api/end_time_batch_user` | Picking batch | Picking cluster · Packing |
| 52 | POST | `/api/update_start_time` | Picking batch | Picking cluster · Packing |
| 53 | POST | `/api/update_end_time` | Picking batch | Picking cluster · Packing |
| 54 | GET | `/api/transferencias/pick` | Picking pick | — |
| 55 | GET | `/api/transferencias/history_picking` | Picking pick | — |
| 56 | GET | `/api/picking/componentes` | Picking pick | — |
| 57 | GET | `/api/picking/componentes/history` | Picking pick | — |
| 58 | GET | `/api/cluster/picking_batchs` | Picking cluster | — |
| 59 | POST | `/api/cluster/send_picking` | Picking cluster | — |
| 60 | POST | `/api/cluster/validate_pedido/id` | Picking cluster | — |
| 61 | GET | `/api/batch_packing` | Packing | — |
| 62 | GET | `/api/batch_packing_unificado` | Packing | — |
| 63 | GET | `/api/transferencias/pack` | Packing | — |
| 64 | POST | `/api/send_packing` | Packing | — |
| 65 | POST | `/api/send_pack_unified` | Packing | — |
| 66 | POST | `/api/send_cluster/pack` | Packing | — |
| 67 | POST | `/api/send_transfer/pack` | Packing | — |
| 68 | POST | `/api/unpacking` | Packing | — |
| 69 | POST | `/api/unpack_unified` | Packing | — |
| 70 | POST | `/api/transferencias/unpacking` | Packing | — |
| 71 | POST | `/api/cluster/packing/ubicacion` | Packing | — |
| 72 | POST | `/api/send_image_linea_recepcion/batch` | Packing | Variante batch del endpoint 27 |
| 73 | POST | `/api/send_imagen_observation/batch` | Packing | Variante batch del endpoint 28 |
| 74 | GET | `/api/transferencias/out` | Expedición | — |
| 75 | POST | `/api/send_out` | Expedición | — |
| 76 | POST | `/api/out_return` | Expedición | — |
| 77 | POST | `/api/complete_out` | Expedición | — |
| 78 | GET | `/api/inventory/all_orders` | Conteo | — |
| 79 | POST | `/api/inventory/send_inventory` | Conteo | — |
| 80 | POST | `/api/inventory/delete_line` | Conteo | — |
| 81 | POST | `/api/inventory/remove_line` | Conteo | — |
| 82 | GET | `/op/api/product_quants` | Inventario | — |
| 83 | GET | `/op/api/quant_post` | Inventario | — |
| 84 | GET | `/api/transferencias/quickinfo` | Info rápida | — |
| 85 | GET | `/api/transferencias/quickinfo/id` | Info rápida | — |
| 86 | POST | `/api/crear_transferencia` | Info rápida | — |
| 87 | POST | `/api/update_product` | Info rápida | — |
| 88 | POST | `/api/update_location` | Info rápida | — |
| 89 | POST | `/api/receipt/sessions` | Recepción multiusuario | — |
| 90 | POST | `/api/receipt/session/{session_id}/pool` | Recepción multiusuario | — |
| 91 | POST | `/api/receipt/claim` | Recepción multiusuario | — |
| 92 | POST | `/api/receipt/session/{session_id}/my_claims` | Recepción multiusuario | — |
| 93 | POST | `/api/receipt/claim/{claim_id}/release` | Recepción multiusuario | — |
| 94 | POST | `/api/receipt/claim/{claim_id}/done` | Recepción multiusuario | — |
| 95 | POST | `/api/receipt/claim/{claim_id}/undo` | Recepción multiusuario | — |
| 96 | POST | `/api/receipt/picking/{picking_id}` | Recepción multiusuario | — |

---

## §3. Detalle por módulo

### Sesión y dispositivo

Arranque de la aplicación: elección de instancia, autenticación, permisos del usuario y registro del terminal.

#### 1. POST `/web/database/list`
**Módulo:** Enterprise · **Cliente:** `searchEnterprice`

Lista las bases de datos disponibles en la instancia. Única llamada sin autenticar.

```json
{ "params": {} }
```
**Respuesta:** Listado de bases de datos de Odoo.
```dart
class EnterpriseModel {
  List<String> databases;   // "result"  ej. ["onpoint_prod", "onpoint_test"]
}
```

#### 2. POST `/web/session/authenticate`
**Módulo:** Login · **Cliente:** `post`

Autenticación del operario. Devuelve la cookie de sesión que usa el resto de la app.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| login | String | string | sí |
| password | String | string | sí |
| db | String | string | sí |

```json
{ "params": { "login": "operario1", "password": "••••••", "db": "onpoint_prod" } }
```
**Respuesta:** Objeto de sesión (uid, name, username, company_id…) más la cabecera set-cookie con el session_id. Un objeto error se traduce a mensaje de credenciales inválidas.
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

#### 3. GET `/api/configurations`
**Módulo:** User · **Cliente:** `get`

Configuración y permisos del usuario. Si el código no es 200 la app bloquea el acceso con el mensaje devuelto.

```json
{ "params": {} }
```
**Respuesta:** result.result con la configuración del usuario.
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

#### 4. GET `/api/ubicaciones`
**Módulo:** User · **Cliente:** `get`

Catálogo de ubicaciones habilitadas para el usuario.

```json
{ "params": {} }
```
**Respuesta:** result.result = arreglo de ubicaciones.
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

#### 5. GET `/api/picking_novelties`
**Módulo:** User · **Cliente:** `get`

Catálogo de novedades seleccionables al reportar un producto.

```json
{ "params": {} }
```
**Respuesta:** result.result = arreglo de novedades.
```dart
// result.result -> List<UserNoveltyModel>
class UserNoveltyModel {
  int id;       // "id"
  String name;  // "name"
  String code;  // "code"
}
```

#### 6. POST `/api/pda/register`
**Módulo:** User · **Cliente:** `postPicking`

Registro del terminal en el backend.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| device_id | String | string | MAC o IMEI |
| device_name | String | string | |
| device_model | String | string | |
| version_app | String | string | |

```json
{ "params": { "device_id": "AA:BB:CC:DD:EE:FF", "device_name": "TC21-01",
              "device_model": "Zebra TC21", "version_app": "1.4.2" } }
```
**Respuesta:** result.data con el registro del dispositivo.
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

#### 7. GET `/api/last-version`
**Módulo:** Home · **Cliente:** `get`

Control de versión mínima. Si la app está desactualizada se bloquea el uso.

```json
{ "params": {} }
```
**Respuesta:** Versión mínima requerida y URL de descarga.
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

### Maestros compartidos

Catálogos y utilidades transversales. Son los endpoints con más replicación entre módulos.

#### 8. GET `/api/lotes/{product_id}`
**Módulo:** Inventario · **También en:** Recepción · Recepción multiusuario · Devoluciones · Picking cluster · **Cliente:** `get`

Lotes disponibles de un producto. El identificador viaja en la ruta.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| product_id | int | number | en la ruta |

```json
{ "params": {} }
```
**Respuesta:** result.result = arreglo de lotes (id, name, expiration_date…).
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

#### 9. POST `/api/create_lote`
**Módulo:** Inventario · **También en:** Recepción · Recepción multiusuario · Devoluciones · Picking cluster · **Cliente:** `postPacking`

Alta de lote desde el terminal.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_producto | int | number | sí |
| nombre_lote | String | string | sí |
| fecha_vencimiento | String | string | formato yyyy-MM-dd; cadena vacía si no aplica |
| priority_expiration | bool | boolean | Picking cluster no envía este campo |

```json
{ "params": { "id_producto": 4821, "nombre_lote": "L-2026-08-14",
              "fecha_vencimiento": "2027-02-01", "priority_expiration": true } }
```
**Respuesta:** result.result = arreglo con el lote creado.
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
> Picking cluster omite priority_expiration y omite fecha_vencimiento cuando es nula.

#### 10. GET `/api/get_imagen_product/{product_id}`
**Módulo:** Inventario · **También en:** Picking cluster · Picking pick · **Cliente:** `get`

Devuelve la URL de la imagen del producto. La descarga posterior se hace con la cookie de sesión.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| product_id | int | number | en la ruta |

```json
{ "params": {} }
```
**Respuesta:** result.result.url = cadena con la URL. La imagen se descarga con GET {url} enviando la cookie y Accept: image/png, image/jpeg. Si el servidor responde text/html la app lo trata como fallo de autenticación.
```dart
// La respuesta solo transporta la URL; la app descarga la imagen aparte.
class RespuestaImagen {
  int? code;     // result.code   200 si hay imagen
  String? msg;   // result.msg    motivo cuando no la hay
  String? url;   // result.result.url
}
```

#### 11. GET `/api/get_packaging_types`
**Módulo:** Packaging types · **Cliente:** `get`

Tipos de empaque disponibles al armar un paquete.

```json
{ "params": {} }
```
**Respuesta:** result.result = arreglo de tipos de empaque.
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

#### 12. GET `/api/terceros`
**Módulo:** Devoluciones · **Cliente:** `get`

Proveedores y terceros para el encabezado de una devolución.

```json
{ "params": {} }
```
**Respuesta:** result.result = arreglo de terceros.
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

#### 13. GET `/api/muelles`
**Módulo:** Picking batch · **También en:** Picking pick · **Cliente:** `get`

Muelles de cargue disponibles.

```json
{ "params": {} }
```
**Respuesta:** result.result = arreglo de muelles.
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

#### 14. POST `/api/printer_details`
**Módulo:** Printing · **Cliente:** `postPacking`

Impresoras configuradas. Único endpoint que envía un cuerpo vacío sin envoltura params.

```json
{}
```
**Respuesta:** result.result = arreglo de impresoras.
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

#### 15. POST `/direct-print/print-report`
**Módulo:** Printing · **Cliente:** `postPrint`

Impresión directa de un reporte. Envía el sobre JSON-RPC completo, igual que los cierres de recepción multiusuario (endpoints 94 y 95).

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| jsonrpc | String | string | siempre "2.0" |
| method | String | string | siempre "call" |
| params.action.type | String | string | siempre "ir.actions.report" |
| params.action.nameEE | String | string | |
| params.action.report_name | String | string | |
| params.action.context.active_model | String | string | |
| params.action.context.active_ids | List\<int\> | array de number | |
| params.action.context.active_id | int | number | primer elemento de active_ids |
| params.action.context.allowed_company_ids | List\<int\> | array de number | |
| params.action.context.printer_id | int | number | |
| params.options | Map | object | siempre vacío |

```json
{ "jsonrpc": "2.0", "method": "call",
  "params": {
    "action": { "type": "ir.actions.report", "nameEE": "…", "report_name": "…",
      "context": { "active_model": "stock.picking", "active_ids": [5521],
                   "active_id": 5521, "allowed_company_ids": [1], "printer_id": 3 } },
    "options": {} } }
```
**Respuesta:** Confirmación de envío a la impresora.
```dart
// La app solo comprueba el código de estado HTTP y result.code.
class Envelope { int? code; String? msg; }
```

### Recepción

Entradas individuales, devoluciones de cliente y recepciones agrupadas por lote de trabajo.

#### 16. GET `/api/recepciones`
**Módulo:** Recepción · **Cliente:** `getValidation`

Listado de recepciones individuales asignables.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| device_id | String | string | |
| version_app | String | string | |

```json
{ "params": { "device_id": "AA:BB:CC:DD:EE:FF", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de recepciones.
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

#### 17. GET `/api/recepciones/devs`
**Módulo:** Recepción · **Cliente:** `getValidation`

Listado de devoluciones de cliente pendientes de recibir.

Mismos campos que el endpoint 16.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de devoluciones.
```dart
// Mismo modelo que el endpoint 16.
class RecepcionresponseResult {
  RecepcionresponseResult? result;   // code / msg / update_version
}                                    // result.result -> List<ResultEntrada>
```

#### 18. GET `/api/recepciones/batchs`
**Módulo:** Recepción · **Cliente:** `getValidation`

Listado de recepciones agrupadas en lote de trabajo.

Mismos campos que el endpoint 16.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de batches de recepción.
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

#### 19. POST `/api/asignar_responsable`
**Módulo:** Recepción · **Cliente:** `postPacking`

Asigna el operario responsable de una recepción individual.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_recepcion | int | number | |
| id_responsable | int | number | |

```json
{ "params": { "id_recepcion": 1032, "id_responsable": 7 } }
```
**Respuesta:** result.code 200 al asignar.
```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 20. POST `/api/asignar_responsable/batch`
**Módulo:** Recepción · **Cliente:** `postPacking`

Asigna el operario responsable de un lote de recepción.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_batch | int | number | |
| id_responsable | int | number | |

```json
{ "params": { "id_batch": 412, "id_responsable": 7 } }
```
**Respuesta:** result.code 200 al asignar.
```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 21. POST `/api/send_recepcion`
**Módulo:** Recepción · **Cliente:** `postPacking`

Envía a Odoo las líneas recibidas de una recepción individual.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_recepcion | int | number | |
| list_items | List\<ListItem\> | array de objeto | |
| list_items[].id_producto | int | number | |
| list_items[].id_move | int | number | |
| list_items[].lote_producto | int | number | |
| list_items[].ubicacion_destino | int | number | |
| list_items[].cantidad_separada | dynamic | number | coaccionado a número: nunca viaja null |
| list_items[].id_operario | int | number | |
| list_items[].fecha_transaccion | String | string | |
| list_items[].observacion | String | string | |
| list_items[].time_line | int | number | segundos en la línea |
| list_items[].quantity_segunda_unidad | double | number | 0.0 por defecto |

```json
{ "params": {
    "id_recepcion": 1032,
    "list_items": [
      { "id_producto": 4821, "id_move": 99213, "lote_producto": 771,
        "ubicacion_destino": 18, "cantidad_separada": 12, "id_operario": 7,
        "fecha_transaccion": "2026-08-14 09:31:02", "observacion": "Sin novedad",
        "time_line": 34, "quantity_segunda_unidad": 0.0 } ] } }
```
**Respuesta:** result.code + result.result con las líneas procesadas.
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
> cantidad_separada se coacciona a número en el cliente porque el backend hace float() sobre el campo y un null aborta la operación.

#### 22. POST `/api/send_recepcion/batch`
**Módulo:** Recepción · **Cliente:** `postPacking`

Igual que send_recepcion, pero la clave del documento es id_batch.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_batch | int | number | |
| list_items | List\<ListItem\> | array de objeto | mismos campos que send_recepcion |

```json
{ "params": { "id_batch": 412, "list_items": [ … ] } }
```
**Respuesta:** result.code + result.result con las líneas procesadas.
```dart
// Mismo modelo que el endpoint 21 (ResponSendRecepcion).
class ResponSendRecepcionResult {
  int? code;                   // "code"
  String? msg;                 // "msg"
  List<ResultElement>? result; // "result"  líneas procesadas
}
```

#### 23. POST `/api/update_recepcion`
**Módulo:** Recepción · **Cliente:** `postPacking`

Elimina en Odoo líneas ya enviadas de una recepción.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_recepcion | int | number | |
| list_items | List\<Map\> | array de objeto | mismo formato de línea que send_recepcion |

```json
{ "params": { "id_recepcion": 1032, "list_items": [ … ] } }
```
**Respuesta:** result.code 200 al actualizar.
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

#### 24. POST `/api/complete_recepcion`
**Módulo:** Recepción · **Cliente:** `postPacking`

Cierra la recepción en Odoo.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_recepcion | int | number | |
| crear_backorder | bool | boolean | |
| forzar_lote_vencido | bool | boolean | solo se envía cuando es true |

```json
{ "params": { "id_recepcion": 1032, "crear_backorder": false } }
```
**Respuesta:** result.code 200, o result.msg con el motivo del rechazo.
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

#### 25. POST `/api/complete_recepcion/expire`
**Módulo:** Recepción · **Cliente:** `postPacking`

Cierra la recepción confirmando explícitamente productos caducados.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_recepcion | int | number | |
| crear_backorder | bool | boolean | |
| confirmar_caducados | bool | boolean | siempre true |

```json
{ "params": { "id_recepcion": 1032, "crear_backorder": false,
              "confirmar_caducados": true } }
```
**Respuesta:** result.code 200 al cerrar.
```dart
// Mismo modelo que el endpoint 24 (ResponseValidate / ResultValidate).
class ResultValidate {
  int? code;                        // "code"
  String? msg;                      // "msg"
  String? tipoError;                // "tipo_error"
  List<DetalleValidate>? detalles;  // "detalles"
}
```

#### 26. POST `/api/update_time_reception`
**Módulo:** Recepción · **Cliente:** `postPacking`

Marca de inicio o fin de tiempo del documento de recepción.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| reception_id | int | number | |
| time | String | string | yyyy-MM-dd HH:mm:ss |
| field_name | String | string | start_time_reception \| end_time_reception |

```json
{ "params": { "reception_id": 1032, "time": "2026-08-14 09:00:00",
              "field_name": "start_time_reception" } }
```
**Respuesta:** result.code 200.
```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 27. POST `/api/send_image_linea_recepcion`
**Módulo:** Recepción · **También en:** Packing usa la variante /batch · **Cliente:** `postMultipart` · `postMultipartManual`

Adjunta foto y temperatura a una línea. multipart/form-data.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| image_data | File | parte de archivo | JPEG o PNG; la variante manual no envía archivo |
| move_line_id | String | campo de texto | |
| temperatura | String | campo de texto | |

**Respuesta:** Confirmación del adjunto.
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
> Envía la cookie completa, no solo el fragmento session_id.

#### 28. POST `/api/send_imagen_observation`
**Módulo:** Recepción · **También en:** Packing usa la variante /batch · **Cliente:** `postMultipartDynamic`

Adjunta la foto que respalda una novedad. multipart/form-data.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| image_data | File | parte de archivo | JPEG o PNG |
| id_move | String | campo de texto | |

**Respuesta:** Confirmación del adjunto.
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

### Devoluciones

Creación de devoluciones a proveedor desde el terminal. Reutiliza los maestros de terceros y lotes.

#### 29. POST `/api/crear_devs`
**Módulo:** Devoluciones · **Cliente:** `postPacking`

Crea la devolución completa: encabezado y líneas en una sola llamada.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| device_id | String | string | MAC o IMEI |
| id_almacen | int | number | |
| id_proveedor | int | number | |
| id_ubicacion_destino | int | number | |
| id_responsable | int | number | |
| fecha_inicio | String | string | |
| fecha_fin | String | string | |
| id_propietario | int | number | |
| list_items | List\<ProductRequest\> | array de objeto | |
| list_items[].id_producto | int | number | |
| list_items[].id_lote | dynamic | number \| string | |
| list_items[].ubicacion_destino | int | number | |
| list_items[].cantidad_enviada | dynamic | number | |
| list_items[].id_operario | int | number | |
| list_items[].time_line | int | number | |
| list_items[].fecha_transaccion | String | string | |
| list_items[].observacion | String | string | |
| list_items[].quantity_segunda_unidad | double | number | |

```json
{ "params": {
    "device_id": "AA:BB:CC:DD:EE:FF", "id_almacen": 1, "id_proveedor": 340,
    "id_ubicacion_destino": 18, "id_responsable": 7,
    "fecha_inicio": "2026-08-14 08:00:00", "fecha_fin": "2026-08-14 08:40:00",
    "id_propietario": 1,
    "list_items": [
      { "id_producto": 4821, "id_lote": 771, "ubicacion_destino": 18,
        "cantidad_enviada": 6, "id_operario": 7, "time_line": 22,
        "fecha_transaccion": "2026-08-14 08:22:10", "observacion": "Avería",
        "quantity_segunda_unidad": 0.0 } ] } }
```
**Respuesta:** result.code + documento de devolución creado.
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

### Transferencias

Movimientos internos entre ubicaciones, incluido el flujo de pick que comparte contrato con el módulo de picking.

#### 30. GET `/api/transferencias`
**Módulo:** Transferencias · **Cliente:** `getValidation`

Listado de transferencias internas asignables.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| device_id | String | string | |
| version_app | String | string | |

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de transferencias.
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

#### 31. GET `/api/transferencias/producto_terminado`
**Módulo:** Transferencias · **Cliente:** `getValidation`

Entradas de producto terminado desde producción. Mismos campos que el endpoint 30.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de entradas.
```dart
// Mismo modelo que el endpoint 30.
class ResponseTransferenciasResult {
  int? code;                           // "code"
  bool? updateVersion;                 // "update_version"
  List<ResultTransFerencias>? result;  // "result"  ver §7
}
```

#### 32. GET `/api/transferencias/{id_picking}`
**Módulo:** Transferencias · **Cliente:** `get`

Detalle de una transferencia por identificador.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_picking | int | number | en la ruta |

```json
{ "params": {} }
```
**Respuesta:** result.result con el detalle del documento.
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

#### 33. POST `/api/transferencias/asignar`
**Módulo:** Transferencias · **También en:** Packing · **Cliente:** `postPacking`

Asigna el operario responsable de la transferencia. Packing envía exactamente el mismo cuerpo.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_transferencia | int | number | |
| id_responsable | int | number | |

```json
{ "params": { "id_transferencia": 5521, "id_responsable": 7 } }
```
**Respuesta:** result.code 200 al asignar.
```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 34. POST `/api/send_transfer`
**Módulo:** Transferencias · **Cliente:** `postPacking`

Envía a Odoo las líneas movidas de una transferencia interna.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_transferencia | int | number | |
| list_items | List\<ListItem\> | array de objeto | |
| list_items[].id_move | int | number | |
| list_items[].id_producto | int | number | |
| list_items[].id_lote | int | number | |
| list_items[].id_ubicacion_origen | int? | number \| null | puede viajar nulo |
| list_items[].id_ubicacion_destino | int | number | |
| list_items[].cantidad_enviada | dynamic | number | coaccionado a número: nunca viaja null |
| list_items[].id_operario | int | number | |
| list_items[].time_line | dynamic | number | |
| list_items[].fecha_transaccion | String | string | |
| list_items[].observacion | String | string | |
| list_items[].dividida | bool | boolean | la línea se dividió en el terminal |
| list_items[].quantity_segunda_unidad | double | number | |

```json
{ "params": {
    "id_transferencia": 5521,
    "list_items": [
      { "id_move": 99213, "id_producto": 4821, "id_lote": 771,
        "id_ubicacion_origen": 12, "id_ubicacion_destino": 18,
        "cantidad_enviada": 6, "id_operario": 7, "time_line": 22,
        "fecha_transaccion": "2026-08-14 09:31:02", "observacion": "Sin novedad",
        "dividida": false, "quantity_segunda_unidad": 0.0 } ] } }
```
**Respuesta:** result.code + result.result con las líneas procesadas.
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

#### 35. POST `/api/send_transfer/pick`
**Módulo:** Transferencias · **También en:** Picking pick · **Cliente:** `postPacking`

Variante de send_transfer para el flujo de pick. Mismo cuerpo.

```json
{ "params": { "id_transferencia": 5521, "list_items": [ … ] } }
```
**Respuesta:** result.code + result.result con las líneas procesadas.
```dart
// Mismo modelo que el endpoint 34 (ResponseSenTransfer).
class ResponseSenTransferResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"
}
```

#### 36. POST `/api/complete_transfer`
**Módulo:** Transferencias · **También en:** Packing · Picking pick · **Cliente:** `postPacking`

Cierra la transferencia en Odoo.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_transferencia | int | number | |
| crear_backorder | bool | boolean | |

```json
{ "params": { "id_transferencia": 5521, "crear_backorder": false } }
```
**Respuesta:** result.code 200, o result.msg con el motivo del rechazo.
```dart
// Mismo modelo que el endpoint 24 (ResponseValidate).
class ResultValidate {
  int? code;                       // "code"
  String? msg;                     // "msg"
  String? tipoError;               // "tipo_error"
  List<DetalleValidate>? detalles; // "detalles"
}
```

#### 37. POST `/api/complete_transfer/expire`
**Módulo:** Transferencias · **También en:** Packing · Picking pick · **Cliente:** `postPacking`

Cierre confirmando productos con fecha de vencimiento comprometida.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_transferencia | int | number | |
| crear_backorder | bool | boolean | |

```json
{ "params": { "id_transferencia": 5521, "crear_backorder": true } }
```
**Respuesta:** result.code 200 al cerrar.
```dart
// Mismo modelo que el endpoint 24 (ResponseValidate).
class ResultValidate {
  int? code;                       // "code"
  String? msg;                     // "msg"
  String? tipoError;               // "tipo_error"
  List<DetalleValidate>? detalles; // "detalles"
}
```

#### 38. POST `/api/comprobar_disponibilidad`
**Módulo:** Transferencias · **Cliente:** `postPacking`

Solicita a Odoo recalcular la disponibilidad del documento.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_transferencia | int | number | |

```json
{ "params": { "id_transferencia": 5521 } }
```
**Respuesta:** result.code + disponibilidad recalculada.
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

#### 39. POST `/api/transferencias/delete_line`
**Módulo:** Transferencias · **Cliente:** `postPacking`

Elimina una línea del documento.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_linea | int | number | |

```json
{ "params": { "id_linea": 99213 } }
```
**Respuesta:** result.code 200 al eliminar.
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
> La línea "por hacer" ya viene completa y final en `result.result` (si coincidía con una demanda pendiente existente, viene fusionada/sumada). El backend puede devolver un `id_move` distinto al enviado.

#### 40. POST `/api/transferencias/create_trasferencia`
**Módulo:** Transferencias · **Cliente:** `postPacking`

Crea una transferencia completa desde el terminal.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| date_start | String | string | |
| date_end | String | string | |
| id_almacen | int | number | |
| id_ubicacion_origen | int | number | |
| id_ubicacion_destino | int | number | |
| id_operario | int | number | |
| fecha_transaccion | String | string | |
| list_items | List\<ListItem\> | array de objeto | |
| list_items[].id_producto | int | number | |
| list_items[].cantidad_enviada | double | number | |
| list_items[].id_lote | int | number | |
| list_items[].time_line | int | number | |
| list_items[].id_propietario | int | number | |
| list_items[].quantity_segunda_unidad | double | number | |

```json
{ "params": {
    "date_start": "2026-08-14 08:00:00", "date_end": "2026-08-14 08:40:00",
    "id_almacen": 1, "id_ubicacion_origen": 12, "id_ubicacion_destino": 18,
    "id_operario": 7, "fecha_transaccion": "2026-08-14 08:40:00",
    "list_items": [
      { "id_producto": 4821, "cantidad_enviada": 6.0, "id_lote": 771,
        "time_line": 22, "id_propietario": 1, "quantity_segunda_unidad": 0.0 } ] } }
```
**Respuesta:** result.code + documento creado.
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
> El nombre del endpoint contiene la errata "trasferencia"; así está en el backend.

#### 41. GET `/api/validar_stock`
**Módulo:** Transferencias · **Cliente:** `getInfo`

Valida existencias antes de mover. GET con cuerpo JSON.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_producto | int | number | |
| id_ubicacion | int | number | |
| id_lote | int | number | |
| cantidad_requerida | dynamic | number | |

```json
{ "params": { "id_producto": 4821, "id_ubicacion": 12,
              "id_lote": 771, "cantidad_requerida": 6 } }
```
**Respuesta:** result.code + disponibilidad de la combinación consultada.
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

#### 42. POST `/api/update_time_transfer`
**Módulo:** Transferencias · **También en:** Packing (pedido y batch) · Picking pick · **Cliente:** `postPacking`

Marca de inicio o fin de tiempo del documento.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| transfer_id | int | number | |
| time | String | string | yyyy-MM-dd HH:mm:ss |
| field_name | String | string | start_time_transfer \| end_time_transfer |

```json
{ "params": { "transfer_id": 5521, "time": "2026-08-14 09:00:00",
              "field_name": "start_time_transfer" } }
```
**Respuesta:** result.code 200.
```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

### Picking — batch y componentes

Separación por lote de trabajo. Los cuatro endpoints de tiempo se comparten con packing y con picking cluster.

#### 43. GET `/api/batchs`
**Módulo:** Picking batch · **Cliente:** `getValidation`

Listado de batches de picking asignables.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de batches.
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

#### 44. GET `/api/batchs/componentes`
**Módulo:** Picking batch · **Cliente:** `getValidation`

Listado de batches de separación de componentes.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de batches de componentes.
```dart
// Mismo modelo que el endpoint 43.
class DataBatch {
  int? code;                  // "code"
  String? msg;                // "msg"
  bool? updateVersion;        // "update_version"
  List<BatchsModel>? result;  // "result"  ver §7 · BatchsModel
}
```

#### 45. GET `/api/batchs_done`
**Módulo:** Picking batch · **Cliente:** `getHistory`

Histórico de batches cerrados en una fecha. GET con cuerpo JSON.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| fecha_batch | String | string | yyyy-MM-dd |

```json
{ "params": { "fecha_batch": "2026-08-14" } }
```
**Respuesta:** result.result = arreglo de batches cerrados.
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

#### 46. GET `/api/batch/{batch_id}`
**Módulo:** Picking batch · **Cliente:** `get`

Detalle de un batch con sus productos.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| batch_id | int | number | en la ruta |

```json
{ "params": {} }
```
**Respuesta:** result.result con el batch y sus líneas.
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

#### 47. POST `/api/send_batch`
**Módulo:** Picking batch · **Cliente:** `postPicking`

Envía a Odoo las líneas separadas del batch.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_batch | int | number | |
| time_total | double | number | segundos totales |
| cant_items_separados | int | number | |
| list_item | List\<Item\> | array de objeto | |
| list_item[].id_move | int | number | |
| list_item[].product_id | int | number | |
| list_item[].lote | String | string | |
| list_item[].cantidad | dynamic | number | |
| list_item[].novedad | String | string | |
| list_item[].time_line | double | number | |
| list_item[].muelle | int | number | |
| list_item[].id_operario | int | number | |
| list_item[].fecha_transaccion | String | string | |

```json
{ "params": {
    "id_batch": 412, "time_total": 640.0, "cant_items_separados": 18,
    "list_item": [
      { "id_move": 99213, "product_id": 4821, "lote": "L-2026-08-14",
        "cantidad": 12, "novedad": "Sin novedad", "time_line": 34.0,
        "muelle": 3, "id_operario": 7,
        "fecha_transaccion": "2026-08-14 09:31:02" } ] } }
```
**Respuesta:** result.code + result.result con las líneas procesadas.
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

#### 48. POST `/api/send_batch/componentes`
**Módulo:** Picking batch · **Cliente:** `postPicking`

Variante para separación de componentes. Cuerpo idéntico a send_batch; la app elige la ruta según el tipo de picking.

```json
{ "params": { "id_batch": 412, "time_total": 640.0,
              "cant_items_separados": 18, "list_item": [ … ] } }
```
**Respuesta:** result.code + result.result con las líneas procesadas.
```dart
// Mismo modelo que el endpoint 47 (SendPickingResponse).
class Data {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"  una entrada por línea enviada
}
```

#### 49. POST `/api/update_dock`
**Módulo:** Picking batch · **También en:** Picking pick · **Cliente:** `postPicking`

Marca un muelle como ocupado o libre.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| muelle_id | int | number | |
| is_full | bool | boolean | |

```json
{ "params": { "muelle_id": 3, "is_full": true } }
```
**Respuesta:** result.code 200.
```dart
class OcuparMuelle {
  String? jsonrpc;
  dynamic id;
  Result? result;    // "result"  code + msg; la app solo lee code == 200
}
```

#### 50. POST `/api/start_time_batch_user`
**Módulo:** Picking batch · **También en:** Picking cluster · Packing · **Cliente:** `postPicking`

Marca de inicio de tiempo por operario.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_batch | String | string | identificador numérico serializado como texto |
| user_id | String | string | identificador numérico serializado como texto |
| start_time | String | string | clave dinámica: start_time |
| operation_type | String | string | "picking" o "packing" |

```json
{ "params": { "id_batch": "412", "user_id": "7",
              "start_time": "2026-08-14 09:00:00",
              "operation_type": "picking" } }
```
**Respuesta:** result.code 200.
```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 51. POST `/api/end_time_batch_user`
**Módulo:** Picking batch · **También en:** Picking cluster · Packing · **Cliente:** `postPicking`

Marca de fin de tiempo por operario.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_batch | String | string | |
| user_id | String | string | |
| end_time | String | string | clave dinámica: end_time |
| operation_type | String | string | "picking" o "packing" |

```json
{ "params": { "id_batch": "412", "user_id": "7",
              "end_time": "2026-08-14 09:42:00",
              "operation_type": "picking" } }
```
**Respuesta:** result.code 200.
```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 52. POST `/api/update_start_time`
**Módulo:** Picking batch · **También en:** Picking cluster · Packing · **Cliente:** `postPicking`

Marca de inicio de tiempo del documento completo.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| picking_id | String | string | identificador numérico serializado como texto |
| start_time | String | string | clave dinámica: start_time |
| field_name | String | string | start_time_pick \| start_time_pack \| end_time_pick \| end_time_pack |

```json
{ "params": { "picking_id": "412", "start_time": "2026-08-14 09:00:00",
              "field_name": "start_time_pick" } }
```
**Respuesta:** result.code 200.
```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

#### 53. POST `/api/update_end_time`
**Módulo:** Picking batch · **También en:** Picking cluster · Packing · **Cliente:** `postPicking`

Marca de fin de tiempo del documento completo.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| picking_id | String | string | |
| end_time | String | string | clave dinámica: end_time |
| field_name | String | string | end_time_pick \| end_time_pack |

```json
{ "params": { "picking_id": "412", "end_time": "2026-08-14 09:42:00",
              "field_name": "end_time_pick" } }
```
**Respuesta:** result.code 200.
```dart
// La app solo lee result.code == 200.
class Envelope { int? code; String? msg; }
```

### Picking — pick

Separación sobre transferencias de salida. Solo consultas propias: los envíos y validaciones reutilizan los endpoints de transferencias.

#### 54. GET `/api/transferencias/pick`
**Módulo:** Picking pick · **Cliente:** `getValidation`

Listado de picks asignables.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de picks.
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

#### 55. GET `/api/transferencias/history_picking`
**Módulo:** Picking pick · **Cliente:** `getHistory`

Histórico de picks cerrados en una fecha. GET con cuerpo JSON.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| fecha_picking | String | string | yyyy-MM-dd |

```json
{ "params": { "fecha_picking": "2026-08-14" } }
```
**Respuesta:** result.result = arreglo de picks cerrados.
```dart
// result.result -> List<ResultPick>   (ver §7 · ResultPick)
class ResponsePickResult {
  int? code;                 // "code"
  String? msg;               // "msg"
  List<ResultPick>? result;  // "result"  picks cerrados en la fecha
}
```

#### 56. GET `/api/picking/componentes`
**Módulo:** Picking pick · **Cliente:** `getValidation`

Listado de picks de componentes.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de picks de componentes.
```dart
// Mismo modelo que el endpoint 54.
class ResponsePickResult {
  int? code;                 // "code"
  String? msg;               // "msg"
  bool? updateVersion;       // "update_version"
  List<ResultPick>? result;  // "result"  ver §7 · ResultPick
}
```

#### 57. GET `/api/picking/componentes/history`
**Módulo:** Picking pick · **Cliente:** `getHistory`

Histórico de picks de componentes. GET con cuerpo JSON.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| fecha_picking | String | string | yyyy-MM-dd |

```json
{ "params": { "fecha_picking": "2026-08-14" } }
```
**Respuesta:** result.result = arreglo de picks cerrados.
```dart
// result.result -> List<ResultPick>   (ver §7 · ResultPick)
class ResponsePickResult {
  int? code;                 // "code"
  List<ResultPick>? result;  // "result"  picks de componentes cerrados
}
```

### Picking — cluster

Separación multipedido. Comparte los cuatro endpoints de tiempo con picking batch y packing.

#### 58. GET `/api/cluster/picking_batchs`
**Módulo:** Picking cluster · **Cliente:** `get`

Listado de batches de cluster.

```json
{ "params": {} }
```
**Respuesta:** result.result = arreglo de batches de cluster.
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

#### 59. POST `/api/cluster/send_picking`
**Módulo:** Picking cluster · **Cliente:** `postPicking`

Envía una línea separada. La app siempre manda un único elemento en la lista.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_batch | int | number | |
| list_item | List\<Map\> | array de objeto | siempre un elemento |
| list_item[].id_move | int | number | |
| list_item[].product_id | int | number | |
| list_item[].id_lote | int | number | |
| list_item[].cantidad_separada | double | number | topada a la cantidad solicitada si hay exceso |
| list_item[].observacion | String | string | "Sin novedad" por defecto |
| list_item[].time_line | double | number | 10.0 por defecto |
| list_item[].id_operario | int | number | |
| list_item[].fecha_transaccion | String | string | |

```json
{ "params": {
    "id_batch": 412,
    "list_item": [
      { "id_move": 99213, "product_id": 4821, "id_lote": 771,
        "cantidad_separada": 12.0, "observacion": "Sin novedad",
        "time_line": 34.0, "id_operario": 7,
        "fecha_transaccion": "2026-08-14 09:31:02" } ] } }
```
**Respuesta:** result.code 200, o result.msg con el motivo del rechazo.
```dart
// El datasource devuelve el cuerpo crudo; el caso de uso lo decodifica.
class Envelope {
  int? code;    // result.code  == 200 -> "Ok"
  String? msg;  // result.msg   motivo del rechazo
}
```

#### 60. POST `/api/cluster/validate_pedido/id`
**Módulo:** Picking cluster · **Cliente:** `postPicking`

Valida un pedido del cluster contra una ubicación.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_pedido | int | number | |
| id_location | int | number | |
| list_items | List\<Map\> | array de {"id": number} | |

```json
{ "params": { "id_pedido": 5521, "id_location": 18,
              "list_items": [ {"id": 99213}, {"id": 99214} ] } }
```
**Respuesta:** result.code 200, o result.msg con el motivo del rechazo.
```dart
// La app lee result.code == 200; si no, lanza result.msg.
// Un objeto "error" se propaga como error.message.
class Envelope { int? code; String? msg; }
```

### Packing

Empaque por batch, consolidado y por pedido. Reutiliza los contratos de transferencias para asignación, cierre y tiempos.

#### 61. GET `/api/batch_packing`
**Módulo:** Packing · **Cliente:** `getValidation`

Listado de batches de empaque.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de batches de packing.
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

#### 62. GET `/api/batch_packing_unificado`
**Módulo:** Packing · **Cliente:** `getValidation`

Listado de batches de empaque consolidado.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de batches consolidados.
```dart
// Mismo modelo que el endpoint 61.
class PackingModelResponseResult {
  int? code;                        // "code"
  bool? updateVersion;              // "update_version"
  List<BatchPackingModel>? result;  // "result"  ver §7 · BatchPackingModel
}
```

#### 63. GET `/api/transferencias/pack`
**Módulo:** Packing · **Cliente:** `getValidation`

Listado de pedidos por empacar.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de pedidos.
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

#### 64. POST `/api/send_packing`
**Módulo:** Packing · **Cliente:** `postPacking`

Cierra un paquete de un batch de empaque.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_batch | int | number | |
| is_sticker | bool | boolean | |
| is_certificate | bool | boolean | |
| tipo_paquete | String | string | |
| peso_caja | dynamic | number | |
| peso_total_paquete | dynamic | number | |
| list_item | List\<ListItem\> | array de objeto | |
| list_item[].id_move | int | number | |
| list_item[].product_id | int | number | |
| list_item[].lote | String | string | |
| list_item[].location_id | int | number | |
| list_item[].cantidad_separada | dynamic | number | |
| list_item[].observacion | String | string | |
| list_item[].unidad_medida | String | string | |
| list_item[].id_operario | int | number | |
| list_item[].fecha_transaccion | String | string | |
| list_item[].time_line | dynamic | number | |
| list_item[].dividir | bool | boolean | |

```json
{ "params": {
    "id_batch": 412, "is_sticker": true, "is_certificate": false,
    "tipo_paquete": "Caja L", "peso_caja": 0.8, "peso_total_paquete": 14.2,
    "list_item": [
      { "id_move": 99213, "product_id": 4821, "lote": "L-2026-08-14",
        "location_id": 18, "cantidad_separada": 12, "observacion": "Sin novedad",
        "unidad_medida": "UND", "id_operario": 7,
        "fecha_transaccion": "2026-08-14 09:31:02", "time_line": 34,
        "dividir": false } ] } }
```
**Respuesta:** result.code + paquete creado.
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

#### 65. POST `/api/send_pack_unified`
**Módulo:** Packing · **Cliente:** `postPacking`

Cierra un paquete consolidado. Igual que send_packing pero sin tipo_paquete ni peso_caja.

```json
{ "params": { "id_batch": 412, "is_sticker": true, "is_certificate": false,
              "peso_total_paquete": 14.2, "list_item": [ … ] } }
```
**Respuesta:** result.code + paquete creado.
```dart
// Mismo modelo que el endpoint 64 (ResponseSendPacking).
class ResponseSendPackingResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"  paquete creado y sus líneas
}
```

#### 66. POST `/api/send_cluster/pack`
**Módulo:** Packing · **Cliente:** `postPacking`

Cierra un paquete de un pedido de cluster. La app elige entre esta ruta y send_transfer/pack según el origen del pedido.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_transferencia | int | number | |
| is_sticker | bool | boolean | |
| is_certificate | bool | boolean | |
| tipo_paquete | String | string | |
| peso_caja | dynamic | number | |
| peso_total_paquete | dynamic | number | |
| list_items | List\<ListItemPack\> | array de objeto | |
| list_items[].id_move | int | number | |
| list_items[].id_producto | int | number | |
| list_items[].cantidad_enviada | dynamic | number | |
| list_items[].id_ubicacion_origen | int | number | |
| list_items[].id_ubicacion_destino | int | number | |
| list_items[].id_lote | int | number | |
| list_items[].id_operario | int | number | |
| list_items[].fecha_transaccion | String | string | |
| list_items[].time_line | dynamic | number | |
| list_items[].observacion | String | string | |

```json
{ "params": {
    "id_transferencia": 5521, "is_sticker": true, "is_certificate": false,
    "tipo_paquete": "Caja L", "peso_caja": 0.8, "peso_total_paquete": 14.2,
    "list_items": [
      { "id_move": 99213, "id_producto": 4821, "cantidad_enviada": 6,
        "id_ubicacion_origen": 12, "id_ubicacion_destino": 18, "id_lote": 771,
        "id_operario": 7, "fecha_transaccion": "2026-08-14 09:31:02",
        "time_line": 22, "observacion": "Sin novedad" } ] } }
```
**Respuesta:** result.code + paquete creado.
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

#### 67. POST `/api/send_transfer/pack`
**Módulo:** Packing · **Cliente:** `postPacking`

Cierra un paquete de un pedido de transferencia. Cuerpo idéntico a send_cluster/pack.

```json
{ "params": { "id_transferencia": 5521, "is_sticker": true,
              "is_certificate": false, "tipo_paquete": "Caja L",
              "peso_caja": 0.8, "peso_total_paquete": 14.2,
              "list_items": [ … ] } }
```
**Respuesta:** result.code + paquete creado.
```dart
// Mismo modelo que el endpoint 66 (ResponseSendPack).
class ResponseSendPackResult {
  int? code;                        // "code"
  String? msg;                      // "msg"
  List<ResultElementPack>? result;  // "result"  paquete creado
}
```

#### 68. POST `/api/unpacking`
**Módulo:** Packing · **Cliente:** `postPacking`

Deshace un paquete de un batch.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_batch | int | number | |
| id_paquete | int | number | |
| list_item | List\<ListItemUnpack\> | array de objeto | |
| list_item[].id_move | int | number | |
| list_item[].product_id | int | number | |
| list_item[].lote | dynamic | number \| string | |
| list_item[].location_id | int | number | |
| list_item[].cantidad_separada | dynamic | number | |
| list_item[].observacion | String | string | |
| list_item[].id_operario | int | number | |

```json
{ "params": {
    "id_batch": 412, "id_paquete": 88,
    "list_item": [
      { "id_move": 99213, "product_id": 4821, "lote": "L-2026-08-14",
        "location_id": 18, "cantidad_separada": 12,
        "observacion": "Reempaque", "id_operario": 7 } ] } }
```
**Respuesta:** result.code 200 al deshacer.
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

#### 69. POST `/api/unpack_unified`
**Módulo:** Packing · **Cliente:** `postPacking`

Deshace un paquete consolidado. Cuerpo idéntico a unpacking.

```json
{ "params": { "id_batch": 412, "id_paquete": 88, "list_item": [ … ] } }
```
**Respuesta:** result.code 200 al deshacer.
```dart
// Mismo modelo que el endpoint 68 (UnPacking).
class UnPackingResult {
  int? code;                       // "code"
  String? msg;                     // "msg"
  List<UnPackingElement>? result;  // "result"
}
```

#### 70. POST `/api/transferencias/unpacking`
**Módulo:** Packing · **Cliente:** `postPacking`

Deshace un paquete de un pedido. La línea lleva menos campos que en el flujo de batch.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_transferencia | int | number | |
| id_paquete | int | number | |
| list_items | List\<ListItemUnpack\> | array de objeto | |
| list_items[].id_move | int | number | |
| list_items[].observacion | String | string | |
| list_items[].id_operario | int | number | |

```json
{ "params": {
    "id_transferencia": 5521, "id_paquete": 88,
    "list_items": [
      { "id_move": 99213, "observacion": "Reempaque", "id_operario": 7 } ] } }
```
**Respuesta:** result.code 200 al deshacer.
```dart
// Mismo modelo que el endpoint 68 (UnPacking).
class UnPackingResult {
  int? code;                       // "code"
  String? msg;                     // "msg"
  List<UnPackingElement>? result;  // "result"
}
```

#### 71. POST `/api/cluster/packing/ubicacion`
**Módulo:** Packing · **Cliente:** `postPacking`

Asigna ubicación de destino a uno o varios paquetes ya cerrados.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| movimientos | List\<MovimientoPack\> | array de objeto | |
| movimientos[].id_transferencia | int | number | |
| movimientos[].id_paquete | int | number | |
| movimientos[].id_ubicacion_destino | int | number | |

```json
{ "params": { "movimientos": [
    { "id_transferencia": 5521, "id_paquete": 88,
      "id_ubicacion_destino": 18 } ] } }
```
**Respuesta:** result.code 200 al asignar.
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

#### 72. POST `/api/send_image_linea_recepcion/batch`
**Módulo:** Packing · **También en:** Variante batch del endpoint 27 · **Cliente:** `postMultipart` · `postMultipartManual`

Adjunta foto y temperatura a una línea de packing. multipart/form-data.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| image_data | File | parte de archivo | JPEG o PNG; la variante manual no envía archivo |
| move_line_id | String | campo de texto | |
| temperatura | String | campo de texto | |

**Respuesta:** Confirmación del adjunto.
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

#### 73. POST `/api/send_imagen_observation/batch`
**Módulo:** Packing · **También en:** Variante batch del endpoint 28 · **Cliente:** `postMultipartDynamic`

Adjunta la foto que respalda una novedad. multipart/form-data.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| image_data | File | parte de archivo | JPEG o PNG |
| move_line_id | String | campo de texto | en Recepción el campo se llama id_move |

**Respuesta:** Confirmación del adjunto.
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

### Expedición

Cargue y despacho. Único módulo con validación offline: si no hay red, valida en local y encola el envío.

#### 74. GET `/api/transferencias/out`
**Módulo:** Expedición · **Cliente:** `getValidation`

Listado de expediciones asignables.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** code + msg + listado de expediciones.
```dart
// El modelo aplana el sobre: lee directamente dentro de "result".
class ExpedicionResponseModel {
  int? code;                             // result.code
  bool? updateVersion;                   // result.update_version
  String? msg;                           // result.msg
  List<ExpedicionPedidoModel> result;    // result.result  ver §7
}
```

#### 75. POST `/api/send_out`
**Módulo:** Expedición · **Cliente:** `postPacking`

Valida uno o varios paquetes contra la expedición. La validación individual manda una lista de un elemento; la múltiple manda todos los seleccionados.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| device_id | String | string | MAC o IMEI |
| expedition_id | int | number | |
| packing_id | List\<int\> | array de number | uno o varios paquetes |

```json
{ "params": { "device_id": "AA:BB:CC:DD:EE:FF", "expedition_id": 771,
              "packing_id": [88, 89, 90] } }
```
**Respuesta:** result.code 200, o result.msg con el motivo del rechazo.
```dart
// La app lee result.code == 200; result.msg lleva el motivo del rechazo.
// Un HTTP >= 400 se trata como fallo de red y dispara la cola offline.
class Envelope { int? code; String? msg; }
```
> Se invoca con el aviso global de red desactivado: sin conexión, la app valida en local y encola el envío en lugar de mostrar error.

#### 76. POST `/api/out_return`
**Módulo:** Expedición · **Cliente:** `postPacking`

Deshace la validación de un paquete o ítem suelto. Mismo cuerpo que send_out.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| device_id | String | string | MAC o IMEI |
| expedition_id | int | number | |
| packing_id | List\<int\> | array de number | |

```json
{ "params": { "device_id": "AA:BB:CC:DD:EE:FF", "expedition_id": 771,
              "packing_id": [88] } }
```
**Respuesta:** result.code 200 al deshacer.
```dart
// La app lee result.code == 200; result.msg lleva el motivo del rechazo.
class Envelope { int? code; String? msg; }
```

#### 77. POST `/api/complete_out`
**Módulo:** Expedición · **Cliente:** `postPacking`

Confirma y cierra la expedición.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_transferencia | int | number | identificador de la expedición |
| crear_backorder | bool | boolean | true cuando el operario decide dejar pendiente lo no validado |

```json
{ "params": { "id_transferencia": 771, "crear_backorder": false } }
```
**Respuesta:** result.code 200, o result.msg propagado literal.
```dart
// Sin cuerpo tipado: la app solo comprueba result.code == 200.
// Si falla, propaga literal result.msg (o error.message).
class Envelope { int? code; String? msg; }
// msg con "expiry.picking.confirmation" -> la UI ofrece forzar vencidos.
```
> El msg se propaga sin modificar: si contiene expiry.picking.confirmation, la app ofrece reintentar forzando productos vencidos.

### Conteo

Inventario cíclico sobre órdenes de conteo generadas en Odoo.

#### 78. GET `/api/inventory/all_orders`
**Módulo:** Conteo · **Cliente:** `getValidation`

Listado de órdenes de conteo asignables.

```json
{ "params": { "device_id": "…", "version_app": "1.4.2" } }
```
**Respuesta:** result.result = arreglo de órdenes de conteo.
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

#### 79. POST `/api/inventory/send_inventory`
**Módulo:** Conteo · **Cliente:** `postPicking`

Envía una línea contada. La app siempre manda un único elemento en la lista.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| order_id | int | number | 0 cuando es nulo |
| list_items | List\<Map\> | array de objeto | siempre un elemento |
| list_items[].line_id | String | string | identificador numérico serializado como texto |
| list_items[].quantity_counted | dynamic | number | |
| list_items[].observation | String | string | actualmente se envía siempre vacío |
| list_items[].time_line | dynamic | number | |
| list_items[].fecha_transaccion | String | string | |
| list_items[].id_operario | int | number | |
| list_items[].product_id | int | number | |
| list_items[].location_id | dynamic | number \| "" | cadena vacía cuando el identificador es 0 |
| list_items[].lote_id | dynamic | number \| "" | cadena vacía cuando es nulo |

```json
{ "params": {
    "order_id": 88,
    "list_items": [
      { "line_id": "99213", "quantity_counted": 12, "observation": "",
        "time_line": 34, "fecha_transaccion": "2026-08-14 09:31:02",
        "id_operario": 7, "product_id": 4821, "location_id": 18,
        "lote_id": 771 } ] } }
```
**Respuesta:** result.code 200 al registrar el conteo.
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

#### 80. POST `/api/inventory/delete_line`
**Módulo:** Conteo · **Cliente:** `postPicking`

Borra el conteo registrado en una línea.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| line_id | int | number | |

```json
{ "params": { "line_id": 99213 } }
```
**Respuesta:** result.code 200 al borrar.
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

#### 81. POST `/api/inventory/remove_line`
**Módulo:** Conteo · **Cliente:** `postPicking`

Elimina la línea completa de la orden de conteo.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| line_id | int | number | |

```json
{ "params": { "line_id": 99213 } }
```
**Respuesta:** result.code 200 al eliminar.
```dart
// Mismo modelo que el endpoint 80 (ResponseDeleteProduct).
class ResponseDeleteProductResult {
  int? code;                    // "code"
  String? msg;                  // "msg"
  List<ResultElement>? result;  // "result"
}
```

### Inventario

Único módulo bajo el prefijo /op/api. Sincroniza el catálogo completo al dispositivo para consulta y ajuste offline.

#### 82. GET `/op/api/product_quants`
**Módulo:** Inventario · **Cliente:** `getInventario`

Sincronización completa de productos y códigos de barras. La respuesta es grande: se procesa en un hilo aparte para no bloquear la interfaz.

```json
{ "params": {} }
```
**Respuesta:** Productos y códigos de barras para la base local del terminal.
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

#### 83. GET `/op/api/quant_post`
**Módulo:** Inventario · **Cliente:** `postInventario`

Registra la cantidad contada de un producto en una ubicación. GET con cuerpo JSON pese al nombre del método cliente.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| location_id | dynamic | number | |
| product_id | dynamic | number | |
| lot_id | dynamic | number \| null | |
| quantity | dynamic | number | |
| user_id | int | number | |

```json
{ "params": { "location_id": 18, "product_id": 4821, "lot_id": 771,
              "quantity": 12, "user_id": 7 } }
```
**Respuesta:** result.code + resultado del ajuste.
```dart
class ResultadoEnvioInventarioModel {
  String? status;   // result.status
  String? message;  // result.message
  int? data;        // result.data
}
// error.code == 100 -> SessionExpiredException
```

### Info rápida

Consulta por escaneo y edición puntual de maestros desde el terminal.

#### 84. GET `/api/transferencias/quickinfo`
**Módulo:** Info rápida · **Cliente:** `getInfo`

Consulta por código de barras: devuelve producto o ubicación según lo escaneado. GET con cuerpo JSON.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| device_id | String | string | MAC o IMEI |
| barcode | String | string | |
| version_app | String | string | |

```json
{ "params": { "device_id": "AA:BB:CC:DD:EE:FF", "barcode": "7702001234567",
              "version_app": "1.4.2" } }
```
**Respuesta:** result.result con la información del producto o de la ubicación.
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

#### 85. GET `/api/transferencias/quickinfo/id`
**Módulo:** Info rápida · **Cliente:** `getInfo`

Consulta por identificador. El cuerpo cambia según se consulte un producto o una ubicación. GET con cuerpo JSON.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| device_id | String | string | MAC o IMEI |
| id_product | int | number | solo al consultar un producto |
| id_location | int | number | solo al consultar una ubicación |
| version_app | String | string | |

```json
// producto
{ "params": { "device_id": "…", "id_product": 4821, "version_app": "1.4.2" } }

// ubicación
{ "params": { "device_id": "…", "id_location": 18, "version_app": "1.4.2" } }
```
**Respuesta:** result.result con la información solicitada.
```dart
// Mismo modelo que el endpoint 84 (InfoRapida).
class InfoRapidaResult {
  int? code;            // "code"
  String? type;         // "type"
  String? msg;          // "msg"
  InfoResult? result;   // "result"  ver §7 · InfoResult
}
```

#### 86. POST `/api/crear_transferencia`
**Módulo:** Info rápida · **Cliente:** `postPacking`

Crea un movimiento puntual de una sola línea desde la consulta rápida.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| id_almacen | int | number | |
| id_move | int | number | |
| id_producto | int | number | |
| id_propietario | int | number | |
| id_lote | int | number | |
| id_ubicacion_origen | int | number | |
| id_ubicacion_destino | int | number | |
| cantidad_enviada | dynamic | number | |
| id_operario | int | number | |
| time_line | dynamic | number | |
| fecha_transaccion | String | string | |
| observacion | String | string | |
| date_start | String | string | |
| date_end | String | string | |

```json
{ "params": {
    "id_almacen": 1, "id_move": 99213, "id_producto": 4821,
    "id_propietario": 1, "id_lote": 771, "id_ubicacion_origen": 12,
    "id_ubicacion_destino": 18, "cantidad_enviada": 6, "id_operario": 7,
    "time_line": 22, "fecha_transaccion": "2026-08-14 09:31:02",
    "observacion": "Reubicación", "date_start": "2026-08-14 09:30:00",
    "date_end": "2026-08-14 09:31:02" } }
```
**Respuesta:** result.code + movimiento creado.
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

#### 87. POST `/api/update_product`
**Módulo:** Info rápida · **Cliente:** `postPacking`

Edita los datos maestros de un producto.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| product_id | int | number | |
| default_code | String | string | |
| name | String | string | |
| barcode | String | string | |
| list_price | double | number | |
| weight | double | number | |
| volume | double | number | |

```json
{ "params": { "product_id": 4821, "default_code": "REF-4821",
              "name": "Caja 500 ml", "barcode": "7702001234567",
              "list_price": 12500.0, "weight": 0.62, "volume": 0.004 } }
```
**Respuesta:** result.code 200 al actualizar.
```dart
// Devuelve el mismo modelo de consulta, con el producto ya actualizado.
class InfoRapidaResult {
  int? code;           // "code"
  String? msg;         // "msg"
  InfoResult? result;  // "result"  ver §7 · InfoResult
}
```

#### 88. POST `/api/update_location`
**Módulo:** Info rápida · **Cliente:** `postPacking`

Edita los datos maestros de una ubicación.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| location_id | int | number | |
| name | String | string | |
| barcode | String | string | |

```json
{ "params": { "location_id": 18, "name": "BOD-A-01-03",
              "barcode": "UB-000018" } }
```
**Respuesta:** result.code 200 al actualizar.
```dart
// Devuelve el mismo modelo de consulta, con la ubicación ya actualizada.
class InfoRapidaResult {
  int? code;           // "code"
  String? msg;         // "msg"
  InfoResult? result;  // "result"  ver §7 · InfoResult
}
```

### Recepción multiusuario

Recepción colaborativa sobre una misma entrada: varios operarios toman productos de un pool común, cada toma queda registrada como una asignación (claim) y el avance se refleja para todos. Es el único bloque bajo el prefijo `/api/receipt`, y el único cuyas respuestas viajan en la envoltura `status / message / data` en lugar de `code / msg / result`. Para el lote reutiliza los endpoints 8 y 9; la ubicación de destino se resuelve contra la base local del terminal, sin endpoint propio.

#### 89. POST `/api/receipt/sessions`
**Módulo:** Recepción multiusuario · **Cliente:** `postPacking`

Listado de sesiones de recepción multiusuario disponibles para el operario.

```json
{ "params": {} }
```
**Respuesta:** result.data = arreglo de sesiones.
```dart
// result.data -> List<RecepcionSessionModel>
class RecepcionSessionModel {
  int? sessionId;               // "id"
  String? name;                 // "name"
  String? state;                // "state"
  int? pickingId;               // "picking_id"
  String? pickingName;          // "picking_name"
  double? progressPercent;      // "progress_percent"
  int? pendingTasks;            // "pending_tasks"
  int? proveedorId;             // "proveedor_id"
  String? proveedor;            // "proveedor"
  double? pesoTotal;            // "peso_total"
  int? numeroLineas;            // "numero_lineas"
  double? numeroItems;          // "numero_items"
  String? origin;               // "origin"
  String? priority;             // "priority"
  int? warehouseId;             // "warehouse_id"
  String? warehouseName;        // "warehouse_name"
  String? pickingType;          // "picking_type"
  int? backorderId;             // "backorder_id"
  String? backorderName;        // "backorder_name"
  bool? showCheckAvailability;  // "show_check_availability"
  bool? manejaTemperatura;      // "maneja_temperatura"
  double? temperatura;          // "temperatura"
  bool? manejoPropietario;      // "manejo_propietario"
  String? propietario;          // "propietario"
}
// El sobre es status / message / data:
// status != "success" -> ServerException(message).
// Cada sesión se cachea en la tabla local recepcion_sessions.
```
> Ruta JSON-RPC de Odoo: solo acepta POST. Un GET responde 405 Method Not Allowed.

#### 90. POST `/api/receipt/session/{session_id}/pool`
**Módulo:** Recepción multiusuario · **Cliente:** `postPacking`

Productos y tareas libres de la sesión en este instante. Se llama en cada refresco de la pantalla de detalle, así que va sin diálogo de carga.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| session_id | int | number | en la ruta |
| verification | bool | boolean | solo se envía cuando es true |

```json
// tab Por hacer: solo lo reclamable ahora
{ "params": {} }

// tab Terminados: incluye tareas agotadas con historial
{ "params": { "verification": true } }
```
**Respuesta:** result.data = arreglo de tareas del pool.
```dart
// result.data -> List<RecepcionPoolItemModel>
class RecepcionPoolItemModel {
  int? taskId;                // "task_id"
  int? sessionId;             // no viene en el json: es el id de la ruta
  int? productId;             // "product_id"
  String? productName;        // "product_name"
  String? defaultCode;        // "default_code"
  String? barcode;            // "barcode"
  double? qtyDemanded;        // "qty_demanded"
  double? qtyAsignada;        // "qty_asignada"
  double? qtyRecibida;        // "qty_recibida"
  double? qtyAvailable;       // "qty_available"   lo que queda por reclamar
  String? uom;                // "uom"
  int? asignacionesActivas;   // "asignaciones_activas"
  double? qtyClaimed;         // "qty_claimed"
  double? qtyDone;            // "qty_done"
  String? taskState;          // "task_state"
  bool? tieneObservaciones;   // "tiene_observaciones"
  List<AsignacionObservacion> observaciones;  // "observaciones"
}
class AsignacionObservacion {
  int? asignacionId;        // "asignacion_id"
  int? operarioId;          // "operario_id"
  String? operario;         // "operario"
  String? state;            // "state"
  double? qtyAsignada;      // "qty_asignada"
  double? qtyRecibida;      // "qty_recibida"
  String? observacion;      // "observacion"
  String? notaCorreccion;   // "nota_correccion"
  String? fechaAsignacion;  // "fecha_asignacion"
  String? fechaCompletado;  // "fecha_completado"
  int? lotId;               // "lot_id"
  String? lotName;          // "lot_name"
  int? locationDestId;      // "location_dest_id"
  String? locationDestName; // "location_dest_name"
  double? timeSeconds;      // "time_seconds"
  double? tiempoHoras;      // "tiempo_horas"
  int? claimId;             // "claim_id"
}
// El pool se cachea en la tabla local recepcion_session_pool;
// las observaciones se guardan serializadas en una columna JSON.
```
> **verification** cambia qué devuelve el backend: con el flag activo aparecen tareas con `qty_available` en 0 que ya tienen asignaciones; sin él, esas tareas no vienen en la respuesta.

#### 91. POST `/api/receipt/claim`
**Módulo:** Recepción multiusuario · **Cliente:** `postPacking`

Reclama (toma) un producto libre del pool para el operario actual.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| session_id | int | number | |
| product_id | int | number | |

```json
{ "params": { "session_id": 118, "product_id": 4821 } }
```
**Respuesta:** result.data = la asignación creada.
```dart
// result.data -> RecepcionClaimModel
class RecepcionClaimModel {
  int? id;                      // "id"          id de la asignación
  int? taskId;                  // "task_id"
  int? productId;               // "product_id"
  String? productName;          // "product_name"
  String? barcode;              // "barcode"
  double? qtyAsignada;          // "qty_asignada"
  double? qtyRecibida;          // "qty_recibida"
  String? uom;                  // "uom"
  String? state;                // "state"       claimed | done
  int? lotId;                   // "lot_id"      false cuando no maneja lote
  String? lotName;              // "lot_name"
  String? fechaAsignacion;      // "fecha_asignacion"
  String? bloqueadoHasta;       // "bloqueado_hasta"
  String? observacion;          // "observacion"
  String? notaCorreccion;       // "nota_correccion"
  int? locationId;              // "location_id"
  String? locationName;         // "location_name"
  String? locationBarcode;      // "location_barcode"
  int? locationDestId;          // "location_dest_id"
  String? locationDestName;     // "location_dest_name"
  String? locationDestBarcode;  // "location_dest_barcode"
  int? idMove;                  // "id_move"
  String? productCode;          // "product_code"
  String? productBarcode;       // "product_barcode"
  String? productTracking;      // "product_tracking"
  String? fechaVencimiento;     // "fecha_vencimiento"
  int? diasVencimiento;         // "dias_vencimiento"
  bool? useExpirationDate;      // "use_expiration_date"
  double? weight;               // "weight"
  double? cantidadFaltante;     // "cantidad_faltante"
  bool? manejaTemperatura;      // "maneja_temperatura"
  double? temperatura;          // "temperatura"
  bool? manejaSegundaUnidad;    // "maneja_segunda_unidad"
  String? uomSegundaUnidad;     // "uom_segunda_unidad"
  List<Barcodes> otherBarcodes; // "other_barcodes"
  List<Barcodes> productPacking;// "product_packing"
}
```
> Si el backend responde `status: error` —por ejemplo, otro operario tomó el producto primero— la app muestra el `message` tal cual y no navega a la pantalla de escaneo.

#### 92. POST `/api/receipt/session/{session_id}/my_claims`
**Módulo:** Recepción multiusuario · **Cliente:** `postPacking`

Productos que el operario actual ya reclamó y sigue trabajando en esta sesión.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| session_id | int | number | en la ruta |

```json
{ "params": {} }
```
**Respuesta:** result.data = arreglo de asignaciones, con el mismo objeto que devuelve /receipt/claim.
```dart
// Mismo objeto que el endpoint 91, en lista.
// result.data -> List<RecepcionClaimModel>
```

#### 93. POST `/api/receipt/claim/{claim_id}/release`
**Módulo:** Recepción multiusuario · **Cliente:** `postPacking`

Libera una asignación: la cantidad vuelve al pool y queda disponible para otro operario.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| claim_id | int | number | en la ruta |

```json
{ "params": {} }
```
**Respuesta:** result.status = success; la app no lee cuerpo.
```dart
// La app solo comprueba result.status == "success".
class Envelope { String? status; String? message; dynamic data; }
```

#### 94. POST `/api/receipt/claim/{claim_id}/done`
**Módulo:** Recepción multiusuario · **Cliente:** `postPacking`

Confirma la recepción de la cantidad trabajada en esta asignación y la cierra.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| claim_id | int | number | en la ruta |
| jsonrpc | String | string | siempre 2.0 |
| method | String | string | siempre call |
| params.qty_done | double | number | cantidad realmente recibida |
| params.lot_id | int | number | lote elegido o recién creado |
| params.ubicacion_destino | int | number | id de la ubicación de destino |
| params.time_line | int | number | segundos desde que se validó el producto hasta el envío |
| params.observation | String | string | novedad; vacío cuando no hay |

```json
{ "jsonrpc": "2.0", "method": "call",
  "params": { "qty_done": 12, "lot_id": 771, "ubicacion_destino": 18,
              "time_line": 34, "observation": "Sin novedad" } }
```
**Respuesta:** result.data = la asignación actualizada, con state en done y qty_recibida al día.
```dart
// result.data -> RecepcionClaimModel, ya cerrado (mismo modelo que el endpoint 91).
```
> A diferencia del resto de `/receipt/*`, este endpoint y `/undo` esperan el sobre JSON-RPC completo en el cuerpo, no solo `{"params": …}`.

#### 95. POST `/api/receipt/claim/{claim_id}/undo`
**Módulo:** Recepción multiusuario · **Cliente:** `postPacking`

Deshace una recepción ya terminada y devuelve la cantidad al pool. El motivo es obligatorio.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| claim_id | int | number | en la ruta |
| jsonrpc | String | string | siempre 2.0 |
| method | String | string | siempre call |
| params.observacion | String | string | motivo de la corrección |

```json
{ "jsonrpc": "2.0", "method": "call",
  "params": { "observacion": "Cantidad mal digitada" } }
```
**Respuesta:** result.status = success; la app no lee cuerpo.
```dart
// La app solo comprueba result.status == "success".
class Envelope { String? status; String? message; dynamic data; }
```

#### 96. POST `/api/receipt/picking/{picking_id}`
**Módulo:** Recepción multiusuario · **Cliente:** `postPacking`

Estado actualizado de la sesión (progress_percent, pending_tasks…). Se pide al entrar al tab Detalle para refrescar lo que trajo /receipt/sessions, que puede haber quedado atrás si otro operario avanzó mientras tanto.

| Campo | Tipo Dart | Tipo JSON | Nota |
|---|---|---|---|
| picking_id | int | number | en la ruta |

```json
{ "params": {} }
```
**Respuesta:** result.data con el encabezado de la sesión.
```dart
// result.data -> RecepcionSessionModel (mismo modelo que el endpoint 89).
// Se ignoran los arrays tasks / my_claims / pool que vienen dentro de data:
// cada tab los pide con su propio endpoint (90 y 92).
```

---

## §4. Matriz de replicación

Rutas consumidas desde más de un módulo. Un cambio de contrato en cualquiera de ellas impacta a todos los módulos listados.

| Ruta | Módulos que la consumen |
|---|---|
| `/api/lotes/{product_id}` | Inventario · Recepción · Recepción multiusuario · Devoluciones · Picking cluster |
| `/api/create_lote` | Inventario · Recepción · Recepción multiusuario · Devoluciones · Picking cluster |
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
| `/api/send_image_linea_recepcion` ↔ `/batch` | Recepción individual ↔ Packing y Recepción batch |
| `/api/send_imagen_observation` ↔ `/batch` | Recepción individual ↔ Packing y Recepción batch |

> **Nota de arquitectura.** El módulo nuevo de picking (Clean Architecture) y las pantallas legacy son *pantallas gemelas* sobre los mismos repositorios: la versión nueva delega en la legacy, así que no duplican endpoints ni contratos.

---

## §5. Servicios que no son el backend Odoo

| Servicio | URL | Uso |
|---|---|---|
| Lectura de temperatura por imagen | `POST https://apitemperature.360software.com.co/extract-temp-humidity` | Recepción y Packing. Multipart con la parte `image` (JPEG o PNG). Sin cookie de sesión; cabecera `Accept: application/json`. |
| WebSocket de notificaciones | `wss://{base}/websocket` | Notificaciones en tiempo real. Deriva de la URL de la instancia sustituyendo `https://` por `wss://`. |

---

## §6. Códigos y manejo de errores

| Situación | Cómo llega | Qué hace la app |
|---|---|---|
| Éxito | 200 · result.code == 200 | Continúa el flujo |
| Rechazo de negocio | 200 · result.code != 200 | Muestra `result.msg` al operario |
| Rechazo de negocio en `/receipt/*` | 200 · result.status != "success" | Muestra `result.message` tal cual llega |
| Sesión expirada | 500 · error.code == 100 | Cierra sesión y fuerza re-login |
| Error de Odoo | 500 · error.message | Muestra el mensaje del servidor |
| Sin conexión | 404 sintético local | Aviso de red. Expedición es la excepción: valida en local y encola el envío |
| Timeout | 408 sintético local | Aviso de tiempo de espera agotado |
| Ruta inexistente | 404 real | Aviso indicando revisar el backend |

---

## §7. Estructuras Dart compartidas

Modelos que aparecen en varias respuestas: documentos, líneas de documento y el perfil de configuración. El comentario junto a cada campo es la clave JSON que llega del backend.

La envoltura JSON-RPC es común a todas las respuestas Odoo:

```dart
class Envelope {
  String? jsonrpc;   // "jsonrpc"  siempre "2.0"
  dynamic id;        // "id"       siempre null
  Result? result;    // "result"
}
```

Las estructuras siguientes se repiten en varias respuestas. Las fichas de cada endpoint remiten aquí en lugar de repetirlas.

### ResultEntrada
Elemento de `result.result` en `/api/recepciones` y `/api/recepciones/devs` (endpoints 16 y 17).

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
Elemento de `result.result` en `/api/recepciones/batchs` (endpoint 18).

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
Elemento de `result.result` en `/api/transferencias`, `/api/transferencias/producto_terminado` y `/api/comprobar_disponibilidad` (endpoints 30, 31 y 38).

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
Elemento de `result.result` en `/api/batchs` y `/api/batchs/componentes` (endpoints 43 y 44).

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
Elemento de `result.result` en `/api/cluster/picking_batchs` (endpoint 58).

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
Elemento de `result.result` en `/api/batch_packing` y `/api/batch_packing_unificado` (endpoints 61 y 62).

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
Elemento de `result.result` en `/api/transferencias/pack` (endpoint 63).

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
Elemento de `result.result` en `/api/transferencias/out` (endpoint 74). El modelo reparte los ítems en cuatro listas según su estado de validación.

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
Elemento de `result.data` en `/api/inventory/all_orders` (endpoint 78).

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
Cuerpo de `result.result` en `/api/configurations` (endpoint 3). Es el interruptor maestro de la app: cada bandera habilita o esconde una parte de la interfaz.

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

---

*Documento generado a partir del artifact "Mapa de Endpoints WMS" · rama desarrollo · septiembre 2026*
