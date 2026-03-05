import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/transferencia/tbl_product_transferencia/product_transferencia_table.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/response_transferencias.dart';

class ProductTransferenciaRepository {
  //metodo para insertar todos los productos de una transferencia
  Future<void> insertarProductoEntrada(
      List<LineasTransferenciaTrans> products, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      debugPrint('insertarProductoEntrada: ${products.length} productos');

      await db.transaction((txn) async {
        Batch batch = txn.batch();

        for (var producto in products) {
          // Buscar si ya existe un producto con los 4 campos clave
          final existing = await txn.query(
            ProductTransferenciaTable.tableName,
            where: '${ProductTransferenciaTable.columnIdMove} = ? AND '
                '${ProductTransferenciaTable.columnIdTransferencia} = ? AND '
                '${ProductTransferenciaTable.columnProductId} = ?',
            whereArgs: [
              producto.idMove ?? 0,
              producto.idTransferencia ?? 0,
              producto.productId ?? 0,
            ],
          );

          // Armar los datos a insertar o actualizar
          Map<String, dynamic> data = {
            ProductTransferenciaTable.columnIdMove: producto.idMove ?? 0,
            ProductTransferenciaTable.columnProductId: producto.productId ?? 0,
            ProductTransferenciaTable.columnIdTransferencia:
                producto.idTransferencia ?? 0,
            ProductTransferenciaTable.columnProductName:
                producto.productName ?? '',
            ProductTransferenciaTable.columnProductCode:
                producto.productCode ?? '',
            ProductTransferenciaTable.columnProductBarcode:
                producto.productBarcode ?? '',
            ProductTransferenciaTable.columnProductTracking:
                producto.productTracking ?? '',
            ProductTransferenciaTable.columnFechaVencimiento:
                producto.fechaVencimiento ?? '',
            ProductTransferenciaTable.columnDiasVencimiento:
                producto.diasVencimiento ?? 0,
            ProductTransferenciaTable.columnQuantityOrdered:
                producto.quantityOrdered ?? 0,
            ProductTransferenciaTable.columnQuantityDone:
                producto.quantityDone ?? 0,
            ProductTransferenciaTable.columnUom: producto.uom ?? "",
            ProductTransferenciaTable.columnLocationDestId:
                producto.locationDestId ?? 0,
            ProductTransferenciaTable.columnLocationDestName:
                producto.locationDestName ?? "",
            ProductTransferenciaTable.columnLocationDestBarcode:
                producto.locationDestBarcode ?? '',
            ProductTransferenciaTable.columnLocationId:
                producto.locationId ?? 0,
            ProductTransferenciaTable.columnLocationBarcode:
                producto.locationBarcode ?? '',
            ProductTransferenciaTable.columnLocationName:
                producto.locationName ?? '',
            ProductTransferenciaTable.columnWeight: producto.weight ?? 0,
            ProductTransferenciaTable.columnIsSeparate: 0,
            ProductTransferenciaTable.columnIsSelected: 0,
            ProductTransferenciaTable.columnLotName: producto.lotName ?? "",
            ProductTransferenciaTable.columnLoteId: producto.lotId ?? "",
            ProductTransferenciaTable.columnLoteDate:
                (producto.lotName != "" && producto.lotName != null)
                    ? producto.fechaVencimiento
                    : "",
            ProductTransferenciaTable.columnIsProductSplit: 0,
            ProductTransferenciaTable.columnObservation: producto.observation,
            ProductTransferenciaTable.columnDateStart: "",
            ProductTransferenciaTable.columnDateEnd: "",
            ProductTransferenciaTable.columnTime: producto.time,
            ProductTransferenciaTable.columnIsDoneItem:
                producto.isDoneItem ?? 0,
            ProductTransferenciaTable.columnCantidadFaltante:
                producto.cantidadFaltante ?? 0,
            ProductTransferenciaTable.columnType: type
          };

          if (existing.isNotEmpty) {
            // Si existe exactamente con los 4 campos, actualizar
            batch.update(
              ProductTransferenciaTable.tableName,
              data,
              where: '${ProductTransferenciaTable.columnIdMove} = ? AND '
                  '${ProductTransferenciaTable.columnIdTransferencia} = ? AND '
                  '${ProductTransferenciaTable.columnProductId} = ?',
              whereArgs: [
                producto.idMove ?? 0,
                producto.idTransferencia ?? 0,
                producto.productId ?? 0,
              ],
            );
          } else {
            // No existe esa combinación → insertar
            batch.insert(
              ProductTransferenciaTable.tableName,
              data,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }

        await batch.commit(noResult: true);
      });
    } catch (e, s) {
      debugPrint('Error en el insertarProductoEntrada: $e, $s');
    }
  }

  //METODO PARA OBTENER UN PRODUCTO POR SU ID
  Future<LineasTransferenciaTrans?> getProductById(
      int idProduct, int idMove, int idTransferencia) async {
    try {
      debugPrint(
          'idProduct: $idProduct, idMove: $idMove, idTransferencia: $idTransferencia');
      // Obtener la instancia de la base de datos
      Database db = await DataBaseSqlite().getDatabaseInstance();

      // Convertir idProduct a String (porque en la tabla está como TEXT)
      final List<Map<String, dynamic>> product = await db.query(
        ProductTransferenciaTable.tableName,
        where:
            '${ProductTransferenciaTable.columnProductId} = ? AND ${ProductTransferenciaTable.columnIdMove} = ? AND ${ProductTransferenciaTable.columnIdTransferencia} = ?',
        whereArgs: [
          idProduct.toString(), // Convertir idProduct a String
          idMove,
          idTransferencia
        ],
      );

      // Si hay datos, crear un objeto de LineasRecepcion, si no, retornar null
      return product.isNotEmpty
          ? LineasTransferenciaTrans.fromMap(product.first)
          : null;
    } catch (e, s) {
      // Imprimir detalles del error para facilitar la depuración
      debugPrint('Error en getProductById: $e, StackTrace: $s');
      return null;
    }
  }

  Future<void> insertDuplicateProducto(LineasTransferenciaTrans producto,
      dynamic cantidad, int idMove, int idProduct, String type) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      Map<String, dynamic> productCopy = {
        ProductTransferenciaTable.columnIdMove: idMove,
        ProductTransferenciaTable.columnProductId: idProduct,
        ProductTransferenciaTable.columnIdTransferencia:
            producto.idTransferencia ?? 0,
        ProductTransferenciaTable.columnProductName: producto.productName ?? "",
        ProductTransferenciaTable.columnProductCode: producto.productCode ?? '',
        ProductTransferenciaTable.columnProductBarcode:
            producto.productBarcode ?? '',
        ProductTransferenciaTable.columnProductTracking:
            producto.productTracking ?? '',
        ProductTransferenciaTable.columnFechaVencimiento:
            producto.fechaVencimiento ?? '',
        ProductTransferenciaTable.columnDiasVencimiento:
            producto.diasVencimiento ?? 0,
        ProductTransferenciaTable.columnQuantityOrdered:
            producto.quantityOrdered ?? 0,

        ProductTransferenciaTable.columnQuantityDone:
            producto.quantityDone ?? 0,
        ProductTransferenciaTable.columnUom: producto.uom ?? '',

        ProductTransferenciaTable.columnLocationDestId:
            producto.locationDestId ?? 0,
        ProductTransferenciaTable.columnLocationDestName:
            producto.locationDestName ?? '',
        ProductTransferenciaTable.columnLocationDestBarcode:
            producto.locationDestBarcode ?? '',
        ProductTransferenciaTable.columnLocationId: producto.locationId ?? 0,
        ProductTransferenciaTable.columnLocationBarcode:
            producto.locationBarcode ?? '',
        ProductTransferenciaTable.columnLocationName:
            producto.locationName ?? '',
        ProductTransferenciaTable.columnWeight: producto.weight ?? 0,
        //parametros para ver que es diferente
        ProductTransferenciaTable.columnIsSeparate: 0,
        ProductTransferenciaTable.columnIsProductSplit: 1,

        ProductTransferenciaTable.columnIsSelected: 0,
        ProductTransferenciaTable.columnObservation: producto.observation ?? '',

        ProductTransferenciaTable.columnLoteId: producto.lotId ?? '',
        ProductTransferenciaTable.columnLotName: producto.lotName ?? '',
        ProductTransferenciaTable.columnLoteDate:
            producto.fechaVencimiento ?? '',

        ProductTransferenciaTable.columnIsQuantityIsOk: 0,
        ProductTransferenciaTable.columnProductIsOk: 0,
        ProductTransferenciaTable.columnDateStart: "",
        ProductTransferenciaTable.columnDateEnd: "",
        ProductTransferenciaTable.columnTime: "",
        ProductTransferenciaTable.columnIsDoneItem: 0,
        ProductTransferenciaTable.columnDateTransaction: "",
        ProductTransferenciaTable.columnCantidadFaltante: cantidad,
        ProductTransferenciaTable.columnType: type,
      };

      await db.insert(
        ProductTransferenciaTable.tableName,
        productCopy,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint("Producto duplicado insertado con éxito.");
    } catch (e, s) {
      debugPrint("Error al insertar producto duplicado: $e ==> $s");
    }
  }

//*Método para obtener todos los productos de una entrada por idRecepcion
  Future<List<LineasTransferenciaTrans>> getProductsByTrasnferId(
      int idTransfer) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      debugPrint('idTransfer: $idTransfer');

      // Consulta para obtener los productos con el idRecepcion correspondiente
      final List<Map<String, dynamic>> products = await db.query(
        ProductTransferenciaTable.tableName,
        where: '${ProductTransferenciaTable.columnIdTransferencia} = ?',
        whereArgs: [
          idTransfer,
        ],
      );
      // Convertir los resultados de la consulta en objetos de tipo LineasRecepcion
      return products
          .map((product) => LineasTransferenciaTrans.fromMap(product))
          .toList();
    } catch (e, s) {
      debugPrint('Error en getProductsByTrasnferId: $e, $s');
      return [];
    }
  }

  //*metodo para actualizar la tabla

  // Método: Actualizar un campo específico en la tabla productos_pedidos
  Future<int?> setFieldTableProductTransfer(int idEntrada, int productId,
      String field, dynamic setValue, int idMove) async {
    debugPrint(
        "datos de transfer: idTransfer: $idEntrada, productId: $productId, field: $field, setValue: $setValue, idMove: $idMove");

    Database db = await DataBaseSqlite().getDatabaseInstance();

    // Realizar la actualización solo si is_done_item = 0
    final resUpdate = await db.rawUpdate(
      'UPDATE ${ProductTransferenciaTable.tableName} SET $field = ? '
      'WHERE ${ProductTransferenciaTable.columnProductId} = ? '
      'AND ${ProductTransferenciaTable.columnIdMove} = ? '
      'AND ${ProductTransferenciaTable.columnIdTransferencia} = ? '
      'AND ${ProductTransferenciaTable.columnIsDoneItem} = 0',
      [setValue, productId, idMove, idEntrada],
    );

    debugPrint(
        "update TableProductTransfer (idProduct ----($productId)) -------($field): $resUpdate");

    return resUpdate;
  }

  Future<int?> setFieldTableProductTransferDone(int idEntrada, int productId,
      String field, dynamic setValue, int idMove) async {
    debugPrint(
        "datos de transfer: idTransfer: $idEntrada, productId: $productId, field: $field, setValue: $setValue, idMove: $idMove");

    Database db = await DataBaseSqlite().getDatabaseInstance();

    // Realizar la actualización solo si is_done_item = 0
    final resUpdate = await db.rawUpdate(
      'UPDATE ${ProductTransferenciaTable.tableName} SET $field = ? '
      'WHERE ${ProductTransferenciaTable.columnProductId} = ? '
      'AND ${ProductTransferenciaTable.columnIdMove} = ? '
      'AND ${ProductTransferenciaTable.columnIdTransferencia} = ? '
      'AND ${ProductTransferenciaTable.columnIsDoneItem} = 1',
      [setValue, productId, idMove, idEntrada],
    );

    debugPrint(
        "update setFieldTableProductTransferDone (idProduct ----($productId)) -------($field): $resUpdate");

    return resUpdate;
  }

  // Incrementar cantidad de producto separado para empaque
  Future<int?> incremenQtytProductSeparate(
      int idTransfer, int productId, int idMove, dynamic quantity) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    return await db.transaction((txn) async {
      final result = await txn.query(
        ProductTransferenciaTable.tableName,
        columns: [(ProductTransferenciaTable.columnQuantityDone)],
        where:
            '${ProductTransferenciaTable.columnIdTransferencia} = ? AND ${ProductTransferenciaTable.columnProductId} = ? AND ${ProductTransferenciaTable.columnIdMove} = ?',
        whereArgs: [idTransfer, productId, idMove],
      );

      if (result.isNotEmpty) {
        dynamic currentQty =
            (result.first[ProductTransferenciaTable.columnQuantityDone]);

        dynamic newQty = currentQty + quantity;
        return await txn.update(
          ProductTransferenciaTable.tableName,
          {ProductTransferenciaTable.columnQuantityDone: newQty},
          where:
              '${ProductTransferenciaTable.columnIdTransferencia} = ? AND ${ProductTransferenciaTable.columnProductId} = ? AND ${ProductTransferenciaTable.columnIdMove} = ?',
          whereArgs: [idTransfer, productId, idMove],
        );
      }
      return null; // No encontrado
    });
  }

  // Método: Actualizar la novedad (observación) en la tabla
  Future<int?> updateNovedadTransfer(
    int idRecepcion,
    int productId,
    int idMove,
    String novedad,
  ) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db.rawUpdate(
        "UPDATE ${ProductTransferenciaTable.tableName} SET ${ProductTransferenciaTable.columnObservation} = ? WHERE ${ProductTransferenciaTable.columnProductId} = ? AND ${ProductTransferenciaTable.columnIdTransferencia} = ? AND ${ProductTransferenciaTable.columnIdMove} = ?",
        [novedad, productId, idRecepcion, idMove]);

    debugPrint("updateNovedad: $resUpdate");
    return resUpdate;
  }

  //obtener todos los productos de la tabla
  Future<List<LineasTransferenciaTrans>> getAllProducts() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> products =
          await db.query(ProductTransferenciaTable.tableName);
      return products
          .map((product) => LineasTransferenciaTrans.fromMap(product))
          .toList();
    } catch (e, s) {
      debugPrint('Error en getAllProducts: $e, $s');
      return [];
    }
  }

  //metodo para ejecutar todo esto en una sola
}
