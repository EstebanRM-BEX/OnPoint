part of 'mass_transfer_bloc.dart';

sealed class MassTransferEvent extends Equatable {
  const MassTransferEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializa el flujo de transferencia masiva con la ubicación origen y
/// los productos seleccionados en la pantalla de ubicación.
class MassTransferInicializado extends MassTransferEvent {
  final int idAlmacen;
  final int idUbicacionOrigen;
  final String nombreUbicacionOrigen;
  final List<ProductoUbicacion> productosSeleccionados;

  const MassTransferInicializado({
    required this.idAlmacen,
    required this.idUbicacionOrigen,
    required this.nombreUbicacionOrigen,
    required this.productosSeleccionados,
  });

  @override
  List<Object?> get props => [
        idAlmacen,
        idUbicacionOrigen,
        nombreUbicacionOrigen,
        productosSeleccionados,
      ];
}

/// Carga el catálogo de posibles ubicaciones destino desde la caché.
class CargarUbicacionesDestinoMassEvent extends MassTransferEvent {
  const CargarUbicacionesDestinoMassEvent();
}

/// Filtra las ubicaciones destino por texto de búsqueda.
class BuscarUbicacionDestinoMassEvent extends MassTransferEvent {
  final String query;

  const BuscarUbicacionDestinoMassEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Filtra las ubicaciones destino por almacén.
class FiltrarUbicacionesDestinoMassAlmacenEvent extends MassTransferEvent {
  final String? almacen;

  const FiltrarUbicacionesDestinoMassAlmacenEvent(this.almacen);

  @override
  List<Object?> get props => [almacen];
}

/// Selecciona manualmente una ubicación destino de la lista.
class SeleccionarUbicacionDestinoMassEvent extends MassTransferEvent {
  final UbicacionCatalogo ubicacion;

  const SeleccionarUbicacionDestinoMassEvent(this.ubicacion);

  @override
  List<Object?> get props => [ubicacion];
}

/// Escanea un código de barras para seleccionar la ubicación destino.
class EscanearUbicacionDestinoMassEvent extends MassTransferEvent {
  final String barcode;

  const EscanearUbicacionDestinoMassEvent(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// Modifica y valida la cantidad a transferir de un ítem particular.
class ActualizarCantidadItemMassEvent extends MassTransferEvent {
  final int productoId;
  final int? loteId;
  final double cantidad;

  const ActualizarCantidadItemMassEvent({
    required this.productoId,
    this.loteId,
    required this.cantidad,
  });

  @override
  List<Object?> get props => [productoId, loteId, cantidad];
}

/// Agrega un producto de la ubicación origen escaneando su código de barras.
class AgregarItemMassEvent extends MassTransferEvent {
  final ProductoUbicacion producto;

  const AgregarItemMassEvent(this.producto);

  @override
  List<Object?> get props => [producto];
}

/// Remueve un ítem de la lista de ítems a transferir.
class RemoverItemMassEvent extends MassTransferEvent {
  final int productoId;
  final int? loteId;

  const RemoverItemMassEvent({
    required this.productoId,
    this.loteId,
  });

  @override
  List<Object?> get props => [productoId, loteId];
}

/// Ejecuta la creación de la transferencia masiva en el backend.
class ConfirmarTransferenciaMasivaEvent extends MassTransferEvent {
  const ConfirmarTransferenciaMasivaEvent();
}

/// Limpia mensajes de error o alertas en la UI.
class LimpiarMensajeMassTransferEvent extends MassTransferEvent {
  const LimpiarMensajeMassTransferEvent();
}
