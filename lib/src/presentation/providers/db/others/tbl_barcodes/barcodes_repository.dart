

import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_barcodes/barcodes_table.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

class BarcodesRepository {
  
  // Tamaño del bloque para inserción masiva
  static const int _batchSize = 500;

/// --------------------------------------------------------------------------
  /// METODO: insertOrUpdateBarcodes (Solo Guardar/Actualizar)
  /// --------------------------------------------------------------------------
  /// - NO BORRA NADA.
  /// - Si encuentra la combinación exacta (Batch+Move+Product+Barcode+Type), actualiza.
  /// - Si no la encuentra, inserta nuevo.
  Future<void> insertOrUpdateBarcodes(
      List<Barcodes> barcodesList, String barcodeType) async {
      
    if (barcodesList.isEmpty) return;

    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        
        // Procesamos la lista en bloques de 500 para velocidad
        for (var i = 0; i < barcodesList.length; i += _batchSize) {
          final end = (i + _batchSize < barcodesList.length)
              ? i + _batchSize
              : barcodesList.length;
          final batchList = barcodesList.sublist(i, end);

          final batch = txn.batch();

          for (final b in batchList) {
            batch.insert(
              BarcodesPackagesTable.tableName,
              {
                // CAMPOS CLAVE (Definen la unicidad)
                BarcodesPackagesTable.columnBatchId: b.batchId,
                BarcodesPackagesTable.columnIdMove: b.idMove,
                BarcodesPackagesTable.columnIdProduct: b.idProduct,
                BarcodesPackagesTable.columnBarcode: b.barcode,
                BarcodesPackagesTable.columnBarcodeType: barcodeType,

                // DATOS A GUARDAR
                BarcodesPackagesTable.columnCantidad:
                    (b.cantidad == null || b.cantidad == 0) ? 1 : b.cantidad,
                
                // (Opcional) Mantenemos esto en 1 por consistencia, 
                // aunque ya no usamos la lógica de borrado.
                BarcodesPackagesTable.columnIsSynced: 1, 
              },
              // ⚠️ ESTO ES LO IMPORTANTE:
              // Reemplaza (Actualiza) si existe conflicto de índices únicos.
              // Inserta si es nuevo.
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          
          // Ejecutamos el bloque
          await batch.commit(noResult: true);
        }
      });
      
      print("✅ Barcodes Guardados ($barcodeType): ${barcodesList.length} procesados. (Ninguno borrado)");

    } catch (e, s) {
      print("❌ Error en insertOrUpdateBarcodes: $e => $s");
    }
  }
  /// --------------------------------------------------------------------------
  /// MÉTODOS DE LECTURA (Sin cambios, solo optimizados por los Índices)
  /// --------------------------------------------------------------------------

  Future<List<Barcodes>> getBarcodesProduct(
      int batchId, int productId, int idMove, String barcodeType) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      final List<Map<String, dynamic>> maps = await db.query(
        BarcodesPackagesTable.tableName,
        where: '${BarcodesPackagesTable.columnBatchId} = ? AND '
            '${BarcodesPackagesTable.columnIdMove} = ? AND '
            '${BarcodesPackagesTable.columnBarcodeType} = ?', 
        whereArgs: [batchId, idMove, barcodeType],
      );

      if (maps.isEmpty) return [];

      return maps.map((map) {
        return Barcodes(
          batchId: map[BarcodesPackagesTable.columnBatchId],
          idMove: map[BarcodesPackagesTable.columnIdMove],
          idProduct: map[BarcodesPackagesTable.columnIdProduct],
          barcode: map[BarcodesPackagesTable.columnBarcode],
          cantidad: map[BarcodesPackagesTable.columnCantidad]?.toDouble(),
          barcodeType: map[BarcodesPackagesTable.columnBarcodeType],
        );
      }).toList();
    } catch (e, s) {
      print("❌ Error al obtener los barcodes: $e => $s");
      return [];
    }
  }

  Future<List<Barcodes>> getBarcodesProductNotMove(
      int batchId, int productId, String barcodeType) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      
      final List<Map<String, dynamic>> maps = await db.query(
        BarcodesPackagesTable.tableName,
        where: '${BarcodesPackagesTable.columnBatchId} = ? AND '
            '${BarcodesPackagesTable.columnIdProduct} = ? AND '
            '${BarcodesPackagesTable.columnBarcodeType} = ?',
        whereArgs: [batchId, productId, barcodeType],
      );

      if (maps.isEmpty) return [];

      final barcodes = maps
          .fold<Map<String, Barcodes>>({}, (map, item) {
            final barcode = item[BarcodesPackagesTable.columnBarcode];
            if (!map.containsKey(barcode)) {
              map[barcode] = Barcodes(
                batchId: item[BarcodesPackagesTable.columnBatchId],
                idMove: item[BarcodesPackagesTable.columnIdMove],
                idProduct: item[BarcodesPackagesTable.columnIdProduct],
                barcode: barcode,
                cantidad: item[BarcodesPackagesTable.columnCantidad]?.toDouble(),
                barcodeType: item[BarcodesPackagesTable.columnBarcodeType],
              );
            }
            return map;
          })
          .values
          .toList();
      return barcodes;
    } catch (e) {
      print("Error al obtener los barcodes: $e");
      return [];
    }
  }

  Future<List<Barcodes>> getBarcodesProductTransfer(
      int batchId, int productId, String barcodeType) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      final List<Map<String, dynamic>> maps = await db.query(
        BarcodesPackagesTable.tableName,
        where: '${BarcodesPackagesTable.columnBatchId} = ? AND '
            '${BarcodesPackagesTable.columnIdProduct} = ? AND '
            '${BarcodesPackagesTable.columnBarcodeType} = ?',
        whereArgs: [batchId, productId, barcodeType],
      );

      if (maps.isEmpty) return [];

      final Set<String> seenBarcodes = {};
      final List<Barcodes> barcodes = [];

      for (final map in maps) {
        final String barcode = map[BarcodesPackagesTable.columnBarcode];
        if (!seenBarcodes.contains(barcode)) {
          seenBarcodes.add(barcode);
          barcodes.add(
            Barcodes(
              batchId: map[BarcodesPackagesTable.columnBatchId],
              idMove: map[BarcodesPackagesTable.columnIdMove],
              idProduct: map[BarcodesPackagesTable.columnIdProduct],
              barcode: barcode,
              cantidad: map[BarcodesPackagesTable.columnCantidad]?.toDouble(),
              barcodeType: map[BarcodesPackagesTable.columnBarcodeType],
            ),
          );
        }
      }
      return barcodes;
    } catch (e) {
      print("Error al obtener los barcodes: $e");
      return [];
    }
  }

  Future<List<Barcodes>> getAllBarcodes() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        BarcodesPackagesTable.tableName,
      );
      return maps.map((map) {
        return Barcodes(
          batchId: map[BarcodesPackagesTable.columnBatchId],
          idMove: map[BarcodesPackagesTable.columnIdMove],
          idProduct: map[BarcodesPackagesTable.columnIdProduct],
          barcode: map[BarcodesPackagesTable.columnBarcode],
          cantidad: map[BarcodesPackagesTable.columnCantidad],
          barcodeType: map[BarcodesPackagesTable.columnBarcodeType],
        );
      }).toList();
    } catch (e) {
      print("Error al obtener los barcodes: $e");
      return [];
    }
  }

  Future<List<Barcodes>> getBarcodesByBatchIdAndType(
      int batchId, String barcodeType) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
        BarcodesPackagesTable.tableName,
        where: '${BarcodesPackagesTable.columnBatchId} = ? AND '
            '${BarcodesPackagesTable.columnBarcodeType} = ?',
        whereArgs: [batchId, barcodeType],
      );
      
      return maps.map((map) {
        return Barcodes(
          batchId: map[BarcodesPackagesTable.columnBatchId],
          idMove: map[BarcodesPackagesTable.columnIdMove],
          idProduct: map[BarcodesPackagesTable.columnIdProduct],
          barcode: map[BarcodesPackagesTable.columnBarcode],
          cantidad: map[BarcodesPackagesTable.columnCantidad]?.toDouble(),
          barcodeType: map[BarcodesPackagesTable.columnBarcodeType],
        );
      }).toList();
    } catch (e) {
      print("Error al obtener los barcodes: $e");
      return [];
    }
  }
}