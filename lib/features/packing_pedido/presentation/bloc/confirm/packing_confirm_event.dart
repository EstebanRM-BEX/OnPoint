part of 'packing_confirm_bloc.dart';

sealed class PackingConfirmEvent extends Equatable {
  const PackingConfirmEvent();

  @override
  List<Object?> get props => [];
}

class ValidacionPackSolicitada extends PackingConfirmEvent {
  final PedidoPack pedido;
  final bool crearBackorder;
  const ValidacionPackSolicitada(this.pedido, {required this.crearBackorder});

  @override
  List<Object?> get props => [pedido, crearBackorder];
}

/// El operario acepta validar con productos vencidos.
class VencidosPackAceptados extends PackingConfirmEvent {
  const VencidosPackAceptados();
}

class VencidosPackRechazados extends PackingConfirmEvent {
  const VencidosPackRechazados();
}
