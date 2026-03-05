// urls_recientes_repository.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/enterprise/domain/entities/recent_url.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_urlrecientes/urlrecientes_table.dart';

class UrlsRecientesRepository {
  UrlsRecientesRepository();

  // Método para obtener todas las URLs recientes
  Future<List<RecentUrl>> getAllUrlsRecientes() async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      final List<Map<String, dynamic>> maps =
          await db.query(UrlsRecientesTable.tableName);

      final List<RecentUrl> urls = maps.map((map) {
        return RecentUrl(
          id: map[UrlsRecientesTable.columnId],
          url: map[UrlsRecientesTable.columnUrl],
          fecha: map[UrlsRecientesTable.columnFecha],
        );
      }).toList();

      return urls;
    } catch (e) {
      debugPrint("Error al obtener URLs recientes: $e");
      return []; // Devuelve una lista vacía en caso de error
    }
  }

  // Método para insertar o actualizar una URL reciente
  Future<void> insertUrlReciente(RecentUrl url) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        final List<Map<String, dynamic>> existingUrl = await txn.query(
          UrlsRecientesTable.tableName,
          where: '${UrlsRecientesTable.columnUrl} = ?',
          whereArgs: [url.url],
        );

        if (existingUrl.isNotEmpty) {
          await txn.update(
            UrlsRecientesTable.tableName,
            {
              UrlsRecientesTable.columnUrl: url.url,
              UrlsRecientesTable.columnFecha: url.fecha,
            },
            where: '${UrlsRecientesTable.columnUrl} = ?',
            whereArgs: [url.url],
          );
        } else {
          await txn.insert(
            UrlsRecientesTable.tableName,
            {
              UrlsRecientesTable.columnUrl: url.url,
              UrlsRecientesTable.columnFecha: url.fecha,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      debugPrint("Error al insertar/actualizar URL reciente: $e");
    }
  }

  // Método para eliminar una URL reciente
  Future<void> deleteUrlReciente(String url) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();
      await db.delete(
        UrlsRecientesTable.tableName,
        where: '${UrlsRecientesTable.columnUrl} = ?',
        whereArgs: [url],
      );
    } catch (e) {
      debugPrint("Error al eliminar URL reciente: $e");
    }
  }
}
