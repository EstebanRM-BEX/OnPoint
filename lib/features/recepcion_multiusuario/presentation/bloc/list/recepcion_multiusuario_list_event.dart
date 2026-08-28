part of 'recepcion_multiusuario_list_bloc.dart';

sealed class RecepcionMultiusuarioListEvent extends Equatable {
  const RecepcionMultiusuarioListEvent();

  @override
  List<Object> get props => [];
}

/// Trae las sesiones desde el backend (GET /api/receipt/sessions) y las
/// persiste en SQLite.
class FetchRecepcionSessionsEvent extends RecepcionMultiusuarioListEvent {
  final bool isLoadinDialog;
  const FetchRecepcionSessionsEvent({this.isLoadinDialog = false});

  @override
  List<Object> get props => [isLoadinDialog];
}

/// Carga las sesiones desde SQLite (caché local, offline-first).
class FetchRecepcionSessionsFromDbEvent extends RecepcionMultiusuarioListEvent {
  const FetchRecepcionSessionsFromDbEvent();
}

/// Filtra la lista por texto (nombre de la sesión / picking de origen).
class SearchRecepcionSessionEvent extends RecepcionMultiusuarioListEvent {
  final String query;
  const SearchRecepcionSessionEvent(this.query);

  @override
  List<Object> get props => [query];
}
