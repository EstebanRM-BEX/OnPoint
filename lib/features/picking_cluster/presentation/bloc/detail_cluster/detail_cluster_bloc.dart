import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/release_batch_zonas_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/view_product_image_usecase.dart';

part 'detail_cluster_event.dart';
part 'detail_cluster_state.dart';

class DetailClusterBloc
    extends Bloc<DetailClusterEvent, DetailClusterState> {
  final ViewProductImageUseCase viewProductImageUseCase;
  final ReleaseBatchZonasUseCase releaseBatchZonasUseCase;

  DetailClusterBloc({
    required this.viewProductImageUseCase,
    required this.releaseBatchZonasUseCase,
  }) : super(DetailClusterInitial()) {
    on<ViewProductImageDetailEvent>(_onViewProductImage);
    on<ReleaseZonasEvent>(_onReleaseZonas, transformer: droppable());
  }

  Future<void> _onReleaseZonas(
    ReleaseZonasEvent event,
    Emitter<DetailClusterState> emit,
  ) async {
    emit(ReleaseZonasLoading());
    final result = await releaseBatchZonasUseCase(
      ReleaseBatchZonasParams(
        batchId: event.batchId,
        zoneIds: event.zoneIds,
      ),
    );
    result.fold(
      (failure) => emit(ReleaseZonasFailure(failure.message)),
      (msg) => emit(ReleaseZonasSuccess(msg)),
    );
  }

  Future<void> _onViewProductImage(
    ViewProductImageDetailEvent event,
    Emitter<DetailClusterState> emit,
  ) async {
    emit(ImageDetailLoading());
    final result = await viewProductImageUseCase.call(
      ViewProductImageParams(
          idProduct: event.idProduct, isLoadinDialog: true),
    );
    result.fold(
      (failure) => emit(ImageDetailFailure(failure.message)),
      (url) => emit(ImageDetailSuccess(url)),
    );
  }
}
