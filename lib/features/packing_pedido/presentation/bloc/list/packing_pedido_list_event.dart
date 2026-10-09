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

/// Trae los pedidos de Odoo. El aviso de carga lo da el bloc
/// ([PackingPedidoListState.operacion]); la API no abre diálogo propio, si no
/// quedan dos apilados.
class ListaPackSincronizada extends PackingPedidoListEvent {
  const ListaPackSincronizada();
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

/// Registra la hora de inicio del pedido y lo deja listo para abrir.
class InicioPedidoPackRegistrado extends PackingPedidoListEvent {
  final PedidoPack pedido;
  const InicioPedidoPackRegistrado(this.pedido);

  @override
  List<Object?> get props => [pedido];
}

/// Activa o quita el filtro "Mis pedidos" (responsable = usuario actual).
class SoloMisPedidosPackCambiado extends PackingPedidoListEvent {
  final bool soloMios;
  const SoloMisPedidosPackCambiado(this.soloMios);

  @override
  List<Object?> get props => [soloMios];
}

class PropietarioPackFiltrado extends PackingPedidoListEvent {
  /// null = todos.
  final String? propietario;
  const PropietarioPackFiltrado(this.propietario);

  @override
  List<Object?> get props => [propietario];
}
