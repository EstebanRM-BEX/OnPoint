part of 'packing_pedido_list_bloc.dart';

sealed class PackingPedidoListEvent extends Equatable {
  const PackingPedidoListEvent();

  @override
  List<Object?> get props => [];
}

/// Carga lo local y, si no hay nada (o [sincronizar]), trae de Odoo.
class ListaPackIniciada extends PackingPedidoListEvent {
  final bool sincronizar;
  const ListaPackIniciada({this.sincronizar = false});

  @override
  List<Object?> get props => [sincronizar];
}

class ListaPackSincronizada extends PackingPedidoListEvent {
  final bool isLoadingDialog;
  const ListaPackSincronizada({this.isLoadingDialog = false});

  @override
  List<Object?> get props => [isLoadingDialog];
}

class BusquedaPedidoPackCambiada extends PackingPedidoListEvent {
  final String query;
  const BusquedaPedidoPackCambiada(this.query);

  @override
  List<Object?> get props => [query];
}

class OrdenPedidosPackCambiado extends PackingPedidoListEvent {
  final OrdenPedidosPack orden;
  final bool ascendente;
  const OrdenPedidosPackCambiado(this.orden, {this.ascendente = false});

  @override
  List<Object?> get props => [orden, ascendente];
}

class ResponsablePackAsignado extends PackingPedidoListEvent {
  final int pedidoId;
  const ResponsablePackAsignado(this.pedidoId);

  @override
  List<Object?> get props => [pedidoId];
}
