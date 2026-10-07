import 'package:equatable/equatable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';

enum TipoOperacion {
  ninguna,
  procesando,
  exito,
  error,

  /// La sesión de Odoo expiró: la UI debe mandar a iniciar sesión.
  sesionExpirada,

  /// Odoo procesó algo que el dispositivo no pudo reflejar: refrescar.
  desincronizado,
}

/// Resultado de la última acción de un bloc, para avisos de una sola vez
/// (snackbar, diálogo de carga, error). [seq] cambia en cada emisión, así un
/// `BlocListener` con `listenWhen: (a, b) => a.operacion.seq != b.operacion.seq`
/// se dispara aunque el mensaje se repita.
class PackingOperacion extends Equatable {
  final TipoOperacion tipo;
  final String mensaje;

  /// Qué acción la originó (p. ej. 'crearPaquete'), para que la UI decida.
  final String accion;
  final int seq;

  const PackingOperacion({
    this.tipo = TipoOperacion.ninguna,
    this.mensaje = '',
    this.accion = '',
    this.seq = 0,
  });

  static const ninguna = PackingOperacion();

  bool get procesando => tipo == TipoOperacion.procesando;
  bool get esError =>
      tipo == TipoOperacion.error ||
      tipo == TipoOperacion.sesionExpirada ||
      tipo == TipoOperacion.desincronizado;

  PackingOperacion procesar(String accion, [String mensaje = '']) =>
      PackingOperacion(
        tipo: TipoOperacion.procesando,
        mensaje: mensaje,
        accion: accion,
        seq: seq + 1,
      );

  PackingOperacion exito(String accion, [String mensaje = '']) =>
      PackingOperacion(
        tipo: TipoOperacion.exito,
        mensaje: mensaje,
        accion: accion,
        seq: seq + 1,
      );

  PackingOperacion error(String accion, String mensaje) => PackingOperacion(
    tipo: TipoOperacion.error,
    mensaje: mensaje,
    accion: accion,
    seq: seq + 1,
  );

  PackingOperacion fallo(String accion, Failure f) => PackingOperacion(
    tipo: switch (f) {
      SessionExpiredFailure() => TipoOperacion.sesionExpirada,
      PackingDesyncFailure() => TipoOperacion.desincronizado,
      _ => TipoOperacion.error,
    },
    mensaje: f.message,
    accion: accion,
    seq: seq + 1,
  );

  @override
  List<Object?> get props => [tipo, mensaje, accion, seq];
}
