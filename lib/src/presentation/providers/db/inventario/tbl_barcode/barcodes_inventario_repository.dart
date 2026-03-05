import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';

class BarcodesInventarioRepository {
  // Tamaño del bloque para inserción masiva
  static const int _batchSize = 500;

  /// --------------------------------------------------------------------------
  /// METODO OPTIMIZADO: insertOrUpdateBarcodes (Mark & Sweep)
  /// --------------------------------------------------------------------------
  Future<void> insertOrUpdateBarcodes(
      List<BarcodeInventario> barcodesList) async {
    if (barcodesList.isEmpty) return;

    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        // PASO 1: MARCA (Resetear flag)
        // Marcamos TODO el inventario como no sincronizado.
        // OJO: Esto asume que estás descargando el catálogo completo de barcodes.
        await txn.rawUpdate(
            'UPDATE ${BarcodesInventarioTable.tableName} SET ${BarcodesInventarioTable.columnIsSynced} = 0');

        // PASO 2: UPSERT POR LOTES (Chunking)
        for (var i = 0; i < barcodesList.length; i += _batchSize) {
          final end = (i + _batchSize < barcodesList.length)
              ? i + _batchSize
              : barcodesList.length;
          final batchList = barcodesList.sublist(i, end);

          final batch = txn.batch();

          for (final barcode in batchList) {
            batch.insert(
              BarcodesInventarioTable.tableName,
              {
                BarcodesInventarioTable.columnIdProduct: barcode.idProduct,
                BarcodesInventarioTable.columnBarcode: barcode.barcode,
                BarcodesInventarioTable.columnCantidad: barcode.cantidad ?? 1,
                // ✅ Marcamos como actualizado
                BarcodesInventarioTable.columnIsSynced: 1,
              },
              // ✅ Si existe (Producto + Barcode), actualiza. Si no, inserta.
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        }

        // PASO 3: BARRIDO (Limpiar basura)
        // Borramos los códigos que ya no vienen del servidor
        int deleted = await txn.delete(
          BarcodesInventarioTable.tableName,
          where: '${BarcodesInventarioTable.columnIsSynced} = ?',
          whereArgs: [0],
        );

        debugPrint(
            "📦 Inventario Barcodes: Procesados ${barcodesList.length} | Eliminados Obsoletos: $deleted");
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
