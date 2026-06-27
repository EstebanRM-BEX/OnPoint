import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/view_product_image_usecase.dart';

part 'detail_cluster_event.dart';
part 'detail_cluster_state.dart';

class DetailClusterBloc
    extends Bloc<DetailClusterEvent, DetailClusterState> {
  final ViewProductImageUseCase viewProductImageUseCase;

  DetailClusterBloc({required this.viewProductImageUseCase})
      : super(DetailClusterInitial()) {
    on<ViewProductImageDetailEvent>(_onViewProductImage);
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
