import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../src/api/api_request_service.dart';
import '../models/device_registration_model.dart';
import '../models/user_configuration_model.dart';
import '../models/user_location_model.dart';
import '../models/user_novelty_model.dart';

/// Respuesta de `/api/ubicaciones` ya parseada.
///
/// [full] = [ubicaciones] es la lista completa (reemplazar todo). Con
/// `false` trae solo las cambiadas, y las locales que no estén en [activos]
/// se borran. Servidor sin sync incremental: no manda `server_time`, se trata
/// como completa y [serverTime]/[scope] quedan en null.
class UbicacionesSyncResult {
  final List<UserLocationModel> ubicaciones;
  final bool full;
  final String? serverTime;
  final String? scope;
  final List<int>? activos;

  const UbicacionesSyncResult({
    required this.ubicaciones,
    this.full = true,
    this.serverTime,
    this.scope,
    this.activos,
  });
}

/// Parsea la respuesta de `/api/ubicaciones` (los campos del sync van dentro
/// de `result`, junto a `code`). Lanza en error o sesión expirada.
UbicacionesSyncResult parseUbicacionesSync(String body) {
  final json = jsonDecode(body) as Map<String, dynamic>;
  final error = json['error'];
  if (error is Map) {
    if (error['code'] == 100) {
      throw const SessionExpiredException('Sesión expirada');
    }
    throw ServerException('${error['message'] ?? 'Failed to load locations'}');
  }
  final r = json['result'];
  if (r is! Map<String, dynamic> || r['code'] != 200) {
    throw const ServerException('Failed to load locations');
  }
  final serverTime = r['server_time'] is String && r['server_time'] != ''
      ? r['server_time'] as String
      : null;
  final scope =
      r['scope'] is String && r['scope'] != '' ? r['scope'] as String : null;
  final activos = r['active_location_ids'];
  return UbicacionesSyncResult(
    ubicaciones: [
      for (final e in (r['result'] as List<dynamic>? ?? const []))
        UserLocationModel.fromJson(e as Map<String, dynamic>),
    ],
    // Sin server_time es el servidor anterior: siempre completo.
    full: serverTime == null || r['full'] != false,
    serverTime: serverTime,
    scope: scope,
    activos: activos is List
        ? [for (final id in activos) if (id is num) id.toInt()]
        : null,
  );
}

abstract class UserRemoteDataSource {
  Future<UserConfigurationModel> getUserConfiguration();

  /// Con [since] y [scope] pide solo lo cambiado (el servidor puede igual
  /// responder completo: ver [UbicacionesSyncResult.full]).
  Future<UbicacionesSyncResult> getUserLocations({
    String? since,
    String? scope,
  });
  Future<List<UserNoveltyModel>> getNovelties();
  Future<DeviceRegistrationModel> registerDevice(String deviceId,
      String deviceName, String deviceModel, String versionApp);
}

@LazySingleton(as: UserRemoteDataSource)
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiRequestService apiService;

  UserRemoteDataSourceImpl(this.apiService);

  @override
  Future<UserConfigurationModel> getUserConfiguration() async {
    final response = await apiService.get(
      endpoint: 'configurations',
      isunecodePath: true,
      isLoadinDialog: false,
    );

    if (response.statusCode < 400) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final config = UserConfigurationModel.fromJson(jsonResponse);

      final code = config.result?.code;
      if (code != 200) {
        final msg = config.result?.msg?.toString().isNotEmpty == true
            ? config.result!.msg.toString()
            : 'No tienes permisos para acceder a la aplicación';
        throw ServerException(msg);
      }

      return config;
    } else if (response.statusCode == 404) {
      // Odoo multi-base responde 404 (no el code 100) cuando la cookie de
      // sesión ya no es válida: no sabe a qué base enrutar la petición.
      throw const ServerException(
        'Tu sesión no es válida o expiró. Inicia sesión de nuevo.',
      );
    } else {
      throw ServerException('Error del servidor: ${response.statusCode}');
    }
  }

  @override
  Future<UbicacionesSyncResult> getUserLocations({
    String? since,
    String? scope,
  }) async {
    final incremental = since != null && scope != null;
    final response = await apiService.postPicking(
      endpoint: 'ubicaciones',
      body: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': incremental ? {'since': since, 'scope': scope} : {},
      },
      isunecodePath: true,
      isLoadinDialog: false,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error del servidor: ${response.statusCode}');
    }
    final r = parseUbicacionesSync(response.body);
    // Si no se pidió incremental, la respuesta es completa sí o sí.
    if (incremental || r.full) return r;
    return UbicacionesSyncResult(
      ubicaciones: r.ubicaciones,
      serverTime: r.serverTime,
      scope: r.scope,
    );
  }

  @override
  Future<List<UserNoveltyModel>> getNovelties() async {
    final response = await apiService.get(
      endpoint: 'picking_novelties',
      isunecodePath: true,
      isLoadinDialog: false,
    );

    if (response.statusCode < 400) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('result') &&
          jsonResponse['result']['code'] == 200) {
        final List<dynamic> list = jsonResponse['result']['result'] ?? [];
        return list.map((e) => UserNoveltyModel.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load novelties');
  }

  @override
  Future<DeviceRegistrationModel> registerDevice(String deviceId,
      String deviceName, String deviceModel, String versionApp) async {
    final response = await apiService.postPicking(
      endpoint: 'pda/register',
      body: {
        "params": {
          "device_id": deviceId,
          "device_name": deviceName,
          "device_model": deviceModel,
          "version_app": versionApp,
        }
      },
      isunecodePath: true,
      isLoadinDialog: false,
    );

    if (response.statusCode < 400) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('result') &&
          jsonResponse['result']['code'] == 200) {
        final Map<String, dynamic> data = jsonResponse['result']['data'];
        return DeviceRegistrationModel.fromJson(data);
      }
      throw Exception(jsonResponse['result']?['msg'] ?? 'Failed to register device');
    }
    throw Exception('Failed to register device');
  }
}
