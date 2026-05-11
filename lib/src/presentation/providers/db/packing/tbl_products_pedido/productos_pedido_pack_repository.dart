// productos_pedidos_repository.dart

// ignore_for_file: unnecessary_string_interpolations, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_products_pedido/productos_pedido_pack_table.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';

class ProductosPedidosRepository {
  // Insertar producto duplicado
  Future<void> insertDuplicateProductoPedido(
      ProductoPedido producto, dynamic cantidad, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      Map<String, dynamic> productCopy = {
        ProductosPedidosTable.columnProductId: producto.productId,
        ProductosPedidosTable.columnBatchId: producto.batchId,
        ProductosPedidosTable.columnPedidoId: producto.pedidoId,
        ProductosPedidosTable.columnIdMove: producto.idMove,
        ProductosPedidosTable.columnIdProduct: producto.idProduct,
        ProductosPedidosTable.columnBarcodeLocation:
            producto.barcodeLocation ?? '',
        ProductosPedidosTable.columnLoteId: producto.loteId ?? '',
        ProductosPedidosTable.columnLotId: producto.lotId ?? '',
        ProductosPedidosTable.columnLocationId: producto.locationId ?? '',
        ProductosPedidosTable.columnIdLocation: producto.idLocation ?? 0,
        ProductosPedidosTable.columnLocationDestId:
            producto.locationDestId ?? '',
        ProductosPedidosTable.columnIdLocationDest:
            producto.idLocationDest ?? 0,
        ProductosPedidosTable.columnQuantity: cantidad,
        ProductosPedidosTable.columnExpireDate: producto.expireDate ?? '',
        ProductosPedidosTable.columnTracking: producto.tracking ?? '',
        ProductosPedidosTable.columnBarcode: producto.barcode ?? '',
        ProductosPedidosTable.columnWeight: producto.weight ?? 0.0,
        ProductosPedidosTable.columnUnidades: producto.unidades ?? '',
        ProductosPedidosTable.columnIsLocationIsOk: 0,
        ProductosPedidosTable.columnIsQuantityIsOk: 0,
        ProductosPedidosTable.columnLocationDestIsOk: 0,
        ProductosPedidosTable.columnProductIsOk: 0,
        ProductosPedidosTable.columnObservation: 'Sin novedad',
        ProductosPedidosTable.columnIsSelected: 0,
        ProductosPedidosTable.columnIsProductSplit: 1,
        ProductosPedidosTable.columnType: type,
        ProductosPedidosTable.columnManejoTemperature:
            producto.manejaTemperatura ?? 0,
        ProductosPedidosTable.columnTemperature: producto.temperatura ?? 0.0,
        ProductosPedidosTable.columnImage: producto.image ?? '',
        ProductosPedidosTable.columnImageNovedad: producto.imageNovedad ?? '',
        ProductosPedidosTable.columnTimeSeparate: 0,
        ProductosPedidosTable.columnTimeSeparateStart: null,
        ProductosPedidosTable.columnTimeSeparateEnd: null,
        ProductosPedidosTable.columnProductCode: producto.productCode ?? '',
      };

      await db.insert(
        ProductosPedidosTable.tableName,
        productCopy,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint("Producto duplicado insertado con éxito.");
    } catch (e, s) {
      debugPrint("Error al insertar producto duplicado: $e ==> $s");
    }
  }

  Future<void> insertProductosPedidos(
      List<ProductoPedido> productosList, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        for (var producto in productosList) {
          final List<Map<String, dynamic>> existingProducto = await txn.query(
            ProductosPedidosTable.tableName,
            where:
                '${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnBatchId} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ?',
            whereArgs: [
              producto.idProduct,
              producto.batchId,
              producto.pedidoId,
              producto.idMove
            ],
          );

          // Función para limpiar valores booleanos
          dynamic cleanValue(dynamic value,
              {String defaultString = '', num defaultNum = 0}) {
            if (value is bool) return value ? defaultString : defaultString;
            return value ?? defaultString;
          }

          double cleanDouble(dynamic value) {
            if (value is bool || value == null) return 0.0;
            return double.tryParse(value.toString()) ?? 0.0;
          }

          // Campos que vienen de la API y son válidos tanto para INSERT como UPDATE
          Map<String, dynamic> dataMapBase = {
            ProductosPedidosTable.columnProductId:
                producto.productId is List && producto.productId.length > 1
                    ? producto.productId[1]
                    : '',
            ProductosPedidosTable.columnBatchId: producto.batchId,
            ProductosPedidosTable.columnPedidoId: producto.pedidoId,
            ProductosPedidosTable.columnIdMove: producto.idMove,
            ProductosPedidosTable.columnIdProduct: producto.idProduct,
            ProductosPedidosTable.columnBarcodeLocation:
                cleanValue(producto.barcodeLocation),
            ProductosPedidosTable.columnLoteId: producto.loteId,
            ProductosPedidosTable.columnLotId:
                producto.lotId is List && producto.lotId.isNotEmpty
                    ? producto.lotId[1]
                    : '',
            ProductosPedidosTable.columnLocationId:
                producto.locationId is List && producto.locationId.length > 1
                    ? producto.locationId[1]
                    : null,
            ProductosPedidosTable.columnIdLocation:
                producto.locationId is List && producto.locationId.length > 1
                    ? producto.locationId[0]
                    : null,
            ProductosPedidosTable.columnLocationDestId:
                producto.locationDestId is List &&
                        producto.locationDestId.length > 1
                    ? producto.locationDestId[1]
                    : null,
            ProductosPedidosTable.columnIdLocationDest:
                producto.locationDestId is List &&
                        producto.locationDestId.length > 1
                    ? producto.locationDestId[0]
                    : null,
            ProductosPedidosTable.columnQuantity: producto.quantity,
            ProductosPedidosTable.columnExpireDate: producto.expireDate,
            ProductosPedidosTable.columnTracking:
                cleanValue(producto.tracking).toString(),
            ProductosPedidosTable.columnBarcode:
                cleanValue(producto.barcode).toString(),
            ProductosPedidosTable.columnWeight: cleanDouble(producto.weight),
            ProductosPedidosTable.columnUnidades:
                cleanValue(producto.unidades).toString(),
            ProductosPedidosTable.columnType: type,
            ProductosPedidosTable.columnManejoTemperature:
                producto.manejaTemperatura ?? 0,
            ProductosPedidosTable.columnTemperature:
                cleanDouble(producto.temperatura),
            ProductosPedidosTable.columnImage: producto.image ?? '',
            ProductosPedidosTable.columnImageNovedad:
                producto.imageNovedad ?? '',
            ProductosPedidosTable.columnProductCode: producto.productCode ?? '',
          };

          if (existingProducto.isNotEmpty) {
            // En UPDATE no sobreescribimos time_separate: es calculado localmente
            // por _onSetPickingsEvent y no viene de la API.
            await txn.update(
              ProductosPedidosTable.tableName,
              dataMapBase,
              where:
                  '${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnBatchId} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ?',
              whereArgs: [
                producto.idProduct,
                producto.batchId,
                producto.pedidoId,
                producto.idMove
              ],
            );
          } else {
            // En INSERT sí lo incluimos (valor inicial 0 para productos nuevos)
            await txn.insert(
              ProductosPedidosTable.tableName,
              {
                ...dataMapBase,
                ProductosPedidosTable.columnTimeSeparate:
                    producto.timeSeparate ?? 0,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
    } catch (e, s) {
      debugPrint("Error al insertar productos en productos_pedidos: $e ==> $s");
    }
  }

  Future<void> insertProductosOnPackage(
      List<ProductoPedido> productosList, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        for (var producto in productosList) {
          final List<Map<String, dynamic>> existingProducto = await txn.query(
            ProductosPedidosTable.tableName,
            where:
                '${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnBatchId} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ?',
            whereArgs: [
              producto.idProduct,
              producto.batchId,
              producto.pedidoId,
              producto.idMove
            ],
          );

          if (existingProducto.isNotEmpty) {
            await txn.update(
              ProductosPedidosTable.tableName,
              {
                ProductosPedidosTable.columnProductId:
                    producto.productId[1] ?? '',
                ProductosPedidosTable.columnBatchId: producto.batchId,
                ProductosPedidosTable.columnPedidoId: producto.pedidoId,
                ProductosPedidosTable.columnIdMove: producto.idMove,
                ProductosPedidosTable.columnIdProduct: producto.idProduct,
                ProductosPedidosTable.columnLotId:
                    (producto.loteId != null && producto.loteId!.isNotEmpty)
                        ? producto.loteId![1]
                        : "",
                ProductosPedidosTable.columnQuantity: producto.quantity,
                ProductosPedidosTable.columnWeight:
                    producto.weight == false ? 0 : producto.weight.toDouble(),
                ProductosPedidosTable.columnUnidades: producto.unidades == false
                    ? ""
                    : producto.unidades.toString(),
                ProductosPedidosTable.columnIsCertificate:
                    producto.isCertificate,
                ProductosPedidosTable.columnIsPackage: 1,
                ProductosPedidosTable.columnIdPackage: producto.idPackage,
                ProductosPedidosTable.columnPackageName: producto.packageName,
                ProductosPedidosTable.columnObservation: producto.observation,
                ProductosPedidosTable.columnQuantitySeparate:
                    producto.quantitySeparate,
                ProductosPedidosTable.columnIsSeparate: 1,
                ProductosPedidosTable.columnTracking: producto.tracking == false
                    ? ""
                    : producto.tracking.toString(),
                ProductosPedidosTable.columnType: type,
                ProductosPedidosTable.columnImage: producto.image ?? '',
                ProductosPedidosTable.columnImageNovedad:
                    producto.imageNovedad ?? '',
                ProductosPedidosTable.columnManejoTemperature:
                    producto.manejaTemperatura ?? 0,
                ProductosPedidosTable.columnTemperature:
                    producto.temperatura ?? 0.0,
                ProductosPedidosTable.columnLocationId:
                    producto.locationId is List &&
                            producto.locationId.length > 1
                        ? producto.locationId[1]
                        : null,
                ProductosPedidosTable.columnIdLocation:
                    producto.locationId is List &&
                            producto.locationId.length > 1
                        ? producto.locationId[0]
                        : null,
                ProductosPedidosTable.columnLocationDestId:
                    producto.locationDestId is List &&
                            producto.locationDestId.length > 1
                        ? producto.locationDestId[1]
                        : null,
                ProductosPedidosTable.columnIdLocationDest:
                    producto.locationDestId is List &&
                            producto.locationDestId.length > 1
                        ? producto.locationDestId[0]
                        : null,
                ProductosPedidosTable.columnTimeSeparate:
                    producto.timeSeparate ?? 0,
                ProductosPedidosTable.columnProductCode:
                    producto.productCode ?? '',
              },
              where:
                  '${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnBatchId} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ?',
              whereArgs: [
                producto.idProduct,
                producto.batchId,
                producto.pedidoId,
                producto.idMove
              ],
            );
          } else {
            await txn.insert(
              ProductosPedidosTable.tableName,
              {
                ProductosPedidosTable.columnProductId:
                    producto.productId[1] ?? '',
                ProductosPedidosTable.columnBatchId: producto.batchId,
                ProductosPedidosTable.columnPedidoId: producto.pedidoId,
                ProductosPedidosTable.columnIdMove: producto.idMove,
                ProductosPedidosTable.columnIdProduct: producto.idProduct,
                ProductosPedidosTable.columnLotId:
                    (producto.loteId != null && producto.loteId!.isNotEmpty)
                        ? producto.loteId![1]
                        : "",
                ProductosPedidosTable.columnQuantity: producto.quantity,
                ProductosPedidosTable.columnWeight:
                    producto.weight == false ? 0 : producto.weight.toDouble(),
                ProductosPedidosTable.columnUnidades: producto.unidades == false
                    ? ""
                    : producto.unidades.toString(),
                ProductosPedidosTable.columnIsCertificate:
                    producto.isCertificate,
                ProductosPedidosTable.columnIsPackage: 1,
                ProductosPedidosTable.columnIdPackage: producto.idPackage,
                ProductosPedidosTable.columnPackageName: producto.packageName,
                ProductosPedidosTable.columnObservation: producto.observation,
                ProductosPedidosTable.columnQuantitySeparate:
                    producto.quantitySeparate,
                ProductosPedidosTable.columnIsSeparate: 1,
                ProductosPedidosTable.columnTracking: producto.tracking == false
                    ? ""
                    : producto.tracking.toString(),
                ProductosPedidosTable.columnType: type,
                ProductosPedidosTable.columnImage: producto.image ?? '',
                ProductosPedidosTable.columnImageNovedad:
                    producto.imageNovedad ?? '',
                ProductosPedidosTable.columnManejoTemperature:
                    producto.manejaTemperatura ?? 0,
                ProductosPedidosTable.columnTemperature:
                    producto.temperatura ?? 0.0,
                ProductosPedidosTable.columnLocationId:
                    producto.locationId is List &&
                            producto.locationId.length > 1
                        ? producto.locationId[1]
                        : null,
                ProductosPedidosTable.columnIdLocation:
                    producto.locationId is List &&
                            producto.locationId.length > 1
                        ? producto.locationId[0]
                        : null,
                ProductosPedidosTable.columnLocationDestId:
                    producto.locationDestId is List &&
                            producto.locationDestId.length > 1
                        ? producto.locationDestId[1]
                        : null,
                ProductosPedidosTable.columnIdLocationDest:
                    producto.locationDestId is List &&
                            producto.locationDestId.length > 1
                        ? producto.locationDestId[0]
                        : null,
                ProductosPedidosTable.columnTimeSeparate:
                    producto.timeSeparate ?? 0,
                ProductosPedidosTable.columnProductCode:
                    producto.productCode ?? '',
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
    } catch (e, s) {
      debugPrint(
          "Error al insertar productos de paquetes ya creado : $e ==> $s");
    }
  }

  // Obtener productos de un pedido
  Future<List<ProductoPedido>> getProductosPedido(
      int pedidoId, String type) async {
    debugPrint('idPedido: $pedidoId');
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final List<Map<String, dynamic>> maps = await db.query(
      ProductosPedidosTable.tableName,
      where:
          '${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnType} = ?',
      whereArgs: [pedidoId, type],
    );
    return maps.map((map) => ProductoPedido.fromMap(map)).toList();
  }

  Future<ProductoPedido> getProductoPedidoById(
      int pedidoId, int idMove, String type) async {
    debugPrint('idPedido: $pedidoId   idMove: $idMove');
    final db = await DataBaseSqlite().getDatabaseInstance();

    final List<Map<String, dynamic>> maps = await db.query(
      ProductosPedidosTable.tableName,
      where:
          '${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ? AND ${ProductosPedidosTable.columnType} = ?',
      whereArgs: [pedidoId, idMove, type],
    );

    if (maps.isNotEmpty) {
      return ProductoPedido.fromMap(maps.first);
    } else {
      throw Exception(
          'ProductoPedido no encontrado con pedidoId: $pedidoId y idMove: $idMove');
    }
  }

  // Obtiene el producto pendiente (is_certificate IS NULL) para calcular correctamente
  // el tiempo de separación cuando existen duplicados con el mismo idMove.
  Future<ProductoPedido> getProductoPedidoPendingById(
      int pedidoId, int idMove, String type) async {
    debugPrint(
        '🔍 getProductoPedidoPendingById: pedidoId=$pedidoId  idMove=$idMove');
    final db = await DataBaseSqlite().getDatabaseInstance();

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${ProductosPedidosTable.tableName} '
      'WHERE ${ProductosPedidosTable.columnPedidoId} = ? '
      'AND ${ProductosPedidosTable.columnIdMove} = ? '
      'AND ${ProductosPedidosTable.columnType} = ? '
      'AND ${ProductosPedidosTable.columnIsCertificate} IS NULL',
      [pedidoId, idMove, type],
    );

    if (maps.isNotEmpty) {
      return ProductoPedido.fromMap(maps.first);
    } else {
      // Fallback: retornar cualquier row con ese idMove
      return getProductoPedidoById(pedidoId, idMove, type);
    }
  }

  Future<List<ProductoPedido>> getAllProductosPedidos() async {
    try {
      final Database db = await DataBaseSqlite().getDatabaseInstance();

      // Realiza una consulta a la tabla sin ninguna cláusula WHERE
      final List<Map<String, dynamic>> maps = await db.query(
        ProductosPedidosTable.tableName,
        // Opcional: puedes añadir un 'orderBy' si quieres una ordenación por defecto
        // Por ejemplo, por ID o nombre de producto
        // orderBy: '${ProductosPedidosTable.columnProductId} ASC',
      );

      // Mapea cada Map de la base de datos a un objeto ProductoPedido.
      // La robustez del mapeo recae en la implementación de ProductoPedido.fromMap.
      return maps.map((map) => ProductoPedido.fromMap(map)).toList();
    } catch (e, s) {
      debugPrint(
          "Error al obtener todos los productos de tbl_products_pedido: $e\n$s");
      // Retorna una lista vacía en caso de error para que la aplicación pueda continuar.
      return [];
    }
  }

  // Actualizar el campo de la tabla productos_pedidos (unpacking)
  Future<int?> setFieldTableProductosPedidosUnPacking(
      int pedidoId,
      int productId,
      String field,
      dynamic setValue,
      int idMove,
      int idPackage,
      String type) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db.rawUpdate(
      'UPDATE ${ProductosPedidosTable.tableName} SET $field = ? WHERE ${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ? AND ${ProductosPedidosTable.columnIdPackage} = ? AND ${ProductosPedidosTable.columnType} = ?',
      [setValue, productId, pedidoId, idMove, idPackage, type],
    );
    debugPrint("update unpacking tblproductos_pedidos: $resUpdate");
    return resUpdate;
  }

  // Actualizar la tabla de productos de un pedido (separados)
  Future<int?> setFieldTableProductosPedidos3(int pedidoId, int productId,
      String field, dynamic setValue, int idMove, String type) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db.rawUpdate(
      'UPDATE ${ProductosPedidosTable.tableName} SET $field = ? WHERE ${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ? AND ${ProductosPedidosTable.columnIsCertificate} IS NULL AND ${ProductosPedidosTable.columnType} = ?',
      [setValue, productId, pedidoId, idMove, type],
    );
    debugPrint(
        "☢️3 update separated tblproductos_pedidos: ($field): $resUpdate");
    return resUpdate;
  }

  Future<String> getFieldTableProductsPedidos(int pedidoId, int productId,
      String field, int idMove, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final res = await db.rawQuery('''
      SELECT $field FROM  ${ProductosPedidosTable.tableName}  WHERE ${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ? AND ${ProductosPedidosTable.columnIsCertificate} IS NULL AND ${ProductosPedidosTable.columnType} = ?
    ''', [productId, pedidoId, idMove, type]);
      if (res.isNotEmpty) {
        String responsefield = res[0]['$field'].toString();
        return responsefield;
      }
      return "";
    } catch (e, s) {
      debugPrint("error getFieldTableProductsPick: $e => $s");
    }
    return "";
  }

  // Actualizar la tabla de productos de un pedido (con certificado y sin paquete)
  Future<int?> setFieldTableProductosPedidos2(int pedidoId, int productId,
      String field, dynamic setValue, int idMove, String type) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db.rawUpdate(
      'UPDATE ${ProductosPedidosTable.tableName} SET $field = ? WHERE ${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ? AND ${ProductosPedidosTable.columnIsCertificate} = 1 AND ${ProductosPedidosTable.columnIsPackage} = 0 AND ${ProductosPedidosTable.columnType} = ?',
      [setValue, productId, pedidoId, idMove, type],
    );
    debugPrint(
        "☢️2 update tblproductos_pedidos (certificate and no package): ($field): $resUpdate");
    return resUpdate;
  }

  // Revertir varios campos de un producto en productos_pedidos a sus valores predeterminados
  Future<int?> revertProductFields(
      int pedidoId, int productId, int idMove, String type) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();

    // El mapa de valores que se van a actualizar
    final Map<String, dynamic> updatedValues = {
      "is_separate": null,
      "is_selected": null,
      "is_location_is_ok": 0,
      "product_is_ok": 0,
      "location_dest_is_ok": 0,
      "is_quantity_is_ok": 0,
      "time_separate": 0.0,
      "time_separate_start": null,
      "time_separate_end": null,
      "quantity_separate": null,
      "observation": null,
      "image_novedad": "",
      "image": "",
      "temperatura": 0,
      "is_certificate": null,
      "is_package": null,
    };

    final resUpdate = await db.update(
      ProductosPedidosTable.tableName,
      updatedValues,
      where: '${ProductosPedidosTable.columnIdProduct} = ? AND '
          '${ProductosPedidosTable.columnPedidoId} = ? AND '
          '${ProductosPedidosTable.columnIdMove} = ? AND '
          '${ProductosPedidosTable.columnType} = ?',
      whereArgs: [productId, pedidoId, idMove, type],
    );

    debugPrint("✅ Producto revertido en la BD. Filas afectadas: $resUpdate");
    return resUpdate;
  }

  Future<int?> revertProductFieldsSplit(
    int pedidoId,
    int productId,
    int idMove,
    String type,
  ) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();

    // El mapa de valores que se van a actualizar
    final Map<String, dynamic> updatedValues = {
      "is_separate": null,
      "is_selected": null,
      "is_location_is_ok": 0,
      "product_is_ok": 0,
      "location_dest_is_ok": 0,
      "is_quantity_is_ok": 0,
      "time_separate": 0.0,
      "time_separate_start": null,
      "time_separate_end": null,
      "quantity_separate": null,
      "observation": null,
      "image_novedad": "",
      "image": "",
      "temperatura": 0,
      "is_certificate": null,
      "is_package": null,
    };

    final resUpdate = await db.update(
      ProductosPedidosTable.tableName,
      updatedValues,
      where: '${ProductosPedidosTable.columnIdProduct} = ? AND '
          '${ProductosPedidosTable.columnPedidoId} = ? AND '
          '${ProductosPedidosTable.columnIdMove} = ?'
          ' AND ${ProductosPedidosTable.columnType} = ?',
      whereArgs: [productId, pedidoId, idMove, type],
    );

    debugPrint("✅ Producto revertido en la BD. Filas afectadas: $resUpdate");
    return resUpdate;
  }

  Future<int?> findAndAddQuantityAndDelete(int productId, int idMoveToUpdate,
      dynamic quantityToAdd, int idPedido, String type) async {
    // Renombrado idMove a idMoveToUpdate para claridad
    Database db = await DataBaseSqlite().getDatabaseInstance();
    int? rowsAffected;

    // Asegurar que quantityToAdd es double
    final double safeQuantityToAdd = (quantityToAdd as num).toDouble();

    await db.transaction((txn) async {
      // 1️⃣ Buscar y obtener la cantidad del producto para actualizar (Búsqueda por idMoveToUpdate)
      final List<Map<String, dynamic>> productsToUpdate = await txn.query(
        ProductosPedidosTable.tableName,
        columns: [ProductosPedidosTable.columnQuantity],
        where: '${ProductosPedidosTable.columnIdProduct} = ? AND '
            '${ProductosPedidosTable.columnIdMove} = ? AND '
            '${ProductosPedidosTable.columnPedidoId} = ? AND '
            '${ProductosPedidosTable.columnIsSeparate} IS NULL AND '
            '${ProductosPedidosTable.columnIsProductSplit} = 1 AND '
            '${ProductosPedidosTable.columnIsSelected} = 0 AND '
            '${ProductosPedidosTable.columnIsPackage} IS NULL AND '
            '${ProductosPedidosTable.columnType} = ?',
        whereArgs: [productId, idMoveToUpdate, idPedido, type],
        limit: 1,
      );

      if (productsToUpdate.isNotEmpty) {
        final currentQuantity = (productsToUpdate
                .first[ProductosPedidosTable.columnQuantity] as num)
            .toDouble();
        final newQuantity = currentQuantity + safeQuantityToAdd;

        // 2️⃣ Actualizar la cantidad del producto encontrado (CORRECCIÓN DEL AND COLGANTE)
        rowsAffected = await txn.update(
          ProductosPedidosTable.tableName,
          {ProductosPedidosTable.columnQuantity: newQuantity},
          where: '${ProductosPedidosTable.columnIdProduct} = ? AND '
              '${ProductosPedidosTable.columnIdMove} = ? AND '
              '${ProductosPedidosTable.columnType} = ?', // ✅ SINTAXIS CORREGIDA
          whereArgs: [productId, idMoveToUpdate, type],
        );

        // 3️⃣ Eliminar el producto que ya fue procesado (Se asume que idMoveToDelete es idMoveToUpdate)
        final int rowsDeleted = await txn.delete(
          ProductosPedidosTable.tableName,
          where: '${ProductosPedidosTable.columnIdProduct} = ? AND '
              '${ProductosPedidosTable.columnIdMove} = ? AND '
              '${ProductosPedidosTable.columnPedidoId} = ? AND '
              '${ProductosPedidosTable.columnIsSeparate} = 1 AND '
              '${ProductosPedidosTable.columnIsSelected} = 1 AND '
              '${ProductosPedidosTable.columnIsPackage} = 0 AND '
              '${ProductosPedidosTable.columnIsCertificate} = 1 AND '
              '${ProductosPedidosTable.columnIsProductSplit} = 1 AND '
              '${ProductosPedidosTable.columnType} = ?', // ✅ CONCATENACIÓN Y TIPO CORRECTO
          whereArgs: [productId, idMoveToUpdate, idPedido, type],
        );

        debugPrint(
            "✅ Producto actualizado exitosamente. Filas afectadas: $rowsAffected");
        debugPrint(
            "✅ Producto eliminado exitosamente. Filas eliminadas: $rowsDeleted");
      } else {
        debugPrint("⚠️ No se encontró el producto para actualizar.");
        rowsAffected = 0;
      }
    });

    return rowsAffected;
  }

  // Actualizar la tabla de productos de un pedido (con certificado y paquete)
  Future<int?> setFieldTableProductosPedidos2String(int pedidoId, int productId,
      String field, dynamic setValue, int idMove, String type) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db.rawUpdate(
      "UPDATE ${ProductosPedidosTable.tableName} SET $field = '$setValue' WHERE ${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ? AND ${ProductosPedidosTable.columnIsCertificate} = 1 AND ${ProductosPedidosTable.columnIsPackage} = 0 AND ${ProductosPedidosTable.columnType} = ?",
      [productId, pedidoId, idMove, type],
    );
    debugPrint(
        "☢️2String update tblproductos_pedidos (certificate and no package) String: ($field): $resUpdate");
    return resUpdate;
  }

  // Actualizar la tabla de productos de un pedido (separados, sin certificado)
  Future<int?> setFieldTableProductosPedidos3String(int pedidoId, int productId,
      String field, dynamic setValue, int idMove, String type) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db.rawUpdate(
      "UPDATE ${ProductosPedidosTable.tableName} SET $field = '$setValue' WHERE ${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ? AND ${ProductosPedidosTable.columnIsCertificate} = 0 AND ${ProductosPedidosTable.columnIsPackage} = 1 AND ${ProductosPedidosTable.columnType} = ?",
      [productId, pedidoId, idMove, type],
    );
    debugPrint(
        "☢️3String update separated tblproductos_pedidos ($field): $resUpdate");
    return resUpdate;
  }

  //*metodo para actualizar la tabla de productos de un pedido

  // Método: Actualizar un campo específico en la tabla productos_pedidos
  Future<int?> setFieldTableProductosPedidos(int pedidoId, int productId,
      String field, dynamic setValue, int idMove, String type) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db.rawUpdate(
        'UPDATE ${ProductosPedidosTable.tableName} SET $field = ? WHERE ${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnIdMove} = ? AND ${ProductosPedidosTable.columnType} = ?',
        [setValue, productId, pedidoId, idMove, type]);

    debugPrint(
        "☢️ update tblproductos_pedidos type: $type (idProduct ----($productId)) -------($field): $resUpdate");

    return resUpdate;
  }

  // Incrementar cantidad de producto separado para empaque
  // Solo afecta el row pendiente (is_certificate IS NULL) para no pisar el original certificado.
  Future<int?> incremenQtytProductSeparatePacking(int pedidoId, int productId,
      int idMove, dynamic quantity, String type) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    return await db.transaction((txn) async {
      final result = await txn.rawQuery(
        'SELECT ${ProductosPedidosTable.columnQuantitySeparate} '
        'FROM ${ProductosPedidosTable.tableName} '
        'WHERE ${ProductosPedidosTable.columnPedidoId} = ? '
        'AND ${ProductosPedidosTable.columnIdProduct} = ? '
        'AND ${ProductosPedidosTable.columnIdMove} = ? '
        'AND ${ProductosPedidosTable.columnType} = ? '
        'AND ${ProductosPedidosTable.columnIsCertificate} IS NULL',
        [pedidoId, productId, idMove, type],
      );

      if (result.isNotEmpty) {
        dynamic currentQty =
            (result.first[ProductosPedidosTable.columnQuantitySeparate]);

        dynamic newQty = currentQty + quantity;
        return await txn.rawUpdate(
          'UPDATE ${ProductosPedidosTable.tableName} '
          'SET ${ProductosPedidosTable.columnQuantitySeparate} = ? '
          'WHERE ${ProductosPedidosTable.columnPedidoId} = ? '
          'AND ${ProductosPedidosTable.columnIdProduct} = ? '
          'AND ${ProductosPedidosTable.columnIdMove} = ? '
          'AND ${ProductosPedidosTable.columnType} = ? '
          'AND ${ProductosPedidosTable.columnIsCertificate} IS NULL',
          [newQty, pedidoId, productId, idMove, type],
        );
      }
      return null; // No encontrado
    });
  }

// Método: Actualizar la novedad (observación) en la tabla productos_pedidos
  Future<int?> updateNovedadPacking(
    int pedidoId,
    int productId,
    String novedad,
    String type,
  ) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db.rawUpdate(
        "UPDATE ${ProductosPedidosTable.tableName} SET ${ProductosPedidosTable.columnObservation} = ? WHERE ${ProductosPedidosTable.columnIdProduct} = ? AND ${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnType} = ?",
        [novedad, productId, pedidoId, type]);

    debugPrint("updateNovedad: $resUpdate");
    return resUpdate;
  }

  Future<int> updateProductosBatch({
    required List<ProductoPedido> productos,
    required Map<String, dynamic> fieldsToUpdate,
    required bool isCertificate,
  }) async {
    if (productos.isEmpty) return 0;

    final db = await DataBaseSqlite().getDatabaseInstance();
    int totalUpdated = 0;

    // Usamos una transacción para asegurar atomicidad
    await db.transaction((txn) async {
      // Preparamos la consulta base
      final setClauses =
          fieldsToUpdate.keys.map((key) => "$key = ?").join(', ');
      final setValues = fieldsToUpdate.values.toList();
      final condition = isCertificate
          ? "AND is_certificate = 1 AND is_package = 0"
          : "AND is_certificate IS NULL";

      // Actualizamos cada producto individualmente pero en una sola transacción
      for (final producto in productos) {
        if (producto.idProduct == null ||
            producto.pedidoId == null ||
            producto.idMove == null) {
          continue;
        }

        final sql = '''
        UPDATE ${ProductosPedidosTable.tableName}
        SET $setClauses
        WHERE ${ProductosPedidosTable.columnIdProduct} = ?
        AND ${ProductosPedidosTable.columnPedidoId} = ?
        AND ${ProductosPedidosTable.columnIdMove} = ? 
        $condition
      ''';

        final result = await txn.rawUpdate(sql, [
          ...setValues,
          producto.idProduct,
          producto.pedidoId,
          producto.idMove,
        ]);

        totalUpdated += result;
      }
    });

    return totalUpdated;
  }

  //metodo para eliminar todos los productos de un  typo de pedido
  Future<int> deleteAllProductosByType(String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final int result = await db.delete(
        ProductosPedidosTable.tableName,
        where: '${ProductosPedidosTable.columnType} = ?',
        whereArgs: [type],
      );
      debugPrint("Productos eliminados del tipo $type: $result");
      return result;
    } catch (e, s) {
      debugPrint("Error al eliminar productos del tipo $type: $e ==> $s");
      return 0;
      ;
    }
  }

  // Elimina todos los productos de un pedido específico
  Future<int> deleteProductosByPedidoId(int pedidoId, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final int result = await db.delete(
        ProductosPedidosTable.tableName,
        where:
            '${ProductosPedidosTable.columnPedidoId} = ? AND ${ProductosPedidosTable.columnType} = ?',
        whereArgs: [pedidoId, type],
      );
      debugPrint('🗑️ Productos eliminados del pedido $pedidoId: $result');
      return result;
    } catch (e, s) {
      debugPrint('Error deleteProductosByPedidoId: $e ==> $s');
      return 0;
    }
  }

  // Suma la cantidad separada de todos los rows ya procesados (is_separate=1) de un producto.
  // Se usa para reconciliar la cantidad pendiente cuando llegan datos frescos de la API.
  Future<double> getTotalSeparatedQtyByMove(
      int pedidoId, int idMove, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final result = await db.rawQuery(
        'SELECT SUM(${ProductosPedidosTable.columnQuantitySeparate}) as total '
        'FROM ${ProductosPedidosTable.tableName} '
        'WHERE ${ProductosPedidosTable.columnPedidoId} = ? '
        'AND ${ProductosPedidosTable.columnIdMove} = ? '
        'AND ${ProductosPedidosTable.columnType} = ? '
        'AND ${ProductosPedidosTable.columnIsSeparate} = 1 '
        'AND ${ProductosPedidosTable.columnIsSelected} = 1 '
        'AND ${ProductosPedidosTable.columnQuantitySeparate} IS NOT NULL '
        'AND ${ProductosPedidosTable.columnQuantitySeparate} > 0 '
        'AND ${ProductosPedidosTable.columnTimeSeparateStart} IS NOT NULL '
        'AND ${ProductosPedidosTable.columnIsQuantityIsOk} = 1',
        [pedidoId, idMove, type],
      );
      if (result.isNotEmpty && result.first['total'] != null) {
        return (result.first['total'] as num).toDouble();
      }
      return 0.0;
    } catch (e, s) {
      debugPrint('Error getTotalSeparatedQtyByMove: $e ==> $s');
      return 0.0;
    }
  }

  // Actualiza la cantidad del row pendiente (is_certificate IS NULL) tras reconciliación.
  Future<int> updatePendingProductQuantity(
      int pedidoId, int idMove, double newQuantity, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final int rows = await db.rawUpdate(
        'UPDATE ${ProductosPedidosTable.tableName} '
        'SET ${ProductosPedidosTable.columnQuantity} = ? '
        'WHERE ${ProductosPedidosTable.columnPedidoId} = ? '
        'AND ${ProductosPedidosTable.columnIdMove} = ? '
        'AND ${ProductosPedidosTable.columnType} = ? '
        'AND ${ProductosPedidosTable.columnIsCertificate} IS NULL',
        [newQuantity, pedidoId, idMove, type],
      );
      debugPrint('✅ updatePendingProductQuantity: idMove=$idMove, qty=$newQuantity, rows=$rows');
      return rows;
    } catch (e, s) {
      debugPrint('Error updatePendingProductQuantity: $e ==> $s');
      return 0;
    }
  }
}
