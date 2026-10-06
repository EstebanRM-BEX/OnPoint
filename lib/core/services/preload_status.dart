import 'package:flutter/foundation.dart';

/// Qué precargas post-login siguen "en espera" (en cola, descargando o
/// insertando en SQLite).
///
/// El Resumen operativo del Home lee los conteos de la BD, que valen 0 hasta
/// que termina la inserción: sin esto el operario veía "0" y creía que no había
/// datos. Mientras una clave esté pendiente, la UI muestra "En espera".
class PreloadStatus extends ChangeNotifier {
  PreloadStatus._();
  static final PreloadStatus instance = PreloadStatus._();

  static const productos = 'productos';
  static const ubicaciones = 'ubicaciones';
  static const novedades = 'novedades';

  final Set<String> _pending = {};

  bool isPending(String key) => _pending.contains(key);

  /// Marca todas como pendientes al arrancar la secuencia de precargas.
  void start(Iterable<String> keys) {
    _pending
      ..clear()
      ..addAll(keys);
    notifyListeners();
  }

  /// Termina una precarga (con éxito, error o timeout: nunca queda pegada).
  void done(String key) {
    if (_pending.remove(key)) notifyListeners();
  }
}
