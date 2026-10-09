import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';

/// Hasta este número de filas se arma la lista en el hilo principal: crear el
/// isolate de `compute` costó ~5 s en PDA, y armar 2.400 ubicaciones toma
/// unos pocos ms. Con catálogos más grandes sí conviene el isolate.
const int _umbralCompute = 5000;

List<ResultUbicaciones> _parseUbicacionesMap(List<Map<String, dynamic>> maps) {
  return maps.map((map) => ResultUbicaciones(
        id: map[UbicacionesTable.columnId],
        name: map[UbicacionesTable.columnName],
        barcode: map[UbicacionesTable.columnBarcode],
        locationId: map[UbicacionesTable.columnLocationId],
        locationName: map[UbicacionesTable.columnLocationName],
        idWarehouse: map[UbicacionesTable.columnIdWarehouse],
        warehouseName: map[UbicacionesTable.columnWarehouseName],
        isADockAlter: map[UbicacionesTable.columnIsADock] == 1,
      )).toList();
}

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
              _fila(item),
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
      // Se relanza: el sync incremental no debe guardar su marca
      // (since/scope) si la escritura falló.
      rethrow;
    }
  }

  /// Fila de [item] marcada como sincronizada.
  Map<String, Object?> _fila(ResultUbicaciones item) => {
        UbicacionesTable.columnId: item.id,
        UbicacionesTable.columnName: item.name,
        UbicacionesTable.columnBarcode: item.barcode,
        UbicacionesTable.columnLocationId: item.locationId,
        UbicacionesTable.columnLocationName: item.locationName,
        UbicacionesTable.columnIdWarehouse: item.idWarehouse,
        UbicacionesTable.columnWarehouseName: item.warehouseName,
        // is_a_dock_alter
        UbicacionesTable.columnIsADock: item.isADockAlter == true ? 1 : 0,
        // ✅ IMPORTANTE: Marcamos este registro como actualizado
        UbicacionesTable.columnIsSynced: 1,
      };

  /// SQLite admite 999 variables por sentencia en las versiones viejas.
  static const int _tandaIds = 500;

  /// Sync INCREMENTAL, en una transacción: reemplaza las ubicaciones de
  /// [cambios] (las que llegan sin barcode quedan borradas, como en el sync
  /// completo) y, si viene [activos], borra las que no estén en esa lista
  /// (archivadas o eliminadas).
  ///
  /// [db] solo para tests (por defecto, la base de la app).
  Future<void> aplicarCambios(
    List<ResultUbicaciones> cambios,
    List<int>? activos, {
    @visibleForTesting Database? db,
  }) async {
    db ??= await DataBaseSqlite().getDatabaseInstance();
    const tabla = UbicacionesTable.tableName;
    const id = UbicacionesTable.columnId;

    await db.transaction((txn) async {
      final ids = [for (final u in cambios) if (u.id != null) u.id!];
      for (var i = 0; i < ids.length; i += _tandaIds) {
        final tanda = ids.sublist(i, min(i + _tandaIds, ids.length));
        await txn.delete(
          tabla,
          where: '$id IN (${List.filled(tanda.length, '?').join(',')})',
          whereArgs: tanda,
        );
      }

      final batch = txn.batch();
      for (final item in cambios) {
        if (item.barcode == null || item.barcode!.isEmpty) continue;
        batch.insert(tabla, _fila(item),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);

      if (activos != null) {
        // Un NOT IN con miles de parámetros no entra: tabla temporal.
        await txn.execute(
          'CREATE TEMP TABLE IF NOT EXISTS tmp_ubicaciones_activas '
          '(id INTEGER PRIMARY KEY)',
        );
        await txn.delete('tmp_ubicaciones_activas');
        for (var i = 0; i < activos.length; i += _tandaIds) {
          final tanda = activos.sublist(i, min(i + _tandaIds, activos.length));
          await txn.rawInsert(
            'INSERT OR IGNORE INTO tmp_ubicaciones_activas (id) VALUES '
            '${List.filled(tanda.length, '(?)').join(',')}',
            tanda,
          );
        }
        final borradas = await txn.rawDelete(
          'DELETE FROM $tabla WHERE $id NOT IN '
          '(SELECT id FROM tmp_ubicaciones_activas)',
        );
        await txn.execute('DROP TABLE IF EXISTS tmp_ubicaciones_activas');
        debugPrint('⚡ Sync incremental ubicaciones: ${cambios.length} '
            'cambiadas | $borradas eliminadas');
      }
    });
  }

  /// --------------------------------------------------------------------------
  /// SINGLE UPDATE (Para WebSockets / Tiempo Real)
  /// --------------------------------------------------------------------------
  Future<void> insertOrUpdateSingle(ResultUbicaciones item) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      await db.insert(
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

      final List<Map<String, dynamic>> res = await db.query(
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

  Future<List<ResultUbicaciones>> getAllUbicaciones() async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps =
          await db.query(UbicacionesTable.tableName);
      if (maps.isEmpty) return [];
      if (maps.length <= _umbralCompute) return _parseUbicacionesMap(maps);
      return await compute(_parseUbicacionesMap, maps);
    } catch (e) {
      debugPrint("Error getAllUbicaciones: $e");
      return [];
    }
  }

  Future<List<ResultUbicaciones>> getAllUbicacionesByParams(
      String params) async {
    try {
      final db = await DataBaseSqlite().getDatabaseInstance();
      final List<Map<String, dynamic>> maps = await db.query(
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
    await db.delete(UbicacionesTable.tableName);
  }
}
