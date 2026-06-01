part of 'picking_list_bloc.dart';

sealed class PickingListEvent extends Equatable {
  const PickingListEvent();

  @override
  List<Object> get props => [];
}

// Carga picks desde Odoo y los persiste en SQLite
class FetchPicksEvent extends PickingListEvent {
  final bool isLoadingDialog;
  const FetchPicksEvent(this.isLoadingDialog);

  @override
  List<Object> get props => [isLoadingDialog];
}

// Carga picks desde SQLite
class FetchPicksFromDbEvent extends PickingListEvent {
  const FetchPicksFromDbEvent();
}

// Filtra la lista de picks o componentes por query
class SearchPickListEvent extends PickingListEvent {
  final String query;
  final bool isComponentes;
  const SearchPickListEvent(this.query, this.isComponentes);

  @override
  List<Object> get props => [query, isComponentes];
}

// Ordena la lista de picks por campo y dirección
class SortPicksEvent extends PickingListEvent {
  final String field;
  final bool ascending;
  const SortPicksEvent(this.field, this.ascending);

  @override
  List<Object> get props => [field, ascending];
}

// Asigna el usuario autenticado como responsable del pick
class AssignUserToPickEvent extends PickingListEvent {
  final int id;
  const AssignUserToPickEvent(this.id);

  @override
  List<Object> get props => [id];
}

// Registra el tiempo de inicio o fin de una transferencia
class StartStopTimePickEvent extends PickingListEvent {
  final int id;
  final String value; // 'start_time_transfer' | 'end_time_transfer'
  const StartStopTimePickEvent(this.id, this.value);

  @override
  List<Object> get props => [id, value];
}

// Carga el pick con sus productos desde SQLite
class LoadPickWithProductsEvent extends PickingListEvent {
  final int pickId;
  const LoadPickWithProductsEvent(this.pickId);

  @override
  List<Object> get props => [pickId];
}

// Carga la configuración/permisos del usuario desde SQLite
class LoadPickConfigurationsEvent extends PickingListEvent {
  const LoadPickConfigurationsEvent();
}

// Carga el historial de picks finalizados desde Odoo por fecha
class LoadPickHistoryEvent extends PickingListEvent {
  final bool isLoadingDialog;
  final String date;
  const LoadPickHistoryEvent(this.isLoadingDialog, this.date);

  @override
  List<Object> get props => [isLoadingDialog, date];
}
