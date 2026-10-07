part of 'packing_confirm_bloc.dart';

sealed class PackingConfirmEvent extends Equatable {
  const PackingConfirmEvent();

  @override
  List<Object?> get props => [];
}

/// Valida el pedido; antes revisa que no queden listos sin empacar y que
/// haya al menos una caja.
class ValidacionPackSolicitada extends PackingConfirmEvent {
  final PedidoPackDetalle detalle;
  final bool crearBackorder;
  const ValidacionPackSolicitada(this.detalle, {required this.crearBackorder});

  @override
  List<Object?> get props => [detalle, crearBackorder];
}

/// El operario acepta validar con productos vencidos.
class VencidosPackAceptados extends PackingConfirmEvent {
  const VencidosPackAceptados();
}

class VencidosPackRechazados extends PackingConfirmEvent {
  const VencidosPackRechazados();
}
