part of 'recepcion_multiusuario_pool_bloc.dart';

sealed class RecepcionMultiusuarioPoolEvent extends Equatable {
  const RecepcionMultiusuarioPoolEvent();

  @override
  List<Object> get props => [];
}

/// Trae el pool de productos libres de [sessionId] desde el backend
/// (POST /api/receipt/session/{sessionId}/pool) y reemplaza el pool local de
/// esa sesión. Se va a disparar seguido (cada refresco de la pantalla de
/// detalle), así que por defecto no muestra el diálogo de carga global.
class FetchRecepcionPoolEvent extends RecepcionMultiusuarioPoolEvent {
  final int sessionId;
  final bool isLoadinDialog;
  const FetchRecepcionPoolEvent(this.sessionId, {this.isLoadinDialog = false});

  @override
  List<Object> get props => [sessionId, isLoadinDialog];
}

/// Carga el pool de [sessionId] desde SQLite (caché local, offline-first).
class FetchRecepcionPoolFromDbEvent extends RecepcionMultiusuarioPoolEvent {
  final int sessionId;
  const FetchRecepcionPoolFromDbEvent(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}
