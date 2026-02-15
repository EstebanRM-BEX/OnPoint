import 'package:injectable/injectable.dart';
import '../../../../src/presentation/providers/db/database.dart';
import '../../../../src/presentation/providers/db/others/tbl_urlrecientes/urlrecientes_table.dart';
import '../../../../src/core/utils/prefs/pref_utils.dart';
import '../models/recent_url_model.dart';
import 'package:sqflite/sqflite.dart';

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

    return maps
        .map((map) => RecentUrlModel.fromJson({
              'id': map[UrlsRecientesTable.columnId],
              'url': map[UrlsRecientesTable.columnUrl],
              'fecha': _parseOldDateFormat(map[UrlsRecientesTable.columnFecha]),
            }))
        .toList();
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
    await db.insert(
      UrlsRecientesTable.tableName,
      recentUrl.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
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
