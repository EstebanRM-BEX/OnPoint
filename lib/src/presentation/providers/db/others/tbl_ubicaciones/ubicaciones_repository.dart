import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';

class UbicacionesRepository {
  // Tamaño del bloque para procesar. 500 es un balance seguro entre velocidad y consumo de RAM.
  static const int _batchSize = 500;

  /// --------------------------------------------------------------------------
  /// METODO MAESTRO DE SINCRONIZACIÓN (Full Sync)
  /// --------------------------------------------------------------------------
  /// 1. MARCA: Pone todos los registros locales como "no sincronizados" (is_synced = 0).
  /// 2. UPSERT: Inserta o Actualiza los registros nuevos en lotes y los marca como "sincronizados" (is_synced = 1).
  /// 3. BARRIDO: Elimina los registros que quedaron en 0 (ya no vienen del servidor).
  Future<void> syncUbicaciones(List<ResultUbicaciones> ubicacionesList) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      if (db == null) return;

      // Usamos una transacción exclusiva. Si algo falla, se revierte todo.
      await db.transaction((txn) async {
        // PASO 1: MARCA (Resetear flag)
        // O(1) - Es instantáneo
        await txn.rawUpdate(
            'UPDATE ${UbicacionesTable.tableName} SET ${UbicacionesTable.columnIsSynced} = 0');

        // PASO 2: UPSERT POR LOTES (Chunking)
        // Evita saturar la memoria creando 30,000 operaciones en un solo golpe.
        int totalProcesados = 0;

        for (var i = 0; i < ubicacionesList.length; i += _batchSize) {
          final end = (i + _batchSize < ubicacionesList.length)
              ? i + _batchSize
              : ubicacionesList.length;
          final batchList = ubicacionesList.sublist(i, end);

          final batch = txn.batch();

          for (var item in batchList) {
            // Validación mínima de integridad
            if (item.barcode == null || item.barcode!.isEmpty) continue;

            batch.insert(
              UbicacionesTable.tableName,
              {
                UbicacionesTable.columnId: item.id,
                UbicacionesTable.columnName: item.name,
                UbicacionesTable.columnBarcode: item.barcode,
                UbicacionesTable.columnLocationId: item.locationId,
                UbicacionesTable.columnLocationName: item.locationName,
                UbicacionesTable.columnIdWarehouse: item.idWarehouse,
                UbicacionesTable.columnWarehouseName: item.warehouseName,
                // is_a_dock_alter
                UbicacionesTable.columnIsADock:
                    item.isADockAlter == true ? 1 : 0,

                // ✅ IMPORTANTE: Marcamos este registro como actualizado
                UbicacionesTable.columnIsSynced: 1,
              },
              // ✅ LA CLAVE: REPLACE actúa como "Insertar si no existe, Actualizar si existe"
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          // Ejecutamos este lote
          await batch.commit(noResult: true);
          totalProcesados += batchList.length;
        }

        // PASO 3: BARRIDO (Eliminar obsoletos)
        // Borramos todo lo que se quedó con la bandera en 0
        final deletedCount = await txn.delete(
          UbicacionesTable.tableName,
          where: '${UbicacionesTable.columnIsSynced} = ?',
          whereArgs: [0],
        );

        debugPrint(
            "⚡ Sync Ubicaciones Finalizada: Procesados $totalProcesados | Eliminados (Obsoletos) $deletedCount");
      });
    } catch (e, s) {
      debugPrint("❌ Error crítico en syncUbicaciones: $e => $s");
      // Opcional: Relanzar error si necesitas manejarlo en la UI
      // throw e;
    }
  }

  /// --------------------------------------------------------------------------
  /// SINGLE UPDATE (Para WebSockets / Tiempo Real)
  /// --------------------------------------------------------------------------
  Future<void> insertOrUpdateSingle(ResultUbicaciones item) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      await db!.insert(
        UbicacionesTable.tableName,
        {
          UbicacionesTable.columnId: item.id,
          UbicacionesTable.columnName: item.name,
          UbicacionesTable.columnBarcode: item.barcode,
          UbicacionesTable.columnLocationId: item.locationId,
          UbicacionesTable.columnLocationName: item.locationName,
          UbicacionesTable.columnIdWarehouse: item.idWarehouse,
          UbicacionesTable.columnWarehouseName: item.warehouseName,
          UbicacionesTable.columnIsADock: item.isADockAlter == true ? 1 : 0,
          UbicacionesTable.columnIsSynced: 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint("Error insertOrUpdateSingle: $e");
    }
  }

  /// --------------------------------------------------------------------------
  /// CONSULTAS OPTIMIZADAS
  /// --------------------------------------------------------------------------

  // Obtener ubicación por código de barras (Usando el Índice)
  Future<ResultUbicaciones?> getUbicacionByBarcode(String barcode) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();

      final List<Map<String, dynamic>> res = await db!.query(
          UbicacionesTable.tableName,
          where: '${UbicacionesTable.columnBarcode} = ?',
          whereArgs: [barcode],
          limit: 1 // ✅ Optimización: Detener búsqueda al encontrar el primero
          );

      if (res.isNotEmpty) {
        return _mapToModel(res.first);
      }
      return null;
    } catch (e) {
      debugPrint("Error getUbicacionByBarcode: $e");
      return null;
    }
  }

  // Obtener todas (Con advertencia de memoria)
  Future<List<ResultUbicaciones>> getAllUbicaciones() async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps =
          await db!.query(UbicacionesTable.tableName);

      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      debugPrint("Error getAllUbicaciones: $e");
      return [];
    }
  }

  Future<List<ResultUbicaciones>> getAllUbicacionesByParams(
      String params) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db!.query(
        UbicacionesTable.tableName,
        where: '${UbicacionesTable.columnIsADock} = ?',
        whereArgs: [1], // 1 representa 'true' en SQLite
      );

      return maps.map((map) => _mapToModel(map)).toList();
    } catch (e) {
      debugPrint("Error getAllUbicacionesByParams: $e");
      return [];
    }
  }

  /// Helper para mapear de SQL a Modelo (Evita repetir código)
  ResultUbicaciones _mapToModel(Map<String, dynamic> map) {
    return ResultUbicaciones(
      id: map[UbicacionesTable.columnId],
      name: map[UbicacionesTable.columnName],
      barcode: map[UbicacionesTable.columnBarcode],
      locationId: map[UbicacionesTable.columnLocationId],
      locationName: map[UbicacionesTable.columnLocationName],
      idWarehouse: map[UbicacionesTable.columnIdWarehouse],
      warehouseName: map[UbicacionesTable.columnWarehouseName],
      isADockAlter: map[UbicacionesTable.columnIsADock] == 1 ? true : false,
    );
  }

  /// Borrar todo (Reset manual)
  Future<void> deleteAll() async {
    final db = await DataBaseSqlite().getDatabaseInstance();
    await db!.delete(UbicacionesTable.tableName);
  }
}
