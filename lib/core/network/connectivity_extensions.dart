import 'package:connectivity_plus/connectivity_plus.dart';

/// Helpers para evaluar el estado real de conexión.
///
/// `connectivity_plus` 6.x cambió `checkConnectivity()` para devolver
/// `List<ConnectivityResult>` en lugar de un único `ConnectivityResult`.
/// El código previo comparaba la lista contra un solo valor
/// (`result == ConnectivityResult.none`), lo cual es SIEMPRE falso: la guarda
/// de "sin conexión" nunca se disparaba. Estos helpers concentran la lógica
/// correcta en un solo lugar.
extension ConnectivityResultListX on List<ConnectivityResult> {
  /// `true` si no hay ninguna interfaz de red activa.
  bool get isOffline => isEmpty || contains(ConnectivityResult.none);

  /// `true` si hay al menos una interfaz de red activa.
  bool get isOnline => !isOffline;
}
