import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/services/productos_cache_service.dart';
import 'package:wms_app/core/services/ubicaciones_cache_service.dart';
import 'package:wms_app/features/info_rapida/data/models/catalogo_mappers.dart';
import 'package:wms_app/features/info_rapida/data/models/recent_query_model.dart';
import 'package:wms_app/features/info_rapida/data/services/info_rapida_entorno.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/update_product_request.dart';

/// Contrato del origen de datos local para Información Rápida.
abstract class InfoRapidaLocalDataSource {
  /// Obtiene la lista de consultas recientes guardadas para la empresa actual.
  Future<List<RecentQuery>> getRecentQueries();

  /// Agrega una consulta reciente al inicio, desduplicando y limitando a 5 elementos.
  Future<void> saveRecentQuery(RecentQuery query);

  /// Borra todas las consultas recientes de la empresa actual.
  Future<void> clearRecentQueries();

  /// Página de productos (uno por producto) cuyo nombre, código, barcode o
  /// barcode alterno contiene [query]; con [propietario] solo los de ese
  /// propietario. Consulta SQLite directo: el catálogo no se carga en memoria.
  Future<List<ProductoCatalogo>> buscarCatalogoProductos({
    required String query,
    String? propietario,
    required int limit,
    required int offset,
  });

  /// Propietarios distintos de los productos que manejan propietario.
  Future<List<String>> getPropietariosCatalogo();

  /// Obtiene el catálogo de ubicaciones para búsqueda predictiva.
  Future<List<UbicacionCatalogo>> getCatalogoUbicaciones({bool forceRefresh = false});

  /// Deja el catálogo de ubicaciones cargado en memoria, sin convertirlo:
  /// así la primera lista que se abra ya no espera a SQLite. Los productos no
  /// se precargan: se consultan en SQLite al buscar.
  Future<void> precargarCatalogos();

  /// Obtiene los permisos del usuario activo para Información Rápida.
  Future<ConfigInfoRapidaUsuario> getConfiguracionUsuario({int? userId});

  /// Sincroniza la actualización de un producto en la base SQLite y caché en memoria.
  Future<void> syncLocalProductUpdated(ActualizarProductoParams params);

  /// Sincroniza la actualización de una ubicación en la base SQLite y caché en memoria.
  Future<void> syncLocalLocationUpdated(ActualizarUbicacionParams params);
}

/// Implementación del origen de datos local con SQLite, cachés en memoria y SharedPreferences.
@LazySingleton(as: InfoRapidaLocalDataSource)
class InfoRapidaLocalDataSourceImpl implements InfoRapidaLocalDataSource {
  static const int maxRecentItems = 5;

  final InfoRapidaEntorno _entorno;
  final ProductosCacheService _productosCache;
  final UbicacionesCacheService _ubicacionesCache;
  final ConfiguracionCacheService _configuracionCache;
  final DataBaseSqlite _database;

  InfoRapidaLocalDataSourceImpl(
    this._entorno,
    this._productosCache,
    this._ubicacionesCache,
    this._configuracionCache,
  ) : _database = DataBaseSqlite();

  @visibleForTesting
  InfoRapidaLocalDataSourceImpl.test(
    this._entorno,
    this._productosCache,
    this._ubicacionesCache,
    this._configuracionCache,
    this._database,
  );

  String get _recentKey =>
      'info_rapida_v2_recent_${_entorno.databaseName()}';

  /// Clave del historial del módulo legacy (`RecentQueriesStore`).
  String get _legacyRecentKey =>
      'info_rapida_recent_${_entorno.databaseName()}';

  /// Pasa una sola vez el historial del módulo legacy a la clave nueva (mismo
  /// formato JSON) y borra la vieja, para que limpiar el historial nuevo no
  /// lo vuelva a traer.
  Future<void> _migrarHistorialLegacy(SharedPreferences prefs) async {
    final legacy = prefs.getString(_legacyRecentKey);
    if (legacy == null) return;
    if (prefs.getString(_recentKey) == null) {
      await prefs.setString(_recentKey, legacy);
    }
    await prefs.remove(_legacyRecentKey);
  }

  @override
  Future<List<RecentQuery>> getRecentQueries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrarHistorialLegacy(prefs);
      final raw = prefs.getString(_recentKey);
      if (raw == null) return const [];

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map(
            (e) => RecentQueryModel.fromJson(Map<String, dynamic>.from(e))
                .toEntity(),
          )
          .take(maxRecentItems)
          .toList();
    } catch (e, s) {
      debugPrint('Error al leer consultas recientes: $e, $s');
      return const [];
    }
  }

  @override
  Future<void> saveRecentQuery(RecentQuery query) async {
    try {
      // Copia modificable: getRecentQueries devuelve `const []` cuando no hay
      // historial y removeWhere sobre esa lista lanzaba, así que la primera
      // consulta nunca se guardaba.
      final items = List<RecentQuery>.of(await getRecentQueries())
        ..removeWhere((q) => q.dedupeKey == query.dedupeKey)
        ..insert(0, query);

      final toSave = items.take(maxRecentItems).toList();
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        toSave.map((e) => RecentQueryModel.fromEntity(e).toJson()).toList(),
      );
      await prefs.setString(_recentKey, encoded);
    } catch (e, s) {
      debugPrint('Error al guardar consulta reciente: $e, $s');
    }
  }

  @override
  Future<void> clearRecentQueries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentKey);
    } catch (e, s) {
      debugPrint('Error al limpiar consultas recientes: $e, $s');
    }
  }

  @override
  Future<List<ProductoCatalogo>> buscarCatalogoProductos({
    required String query,
    String? propietario,
    required int limit,
    required int offset,
  }) async {
    const p = ProductInventarioTable.tableName;
    const b = BarcodesInventarioTable.tableName;
    final condiciones = <String>[];
    final args = <Object?>[];

    final q = query.trim();
    if (q.isNotEmpty) {
      // LIKE de SQLite ya ignora mayúsculas (ASCII); se escapan % y _ para
      // que se busquen literales.
      final like =
          '%${q.replaceAll('!', '!!').replaceAll('%', '!%').replaceAll('_', '!_')}%';
      condiciones.add("""(
          p.${ProductInventarioTable.columnProductName} LIKE ? ESCAPE '!'
          OR p.${ProductInventarioTable.columnProductCode} LIKE ? ESCAPE '!'
          OR p.${ProductInventarioTable.columnBarcode} LIKE ? ESCAPE '!'
          OR p.${ProductInventarioTable.columnProductId} IN (
            SELECT ${BarcodesInventarioTable.columnIdProduct} FROM $b
            WHERE ${BarcodesInventarioTable.columnBarcode} LIKE ? ESCAPE '!'
          ))""");
      args.addAll(List.filled(4, like));
    }
    if (propietario != null) {
      condiciones.add(
        'p.${ProductInventarioTable.columnManejoPropietario} = 1 '
        'AND p.${ProductInventarioTable.columnPropietario} = ?',
      );
      args.add(propietario);
    }
    final where =
        condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    final db = await _database.getDatabaseInstance();
    // Una fila por producto, igual que getAllUniqueProducts.
    final rows = await db.rawQuery(
      """
      SELECT p.* FROM $p p
      $where
      GROUP BY p.${ProductInventarioTable.columnProductId}
      ORDER BY p.${ProductInventarioTable.columnProductId}
      LIMIT ? OFFSET ?
      """,
      [...args, limit, offset],
    );

    final result = <ProductoCatalogo>[];
    for (final row in rows) {
      final cat = CatalogoMappers.toProductoCatalogo(Product.fromMap(row));
      if (cat != null) result.add(cat);
    }
    return List.unmodifiable(result);
  }

  @override
  Future<List<String>> getPropietariosCatalogo() async {
    const p = ProductInventarioTable.tableName;
    final db = await _database.getDatabaseInstance();
    final rows = await db.rawQuery("""
      SELECT DISTINCT ${ProductInventarioTable.columnPropietario} AS propietario
      FROM $p
      WHERE ${ProductInventarioTable.columnManejoPropietario} = 1
        AND IFNULL(${ProductInventarioTable.columnPropietario}, '')
            NOT IN ('', 'false', '0')
      ORDER BY ${ProductInventarioTable.columnPropietario}
      """);
    return [for (final r in rows) r['propietario'].toString()];
  }

  @override
  Future<List<UbicacionCatalogo>> getCatalogoUbicaciones({
    bool forceRefresh = false,
  }) async {
    final ubicaciones = await _ubicacionesCache.getAll(
      forceRefresh: forceRefresh,
    );

    final result = <UbicacionCatalogo>[];
    for (final u in ubicaciones) {
      final cat = CatalogoMappers.toUbicacionCatalogo(u);
      if (cat != null) {
        result.add(cat);
      }
    }
    return List.unmodifiable(result);
  }

  @override
  Future<void> precargarCatalogos() async {
    await _ubicacionesCache.getAll();
  }

  @override
  Future<ConfigInfoRapidaUsuario> getConfiguracionUsuario({int? userId}) async {
    final id = userId ?? await _entorno.userId();
    final configModel = await _configuracionCache.getConfiguration(id);
    final userProfile = configModel?.result?.result;

    if (userProfile == null) {
      return const ConfigInfoRapidaUsuario();
    }

    return ConfigInfoRapidaUsuario(
      updateItemInventory: userProfile.updateItemInventory ?? false,
      updateLocationInventory: userProfile.updateLocationInventory ?? false,
    );
  }

  @override
  Future<void> syncLocalProductUpdated(ActualizarProductoParams params) async {
    // 1. Actualizar en la base de datos SQLite local
    await _database.productoInventarioRepository.updateProduct(
      UpdateProductRequest(
        productId: params.productId,
        name: params.name,
        barcode: params.barcode,
        defaultCode: params.defaultCode,
        listPrice: params.listPrice,
        weight: params.weight,
        volume: params.volume,
      ),
    );

    // 2. Actualizar en la memoria compartida de productos
    _productosCache.applyWsProductUpsert(
      params.productId,
      {
        'name': params.name,
        'barcode': params.barcode,
        'code': params.defaultCode,
        'weight': double.tryParse(params.weight),
        'volume': double.tryParse(params.volume),
      },
    );
  }

  @override
  Future<void> syncLocalLocationUpdated(ActualizarUbicacionParams params) async {
    // insertOrUpdateSingle reemplaza la fila completa: si solo se pasaban
    // id/name/barcode quedaban en null almacén, ubicación padre y muelle
    // (bug 3 del plan). Se parte de la ubicación existente.
    final actuales = await _ubicacionesCache.getAll();
    ResultUbicaciones? existente;
    for (final u in actuales) {
      if (u.id == params.locationId) {
        existente = u;
        break;
      }
    }

    // 1. Actualizar o insertar en SQLite conservando el resto de campos
    await _database.ubicacionesRepository.insertOrUpdateSingle(
      ResultUbicaciones(
        id: params.locationId,
        name: params.name,
        barcode: params.barcode,
        locationId: existente?.locationId,
        locationName: existente?.locationName,
        idWarehouse: existente?.idWarehouse,
        warehouseName: existente?.warehouseName,
        isADockAlter: existente?.isADockAlter,
      ),
    );

    // 2. Refrescar el caché en memoria para que las listas vean el cambio
    await _ubicacionesCache.refresh();
  }
}
