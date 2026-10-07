part of 'packing_pedido_detail_bloc.dart';

sealed class PackingPedidoDetailEvent extends Equatable {
  const PackingPedidoDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Abre un pedido: limpia selección, búsqueda y sticker del anterior.
class DetallePackIniciado extends PackingPedidoDetailEvent {
  final int pedidoId;
  const DetallePackIniciado(this.pedidoId);

  @override
  List<Object?> get props => [pedidoId];
}

/// Relee el pedido actual (tras escanear, empacar o tocar paquetes).
class DetallePackRecargado extends PackingPedidoDetailEvent {
  const DetallePackRecargado();
}

class BusquedaProductoPackCambiada extends PackingPedidoDetailEvent {
  final String query;
  const BusquedaProductoPackCambiada(this.query);

  @override
  List<Object?> get props => [query];
}

class ProductoPackSeleccionado extends PackingPedidoDetailEvent {
  final int productoId;
  final bool seleccionado;
  const ProductoPackSeleccionado(this.productoId, {required this.seleccionado});

  @override
  List<Object?> get props => [productoId, seleccionado];
}

/// Reemplaza la selección completa (seleccionar todos / ninguno).
class SeleccionPackReemplazada extends PackingPedidoDetailEvent {
  final Iterable<int> productoIds;
  const SeleccionPackReemplazada(this.productoIds);

  @override
  List<Object?> get props => [productoIds.toList()];
}

class StickerPackCambiado extends PackingPedidoDetailEvent {
  final bool isSticker;
  const StickerPackCambiado(this.isSticker);

  @override
  List<Object?> get props => [isSticker];
}

/// Crea una caja con lo seleccionado de "Listos" ([certificado] = true) o de
/// "Por hacer" (false).
class PaquetePackCreado extends PackingPedidoDetailEvent {
  final bool certificado;
  final double peso;
  final PackagingType? tipoEmpaque;

  const PaquetePackCreado({
    required this.certificado,
    this.peso = 0,
    this.tipoEmpaque,
  });

  @override
  List<Object?> get props => [certificado, peso, tipoEmpaque];
}

class SeparacionPackDeshecha extends PackingPedidoDetailEvent {
  final ProductoPacking producto;
  const SeparacionPackDeshecha(this.producto);

  @override
  List<Object?> get props => [producto];
}
