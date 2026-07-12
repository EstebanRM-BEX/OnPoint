part of 'expedicion_confirm_bloc.dart';

sealed class ExpedicionConfirmEvent extends Equatable {
  const ExpedicionConfirmEvent();

  @override
  List<Object> get props => [];
}

/// Confirma (cierra) el pedido de expedición. [forzarVencidos] se usa solo
/// en el reintento explícito tras un error de productos vencidos.
class ConfirmarPedidoEvent extends ExpedicionConfirmEvent {
  final int expeditionId;
  final bool forzarVencidos;

  const ConfirmarPedidoEvent({
    required this.expeditionId,
    this.forzarVencidos = false,
  });

  @override
  List<Object> get props => [expeditionId, forzarVencidos];
}
