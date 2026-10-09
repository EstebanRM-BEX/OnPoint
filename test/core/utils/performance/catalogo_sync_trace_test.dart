import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/core/utils/performance/catalogo_sync_trace.dart';

void main() {
  String motivo({
    String? local,
    String? enviado,
    String? serverTime = '2026-10-09 16:00:00',
    String? recibido,
  }) => motivoDescargaCompleta(
    motivoLocal: local,
    scopeEnviado: enviado,
    serverTime: serverTime,
    scopeRecibido: recibido,
  );

  test('sin server_time es el backend anterior', () {
    expect(motivo(local: 'sin_marca', serverTime: null), 'backend_anterior');
  });

  test('si la app no pidió incremental gana el motivo local', () {
    expect(motivo(local: 'empresa_distinta', recibido: 'x'), 'empresa_distinta');
  });

  test('scope recibido distinto al enviado', () {
    expect(motivo(enviado: 'a', recibido: 'b'), 'scope_distinto');
  });

  test('mismo scope: el servidor decidió completa', () {
    expect(motivo(enviado: 'a', recibido: 'a'), 'servidor_full');
  });

  test('en tests (debug) la traza es un no-op', () {
    final t = CatalogoSyncTrace.iniciar()
      ..atributo('tipo', 'completa')
      ..metrica('filas', 1)
      ..tramo('ms_descarga');
    t.terminar('ok');
  });
}
