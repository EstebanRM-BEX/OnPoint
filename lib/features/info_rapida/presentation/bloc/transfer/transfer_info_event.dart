part of 'transfer_info_bloc.dart';

sealed class TransferInfoEvent extends Equatable {
  const TransferInfoEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializa el flujo de transferencia individual con los datos del producto
/// y ubicación origen seleccionados.
class TransferInfoInicializado extends TransferInfoEvent {
  final int idAlmacen;
  final int idMove;
  final int idProducto;
  final String nombreProducto;
  final int idLote;
  final String nombreLote;
  final int idUbicacionOrigen;
  final String nombreUbicacionOrigen;
  final double cantidadDisponible;
  final int? idPropietario;
  final String? propietario;
  final bool? manejoPropietario;

  const TransferInfoInicializado({
    required this.idAlmacen,
    required this.idMove,
    required this.idProducto,
    required this.nombreProducto,
    required this.idLote,
    required this.nombreLote,
    required this.idUbicacionOrigen,
    required this.nombreUbicacionOrigen,
    required this.cantidadDisponible,
    this.idPropietario,
    this.propietario,
    this.manejoPropietario,
  });

  @override
  List<Object?> get props => [
        idAlmacen,
        idMove,
        idProducto,
        nombreProducto,
        idLote,
        nombreLote,
        idUbicacionOrigen,
        nombreUbicacionOrigen,
        cantidadDisponible,
        idPropietario,
        propietario,
        manejoPropietario,
      ];
}

/// Carga el catálogo de posibles ubicaciones destino desde la caché.
class CargarUbicacionesDestinoTransferEvent extends TransferInfoEvent {
  const CargarUbicacionesDestinoTransferEvent();
}

/// Filtra las ubicaciones destino por texto de búsqueda.
class BuscarUbicacionDestinoTransferEvent extends TransferInfoEvent {
  final String query;

  const BuscarUbicacionDestinoTransferEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Filtra las ubicaciones destino por almacén.
class FiltrarUbicacionesDestinoAlmacenEvent extends TransferInfoEvent {
  final String? almacen;

  const FiltrarUbicacionesDestinoAlmacenEvent(this.almacen);

  @override
  List<Object?> get props => [almacen];
}

/// Selecciona manualmente una ubicación destino de la lista.
class SeleccionarUbicacionDestinoEvent extends TransferInfoEvent {
  final UbicacionCatalogo ubicacion;

  const SeleccionarUbicacionDestinoEvent(this.ubicacion);

  @override
  List<Object?> get props => [ubicacion];
}

/// Escanea un código de barras para seleccionar la ubicación destino.
class EscanearUbicacionDestinoEvent extends TransferInfoEvent {
  final String barcode;

  const EscanearUbicacionDestinoEvent(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// Modifica y valida la cantidad a transferir.
class CambiarCantidadTransferEvent extends TransferInfoEvent {
  final double cantidad;

  const CambiarCantidadTransferEvent(this.cantidad);

  @override
  List<Object?> get props => [cantidad];
}

/// Modifica la observación / nota de la transferencia.
class CambiarObservacionTransferEvent extends TransferInfoEvent {
  final String observacion;

  const CambiarObservacionTransferEvent(this.observacion);

  @override
  List<Object?> get props => [observacion];
}

/// Ejecuta la creación de la transferencia individual en el backend.
class ConfirmarTransferenciaIndividualEvent extends TransferInfoEvent {
  const ConfirmarTransferenciaIndividualEvent();
}

/// Limpia mensajes de error o alertas en la UI.
class LimpiarMensajeTransferEvent extends TransferInfoEvent {
  const LimpiarMensajeTransferEvent();
}
