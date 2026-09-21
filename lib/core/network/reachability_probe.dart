import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

/// Resultado de una sonda de alcance real (no solo "hay interfaz de red").
enum ProbeResult {
  /// El servidor Odoo de la empresa responde.
  ok,

  /// Hay salida a internet pero el servidor Odoo no responde.
  serverUnreachable,

  /// No hay salida a internet.
  noInternet,
}

abstract class ReachabilityProbe {
  Future<ProbeResult> check();
}

/// Sonda HTTP ligera. Primero el servidor Odoo de la empresa activa (lo que
/// realmente importa a la app) y, si falla, endpoints públicos `generate_204`
/// para distinguir "sin internet" de "servidor caído".
///
/// Usa `dart:io` directo: cualquier respuesta HTTP (incluso 401/404) prueba
/// que el host es alcanzable, y no se descarga cuerpo.
@LazySingleton(as: ReachabilityProbe)
class HttpReachabilityProbe implements ReachabilityProbe {
  static const Duration _timeout = Duration(seconds: 3);
  static const List<String> _internetEndpoints = [
    'https://www.gstatic.com/generate_204',
    'https://cp.cloudflare.com/generate_204',
  ];

  final HttpClient _client = HttpClient()
    ..connectionTimeout = _timeout
    ..idleTimeout = const Duration(seconds: 5)
    ..userAgent = 'wms_app-reachability';

  @override
  Future<ProbeResult> check() async {
    final serverUrl = (await PrefUtils.getEnterprise()).trim();
    if (serverUrl.isNotEmpty && await _reach(serverUrl, head: true)) {
      return ProbeResult.ok;
    }

    // En paralelo: gana el primero que responda, sin sumar timeouts.
    final internet = await _anySuccess(
      _internetEndpoints.map((u) => _reach(u, head: false)),
    );
    if (!internet) return ProbeResult.noInternet;
    // Sin URL de empresa configurada (pre-login) basta con tener internet.
    return serverUrl.isEmpty ? ProbeResult.ok : ProbeResult.serverUnreachable;
  }

  Future<bool> _reach(String url, {required bool head}) async {
    try {
      final uri = Uri.parse(url);
      final request = await (head ? _client.headUrl(uri) : _client.getUrl(uri))
          .timeout(_timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(_timeout);
      await response.drain<void>();
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> _anySuccess(Iterable<Future<bool>> futures) {
    final completer = Completer<bool>();
    var pending = futures.length;
    if (pending == 0) return Future.value(false);
    for (final f in futures) {
      f.then((ok) {
        if (ok && !completer.isCompleted) completer.complete(true);
        if (--pending == 0 && !completer.isCompleted) completer.complete(false);
      });
    }
    return completer.future;
  }
}
