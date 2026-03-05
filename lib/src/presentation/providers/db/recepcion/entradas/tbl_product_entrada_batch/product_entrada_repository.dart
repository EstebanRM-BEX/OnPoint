import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_product_entrada_batch/product_entrada_batch_table.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_batch_model.dart';

class ProductsEntradaBatchRepository {
  //metodo para insertar todas las entradas
  Future<void> insertarProductoEntrada(
      List<LineasRecepcionBatch> products) async {
    try {
      // Obtener la instancia de la base de datos.
      Database dbInstance = await DataBaseSqlite().getDatabaseInstance();

      await dbInstance.transaction((txn) async {
        Batch batch = txn.batch();

        // Generar el conjunto de productIds a consultar y crear las claves compuestas de los productos a insertar/actualizar.
        final productIds =
            products.map((p) => p.productId ?? 0).toSet().toList();
        final Set<String> keysToInsert = products
            .map((p) => '${p.productId}-${p.idMove}-${p.idRecepcion}')
            .toSet();

        // Consulta única para obtener los registros existentes en la tabla
        final List<Map<String, dynamic>> existingRows = await txn.query(
          ProductRecepcionBatchTable.tableName,
          columns: [
            ProductRecepcionBatchTable.columnProductId,
            ProductRecepcionBatchTable.columnIdMove,
            ProductRecepcionBatchTable.columnIdRecepcion,
          ],
          where:
              '${ProductRecepcionBatchTable.columnProductId} IN (${List.filled(productIds.length, '?').join(',')})',
          whereArgs: productIds,
        );

        // Construir un Set de claves compuestas de los registros existentes.
        Set<String> existingKeys = existingRows.map((e) {
          return '${e[ProductRecepcionBatchTable.columnProductId]}-${e[ProductRecepcionBatchTable.columnIdMove]}-${e[ProductRecepcionBatchTable.columnIdRecepcion]}';
        }).toSet();

        // Recorrer cada producto y definir si se debe hacer UPDATE o INSERT.
        for (var product in products) {
          final key =
              '${product.productId}-${product.idMove}-${product.idRecepcion}';

          // Definir los valores a insertar/actualizar.
          final Map<String, dynamic> values = {
            ProductRecepcionBatchTable.columnId: product.id ?? 0,
            ProductRecepcionBatchTable.columnIdMove: product.idMove ?? 0,
            ProductRecepcionBatchTable.columnProductId: product.productId ?? 0,
            ProductRecepcionBatchTable.columnIdRecepcion:
                product.idRecepcion ?? 0,
            ProductRecepcionBatchTable.columnProductName:
                product.productName ?? '',
            ProductRecepcionBatchTable.columnProductCode:
                product.productCode ?? '',
            ProductRecepcionBatchTable.columnProductBarcode:
                product.productBarcode ?? '',
            ProductRecepcionBatchTable.columnProductTracking:
                product.productTracking ?? '',
            ProductRecepcionBatchTable.columnFechaVencimiento:
                product.fechaVencimiento ?? "",
            ProductRecepcionBatchTable.columnDiasVencimiento:
                product.diasVencimiento ?? '',
            ProductRecepcionBatchTable.columnQuantityOrdered:
                product.quantityOrdered ?? 0,

            ProductRecepcionBatchTable.columnQuantityDone:
                product.quantityDone ?? 0,

            ProductRecepcionBatchTable.columnQuantityToReceive:
                product.quantityToReceive ?? 0,
            ProductRecepcionBatchTable.columnUom: product.uom ?? "",
            ProductRecepcionBatchTable.columnLocationDestId:
                product.locationDestId ?? 0,
            ProductRecepcionBatchTable.columnLocationDestName:
                product.locationDestName ?? '',
            ProductRecepcionBatchTable.columnLocationDestBarcode:
                product.locationDestBarcode ?? '',
            ProductRecepcionBatchTable.columnLocationId:
                product.locationId ?? 0,
            ProductRecepcionBatchTable.columnLocationBarcode:
                product.locationBarcode ?? '',
            ProductRecepcionBatchTable.columnLocationName:
                product.locationName ?? '',
            ProductRecepcionBatchTable.columnWeight: product.weight ?? 0,
            ProductRecepcionBatchTable.columnIsSeparate: 0,
            ProductRecepcionBatchTable.columnIsSelected: 0,
            ProductRecepcionBatchTable.columnLotName: product.lotName ?? "",
            // Se valida que exista el lote para asignar la fecha de vencimiento.
            ProductRecepcionBatchTable.columnLoteDate:
                (product.lotName != "" ? product.fechaVencimiento : ""),
            ProductRecepcionBatchTable.columnIsProductSplit: 0,
            ProductRecepcionBatchTable.columnObservation:
                product.observation ?? '',
            ProductRecepcionBatchTable.columnDateStart: "",
            ProductRecepcionBatchTable.columnDateEnd: "",
            ProductRecepcionBatchTable.columnTime: product.time,
            ProductRecepcionBatchTable.columnIsDoneItem:
                product.isDoneItem == true ? 1 : 0,
            ProductRecepcionBatchTable.columnDateTransaction:
                product.dateTransaction ?? '',
            ProductRecepcionBatchTable.columnCantidadFaltante:
                product.cantidadFaltante ?? 0,
            //temperatura
            ProductRecepcionBatchTable.columnManejoTemperature:
                product.manejaTemperatura ?? 0,
            ProductRecepcionBatchTable.columnTemperature:
                product.temperatura ?? 0.0,
            ProductRecepcionBatchTable.columnImage: product.image ?? '',
            ProductRecepcionBatchTable.columnUseExpirationDate:
                product.useExpirationDate ?? 0,
          };

          // Si la clave ya existe, se hace UPDATE; si no, se hace INSERT.
          if (existingKeys.contains(key)) {
            batch.update(
              ProductRecepcionBatchTable.tableName,
              values,
              where:
                  '${ProductRecepcionBatchTable.columnProductId} = ? AND ${ProductRecepcionBatchTable.columnIdMove} = ? AND ${ProductRecepcionBatchTable.columnIdRecepcion} = ?',
              whereArgs: [
                product.productId,
                product.idMove,
                product.idRecepcion
              ],
            );
          } else {
            batch.insert(
              ProductRecepcionBatchTable.tableName,
              values,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        // Ejecutar el batch sin esperar los resultados individuales para mayor eficiencia.
        await batch.commit(noResult: true);
      });
      debugPrint('Productos de entradas insertados con éxito.');
    } catch (e, s) {
      debugPrint('Error en el insertarProductoEntrada: $e, $s');
    }
  }

  Future<void> insertDuplicateProducto(
      LineasRecepcionBatch producto, dynamic cantidad) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      Map<String, dynamic> productCopy = {
        ProductRecepcionBatchTable.columnIdMove: producto.idMove ?? 0,
        ProductRecepcionBatchTable.columnProductId: producto.productId ?? 0,
        ProductRecepcionBatchTable.columnIdRecepcion: producto.idRecepcion ?? 0,
        ProductRecepcionBatchTable.columnProductName:
            producto.productName ?? '',
        ProductRecepcionBatchTable.columnProductCode:
            producto.productCode ?? "",
        ProductRecepcionBatchTable.columnProductBarcode:
            producto.productBarcode ?? '',
        ProductRecepcionBatchTable.columnProductTracking:
            producto.productTracking ?? '',
        ProductRecepcionBatchTable.columnFechaVencimiento:
            producto.fechaVencimiento ?? '',
        ProductRecepcionBatchTable.columnDiasVencimiento:
            producto.diasVencimiento ?? 0,
        ProductRecepcionBatchTable.columnQuantityOrdered:
            producto.quantityOrdered ?? 0,
        ProductRecepcionBatchTable.columnQuantityToReceive:
            producto.quantityToReceive ?? 0,
        ProductRecepcionBatchTable.columnUom: producto.uom ?? '',
        ProductRecepcionBatchTable.columnLocationDestId:
            producto.locationDestId ?? 0,
        ProductRecepcionBatchTable.columnLocationDestName:
            producto.locationDestName ?? '',
        ProductRecepcionBatchTable.columnLocationDestBarcode:
            producto.locationDestBarcode ?? "",
        ProductRecepcionBatchTable.columnLocationId: producto.locationId ?? 0,
        ProductRecepcionBatchTable.columnLocationBarcode:
            producto.locationBarcode ?? '',
        ProductRecepcionBatchTable.columnLocationName:
            producto.locationName ?? '',
        ProductRecepcionBatchTable.columnWeight: producto.weight ?? 0,
        ProductRecepcionBatchTable.columnIsSeparate: 0,
        ProductRecepcionBatchTable.columnIsProductSplit: 1,
        ProductRecepcionBatchTable.columnIsSelected: 0,
        ProductRecepcionBatchTable.columnObservation:
            producto.observation ?? '',
        ProductRecepcionBatchTable.columnQuantitySeparate: 0,
        ProductRecepcionBatchTable.columnLoteId: 0,
        ProductRecepcionBatchTable.columnLotName: "",
        ProductRecepcionBatchTable.columnLoteDate: "",
        ProductRecepcionBatchTable.columnIsQuantityIsOk: 0,
        ProductRecepcionBatchTable.columnProductIsOk: 0,
        ProductRecepcionBatchTable.columnLocationDestIsOk: 0,
        ProductRecepcionBatchTable.columnDateStart: "",
        ProductRecepcionBatchTable.columnDateEnd: "",
        ProductRecepcionBatchTable.columnTime: "",
        ProductRecepcionBatchTable.columnIsDoneItem: 0,
        ProductRecepcionBatchTable.columnDateTransaction: "",
        ProductRecepcionBatchTable.columnCantidadFaltante: cantidad,
        ProductRecepcionBatchTable.columnQuantityDone:
            producto.quantityDone ?? 0,
        //temperatura
        ProductRecepcionBatchTable.columnManejoTemperature:
            producto.manejaTemperatura ?? 0,
        ProductRecepcionBatchTable.columnTemperature:
            producto.temperatura ?? 0.0,
        ProductRecepcionBatchTable.columnImage: producto.image ?? '',
        ProductRecepcionBatchTable.columnUseExpirationDate:
            producto.useExpirationDate ?? 0,
      };

      await db.insert(
        ProductRecepcionBatchTable.tableName,
        productCopy,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint("Producto duplicado insertado con éxito.");
    } catch (e, s) {
      debugPrint("Error al insertar producto duplicado: $e ==> $s");
    }
  }

  //metodo para obtener todos los productos de la entrada
  Future<List<LineasRecepcionBatch>> getAllProductsEntradaBatch() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> products = await db.query(
        ProductRecepcionBatchTable.tableName,
        where: '${ProductRecepcionBatchTable.columnIsDoneItem} = 1',
      );
      return products
          .map((product) => LineasRecepcionBatch.fromMap(product))
          .toList();
    } catch (e, s) {
      debugPrint('Error en getAllProductsEntrada: $e, $s');
      return [];
    }
  }

//*Método para obtener todos los productos de una entrada por idRecepcion
  Future<List<LineasRecepcionBatch>> getProductsByRecepcionBatchId(
      int idRecepcion) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      // Consulta para obtener los productos con el idRecepcion correspondiente
      final List<Map<String, dynamic>> products = await db.query(
        ProductRecepcionBatchTable.tableName,
        where: '${ProductRecepcionBatchTable.columnIdRecepcion} = ?',
        whereArgs: [idRecepcion],
      );
      // Convertir los resultados de la consulta en objetos de tipo LineasRecepcion
      return products
          .map((product) => LineasRecepcionBatch.fromMap(product))
          .toList();
    } catch (e, s) {
      debugPrint('Error en getProductsByRecepcionId: $e, $s');
      return [];
    }
  }

  //*metodo para actualizar la tabla

  // Método: Actualizar un campo específico en la tabla productos_pedidos
  Future<int?> setFieldTableProductEntradaBatch(int idEntrada, int productId,
      String field, dynamic setValue, int idMove) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();

    final resUpdate = await db.rawUpdate(
        'UPDATE ${ProductRecepcionBatchTable.tableName} SET $field = ?'
        'WHERE ${ProductRecepcionBatchTable.columnProductId} = ?'
        'AND ${ProductRecepcionBatchTable.columnIdMove} = ?'
        'AND ${ProductRecepcionBatchTable.columnIdRecepcion} = ?'
        'AND ${ProductRecepcionBatchTable.columnIsDoneItem} = 0',
        [setValue, productId, idMove, idEntrada]);

    debugPrint(
        "update TableProductEntradaBatch (idProduct ----($productId)) -------($field): $resUpdate");

    return resUpdate;
  }

  //METODO PARA OBTENER UN PRODUCTO POR SU ID
  Future<LineasRecepcionBatch?> getProductById(
      int idProduct, int idMove, int idRecepcion) async {
    try {
      debugPrint(
          'idProduct: $idProduct, idMove: $idMove, idRecepcion: $idRecepcion');
      // Obtener la instancia de la base de datos
      Database db = await DataBaseSqlite().getDatabaseInstance();

      // Convertir idProduct a String (porque en la tabla está como TEXT)
      final List<Map<String, dynamic>> product = await db.query(
        ProductRecepcionBatchTable.tableName,
        where:
            '${ProductRecepcionBatchTable.columnProductId} = ? AND ${ProductRecepcionBatchTable.columnIdMove} = ? AND ${ProductRecepcionBatchTable.columnIdRecepcion} = ?',
        whereArgs: [
          idProduct.toString(), // Convertir idProduct a String
          idMove,
          idRecepcion
        ],
      );

      // Si hay datos, crear un objeto de LineasRecepcion, si no, retornar null
      return product.isNotEmpty
          ? LineasRecepcionBatch.fromMap(product.first)
          : null;
    } catch (e, s) {
      // Imprimir detalles del error para facilitar la depuración
      debugPrint('Error en getProductById: $e, StackTrace: $s');
      return null;
    }
  }

  // Incrementar cantidad de producto separado para empaque
  Future<int?> incremenQtytProductSeparatePacking(
    int idRecepcion,
    int productId,
    int idMove,
    int quantity, // Asegúrate de que quantity sea int
  ) async {
    final db = await DataBaseSqlite().getDatabaseInstance();

    return await db.transaction((txn) async {
      final result = await txn.query(
        ProductRecepcionBatchTable.tableName,
        columns: [ProductRecepcionBatchTable.columnQuantitySeparate],
        where:
            '${ProductRecepcionBatchTable.columnIdRecepcion} = ? AND ${ProductRecepcionBatchTable.columnProductId} = ? AND ${ProductRecepcionBatchTable.columnIdMove} = ?',
        whereArgs: [idRecepcion, productId, idMove],
      );

      if (result.isNotEmpty) {
        final currentQty =
            result.first[ProductRecepcionBatchTable.columnQuantitySeparate];
        final int safeCurrentQty = (currentQty is int) ? currentQty : 0;

        final int newQty = safeCurrentQty + quantity;

        return await txn.update(
          ProductRecepcionBatchTable.tableName,
          {ProductRecepcionBatchTable.columnQuantitySeparate: newQty},
          where:
              '${ProductRecepcionBatchTable.columnIdRecepcion} = ? AND ${ProductRecepcionBatchTable.columnProductId} = ? AND ${ProductRecepcionBatchTable.columnIdMove} = ?',
          whereArgs: [idRecepcion, productId, idMove],
        );
      }

      return null; // No encontrado
    });
  }

  // Método: Actualizar la novedad (observación) en la tabla
  Future<int?> updateNovedadOrder(
    int idRecepcion,
    int productId,
    int idMove,
    String novedad,
  ) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();
    final resUpdate = await db.rawUpdate(
        "UPDATE ${ProductRecepcionBatchTable.tableName} SET ${ProductRecepcionBatchTable.columnObservation} = ? WHERE ${ProductRecepcionBatchTable.columnProductId} = ? AND ${ProductRecepcionBatchTable.columnIdRecepcion} = ? AND ${ProductRecepcionBatchTable.columnIdMove} = ?",
        [novedad, productId, idRecepcion, idMove]);

    debugPrint("updateNovedad: $resUpdate");
    return resUpdate;
  }
}
