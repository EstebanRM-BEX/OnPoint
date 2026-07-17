import 'package:injectable/injectable.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import '../../../../src/presentation/providers/db/database.dart';
import '../../../../src/presentation/providers/db/others/tbl_urlrecientes/urlrecientes_table.dart';
import '../models/recent_url_model.dart';

abstract class EnterpriseLocalDataSource {
  Future<List<RecentUrlModel>> getRecentUrls();
  Future<void> saveRecentUrl(RecentUrlModel recentUrl);
  Future<void> deleteRecentUrl(String url);
  Future<void> cacheEnterpriseUrl(String url);
}

@LazySingleton(as: EnterpriseLocalDataSource)
class EnterpriseLocalDataSourceImpl implements EnterpriseLocalDataSource {
  final DataBaseSqlite database;

  EnterpriseLocalDataSourceImpl(this.database);

  @override
  Future<List<RecentUrlModel>> getRecentUrls() async {
    final db = await database.getDatabaseInstance();
    final List<Map<String, dynamic>> maps =
        await db.query(UrlsRecientesTable.tableName);

    final models = <RecentUrlModel>[];
    for (final map in maps) {
      final String? rawFecha = map[UrlsRecientesTable.columnFecha];
      final normalized = _parseOldDateFormat(rawFecha);

      // Si la fila tenía el formato legacy (day/month/year), la normalizamos
      // en la BD para que las próximas cargas no vuelvan a convertirla.
      if (normalized != rawFecha) {
        await db.update(
          UrlsRecientesTable.tableName,
          {UrlsRecientesTable.columnFecha: normalized},
          where: '${UrlsRecientesTable.columnId} = ?',
          whereArgs: [map[UrlsRecientesTable.columnId]],
        );
      }

      models.add(RecentUrlModel.fromJson({
        'id': map[UrlsRecientesTable.columnId],
        'url': map[UrlsRecientesTable.columnUrl],
        'fecha': normalized,
      }));
    }
    return models;
  }

  /// The old implementation saved dates as "day/month/year".
  /// We need to handle this to avoid crashes when parsing as ISO-8601.
  String _parseOldDateFormat(String? dateStr) {
    if (dateStr == null) return DateTime.now().toIso8601String();
    try {
      // Try ISO parse first
      DateTime.parse(dateStr);
      return dateStr;
    } catch (_) {
      // Fallback to day/month/year
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
      return DateTime.now().toIso8601String();
    }
  }

  @override
  Future<void> saveRecentUrl(RecentUrlModel recentUrl) async {
    final db = await database.getDatabaseInstance();

    // Insert atómico: solo inserta si la URL no existe todavía.
    // Evita la carrera del patrón "query y después insert".
    await db.rawInsert(
      '''
      INSERT INTO ${UrlsRecientesTable.tableName}
        (${UrlsRecientesTable.columnUrl}, ${UrlsRecientesTable.columnFecha})
      SELECT ?, ?
      WHERE NOT EXISTS (
        SELECT 1 FROM ${UrlsRecientesTable.tableName}
        WHERE ${UrlsRecientesTable.columnUrl} = ?
      )
      ''',
      [recentUrl.url, recentUrl.fecha.toIso8601String(), recentUrl.url],
    );
  }

  @override
  Future<void> deleteRecentUrl(String url) async {
    final db = await database.getDatabaseInstance();
    await db.delete(
      UrlsRecientesTable.tableName,
      where: '${UrlsRecientesTable.columnUrl} = ?',
      whereArgs: [url],
    );
  }

  @override
  Future<void> cacheEnterpriseUrl(String url) async {
    await PrefUtils.setEnterprise(url);
  }
}
