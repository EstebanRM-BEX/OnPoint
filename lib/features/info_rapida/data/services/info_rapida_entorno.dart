import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wms_app/core/network/network_guard.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

/// Servicio de entorno para Información Rápida.
///
/// Centraliza la lectura de conectividad, dispositivo PDA, versión de la app,
/// usuario activo y empresa seleccionada para permitir pruebas unitarias limpias.
@lazySingleton
class InfoRapidaEntorno {
  final IStorageService storageService;

  InfoRapidaEntorno(this.storageService);

  /// Verifica si el dispositivo cuenta con conexión a Internet activa.
  Future<bool> hayRed() => hasNetwork();

  /// Identificador único del dispositivo (MAC o IMEI si la MAC no está disponible).
  Future<String> deviceId() => PrefUtils.getDeviceIdPDA();

  /// Versión actual de la aplicación (ej. '1.7.2').
  Future<String> versionApp() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '';
    }
  }

  /// ID del usuario autenticado actualmente en la sesión.
  Future<int> userId() => PrefUtils.getUserId();

  /// Nombre de la base de datos (empresa) activa.
  String databaseName() => storageService.nameDatabase;
}
