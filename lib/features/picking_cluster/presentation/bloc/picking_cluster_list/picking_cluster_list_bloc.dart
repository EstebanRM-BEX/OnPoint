import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/picking_batch.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/assign_batch_zonas_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/get_picking_cluster_data.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/get_local_picking_cluster_data.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/start_time_pick_use_case.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';

part 'picking_cluster_list_event.dart';
part 'picking_cluster_list_state.dart';

class PickingClusterListBloc
    extends Bloc<PickingClusterListEvent, PickingClusterListState> {
  final GetPickingClusterData getPickingClusterData;
  final GetLocalPickingClusterData getLocalPickingClusterData;
  final StartTimePickUseCase startTimePickUseCase;
  final AssignBatchZonasUseCase assignBatchZonasUseCase;
  final ClusterPickingBloc clusterPickingBloc;

  PickingClusterListBloc({
    required this.getPickingClusterData,
    required this.getLocalPickingClusterData,
    required this.startTimePickUseCase,
    required this.assignBatchZonasUseCase,
    required this.clusterPickingBloc,
  }) : super(PickingClusterListInitial()) {
    on<FetchClustersEvent>(_onFetchClusters);
    on<LoadLocalClustersEvent>(_onLoadLocalClusters);
    on<SelectBatchEvent>(_onSelectBatch);
  }

  Future<void> _onFetchClusters(
    FetchClustersEvent event,
    Emitter<PickingClusterListState> emit,
  ) async {
    if (!event.silent) emit(ClustersLoadingState());
    final result = await getPickingClusterData(NoParams());
    result.fold(
      (failure) {
        if (event.silent) {
          debugPrint('⚠️ Refresco silencioso de clusters falló: ${failure.message}');
        } else {
          emit(ClustersErrorState(failure.message));
        }
      },
      (_) => add(LoadLocalClustersEvent(silent: event.silent)),
    );
  }

  Future<void> _onLoadLocalClusters(
    LoadLocalClustersEvent event,
    Emitter<PickingClusterListState> emit,
  ) async {
    if (!event.silent) emit(ClustersLoadingState());
    final result = await getLocalPickingClusterData(NoParams());
    result.fold(
      (failure) {
        if (!event.silent) emit(ClustersErrorState(failure.message));
      },
      (batches) => emit(
        event.silent
            ? ClustersSilentLoadedState(batches)
            : ClustersLoadedState(batches),
      ),
    );
  }

  Future<void> _onSelectBatch(
    SelectBatchEvent event,
    Emitter<PickingClusterListState> emit,
  ) async {
    // Asignar zonas primero: si falla no se inicia el tiempo ni se abre el batch.
    var batch = event.batch;
    if (event.assignZonas) {
      emit(BatchZonasAssigningState());
      final assigned = await assignBatchZonasUseCase(batch.id ?? 0);
      final failure = assigned.fold((f) => f, (_) => null);
      if (failure != null) {
        debugPrint('❌ Error al asignar zonas del batch: ${failure.message}');
        emit(BatchZonasErrorState(failure.message));
        return;
      }
      // Solo se toman las zonas del servidor: los productos locales (con el
      // avance del operario) no se reemplazan.
      batch = batch.copyWith(
        zonasTrabajo: assigned.fold((_) => batch.zonasTrabajo, (b) => b.zonasTrabajo),
      );
      emit(BatchZonasAssignedState());
    }

    if (event.startTime != null) {
      final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final formattedDate = formatter.format(event.startTime!);
      final result = await startTimePickUseCase.call(
        StartTimePickParams(
          batchId: batch.id ?? 0,
          formattedDate: formattedDate,
          typePicking: 'cluster',
        ),
      );
      final errorMsg = result.fold((f) => f.message, (_) => null);
      if (errorMsg != null) {
        debugPrint('❌ Error al iniciar tiempo de picking: $errorMsg');
        emit(BatchStartTimeErrorState(errorMsg));
        return;
      }
    }

    // Delegamos la carga de productos al BLoC compartido.
    // La pantalla escucha a ClusterPickingBloc para BatchProductsLoaded/Error.
    clusterPickingBloc.add(FetchBatchProductsEvent(batch));
    emit(BatchDelegatedState());
  }
}
