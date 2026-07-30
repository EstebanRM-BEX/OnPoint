import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/src/api/api_request_service.dart';

/// Estas pruebas blindan el contrato de las respuestas sintéticas de
/// [ApiRequestService] (sin conexión, timeout, error inesperado).
///
/// Antes se devolvía texto plano ('Error de red'), que reventaba el
/// `jsonDecode(response.body)` de los repositorios que parsean el cuerpo en
/// errores. Esos repositorios usan guards `statusCode <= 500` a propósito:
/// Odoo entrega sus errores como HTTP 500 con cuerpo JSON, incluida la sesión
/// expirada (`error.code == 100`). Por eso el guard NO se puede estrechar a
/// `< 400`, y la respuesta sintética sí debe ser JSON válido.
void main() {
  group('buildClientErrorResponse', () {
    test('el cuerpo es JSON decodificable (no revienta jsonDecode)', () {
      final response =
          ApiRequestService.buildClientErrorResponse(404, 'Error de red');

      expect(() => jsonDecode(response.body), returnsNormally);
      expect(jsonDecode(response.body), isA<Map<String, dynamic>>());
    });

    test('conserva el statusCode que se le pasa', () {
      expect(ApiRequestService.buildClientErrorResponse(404, 'x').statusCode,
          404);
      expect(ApiRequestService.buildClientErrorResponse(408, 'x').statusCode,
          408);
      expect(ApiRequestService.buildClientErrorResponse(500, 'x').statusCode,
          500);
    });

    test('nunca usa code 100: no dispara el diálogo de sesión expirada', () {
      // 49 call sites hacen exactamente: if (jsonResponse['error']['code'] == 100)
      for (final status in [404, 408, 500]) {
        final json = jsonDecode(
                ApiRequestService.buildClientErrorResponse(status, 'fallo').body)
            as Map<String, dynamic>;

        expect(json['error']['code'], isNot(100),
            reason: 'un $status no debe simular sesión expirada');
      }
    });

    test('expone el mensaje en las claves que leen los repositorios', () {
      final json = jsonDecode(ApiRequestService.buildClientErrorResponse(
              408, 'La solicitud superó el tiempo de espera')
          .body) as Map<String, dynamic>;

      // Patrones observados en lib/: error.message, error.msg, error.data.message
      expect(json['error']['message'], 'La solicitud superó el tiempo de espera');
      expect(json['error']['msg'], 'La solicitud superó el tiempo de espera');
      expect(json['error']['data']['message'],
          'La solicitud superó el tiempo de espera');
    });

    test('no trae update_version: no fuerza la pantalla de actualización', () {
      final json = jsonDecode(
              ApiRequestService.buildClientErrorResponse(404, 'Error de red').body)
          as Map<String, dynamic>;

      expect(json['error']['update_version'], isNull);
    });
  });

  group('comportamiento en los repositorios que parsean el body', () {
    /// Reproduce el patrón literal de los ~10 call sites con guard `<= 500`
    /// (transferencias, wms_packing, recepcion). Devuelve la rama tomada.
    String simularCallSite(int statusCode, String body) {
      if (statusCode <= 500) {
        final jsonResponse = jsonDecode(body) as Map<String, dynamic>;

        if (jsonResponse.containsKey('result')) return 'result';
        if (jsonResponse.containsKey('error')) {
          if (jsonResponse['error']['code'] == 100) return 'sesion-expirada';
          return 'error';
        }
      }
      return 'vacio';
    }

    test('una respuesta sintética entra por la rama de error, sin excepción',
        () {
      final response =
          ApiRequestService.buildClientErrorResponse(408, 'Timeout');

      expect(simularCallSite(response.statusCode, response.body), 'error');
    });

    test('el texto plano anterior sí lanzaba FormatException', () {
      // Regresión que se está corrigiendo: este era el comportamiento previo
      // ante offline (404) y timeout (408).
      expect(() => simularCallSite(404, 'Error de red'),
          throwsA(isA<FormatException>()));
    });

    test('la sesión expirada de Odoo (HTTP 500 + code 100) sigue detectándose',
        () {
      // Comprueba que el guard `<= 500` conserva su razón de ser.
      final bodyOdoo = jsonEncode({
        'jsonrpc': '2.0',
        'error': {'code': 100, 'message': 'Odoo Session Expired'},
      });

      expect(simularCallSite(500, bodyOdoo), 'sesion-expirada');
    });

    test('una respuesta exitosa sigue entrando por result', () {
      final bodyOk = jsonEncode({
        'jsonrpc': '2.0',
        'result': {'code': 200, 'msg': 'ok'},
      });

      expect(simularCallSite(200, bodyOk), 'result');
    });
  });
}
