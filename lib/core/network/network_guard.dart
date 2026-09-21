import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wms_app/core/network/connectivity_extensions.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/injection_container.dart' show getIt;

/// Guarda de red para repositorios y servicios que no reciben [NetworkInfo]
/// por constructor.
///
/// Sin latencia en el camino feliz:
/// 1. Sin interfaz de red → `false` inmediato (llamada de plataforma barata).
/// 2. [NetworkInfo.current] online → `true`, sin I/O.
/// 3. Estado offline → [NetworkInfo.verify] (caché corta) por si ya volvió.
///
/// Si [NetworkInfo] no está registrado (tests), solo evalúa la interfaz.
Future<bool> hasNetwork() async {
  final interfaces = await Connectivity().checkConnectivity();
  if (interfaces.isOffline) return false;
  if (!getIt.isRegistered<NetworkInfo>()) return true;
  final networkInfo = getIt<NetworkInfo>();
  if (networkInfo.current == ConnectionStatus.online) return true;
  return networkInfo.verify();
}
