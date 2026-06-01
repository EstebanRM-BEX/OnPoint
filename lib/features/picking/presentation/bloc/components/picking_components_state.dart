part of 'picking_components_bloc.dart';

@immutable
sealed class PickingComponentsState {}

final class PickingComponentsInitial extends PickingComponentsState {}

// ── FetchPickingComponentesEvent ──────────────────────────────────────────

final class PickingPickCompoLoading extends PickingComponentsState {}

final class PickingPickCompoLoaded extends PickingComponentsState {
  final List<Pick> result;
  PickingPickCompoLoaded(this.result);
}

final class PickingPickCompoError extends PickingComponentsState {
  final String error;
  PickingPickCompoError(this.error);
}

// ── FetchPickingComponentesFromDBEvent ────────────────────────────────────

final class PickingPickCompoBDLoading extends PickingComponentsState {}

final class PickingPickCompoLoadedBD extends PickingComponentsState {
  final List<Pick> result;
  PickingPickCompoLoadedBD(this.result);
}

// ── LoadHistoryPickComponentEvent ─────────────────────────────────────────

final class PickingComponentsHistoryLoading extends PickingComponentsState {}

final class PickingComponentsHistoryLoaded extends PickingComponentsState {
  final List<Pick> listOfBatchs;
  PickingComponentsHistoryLoaded({required this.listOfBatchs});
}

final class PickingComponentsHistoryError extends PickingComponentsState {
  final String error;
  PickingComponentsHistoryError(this.error);
}

// ── Versión desactualizada ────────────────────────────────────────────────

final class NeedUpdateVersionCompoState extends PickingComponentsState {}
