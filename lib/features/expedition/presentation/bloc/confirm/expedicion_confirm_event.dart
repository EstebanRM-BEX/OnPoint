part of 'expedicion_confirm_bloc.dart';

sealed class ExpedicionConfirmEvent extends Equatable {
  const ExpedicionConfirmEvent();

  @override
  List<Object> get props => [];
}

/// Confirma (cierra) el pedido de expedición. [forzarVencidos] se usa solo
/// en el reintento explícito tras un error de productos vencidos.
/// [crearBackorder] se usa cuando quedan paquetes o productos sueltos
/// pendientes en "Por hacer" y el usuario eligió confirmar creando una
/// backorder con lo pendiente en vez de bloquear el cierre.
class ConfirmarPedidoEvent extends ExpedicionConfirmEvent {
  final int expeditionId;
  final bool forzarVencidos;
  final bool crearBackorder;

  const ConfirmarPedidoEvent({
    required this.expeditionId,
    this.forzarVencidos = false,
    this.crearBackorder = false,
  });

  @override
  List<Object> get props => [expeditionId, forzarVencidos, crearBackorder];
}
