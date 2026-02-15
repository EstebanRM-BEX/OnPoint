import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/home/domain/entities/user_data.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';

/// Abstract data source for local operations.
abstract class HomeLocalDataSource {
  Future<UserData> getUserData();
  Future<UserConfiguration> getUserConfigurations(int userId);
}

/// Implementation of local data source using shared preferences and local database.
@LazySingleton(as: HomeLocalDataSource)
class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final DataBaseSqlite database;

  HomeLocalDataSourceImpl(this.database);

  @override
  Future<UserData> getUserData() async {
    try {
      final name = await PrefUtils.getUserName();
      final email = await PrefUtils.getUserEmail();
      final rol = await PrefUtils.getUserRol();

      return UserData(
        name: name,
        email: email,
        rol: rol,
      );
    } catch (e) {
      throw CacheException('Error al obtener datos del usuario: $e');
    }
  }

  @override
  Future<UserConfiguration> getUserConfigurations(int userId) async {
    try {
      final config =
          await database.configurationsRepository.getConfiguration(userId);

      if (config == null) {
        throw const CacheException('No se encontraron configuraciones');
      }

      return config;
    } catch (e) {
      throw CacheException('Error al obtener configuraciones: $e');
    }
  }
}
