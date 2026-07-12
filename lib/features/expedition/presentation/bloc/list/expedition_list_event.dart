part of 'expedition_list_bloc.dart';

sealed class ExpedicionListEvent extends Equatable {
  const ExpedicionListEvent();

  @override
  List<Object> get props => [];
}

/// Trae expediciones desde el backend (/api/transferencias/out) y las
/// persiste en SQLite.
class FetchExpedicionesEvent extends ExpedicionListEvent {
  final bool isLoadinDialog;
  const FetchExpedicionesEvent({this.isLoadinDialog = false});

  @override
  List<Object> get props => [isLoadinDialog];
}

/// Carga expediciones desde SQLite (caché local, offline-first).
class FetchExpedicionesFromDbEvent extends ExpedicionListEvent {
  const FetchExpedicionesFromDbEvent();
}

/// Filtra la lista por texto (nombre/cliente/documento origen).
class SearchExpedicionEvent extends ExpedicionListEvent {
  final String query;
  const SearchExpedicionEvent(this.query);

  @override
  List<Object> get props => [query];
}

/// Ordena la lista. field ∈ 'fecha' | 'nombre' | 'cliente'.
class SortExpedicionListEvent extends ExpedicionListEvent {
  final String field;
  final bool ascending;
  const SortExpedicionListEvent(this.field, this.ascending);

  @override
  List<Object> get props => [field, ascending];
}
