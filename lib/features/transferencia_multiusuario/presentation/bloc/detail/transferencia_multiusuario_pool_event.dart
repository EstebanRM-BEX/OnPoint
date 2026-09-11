part of 'transferencia_multiusuario_pool_bloc.dart';

sealed class TransferenciaMultiusuarioPoolEvent extends Equatable {
  const TransferenciaMultiusuarioPoolEvent();

  @override
  List<Object> get props => [];
}

/// Trae el pool de productos de [sessionId] desde el backend
/// (POST /api/transfer/session/{sessionId}/pool). Se va a disparar seguido
/// (cada refresco de la pantalla de detalle), así que por defecto no
/// muestra el diálogo de carga global.
///
/// [verification] distingue qué pantalla pidió el fetch: false para "Por
/// hacer" (solo lo disponible), true para "Terminados" (incluye tareas
/// agotadas con historial) — cada una guarda su propia copia en el bloc
/// (ver [TransferenciaMultiusuarioPoolBloc.poolItems]/[terminadosItems])
/// para no pisarse entre sí.
class FetchTransferenciaPoolEvent extends TransferenciaMultiusuarioPoolEvent {
  final int sessionId;
  final bool verification;
  final bool isLoadinDialog;
  const FetchTransferenciaPoolEvent(
    this.sessionId, {
    required this.verification,
    this.isLoadinDialog = false,
  });

  @override
  List<Object> get props => [sessionId, verification, isLoadinDialog];
}

/// Siembra [terminadosItems] con el `pool` que ya trajo
/// /transfer/session/{id}/snapshot en la carga inicial, sin pegarle de
/// nuevo al backend. No existe el equivalente para "Por hacer": el pool del
/// snapshot no viene filtrado por disponibilidad (ver
/// TransferenciaSnapshotModel.fromJson), así que esa lista sigue pidiéndose
/// siempre con FetchTransferenciaPoolEvent(verification: false).
class SeedTransferenciaTerminadosEvent
    extends TransferenciaMultiusuarioPoolEvent {
  final List<TransferenciaPoolItem> items;
  const SeedTransferenciaTerminadosEvent(this.items);

  @override
  List<Object> get props => [items, Object()];
}
