part of 'recepcion_multiusuario_pool_bloc.dart';

sealed class RecepcionMultiusuarioPoolEvent extends Equatable {
  const RecepcionMultiusuarioPoolEvent();

  @override
  List<Object> get props => [];
}

/// Trae el pool de productos de [sessionId] desde el backend
/// (POST /api/receipt/session/{sessionId}/pool). Se va a disparar seguido
/// (cada refresco de la pantalla de detalle), así que por defecto no
/// muestra el diálogo de carga global.
///
/// [verification] distingue qué pantalla pidió el fetch: false para "Por
/// hacer" (solo lo disponible), true para "Terminados" (incluye tareas
/// agotadas con historial) — cada una guarda su propia copia en el bloc
/// (ver [RecepcionMultiusuarioPoolBloc.poolItems]/[terminadosItems]) para
/// no pisarse entre sí.
class FetchRecepcionPoolEvent extends RecepcionMultiusuarioPoolEvent {
  final int sessionId;
  final bool verification;
  final bool isLoadinDialog;
  const FetchRecepcionPoolEvent(
    this.sessionId, {
    required this.verification,
    this.isLoadinDialog = false,
  });

  @override
  List<Object> get props => [sessionId, verification, isLoadinDialog];
}

/// Carga el pool de [sessionId] desde SQLite (caché local, offline-first).
class FetchRecepcionPoolFromDbEvent extends RecepcionMultiusuarioPoolEvent {
  final int sessionId;
  const FetchRecepcionPoolFromDbEvent(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}
