import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP que registra cada petición como `HttpMetric` en Firebase
/// Performance (latencia, código de respuesta y tamaño de payload por
/// endpoint). En Flutter las llamadas del paquete `http` no se capturan
/// automáticamente, por eso todo el tráfico de [ApiRequestService] pasa por
/// acá.
class PerformanceHttpClient extends http.BaseClient {
  PerformanceHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final metric = _newMetric(request);
    if (metric == null) return _inner.send(request);

    try {
      await metric.start();
      if (request.contentLength != null) {
        metric.requestPayloadSize = request.contentLength;
      }

      final response = await _inner.send(request);
      metric
        ..httpResponseCode = response.statusCode
        ..responseContentType = response.headers['content-type'];

      // La métrica se cierra cuando termina de leerse el body, así la
      // duración incluye la descarga completa y no solo los headers.
      var bytes = 0;
      final stream = response.stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            bytes += chunk.length;
            sink.add(chunk);
          },
          handleError: (error, stack, sink) {
            unawaited(metric.stop());
            sink.addError(error, stack);
          },
          handleDone: (sink) {
            metric.responsePayloadSize = bytes;
            unawaited(metric.stop());
            sink.close();
          },
        ),
      );

      return http.StreamedResponse(
        stream,
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (_) {
      unawaited(metric.stop());
      rethrow;
    }
  }

  HttpMetric? _newMetric(http.BaseRequest request) {
    final method = _methods[request.method.toUpperCase()];
    if (method == null) return null;
    // Sin query string: puede traer ids/tokens y rompe la agrupación por
    // endpoint en la consola.
    final u = request.url;
    final url = Uri(
      scheme: u.scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: u.path,
    ).toString();
    return FirebasePerformance.instance.newHttpMetric(url, method);
  }

  static const _methods = {
    'GET': HttpMethod.Get,
    'POST': HttpMethod.Post,
    'PUT': HttpMethod.Put,
    'DELETE': HttpMethod.Delete,
    'PATCH': HttpMethod.Patch,
  };

  @override
  void close() => _inner.close();
}
