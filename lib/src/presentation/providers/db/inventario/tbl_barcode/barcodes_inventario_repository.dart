import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';

class BarcodesInventarioRepository {
  /// Sentencias INSERT en tandas de 100 para [barcodesList], sin ejecutarlas:
  /// el reemplazo atómico del catálogo las corre dentro de su transacción.
  List<Map<String, dynamic>> construirInserts(
      List<BarcodeInventario> barcodesList) {
    const int itemsPerQuery = 100;
    final queries = <Map<String, dynamic>>[];

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
      queries.add({'sql': queryBuffer.toString(), 'args': args});
    }
    return queries;
  }

  Future<void> insertOrUpdateBarcodes(
      List<BarcodeInventario> barcodesList) async {
    if (barcodesList.isEmpty) return;

    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final Batch batch = txn.batch();
        for (final q in construirInserts(barcodesList)) {
          batch.rawInsert(q['sql'] as String, q['args'] as List<dynamic>);
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

  Future<void> updateBarcodeCantidad(
      int productId, String barcode, dynamic cantidad) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.update(
        BarcodesInventarioTable.tableName,
        {BarcodesInventarioTable.columnCantidad: cantidad},
        where:
            '${BarcodesInventarioTable.columnIdProduct} = ? AND ${BarcodesInventarioTable.columnBarcode} = ?',
        whereArgs: [productId, barcode],
      );
    } catch (e, s) {
      debugPrint("Error al actualizar cantidad del barcode: $e ==> $s");
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
