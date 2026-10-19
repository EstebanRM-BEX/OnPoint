import 'package:http/http.dart' as http;

/// Datos de WMS que el servidor manda en los encabezados de la respuesta de
/// picking, packing y expedición (`secuencia_wms`, `placa_wms`).
///
/// Son por respuesta, no por registro: se leen una vez por petición y se
/// pasan a los modelos de resultado. Si el encabezado no llega, queda ''.
class WmsHeaders {
  final String secuencia;
  final String placa;

  const WmsHeaders({
    this.secuencia = '',
    this.placa = '',
  });

  static const WmsHeaders empty = WmsHeaders();

  factory WmsHeaders.fromResponse(http.Response response) {
    String read(String name) {
      // dart:io puede devolver los nombres con mayúsculas: se compara sin caso.
      for (final entry in response.headers.entries) {
        if (entry.key.toLowerCase() == name) return entry.value;
      }
      return '';
    }

    return WmsHeaders(
      secuencia: read('secuencia_wms'),
      placa: read('placa_wms'),
    );
  }
}
