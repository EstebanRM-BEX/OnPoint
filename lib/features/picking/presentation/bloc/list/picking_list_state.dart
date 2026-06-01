part of 'picking_list_bloc.dart';

sealed class PickingListState extends Equatable {
  const PickingListState();

  @override
  List<Object> get props => [];
}

// ── Iniciales ─────────────────────────────────────────────────────────────────

final class PickingListInitial extends PickingListState {
  const PickingListInitial();
}

// ── Carga de lista (FetchPicksEvent / FetchPicksFromDbEvent) ──────────────────

final class PickingListLoading extends PickingListState {
  const PickingListLoading();
}

final class PickingListDbLoading extends PickingListState {
  const PickingListDbLoading();
}

final class PicksLoaded extends PickingListState {
  final List<ResultPick> picks;
  const PicksLoaded(this.picks);

  @override
  List<Object> get props => [picks];
}

final class PicksLoadedFromDb extends PickingListState {
  final List<ResultPick> picks;
  const PicksLoadedFromDb(this.picks);

  @override
  List<Object> get props => [picks];
}

final class PickingListError extends PickingListState {
  final String message;
  const PickingListError(this.message);

  @override
  List<Object> get props => [message];
}

// ── Búsqueda y ordenamiento ───────────────────────────────────────────────────

final class PickListSearched extends PickingListState {
  const PickListSearched();
}

final class PicksSorted extends PickingListState {
  final List<ResultPick> picks;
  const PicksSorted(this.picks);

  @override
  List<Object> get props => [picks, Object()];
}

// ── Asignación de usuario ─────────────────────────────────────────────────────

final class AssignUserToPickLoading extends PickingListState {
  const AssignUserToPickLoading();
}

final class AssignUserToPickSuccess extends PickingListState {
  final int id;
  const AssignUserToPickSuccess(this.id);

  @override
  List<Object> get props => [id];
}

final class AssignUserToPickError extends PickingListState {
  final String message;
  const AssignUserToPickError(this.message);

  @override
  List<Object> get props => [message];
}

// ── Tiempo de transferencia ───────────────────────────────────────────────────

final class StartStopTimeSuccess extends PickingListState {
  final String value;
  const StartStopTimeSuccess(this.value);

  @override
  List<Object> get props => [value];
}

final class StartStopTimeFailure extends PickingListState {
  final String error;
  const StartStopTimeFailure(this.error);

  @override
  List<Object> get props => [error];
}

// ── Pick con productos ────────────────────────────────────────────────────────

final class PickWithProductsLoaded extends PickingListState {
  final PickWithProducts data;
  const PickWithProductsLoaded(this.data);

  @override
  List<Object> get props => [data];
}

final class PickWithProductsEmpty extends PickingListState {
  const PickWithProductsEmpty();
}

// ── Configuraciones ───────────────────────────────────────────────────────────

final class PickConfigurationsLoading extends PickingListState {
  const PickConfigurationsLoading();
}

final class PickConfigurationsLoaded extends PickingListState {
  final UserConfigurationModel configurations;
  const PickConfigurationsLoaded(this.configurations);

  @override
  List<Object> get props => [configurations];
}

final class PickConfigurationsError extends PickingListState {
  final String message;
  const PickConfigurationsError(this.message);

  @override
  List<Object> get props => [message];
}

// ── Historial ─────────────────────────────────────────────────────────────────

final class PickHistoryLoading extends PickingListState {
  const PickHistoryLoading();
}

final class PickHistoryLoaded extends PickingListState {
  final List<ResultPick> picks;
  const PickHistoryLoaded(this.picks);

  @override
  List<Object> get props => [picks];
}

final class PickHistoryError extends PickingListState {
  final String message;
  const PickHistoryError(this.message);

  @override
  List<Object> get props => [message];
}

// ── Versión ───────────────────────────────────────────────────────────────────

final class NeedUpdateVersionPickState extends PickingListState {
  const NeedUpdateVersionPickState();
}
