import 'dart:async';
import 'dart:io';

import 'package:wms_app/core/network/network_quality_metrics.dart';
import 'package:wms_app/core/network/network_quality_sampler.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

/// Servidor contra el que se mide: el Odoo activo (lo que importa a la app).
/// Antes del login, un host público. Se cachea para no leer prefs en cada
/// muestra.
class ProbeTargetResolver {
  static const fallbackHost = 'www.gstatic.com';
  static const _fallback = 'https://$fallbackHost/generate_204';
  static const _ttl = Duration(minutes: 1);

  Uri? _base;
  DateTime? _at;

  Future<Uri> _resolveBase() async {
    final at = _at;
    if (_base != null && at != null && DateTime.now().difference(at) < _ttl) {
      return _base!;
    }
    final url = await PrefUtils.getEnterprise();
    final uri = Uri.tryParse(url.trim());
    _base = (uri == null || uri.host.isEmpty) ? null : uri;
    _at = DateTime.now();
    return _base ?? Uri.parse(_fallback);
  }

  /// URL del GET: la ruta indicada sobre el servidor Odoo, o el endpoint
  /// `generate_204` si todavía no hay empresa configurada.
  Future<Uri> httpUri(String path) async {
    final base = await _resolveBase();
    if (base.toString() == _fallback) return base;
    return Uri(
      scheme: base.scheme.isEmpty ? 'https' : base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
    );
  }

  Future<(String, int)> tcpTarget() async {
    final base = await _resolveBase();
    return (
      base.host,
      base.hasPort ? base.port : (base.scheme == 'http' ? 80 : 443),
    );
  }
}

/// RTT de apertura de un socket TCP. El socket se cierra siempre y el intento
/// de conexión se cancela si vence el timeout.
class TcpConnectProbe {
  TcpConnectProbe({required this.resolver, required this.timeout});

  final ProbeTargetResolver resolver;
  final Duration timeout;

  Future<int> call() async {
    final (host, port) = await resolver.tcpTarget();
    final sw = Stopwatch()..start();
    final task = await Socket.startConnect(host, port);
    try {
      final socket = await task.socket.timeout(timeout);
      sw.stop();
      socket.destroy();
      return sw.elapsedMilliseconds;
    } catch (_) {
      task.cancel();
      rethrow;
    }
  }

  void dispose() {}
}

/// RTT de un GET ligero sobre un cliente HTTP persistente (keep-alive):
/// se mide desde el envío hasta recibir la respuesta completa. Un código que
/// no sea 2xx lanza (cuenta como pérdida). La petición se aborta al vencer.
class HttpRoundTripProbe {
  HttpRoundTripProbe({required this.resolver, required this.config})
    : _client = HttpClient()
        ..connectionTimeout = config.probeTimeout
        ..idleTimeout = const Duration(seconds: 15)
        ..userAgent = 'wms_app-netquality';

  final ProbeTargetResolver resolver;
  final NetworkQualityConfig config;
  final HttpClient _client;

  Future<int> call() async {
    final uri = await resolver.httpUri(config.httpProbePath);
    HttpClientRequest? request;
    var finished = false;

    Future<int> run() async {
      // El fallback pre-login (generate_204) solo admite GET.
      final post =
          config.httpProbeJsonRpcPost &&
          uri.host != ProbeTargetResolver.fallbackHost;
      request = post ? await _client.postUrl(uri) : await _client.getUrl(uri);
      request!.followRedirects = false;
      if (post) {
        request!.headers.contentType = ContentType.json;
        request!.write('{"jsonrpc":"2.0","method":"call","params":{}}');
      }
      final sw = Stopwatch()..start();
      final response = await request!.close();
      await response.drain<void>();
      sw.stop();
      finished = true;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      return sw.elapsedMilliseconds;
    }

    try {
      return await run().timeout(config.probeTimeout);
    } catch (_) {
      if (!finished) request?.abort();
      rethrow;
    }
  }

  void dispose() => _client.close(force: true);
}

/// Construye el probe del modo configurado.
({RttProbe probe, void Function() dispose}) buildRttProbe(
  NetworkQualityConfig config,
) {
  final resolver = ProbeTargetResolver();
  switch (config.probeMode) {
    case NetworkProbeMode.tcpConnect:
      final p = TcpConnectProbe(
        resolver: resolver,
        timeout: config.probeTimeout,
      );
      return (probe: p.call, dispose: p.dispose);
    case NetworkProbeMode.httpProbe:
      final p = HttpRoundTripProbe(resolver: resolver, config: config);
      return (probe: p.call, dispose: p.dispose);
  }
}
