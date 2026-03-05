import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/transferencia/create_transfer/tbl_create_transfer_products/product_create_transfer_table.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';

class ProductCreateTransferRepository {
  // Aquí irían los métodos para interactuar con la tabla tblproductos_create_transfer
// En ProductCreateTransferRepository

  Future<int?> insertSingleProduct(Product producto) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      // ✅ El Mapa de Inserción, combinado con valores del producto y valores por defecto
      Map<String, dynamic> productoMap = {
        // --- Valores del Producto ---
        ProductCreateTransferTable.columnProductCode:
            producto.code?.toString() ?? '',
        ProductCreateTransferTable.columnProductId: producto.productId,
        ProductCreateTransferTable.columnProductName: producto.name ?? '',
        ProductCreateTransferTable.columnBarcode:
            producto.barcode?.toString() ?? '',
        ProductCreateTransferTable.columnProductracking:
            producto.tracking ?? 'none',

        ProductCreateTransferTable.columnLotId: producto.lotId ?? 0,
        ProductCreateTransferTable.columnLotName: producto.lotName ?? '',
        ProductCreateTransferTable.columnExpirationDate:
            producto.expirationTime ?? '',

        ProductCreateTransferTable.columnWeight: producto.weight ?? 0.0,
        ProductCreateTransferTable.columnWeightUomName:
            producto.weightUomName ?? '',
        ProductCreateTransferTable.columnVolume: producto.volume ?? 0.0,
        ProductCreateTransferTable.columnVolumeUomName:
            producto.volumeUomName ?? '',
        ProductCreateTransferTable.columnUom: producto.uom ?? '',

        ProductCreateTransferTable.columnLocationId: producto.locationId ?? 0,
        ProductCreateTransferTable.columnLocationName:
            producto.locationName ?? '',
        // Asumo que el modelo Product no tiene `quantity` pero lo necesitas en la DB:
        ProductCreateTransferTable.columnQuantity: producto.quantity ?? 0.0,

        ProductCreateTransferTable.columnUseExpirationDate:
            (producto.useExpirationDate == true ||
                    producto.useExpirationDate == 1)
                ? 1
                : 0,
        ProductCreateTransferTable.columnLoteDate:
            producto.expirationDate ?? '',

        // --- Valores por Defecto (Los que NO están en el modelo original) ---
        // Estos campos deben ser inicializados o se obtendrían directamente del modelo si existieran:
        ProductCreateTransferTable.columnDateStart: producto.dateStart ??
            '', // Si no existe en el modelo, usar valor por defecto
        ProductCreateTransferTable.columnDateEnd: producto.dateEnd ?? '',
        ProductCreateTransferTable.columnTime: producto.time ?? 0.0,
        ProductCreateTransferTable.columnDateTransaction:
            producto.dateTransaction ?? '',
        ProductCreateTransferTable.columnQuantityDone:
            producto.quantityDone ?? 0.0,
        ProductCreateTransferTable.columnExpirationDateLote:
            producto.expirationDateLote ?? '',
      };

      // 3. Ejecutar la inserción directa
      final resInsert = await db.insert(
        ProductCreateTransferTable.tableName,
        productoMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint("✅ Producto insertado con ID: $resInsert");
      return resInsert;
    } catch (e, s) {
      debugPrint("❌ Error al insertar un solo producto: $e ==> $s");
      return null;
    }
  }

// ✅ Método para actualizar un campo específico en la tabla de productos de transferencia
  Future<int?> setFieldTableProductTransfer(
      int productId, String field, dynamic setValue) async {
    Database db = await DataBaseSqlite().getDatabaseInstance();

    // Nota: Usaré 'product_id' como clave para la actualización ya que no tenemos un 'idMove' único
    // en este contexto, pero si tu tabla necesita más claves, debes añadirlas al WHERE.
    final resUpdate = await db.rawUpdate(
        'UPDATE ${ProductCreateTransferTable.tableName} SET $field = ? '
        'WHERE ${ProductCreateTransferTable.columnProductId} = ?',
        [setValue, productId]);

    debugPrint(
        "update TableProductTransfer (idProduct ----($productId)) -------($field): $resUpdate");

    return resUpdate;
  }

  /// Elimina un producto de la tabla por su ID de producto.
  Future<int?> deleteProductById(int productId) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      final rowsDeleted = await db.delete(
        ProductCreateTransferTable.tableName,
        where: '${ProductCreateTransferTable.columnProductId} = ?',
        whereArgs: [productId],
      );

      if (rowsDeleted > 0) {
        debugPrint(
            "✅ Producto con ID $productId eliminado exitosamente. Filas: $rowsDeleted");
      } else {
        debugPrint(
            "⚠️ No se encontró el producto con ID $productId para eliminar.");
      }

      return rowsDeleted;
    } catch (e, s) {
      debugPrint('❌ Error al eliminar el producto: $e, $s');
      return null;
    }
  }

//metodo para traer todos los productos de la tabla
  Future<List<Product>> getAllProductsCreateTransfer() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps =
          await db.query(ProductCreateTransferTable.tableName);

      // Convertir la lista de mapas a una lista de productos
      List<Product> productos = List.generate(maps.length, (i) {
        return Product(
          productId: maps[i][ProductCreateTransferTable.columnProductId],
          code: maps[i][ProductCreateTransferTable.columnProductCode],
          name: maps[i][ProductCreateTransferTable.columnProductName],
          barcode: maps[i][ProductCreateTransferTable.columnBarcode],
          tracking: maps[i][ProductCreateTransferTable.columnProductracking],
          lotId: maps[i][ProductCreateTransferTable.columnLotId],
          lotName: maps[i][ProductCreateTransferTable.columnLotName],
          expirationTime: maps[i]
              [ProductCreateTransferTable.columnExpirationDate],
          weight: maps[i][ProductCreateTransferTable.columnWeight],
          weightUomName: maps[i]
              [ProductCreateTransferTable.columnWeightUomName],
          volume: maps[i][ProductCreateTransferTable.columnVolume],
          volumeUomName: maps[i]
              [ProductCreateTransferTable.columnVolumeUomName],
          uom: maps[i][ProductCreateTransferTable.columnUom],
          locationId: maps[i][ProductCreateTransferTable.columnLocationId],
          locationName: maps[i][ProductCreateTransferTable.columnLocationName],
          quantity: maps[i][ProductCreateTransferTable.columnQuantity],
          useExpirationDate:
              maps[i][ProductCreateTransferTable.columnUseExpirationDate] == 1,
          expirationDate: maps[i][ProductCreateTransferTable.columnLoteDate],
          time: maps[i][ProductCreateTransferTable.columnTime],
          dateTransaction: maps[i]
              [ProductCreateTransferTable.columnDateTransaction],
          quantityDone: maps[i][ProductCreateTransferTable.columnQuantityDone],
          dateStart: maps[i][ProductCreateTransferTable.columnDateStart],
          dateEnd: maps[i][ProductCreateTransferTable.columnDateEnd],
          expirationDateLote: maps[i]
              [ProductCreateTransferTable.columnExpirationDateLote],
        );
      });

      debugPrint("✅ Productos obtenidos: ${productos.length}");
      return productos;
    } catch (e, s) {
      debugPrint("❌ Error al obtener productos de transferencia: $e ==> $s");
      return [];
    }
  }

  //eliminar todos los productos de la tabla
  Future<int?> deleteAllProductsCreateTransfer() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final rowsDeleted = await db.delete(ProductCreateTransferTable.tableName);
      debugPrint("✅ Todos los productos eliminados. Filas: $rowsDeleted");
      return rowsDeleted;
    } catch (e, s) {
      debugPrint('❌ Error al eliminar todos los productos: $e, $s');
      return null;
    }
  }
}
