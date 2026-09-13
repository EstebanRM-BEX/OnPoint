import 'dart:collection';

import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';

/// Cache en memoria del catálogo de productos (tbl_product de inventario),
/// compartido por toda la app. Mismo problema que UbicacionesCacheService:
/// 5-6 blocs (InventarioBloc/InventarioLocalDataSource, ConteoBloc,
/// DevolucionesBloc, InfoRapidaBloc, CreateTransferBloc) hacían su propia
/// consulta y guardaban su propia copia completa, para siempre.
///
/// A diferencia de ubicaciones, acá hay DOS consultas realmente distintas
/// sobre la misma tabla (confirmado en product_inventario_repository.dart):
/// - [getAll]: `SELECT *` — todas las filas (puede haber varias por
///   producto, según ubicación/almacén).
/// - [getAllUnique]: `SELECT * ... GROUP BY product_id` — una fila por
///   producto. NO son el mismo dato, se cachean por separado.
@lazySingleton
class ProductosCacheService {
  List<Product>? _cacheAll;
  List<Product>? _cacheUnique;

  Future<List<Product>> getAll({bool forceRefresh = false}) async {
    // No memoizar un resultado vacío: puede ser que todavía no haya
    // terminado la sincronización de productos en background (post-login,
    // fire-and-forget) o un error transitorio de SQLite (el repositorio ya
    // atrapa esas excepciones y devuelve [] en vez de propagarlas) — en
    // cualquiera de los dos casos, cachear [] lo deja "vacío para siempre"
    // aunque el catálogo real ya esté disponible en la siguiente consulta.
    if (_cacheAll == null || _cacheAll!.isEmpty || forceRefresh) {
      _cacheAll = await DataBaseSqlite().productoInventarioRepository
          .getAllProducts();
    }
    // Una sola lista para toda la app: se auditaron todos los consumidores
    // (CreateTransferBloc, ConteoBloc, DevolucionesBloc, InfoRapidaBloc,
    // etc.) y se quitó el idioma `productos.clear(); if(...) productos =
    // response;` que antes hacía falta copiar para evitar (ese clear()
    // vaciaba el cache compartido Y la variable local `response` de esa
    // misma invocación, al ser el mismo objeto — bug real que costó
    // diagnosticar en "Crear Transferencia"). Ahora todos reasignan directo
    // (`productos = response;`), nunca mutan la lista in-place.
    // UnmodifiableListView es una vista (no copia el arreglo interno: sigue
    // siendo LA MISMA lista para todos) y convierte cualquier intento
    // futuro de `.clear()/.sort()/.add()` en un UnsupportedError inmediato
    // en vez de corromper el cache en silencio.
    return UnmodifiableListView(_cacheAll!);
  }

  Future<List<Product>> getAllUnique({bool forceRefresh = false}) async {
    if (_cacheUnique == null || _cacheUnique!.isEmpty || forceRefresh) {
      _cacheUnique = await DataBaseSqlite().productoInventarioRepository
          .getAllUniqueProducts();
    }
    return UnmodifiableListView(_cacheUnique!);
  }

  /// Recarga ambas variantes desde SQLite — usar tras una sincronización
  /// manual de productos.
  Future<void> refreshAll() async {
    await Future.wait([
      getAll(forceRefresh: true),
      getAllUnique(forceRefresh: true),
    ]);
  }

  void invalidate() {
    _cacheAll = null;
    _cacheUnique = null;
  }

  /// Aplica en memoria un evento de producto recibido por WebSocket — UPSERT:
  /// actualiza el producto si ya está en el cache, o lo agrega si es nuevo
  /// (el backend reusa el mismo evento "update" tanto para altas como para
  /// modificaciones). No toca SQLite — eso ya lo hace WebSocketService por
  /// su cuenta, de forma independiente, con el mismo payload. [data] usa las
  /// mismas keys que manda el backend (snake_case: `name`, `code`,
  /// `barcode`, `weight`, etc. — el mismo formato que espera
  /// `Product.fromMap`).
  ///
  /// `tbl_product` de inventario es en realidad una tabla de STOCK (una fila
  /// por producto+ubicación+lote), no un catálogo plano — por eso hay dos
  /// slots con objetos `Product` DISTINTOS para el mismo producto:
  /// - [_cacheAll] puede tener varias filas con ese `productId` (una por
  ///   ubicación/lote). Ahí solo se actualizan los campos que describen al
  ///   PRODUCTO en sí (nombre, código, barcode, peso, etc.) — nunca
  ///   ubicación/lote/cantidad, que son propios de cada fila y se
  ///   corromperían si una sola actualización los pisara en todas. Si no
  ///   hay ninguna fila con ese productId todavía, se agrega una nueva
  ///   (`Product.fromMap(data)` — sin ubicación/lote reales hasta el
  ///   próximo sync, pero visible de inmediato en listados por nombre).
  /// - [_cacheUnique] tiene una sola fila por producto (ya agrupada por el
  ///   GROUP BY) — ahí sí se aplican también los campos de esa fila
  ///   puntual (ubicación/lote/cantidad), igual que ya hacía antes
  ///   InfoRapidaBloc con su copia local. Si no existe, se agrega igual.
  ///
  /// Como [getAll]/[getAllUnique] devuelven una vista sobre estas mismas
  /// listas (no una copia), cualquier consumidor que ya haya cargado
  /// productos ve el cambio al instante — actualización o alta — sin
  /// recargar, siempre que lea del mismo slot que se está tocando acá.
  ///
  /// Devuelve `true` si tocó al menos un slot (para que el caller pueda
  /// evitar emitir un estado de "sincronizado" cuando ni siquiera había
  /// productos cargados todavía).
  bool applyWsProductUpsert(int productId, Map<String, dynamic> data) {
    bool touched = false;
    void applyProductFields(Product p) {
      if (data.containsKey('name')) p.name = data['name']?.toString();
      if (data.containsKey('code')) p.code = data['code'];
      if (data.containsKey('barcode')) p.barcode = data['barcode'];
      if (data.containsKey('tracking')) p.tracking = data['tracking']?.toString();
      if (data.containsKey('uom')) p.uom = data['uom'];
      if (data.containsKey('weight')) {
        p.weight = (data['weight'] as num?)?.toDouble();
      }
      if (data.containsKey('weight_uom_name')) {
        p.weightUomName = data['weight_uom_name'];
      }
      if (data.containsKey('volume')) {
        p.volume = (data['volume'] as num?)?.toDouble();
      }
      if (data.containsKey('volume_uom_name')) {
        p.volumeUomName = data['volume_uom_name'];
      }
      if (data.containsKey('category')) p.category = data['category'];
    }

    if (_cacheAll != null) {
      var foundInAll = false;
      for (final p in _cacheAll!) {
        if (p.productId == productId) {
          applyProductFields(p);
          foundInAll = true;
        }
      }
      if (!foundInAll) {
        _cacheAll!.add(Product.fromMap(data));
      }
      touched = true;
    }

    if (_cacheUnique != null) {
      final idx = _cacheUnique!.indexWhere((p) => p.productId == productId);
      if (idx != -1) {
        final p = _cacheUnique![idx];
        applyProductFields(p);
        if (data.containsKey('location_id')) {
          p.locationId = data['location_id'] as int?;
        }
        if (data.containsKey('location_name')) {
          p.locationName = data['location_name']?.toString();
        }
        if (data.containsKey('lot_id')) p.lotId = data['lot_id'];
        if (data.containsKey('lot_name')) p.lotName = data['lot_name'];
        if (data.containsKey('quantity')) p.quantity = data['quantity'];
        if (data.containsKey('expiration_time')) {
          p.expirationTime = data['expiration_time'];
        }
        if (data.containsKey('use_expiration_date')) {
          p.useExpirationDate = data['use_expiration_date'] == true ? 1 : 0;
        }
      } else {
        _cacheUnique!.add(Product.fromMap(data));
      }
      touched = true;
    }

    return touched;
  }
}
