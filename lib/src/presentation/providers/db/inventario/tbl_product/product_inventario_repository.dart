// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/foundation.dart'; // Import para compute
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/update_product_request.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';
import 'dart:core';

// Funciones Top-Level
List<Map<String, dynamic>> _processProductsRawArgs(
    List<Product> productosList) {
  final List<Map<String, dynamic>> queries = [];
  // LÍMITE ABSOLUTO DE VARIABLES SQLITE: 999.
  // Tenemos 24 columnas, entonces 999 / 24 = 41.6.
  // Usaremos 41 como el tamaño óptimo de iteración masiva de caché.
  const int itemsPerQuery = 41;

  for (var i = 0; i < productosList.length; i += itemsPerQuery) {
    final end = (i + itemsPerQuery < productosList.length)
        ? i + itemsPerQuery
        : productosList.length;
    final chunk = productosList.sublist(i, end);

    final StringBuffer queryBuffer = StringBuffer();
    queryBuffer.write('INSERT INTO ${ProductInventarioTable.tableName} (');
    queryBuffer.write(
        '${ProductInventarioTable.columnProductCode}, ${ProductInventarioTable.columnProductId}, ${ProductInventarioTable.columnProductName}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnBarcode}, ${ProductInventarioTable.columnProductracking}, ${ProductInventarioTable.columnLotId}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnLotName}, ${ProductInventarioTable.columnExpirationDate}, ${ProductInventarioTable.columnWeight}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnWeightUomName}, ${ProductInventarioTable.columnVolume}, ${ProductInventarioTable.columnVolumeUomName}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnUom}, ${ProductInventarioTable.columnLocationId}, ${ProductInventarioTable.columnLocationName}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnQuantity}, ${ProductInventarioTable.columnUseExpirationDate}, ${ProductInventarioTable.columnCategory}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnPropietario}, ${ProductInventarioTable.columnIdPropietario}, ${ProductInventarioTable.columnManejoPropietario}, ');
    queryBuffer.write(
        '${ProductInventarioTable.columnIsSynced}, ${ProductInventarioTable.columnManejaSegundaUnidad}, ${ProductInventarioTable.columnUomSegundaUnidad}) VALUES ');

    final List<dynamic> args = [];
    for (var j = 0; j < chunk.length; j++) {
      if (j > 0) queryBuffer.write(',');
      queryBuffer.write('(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)'); // 24 params

      final producto = chunk[j];
      args.addAll([
        producto.code == false ? "" : producto.code ?? '',
        producto.productId,
        producto.name ?? '',
        producto.barcode == false ? "" : producto.barcode ?? '',
        producto.tracking == false ? "none" : producto.tracking ?? '',
        producto.lotId == false ? 0 : producto.lotId ?? 0,
        producto.lotName == false ? "" : producto.lotName ?? '',
        producto.expirationDate == false ? "" : producto.expirationDate ?? '',
        producto.weight == false ? 0 : producto.weight ?? 0,
        producto.weightUomName == false ? "" : producto.weightUomName ?? '',
        producto.volume == false ? 0 : producto.volume ?? 0,
        producto.volumeUomName == false ? "" : producto.volumeUomName ?? '',
        producto.uom == false ? "" : producto.uom ?? '',
        producto.locationId == false ? 0 : producto.locationId ?? 0,
        producto.locationName == false ? "" : producto.locationName ?? '',
        producto.quantity == false ? 0.0 : producto.quantity ?? 0.0,
        producto.useExpirationDate == true ? 1 : 0,
        producto.category == false ? "" : producto.category ?? '',
        producto.propietario ?? '',
        producto.idPropietario ?? 0,
        producto.manejoPropietario == true ? 1 : 0,
        1,
        producto.manejaSegundaUnidad == true ? 1 : 0,
        producto.uomSegundaUnidad ?? '',
      ]);
    }
    queries.add({
      'sql': queryBuffer.toString(),
      'args': args,
    });
  }
  return queries;
}

List<Product> _parseProductsMap(List<Map<String, dynamic>> maps) {
  return maps.map((m) => Product.fromMap(m)).toList();
}

class ProductInventarioRepository {
  ProductInventarioRepository({DataBaseSqlite? database})
    : _database = database ?? DataBaseSqlite();

  final DataBaseSqlite _database;

  /// Filas por llamada a sqflite al leer el catálogo completo. sqflite pasa
  /// todo el resultado de una consulta en un solo buffer del heap Java: con
  /// el catálogo entero (~72 mil filas) eran 33 MB y la app moría por
  /// OutOfMemoryError en equipos con heap de 128 MB (Urovo DT50). 2.000
  /// filas son ~1 MB.
  static const tandaLectura = 2000;

  /// Sentencias INSERT en tandas (respetan el límite de variables de SQLite)
  /// para [productosList], sin ejecutarlas: el reemplazo atómico del catálogo
  /// las corre dentro de su propia transacción.
  Future<List<Map<String, dynamic>>> construirInserts(
    List<Product> productosList,
  ) => compute(_processProductsRawArgs, productosList);

  /// --------------------------------------------------------------------------
  /// METODO OPTIMIZADO: insertProductosInventario (Mark & Sweep)
  /// --------------------------------------------------------------------------
  Future<void> insertProductosInventario(List<Product> productosList) async {
    if (productosList.isEmpty) return;

    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    try {
      final List<Map<String, dynamic>> queries =
          await compute(_processProductsRawArgs, productosList);

      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.rawQuery('PRAGMA synchronous = OFF;');

      await db.transaction((txn) async {
        final Batch batch = txn.batch();

        for (var query in queries) {
          batch.rawInsert(
              query['sql'] as String, query['args'] as List<dynamic>);
        }

        await batch.commit(noResult: true);
      });

      // Restauramos la DB
      await db.rawQuery('PRAGMA synchronous = NORMAL;');

      stopwatch.stop();
      debugPrint(
          "📦 [BENCHMARK] Insertados Productos Inventario: ${productosList.length} | Tiempo: ${stopwatch.elapsedMilliseconds} ms");
    } catch (e, s) {
      debugPrint("❌ Error al insertar productos en inventario: $e ==> $s");
    }
  }

  // --------------------------------------------------------------------------
  // MÉTODOS DE LECTURA (Optimizados por Índices)
  // --------------------------------------------------------------------------

  /// Todo el stock (varias filas por producto), leído en tandas de
  /// [tandaLectura].
  @Deprecated(
    'Carga el catálogo completo en memoria (OOM en PDAs). Usar buscar(), '
    'contar() o getByCodigo().',
  )
  Future<List<Product>> getAllProducts() async {
    try {
      final db = await _database.getDatabaseInstance();
      return await _leerEnTandas(
        db,
        columnaClave: ProductInventarioTable.columnId,
        agrupar: false,
      );
    } catch (e, s) {
      debugPrint("Error al obtener productos: $e ==> $s");
      return [];
    }
  }

  /// Una fila por producto, leída en tandas de [tandaLectura].
  @Deprecated(
    'Carga el catálogo completo en memoria (OOM en PDAs). Usar buscar(), '
    'contar() o getByCodigo().',
  )
  Future<List<Product>> getAllUniqueProducts() async {
    try {
      final db = await _database.getDatabaseInstance();
      return await _leerEnTandas(
        db,
        columnaClave: ProductInventarioTable.columnProductId,
        agrupar: true,
      );
    } catch (e, s) {
      debugPrint("Error al obtener productos únicos por ID: $e ==> $s");
      return [];
    }
  }

  /// Paginación por clave (`WHERE clave > última`), no por OFFSET: cada
  /// tanda usa el índice y no vuelve a recorrer las filas ya leídas. Cada
  /// tanda se arma en el hilo principal (~2.000 filas, pocos ms) y entre
  /// tandas la UI sigue respondiendo.
  Future<List<Product>> _leerEnTandas(
    DatabaseExecutor db, {
    required String columnaClave,
    required bool agrupar,
  }) async {
    const t = ProductInventarioTable.tableName;
    final productos = <Product>[];
    Object? ultima;
    while (true) {
      final rows = await db.rawQuery(
        'SELECT * FROM $t '
        '${ultima == null ? '' : 'WHERE $columnaClave > ? '}'
        '${agrupar ? 'GROUP BY $columnaClave ' : ''}'
        'ORDER BY $columnaClave LIMIT ?',
        [if (ultima != null) ultima, tandaLectura],
      );
      if (rows.isEmpty) break;
      productos.addAll(_parseProductsMap(rows));
      if (rows.length < tandaLectura) break;
      ultima = rows.last[columnaClave];
    }
    return productos;
  }

  // --------------------------------------------------------------------------
  // CONSULTAS ACOTADAS: nunca devuelven el catálogo completo
  // --------------------------------------------------------------------------

  /// Producto por código escaneado: `barcode` o `code` exactos y, si no,
  /// un código alterno de `tblbarcodes_inventario`. Usa índices; `null` si
  /// no existe.
  Future<Product?> getByCodigo(String codigo) async {
    final c = codigo.trim();
    if (c.isEmpty) return null;
    try {
      const p = ProductInventarioTable.tableName;
      const b = BarcodesInventarioTable.tableName;
      final db = await _database.getDatabaseInstance();
      var rows = await db.rawQuery(
        'SELECT * FROM $p '
        'WHERE ${ProductInventarioTable.columnBarcode} = ? '
        'OR ${ProductInventarioTable.columnProductCode} = ? '
        'LIMIT 1',
        [c, c],
      );
      if (rows.isEmpty) {
        rows = await db.rawQuery(
          'SELECT * FROM $p WHERE ${ProductInventarioTable.columnProductId} = '
          '(SELECT ${BarcodesInventarioTable.columnIdProduct} FROM $b '
          'WHERE ${BarcodesInventarioTable.columnBarcode} = ? LIMIT 1) '
          'LIMIT 1',
          [c],
        );
      }
      return rows.isEmpty ? null : Product.fromMap(rows.first);
    } catch (e, s) {
      debugPrint("Error al buscar producto por código: $e ==> $s");
      return null;
    }
  }

  /// Una página del catálogo, una fila por producto, ordenada por
  /// `product_id` (el orden del índice: SQLite corta al llegar a [limit] sin
  /// ordenar todo el catálogo).
  ///
  /// [query] busca (sin distinguir mayúsculas) en nombre, código, barcode y
  /// códigos alternos. [filtro] restringe a productos y/o categorías.
  Future<List<Product>> buscar({
    String query = '',
    FiltroCatalogo filtro = FiltroCatalogo.todos,
    int limit = 50,
    int offset = 0,
  }) async {
    if (filtro.vacio) return [];
    try {
      final w = _where(query, filtro);
      final db = await _database.getDatabaseInstance();
      final rows = await db.rawQuery(
        'SELECT * FROM ${ProductInventarioTable.tableName} '
        '${w.sql} '
        'GROUP BY ${ProductInventarioTable.columnProductId} '
        'ORDER BY ${ProductInventarioTable.columnProductId} '
        'LIMIT ? OFFSET ?',
        [...w.args, limit, offset],
      );
      return _parseProductsMap(rows);
    } catch (e, s) {
      debugPrint("Error al buscar productos: $e ==> $s");
      return [];
    }
  }

  /// Cantidad de productos (no de filas de stock) que devuelve [buscar] con
  /// los mismos parámetros.
  Future<int> contar({
    String query = '',
    FiltroCatalogo filtro = FiltroCatalogo.todos,
  }) async {
    if (filtro.vacio) return 0;
    try {
      final w = _where(query, filtro);
      final db = await _database.getDatabaseInstance();
      final rows = await db.rawQuery(
        'SELECT COUNT(DISTINCT ${ProductInventarioTable.columnProductId}) '
        'AS total FROM ${ProductInventarioTable.tableName} ${w.sql}',
        w.args,
      );
      return (rows.first['total'] as int?) ?? 0;
    } catch (e, s) {
      debugPrint("Error al contar productos: $e ==> $s");
      return 0;
    }
  }

  ({String sql, List<Object?> args}) _where(
    String query,
    FiltroCatalogo filtro,
  ) {
    final condiciones = <String>[];
    final args = <Object?>[];

    final filtroSql = <String>[];
    if (filtro.productIds != null) {
      // Enteros en línea: no cuentan para el límite de 999 variables de
      // SQLite (una orden de conteo puede traer miles de productos).
      filtroSql.add(
        '${ProductInventarioTable.columnProductId} IN '
        '(${filtro.productIds!.map((id) => id.toString()).join(',')})',
      );
    }
    if (filtro.categorias != null && filtro.categorias!.isNotEmpty) {
      filtroSql.add(
        '${ProductInventarioTable.columnCategory} IN '
        '(${List.filled(filtro.categorias!.length, '?').join(',')})',
      );
      args.addAll(filtro.categorias!);
    }
    // Productos y categorías a la vez = unión (conteo "combined").
    if (filtroSql.isNotEmpty) condiciones.add('(${filtroSql.join(' OR ')})');

    final q = query.trim();
    if (q.isNotEmpty) {
      // LIKE de SQLite ya ignora mayúsculas (ASCII); se escapan % y _ para
      // que se busquen literales.
      final like =
          '%${q.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
      condiciones.add(
        "(${ProductInventarioTable.columnProductName} LIKE ? ESCAPE '\\' "
        "OR ${ProductInventarioTable.columnProductCode} LIKE ? ESCAPE '\\' "
        "OR ${ProductInventarioTable.columnBarcode} LIKE ? ESCAPE '\\' "
        "OR ${ProductInventarioTable.columnProductId} IN ("
        "SELECT ${BarcodesInventarioTable.columnIdProduct} "
        "FROM ${BarcodesInventarioTable.tableName} "
        "WHERE ${BarcodesInventarioTable.columnBarcode} LIKE ? ESCAPE '\\'))",
      );
      args.addAll(List.filled(4, like));
    }

    return (
      sql: condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}',
      args: args,
    );
  }

  /// Proyección liviana (id/name/code/barcode) para pantallas que NO necesitan
  /// las ~35 columnas del producto, p.ej. impresión de etiquetas. Reduce el I/O
  /// de SQLite, el parseo y la memoria frente a `getAllUniqueProducts`
  /// (que hace `SELECT *`). Devuelve filas crudas; el caller las mapea a su
  /// propio modelo liviano para no acoplar la capa DB a un feature.
  Future<List<Map<String, Object?>>> getProductLabelRows() async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final maps = await db.rawQuery('''
        SELECT ${ProductInventarioTable.columnProductId},
               ${ProductInventarioTable.columnProductName},
               ${ProductInventarioTable.columnProductCode},
               ${ProductInventarioTable.columnBarcode}
        FROM ${ProductInventarioTable.tableName}
        GROUP BY ${ProductInventarioTable.columnProductId}
      ''');
      return maps;
    } catch (e, s) {
      debugPrint("Error al obtener filas de etiquetas: $e ==> $s");
      return [];
    }
  }

  Future<Product?> getProductById(int productId) async {
    try {
      Database db = await _database.getDatabaseInstance();
      // Esta consulta ahora es INSTANTÁNEA gracias al índice idx_inv_product_id
      List<Map<String, dynamic>> maps = await db.query(
          ProductInventarioTable.tableName,
          where: '${ProductInventarioTable.columnProductId} = ?',
          whereArgs: [productId],
          limit: 1 // Optimización
          );

      if (maps.isNotEmpty) {
        return Product.fromMap(maps.first);
      } else {
        return null;
      }
    } catch (e, s) {
      debugPrint("Error al obtener producto por id: $e ==> $s");
      return null;
    }
  }

  Future<void> updateProduct(UpdateProductRequest product) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.update(
        ProductInventarioTable.tableName,
        {
          ProductInventarioTable.columnProductName: product.name,
          ProductInventarioTable.columnBarcode: product.barcode,
          ProductInventarioTable.columnProductCode: product.defaultCode,
          ProductInventarioTable.columnWeight: product.weight,
          ProductInventarioTable.columnVolume: product.volume,
          // Aseguramos que se mantenga como sincronizado al editar manualmente
          ProductInventarioTable.columnIsSynced: 1,
        },
        where: '${ProductInventarioTable.columnProductId} = ?',
        whereArgs: [product.productId],
      );
      debugPrint("Producto actualizado correctamente: ${product.productId}");
    } catch (e, s) {
      debugPrint("Error al actualizar producto: $e ==> $s");
    }
  }

  Future<void> updateProductFields(
      int productId, Map<String, dynamic> fields) async {
    if (fields.isEmpty) return;
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.update(
        ProductInventarioTable.tableName,
        {...fields, ProductInventarioTable.columnIsSynced: 1},
        where: '${ProductInventarioTable.columnProductId} = ?',
        whereArgs: [productId],
      );
    } catch (e, s) {
      debugPrint("Error al actualizar campos del producto $productId: $e ==> $s");
    }
  }
}

/// Restricción de [ProductInventarioRepository.buscar] y
/// [ProductInventarioRepository.contar]. `null` = sin restricción; un set
/// vacío = no coincide nada (p. ej. una orden de conteo sin productos).
/// Con [productIds] y [categorias] a la vez se toma la unión.
class FiltroCatalogo {
  const FiltroCatalogo({this.productIds, this.categorias});

  static const todos = FiltroCatalogo();

  final Set<int>? productIds;
  final Set<String>? categorias;

  /// Ningún producto puede cumplirlo: se evita ir a la base.
  bool get vacio {
    final sinIds = productIds != null && productIds!.isEmpty;
    final sinCategorias = categorias != null && categorias!.isEmpty;
    // Con ambos es una unión: vacía solo si los dos lo están.
    if (productIds != null && categorias != null) {
      return sinIds && sinCategorias;
    }
    return sinIds || sinCategorias;
  }
}
