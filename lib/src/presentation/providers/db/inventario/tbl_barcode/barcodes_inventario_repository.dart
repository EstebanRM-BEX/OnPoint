import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';

class BarcodesInventarioRepository {
  Future<void> insertOrUpdateBarcodes(
      List<BarcodeInventario> barcodesList) async {
    if (barcodesList.isEmpty) return;

    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        const int itemsPerQuery = 100;
        final Batch batch = txn.batch();

        for (var i = 0; i < barcodesList.length; i += itemsPerQuery) {
          final end = (i + itemsPerQuery < barcodesList.length)
              ? i + itemsPerQuery
              : barcodesList.length;
          final chunk = barcodesList.sublist(i, end);

          final StringBuffer queryBuffer = StringBuffer();
          queryBuffer.write('INSERT INTO ${BarcodesInventarioTable.tableName} (');
          queryBuffer.write('${BarcodesInventarioTable.columnIdProduct}, ${BarcodesInventarioTable.columnBarcode}, ${BarcodesInventarioTable.columnCantidad}, ${BarcodesInventarioTable.columnIsSynced}) VALUES ');

          final List<dynamic> args = [];
          for (var j = 0; j < chunk.length; j++) {
            if (j > 0) queryBuffer.write(', ');
            queryBuffer.write('(?,?,?,?)');
            var barcode = chunk[j];
            args.addAll([
              barcode.idProduct,
              barcode.barcode,
              barcode.cantidad ?? 1,
              1
            ]);
          }
          batch.rawInsert(queryBuffer.toString(), args);
        }
        await batch.commit(noResult: true);
        debugPrint("📦 Inventario Barcodes: Insertados ${barcodesList.length}");
      });
    } catch (e, s) {
      debugPrint("❌ Error insertOrUpdateBarcodes: $e => $s");
    }
  }

  /// --------------------------------------------------------------------------
  /// MÉTODOS DE LECTURA
  /// --------------------------------------------------------------------------

  Future<List<BarcodeInventario>> getAllBarcodes() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      // Consulta simple (Podrías agregar LIMIT si son demasiados)
      final List<Map<String, dynamic>> maps = await db.query(
        BarcodesInventarioTable.tableName,
      );

      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      debugPrint("Error al obtener los barcodes: $e");
      return [];
    }
  }

  Future<List<BarcodeInventario>> getBarcodesProduct(int productId) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      // Esta consulta ahora usa el índice 'idx_search_inv_product', es instantánea.
      final List<Map<String, dynamic>> maps = await db.query(
        BarcodesInventarioTable.tableName,
        where: '${BarcodesInventarioTable.columnIdProduct} = ? ',
        whereArgs: [productId],
      );

      if (maps.isEmpty) {
        return [];
      }

      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e, s) {
      debugPrint("Error al obtener los barcodes: $e, =>$s");
      return [];
    }
  }

  /// Helper privado para mapear
  BarcodeInventario _mapToModel(Map<String, dynamic> map) {
    return BarcodeInventario(
      idProduct: map[BarcodesInventarioTable.columnIdProduct],
      barcode: map[BarcodesInventarioTable.columnBarcode],
      cantidad: map[BarcodesInventarioTable.columnCantidad],
    );
  }
}
