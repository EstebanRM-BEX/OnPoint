import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking/domain/entities/pick.dart';
import 'package:wms_app/features/picking/domain/usecases/fetch_components_from_db_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/fetch_components_history_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/fetch_components_usecase.dart';

part 'picking_components_event.dart';
part 'picking_components_state.dart';

class PickingComponentsBloc
    extends Bloc<PickingComponentsEvent, PickingComponentsState> {
  final FetchComponentsUseCase fetchComponentsUseCase;
  final FetchComponentsFromDbUseCase fetchComponentsFromDbUseCase;
  final FetchComponentsHistoryUseCase fetchComponentsHistoryUseCase;

  // ── Estado en memoria ─────────────────────────────────────────────────────
  List<Pick> listOfPickCompo = [];
  List<Pick> listOfPickCompoFiltered = [];
  List<Pick> historyPicks = [];
  List<Pick> filtersHistoryPicks = [];

  // ─────────────────────────────────────────────────────────────────────────

  PickingComponentsBloc({
    required this.fetchComponentsUseCase,
    required this.fetchComponentsFromDbUseCase,
    required this.fetchComponentsHistoryUseCase,
  }) : super(PickingComponentsInitial()) {
    on<FetchPickingComponentesEvent>(_onFetchPickingComponentes);
    on<FetchPickingComponentesFromDBEvent>(_onFetchPickingComponentesFromDB);
    on<LoadHistoryPickComponentEvent>(_onLoadHistoryPickComponent);
  }

  // ── FetchPickingComponentesEvent ──────────────────────────────────────────
  Future<void> _onFetchPickingComponentes(
      FetchPickingComponentesEvent event,
      Emitter<PickingComponentsState> emit) async {
    emit(PickingPickCompoLoading());

    final result = await fetchComponentsUseCase(NoParams());

    result.fold(
      (failure) {
        debugPrint('❌ Error fetchComponents: ${failure.message}');
        emit(PickingPickCompoError(failure.message));
      },
      (fetchResult) {
        listOfPickCompo = [];
        listOfPickCompoFiltered = [];

        if (fetchResult.needsUpdate) {
          emit(NeedUpdateVersionCompoState());
        }

        if (fetchResult.picks.isNotEmpty) {
          listOfPickCompo = fetchResult.picks;
          listOfPickCompoFiltered = fetchResult.picks;
          add(FetchPickingComponentesFromDBEvent(true));
        }

        emit(PickingPickCompoLoaded(fetchResult.picks));
      },
    );
  }

  // ── FetchPickingComponentesFromDBEvent ────────────────────────────────────
  Future<void> _onFetchPickingComponentesFromDB(
      FetchPickingComponentesFromDBEvent event,
      Emitter<PickingComponentsState> emit) async {
    emit(PickingPickCompoBDLoading());

    final result = await fetchComponentsFromDbUseCase(NoParams());

    result.fold(
      (failure) {
        debugPrint('❌ Error fetchComponentsFromDb: ${failure.message}');
        emit(PickingPickCompoError(failure.message));
      },
      (picks) {
        listOfPickCompo = picks;
        listOfPickCompoFiltered = picks;
        emit(PickingPickCompoLoadedBD(listOfPickCompoFiltered));
      },
    );
  }

  // ── LoadHistoryPickComponentEvent ─────────────────────────────────────────
  Future<void> _onLoadHistoryPickComponent(
      LoadHistoryPickComponentEvent event,
      Emitter<PickingComponentsState> emit) async {
    debugPrint('date: ${event.date}');
    emit(PickingComponentsHistoryLoading());

    final result = await fetchComponentsHistoryUseCase(
      FetchComponentsHistoryParams(event.date),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Error fetchComponentsHistory: ${failure.message}');
        emit(PickingComponentsHistoryError(failure.message));
      },
      (picks) {
        historyPicks = picks;
        filtersHistoryPicks = picks;
        emit(PickingComponentsHistoryLoaded(listOfBatchs: filtersHistoryPicks));
      },
    );
  }
}
