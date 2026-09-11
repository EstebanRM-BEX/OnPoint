part of 'transferencia_multiusuario_list_bloc.dart';

sealed class TransferenciaMultiusuarioListEvent extends Equatable {
  const TransferenciaMultiusuarioListEvent();

  @override
  List<Object> get props => [];
}

/// Trae las sesiones desde el backend (POST /api/transfer/sessions) y las
/// persiste en SQLite.
class FetchTransferenciaSessionsEvent
    extends TransferenciaMultiusuarioListEvent {
  final bool isLoadinDialog;
  const FetchTransferenciaSessionsEvent({this.isLoadinDialog = false});

  @override
  List<Object> get props => [isLoadinDialog];
}

/// Carga las sesiones desde SQLite (caché local, offline-first).
class FetchTransferenciaSessionsFromDbEvent
    extends TransferenciaMultiusuarioListEvent {
  const FetchTransferenciaSessionsFromDbEvent();
}

/// Filtra la lista por texto (nombre de la sesión / picking de origen).
class SearchTransferenciaSessionEvent
    extends TransferenciaMultiusuarioListEvent {
  final String query;
  const SearchTransferenciaSessionEvent(this.query);

  @override
  List<Object> get props => [query];
}
