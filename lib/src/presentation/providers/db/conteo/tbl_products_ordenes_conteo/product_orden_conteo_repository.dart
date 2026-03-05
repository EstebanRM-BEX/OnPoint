import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_products_ordenes_conteo/product_orden_conteo_table.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';

class ProductoOrdenConteoRepository {
  // Insertar/actualizar productos de orden de conteo
  Future<void> upsertProductosOrdenConteo(List<CountedLine> productos) async {
    Stopwatch stopwatch = Stopwatch()..start();
    // ignore: unused_local_variable
    var count = 0;
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final Batch batch = txn.batch();

        for (final producto in productos) {
          count++;

          final productoMap = {
            ProductosOrdenConteoTable.columnId: producto.id,
            ProductosOrdenConteoTable.columnOrderId: producto.orderId,
            ProductosOrdenConteoTable.columnProductId: producto.productId,
            ProductosOrdenConteoTable.columnProductName:
                producto.productName ?? '',
            ProductosOrdenConteoTable.columnProductCode:
                producto.productCode ?? '',
            ProductosOrdenConteoTable.columnProductBarcode:
                producto.productBarcode ?? '',
            ProductosOrdenConteoTable.columnProductTracking:
                producto.productTracking ?? 'none',
            ProductosOrdenConteoTable.columnLocationId:
                producto.locationId ?? 0,
            ProductosOrdenConteoTable.columnLocationName:
                producto.locationName ?? '',
            ProductosOrdenConteoTable.columnLocationBarcode:
                producto.locationBarcode ?? '',
            ProductosOrdenConteoTable.columnQuantityInventory:
                producto.quantityInventory ?? 0.0,
            ProductosOrdenConteoTable.columnQuantityCounted:
                producto.quantityCounted ?? 0.0,
            ProductosOrdenConteoTable.columnDifferenceQty:
                producto.differenceQty ?? 0.0,
            ProductosOrdenConteoTable.columnUom: producto.uom ?? '',
            ProductosOrdenConteoTable.columnWeight: producto.weight ?? 0.0,
            ProductosOrdenConteoTable.columnIsDoneItem:
                producto.isDoneItem == true ? 1 : 0,
            ProductosOrdenConteoTable.columnDateTransaction:
                producto.dateTransaction ?? '',
            ProductosOrdenConteoTable.columnObservation:
                producto.observation ?? '',
            ProductosOrdenConteoTable.columnTime: producto.time ?? '',
            ProductosOrdenConteoTable.columnUserOperatorId:
                producto.userOperatorId ?? 0,
            ProductosOrdenConteoTable.columnUserOperatorName:
                producto.userOperatorName ?? '',
            ProductosOrdenConteoTable.columnCategoryId:
                producto.categoryId ?? 0,
            ProductosOrdenConteoTable.columnCategoryName:
                producto.categoryName ?? '',
            ProductosOrdenConteoTable.columnLotId: producto.lotId ?? 0,
            ProductosOrdenConteoTable.columnLotName: producto.lotName ?? '',
            ProductosOrdenConteoTable.columnFechaVencimiento:
                producto.fechaVencimiento ?? '',
            ProductosOrdenConteoTable.columnDateStart: producto.dateStart ?? '',
            ProductosOrdenConteoTable.columnDateEnd: producto.dateEnd ?? '',
            ProductosOrdenConteoTable.columnIsSelected:
                producto.isSelected == true ? 1 : 0,
            ProductosOrdenConteoTable.columnIsSeparate:
                producto.isSeparate == true ? 1 : 0,
            ProductosOrdenConteoTable.columnIdMove: producto.idMove ?? 0,
            ProductosOrdenConteoTable.columnIsOriginal:
                producto.isOriginal == true ? 1 : 0,
            //use_expiration_date
            ProductosOrdenConteoTable.columnUseExpirationDate:
                producto.useExpirationDate == true ? 1 : 0,
          };

          batch.insert(
            ProductosOrdenConteoTable.tableName,
            productoMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });

      stopwatch.stop();
      debugPrint(
          '✅ ${productos.length} productos insertados/actualizados en ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, s) {
      debugPrint('❌ Error en upsertProductosOrdenConteo: $e');
      debugPrint(s.toString());
      rethrow;
    }
  }

  // Obtener todos los productos de una orden específica
  Future<List<CountedLine>> getProductosAllByOrderId(int orderId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        ProductosOrdenConteoTable.tableName,
        where: '${ProductosOrdenConteoTable.columnOrderId} = ?',
        whereArgs: [orderId],
      );
      return List.generate(maps.length, (i) => CountedLine.fromMap(maps[i]));
    } catch (e, s) {
      debugPrint('Error en getProductosByOrderId: $e');
      debugPrint(s.toString());
      return [];
    }
  }

  Future<List<CountedLine>> getProductosByOrderId(int orderId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        ProductosOrdenConteoTable.tableName,

        where: '${ProductosOrdenConteoTable.columnOrderId} = ?',
        whereArgs: [orderId],
        groupBy: '${ProductosOrdenConteoTable.columnProductName}, '
            '${ProductosOrdenConteoTable.columnProductId}', // <--- CAMBIO AQUÍ
        orderBy: '${ProductosOrdenConteoTable.columnProductName} ASC',
      );

      return List.generate(maps.length, (i) => CountedLine.fromMap(maps[i]));
    } catch (e, s) {
      debugPrint('Error en getProductosByOrderId: $e');
      debugPrint(s.toString());
      return [];
    }
  }

  //metodo para obtener un producto por su ID
  Future<CountedLine?> getProductoById(
      int productId, int idMove, int orderId, int locationId) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        ProductosOrdenConteoTable.tableName,
        where:
            '${ProductosOrdenConteoTable.columnProductId} = ? AND ${ProductosOrdenConteoTable.columnOrderId} = ? AND ${ProductosOrdenConteoTable.columnIdMove} = ?',
        whereArgs: [productId, orderId, idMove],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return CountedLine.fromMap(maps.first);
      } else {
        return null; // No se encontró el producto
      }
    } catch (e, s) {
      debugPrint('Error en getProductoById: $e');
      debugPrint(s.toString());
      return null; // Manejo de error, puedes lanzar una excepción si lo prefieres
    }
  }

  // Actualizar cantidad contada de un producto
  Future<int> updateCantidadContada({
    required int productId,
    required int orderId,
    required dynamic cantidad,
    required String idMove,
  }) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      return await db.update(
        ProductosOrdenConteoTable.tableName,
        {
          ProductosOrdenConteoTable.columnQuantityCounted: cantidad,
          ProductosOrdenConteoTable.columnDifferenceQty:
              cantidad - (await _getCantidadInventario(db, productId, orderId)),
          ProductosOrdenConteoTable.columnDateTransaction:
              DateTime.now().toIso8601String(),
        },
        where:
            '${ProductosOrdenConteoTable.columnProductId} = ? AND ${ProductosOrdenConteoTable.columnOrderId} = ? AND ${ProductosOrdenConteoTable.columnIdMove} = ?',
        whereArgs: [productId, orderId, idMove],
      );
    } catch (e, s) {
      debugPrint('Error en updateCantidadContada: $e');
      debugPrint(s.toString());
      return 0;
    }
  }

  // Método privado para obtener cantidad en inventario
  Future<double> _getCantidadInventario(
      Database db, int productId, int orderId) async {
    final maps = await db.query(
      ProductosOrdenConteoTable.tableName,
      columns: [ProductosOrdenConteoTable.columnQuantityInventory],
      where:
          '${ProductosOrdenConteoTable.columnProductId} = ? AND ${ProductosOrdenConteoTable.columnOrderId} = ?',
      whereArgs: [productId, orderId],
      limit: 1,
    );

    return maps.isNotEmpty
        ? maps.first[ProductosOrdenConteoTable.columnQuantityInventory]
            as double
        : 0.0;
  }

  // Método: Actualizar un campo específico en la tabla productos_pedidos
  Future<int?> setFieldTableProductOrdenConteo(int idOrdenConteo, int productId,
      String field, dynamic setValue, String idMove, String locationId) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db.rawUpdate(
        'UPDATE ${ProductosOrdenConteoTable.tableName} SET $field = ?'
        'WHERE ${ProductosOrdenConteoTable.columnProductId} = ?'
        'AND ${ProductosOrdenConteoTable.columnIdMove} = ?'
        'AND ${ProductosOrdenConteoTable.columnOrderId} = ?'
        'AND ${ProductosOrdenConteoTable.columnLocationId} = ?',
        [setValue, productId, idMove, idOrdenConteo, locationId]);
    debugPrint(
        "update TableProductOrdenConteo (idProduct ----($productId)). (idMove ----($idMove) -------($field): $resUpdate");
    return resUpdate;
  }

  // Método: Actualizar un campo específico en la tabla productos_pedidos

  // traer todos los productos de la tabla
  Future<List<CountedLine>> getAllProductsAll() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> products = await db.query(
        ProductosOrdenConteoTable.tableName,
      );
      return products.map((product) => CountedLine.fromMap(product)).toList();
    } catch (e, s) {
      debugPrint('Error en getAllProductosOrdenConteo: $e, $s');
      return [];
    }
  }

  //metodo para pasar un prducto de listo enviado a por hacer y borrar sus datos de proceso
  Future<int> deleteInfoProductConteo(CountedLine product) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      //lo que vamos hacer es tomar el producto y actualizarle todos sus campos a pordefecto
      final resUpdate = await db.update(
        ProductosOrdenConteoTable.tableName,
        {
          ProductosOrdenConteoTable.columnQuantityCounted: 0.0,
          ProductosOrdenConteoTable.columnDifferenceQty: 0.0,
          ProductosOrdenConteoTable.columnIsDoneItem: 0,
          ProductosOrdenConteoTable.columnDateTransaction: '',
          ProductosOrdenConteoTable.columnObservation: '',
          ProductosOrdenConteoTable.columnIsSelected: 0,
          ProductosOrdenConteoTable.columnIsSeparate: 0,
          ProductosOrdenConteoTable.columnProductIsOk: 0,
          ProductosOrdenConteoTable.columnIsQuantityIsOk: 0,
          ProductosOrdenConteoTable.columnIsLocationIsOk: 0,
          ProductosOrdenConteoTable.columnDateEnd: '',
          ProductosOrdenConteoTable.columnDateStart: '',
          ProductosOrdenConteoTable.columnTime: '',
          //islocationId no se actualiza porque no se cambia la ubicación
        },
        where:
            '${ProductosOrdenConteoTable.columnProductId} = ? AND ${ProductosOrdenConteoTable.columnOrderId} = ? AND ${ProductosOrdenConteoTable.columnIdMove} = ?',
        whereArgs: [product.productId, product.orderId, product.idMove],
      );
      debugPrint(
          "update TableProductOrdenConteo (idProduct ----(${product.productId})) -------(${ProductosOrdenConteoTable.columnQuantityCounted}): $resUpdate");
      return resUpdate;
    } catch (e, s) {
      debugPrint('Error en deleteProductConteo: $e, $s');
      return 0;
    }
  }

  //metodo para pasar un prducto de listo enviado a por hacer y borrar sus datos de proceso
  Future<int> deleteProductConteo(CountedLine product) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      ///lo que hacemos es eliminar el registro de la tabla
      final resUpdate = await db.delete(
        ProductosOrdenConteoTable.tableName,
        where:
            '${ProductosOrdenConteoTable.columnProductId} = ? AND ${ProductosOrdenConteoTable.columnOrderId} = ? AND ${ProductosOrdenConteoTable.columnIdMove} = ?',
        whereArgs: [product.productId, product.orderId, product.idMove],
      );
      debugPrint(
          "delete TableProductOrdenConteo (idProduct ----(${product.productId})) -------: $resUpdate");
      return resUpdate;
    } catch (e, s) {
      debugPrint('Error en deleteProductConteo: $e, $s');
      return 0;
    }
  }

  //metodo para agregar un nuevo producto a la orden de conteo
  Future<int> addNewProductConteo(CountedLine producto) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      final productoMap = {
        ProductosOrdenConteoTable.columnId: producto.id,
        ProductosOrdenConteoTable.columnOrderId: producto.orderId,
        ProductosOrdenConteoTable.columnProductId: producto.productId,
        ProductosOrdenConteoTable.columnProductName: producto.productName ?? '',
        ProductosOrdenConteoTable.columnProductCode: producto.productCode ?? '',
        ProductosOrdenConteoTable.columnProductBarcode:
            producto.productBarcode ?? '',
        ProductosOrdenConteoTable.columnProductTracking:
            producto.productTracking ?? 'none',
        ProductosOrdenConteoTable.columnLocationId: producto.locationId ?? 0,
        ProductosOrdenConteoTable.columnLocationName:
            producto.locationName ?? '',
        ProductosOrdenConteoTable.columnLocationBarcode:
            producto.locationBarcode ?? '',
        ProductosOrdenConteoTable.columnQuantityInventory:
            producto.quantityInventory ?? 0.0,
        ProductosOrdenConteoTable.columnQuantityCounted:
            producto.quantityCounted ?? 0.0,
        ProductosOrdenConteoTable.columnDifferenceQty:
            producto.differenceQty ?? 0.0,
        ProductosOrdenConteoTable.columnUom: producto.uom ?? '',
        ProductosOrdenConteoTable.columnWeight: producto.weight ?? 0.0,
        ProductosOrdenConteoTable.columnIsDoneItem: producto.isDoneItem,
        ProductosOrdenConteoTable.columnDateTransaction:
            producto.dateTransaction ?? '',
        ProductosOrdenConteoTable.columnObservation: producto.observation ?? '',
        ProductosOrdenConteoTable.columnTime: producto.time ?? '',
        ProductosOrdenConteoTable.columnUserOperatorId:
            producto.userOperatorId ?? 0,
        ProductosOrdenConteoTable.columnUserOperatorName:
            producto.userOperatorName ?? '',
        ProductosOrdenConteoTable.columnCategoryId: producto.categoryId ?? 0,
        ProductosOrdenConteoTable.columnCategoryName:
            producto.categoryName ?? '',
        ProductosOrdenConteoTable.columnLotId: producto.lotId ?? 0,
        ProductosOrdenConteoTable.columnLotName: producto.lotName ?? '',
        ProductosOrdenConteoTable.columnFechaVencimiento:
            producto.fechaVencimiento ?? '',
        ProductosOrdenConteoTable.columnDateStart: producto.dateStart ?? '',
        ProductosOrdenConteoTable.columnDateEnd: producto.dateEnd ?? '',
        ProductosOrdenConteoTable.columnIsSelected: producto.isSelected,
        ProductosOrdenConteoTable.columnIsSeparate: producto.isSeparate,
        ProductosOrdenConteoTable.columnIdMove: producto.idMove ?? 0,
        ProductosOrdenConteoTable.columnIsOriginal: 0,
        //use_expiration_date
        ProductosOrdenConteoTable.columnUseExpirationDate:
            producto.useExpirationDate,
      };

      final resInsert = await db.insert(
        ProductosOrdenConteoTable.tableName,
        productoMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint(
          "insert TableProductOrdenConteo (idProduct ----(${producto.productId})) -------(${ProductosOrdenConteoTable.columnQuantityCounted}): $resInsert");
      return resInsert;
    } catch (e, s) {
      debugPrint('Error en addNewProductConteo: $e, $s');
      return 0;
    }
  }
}
