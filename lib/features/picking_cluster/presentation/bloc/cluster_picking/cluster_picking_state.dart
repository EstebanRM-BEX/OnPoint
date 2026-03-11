part of 'cluster_picking_bloc.dart';

sealed class ClusterPickingState extends Equatable {
  const ClusterPickingState();

  @override
  List<Object> get props => [];
}

final class ClusterPickingInitial extends ClusterPickingState {}

final class PickingClustersLoading extends ClusterPickingState {}

final class PickingClustersLoaded extends ClusterPickingState {
  final List<PickingBatch> batches;
  const PickingClustersLoaded(this.batches);

  @override
  List<Object> get props => [batches];
}

final class PickingClustersError extends ClusterPickingState {
  final String message;
  const PickingClustersError(this.message);

  @override
  List<Object> get props => [message];
}

final class BatchProductsLoading extends ClusterPickingState {}

final class BatchProductsLoaded extends ClusterPickingState {
  final PickingBatch batch;
  final List<BatchProduct> products;

  const BatchProductsLoaded(
    this.batch,
    this.products,
  );

  BatchProductsLoaded copyWith({
    PickingBatch? batch,
    List<BatchProduct>? products,
  }) {
    return BatchProductsLoaded(
      batch ?? this.batch,
      products ?? this.products,
    );
  }

  @override
  List<Object> get props {
    final List<Object> p = [
      batch,
      products,
    ];
    return p;
  }
}

final class BatchProductsError extends ClusterPickingState {
  final String message;
  const BatchProductsError(this.message);

  @override
  List<Object> get props => [message];
}

final class ConfigurationPickingLoaded extends ClusterPickingState {
  final UserConfigurationModel configuration;
  const ConfigurationPickingLoaded(this.configuration);

  @override
  List<Object> get props => [configuration];
}

final class ConfigurationError extends ClusterPickingState {
  final String message;
  const ConfigurationError(this.message);

  @override
  List<Object> get props => [message];
}

class ValidateFieldsStateSuccess extends ClusterPickingState {
  final bool isOk;
  final int timestamp;
  ValidateFieldsStateSuccess(this.isOk)
      : timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object> get props => [isOk, timestamp];
}

class ValidateFieldsStateError extends ClusterPickingState {
  final String msg;
  final int timestamp;
  ValidateFieldsStateError(this.msg)
      : timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object> get props => [msg, timestamp];
}

class ClusterPickingLoading extends ClusterPickingState {}

class ChangeLocationIsOkState extends ClusterPickingState {}

class ClearFieldsState extends ClusterPickingState {}

class ClearFieldsStateError extends ClusterPickingState {
  final String msg;
  const ClearFieldsStateError(this.msg);
}

class BarcodesProductLoadedState extends ClusterPickingState {
  final List<BatchBarcode> listOfBarcodes;
  const BarcodesProductLoadedState({required this.listOfBarcodes});
}

class ChangeQuantitySeparateStateSuccess extends ClusterPickingState {
  final dynamic quantity;
  const ChangeQuantitySeparateStateSuccess(this.quantity);
}

class ChangeQuantitySeparateStateError extends ClusterPickingState {
  final String msg;
  const ChangeQuantitySeparateStateError(this.msg);
}

class ChangeProductIsOkState extends ClusterPickingState {
  final bool isOk;
  const ChangeProductIsOkState(this.isOk);
}

class ChangeQuantityIsOkState extends ClusterPickingState {
  final bool isOk;
  const ChangeQuantityIsOkState(this.isOk);
}

class ShowQuantityState extends ClusterPickingState {
  final bool showQuantity;
  const ShowQuantityState(this.showQuantity);
}

class UpdateNovedadProductState extends ClusterPickingState {
  final String selectedNovedad;
  const UpdateNovedadProductState(this.selectedNovedad);
}

class SetIsProcessingState extends ClusterPickingState {
  final bool isProcessing;
  const SetIsProcessingState(this.isProcessing);
}

class SeparateProductState extends ClusterPickingState {
  final int productId;
  const SeparateProductState(this.productId);
}

class CurrentProductChangedStateLoading extends ClusterPickingState {}

class CurrentProductChangedStateError extends ClusterPickingState {
  final String msg;
  const CurrentProductChangedStateError(this.msg);
}

class SendToOdooStateSuccess extends ClusterPickingState {
  final bool isOk;
  const SendToOdooStateSuccess(this.isOk);
}

class SendToOdooStateError extends ClusterPickingState {
  final String msg;
  const SendToOdooStateError(this.msg);
}

final class CurrentProductChangedState extends ClusterPickingState {
  final BatchProduct? currentProduct;
  final int index;
  CurrentProductChangedState({this.currentProduct, required this.index});
}

class ViewProductImageLoading extends ClusterPickingState {}

class ViewProductImageSuccess extends ClusterPickingState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends ClusterPickingState {
  final String error;
  ViewProductImageFailure(this.error);
}

class LoadSelectedProductState extends ClusterPickingState {
  final BatchProduct selectedProduct;
  const LoadSelectedProductState(this.selectedProduct);
}

class ValidatePedidoStateSuccess extends ClusterPickingState {
  final dynamic quantity;
  const ValidatePedidoStateSuccess(this.quantity);
}

class MarkPedidoAsValidatedStateSuccess extends ClusterPickingState {
  final List<PedidoValidate> pedidosValidate;
  const MarkPedidoAsValidatedStateSuccess(this.pedidosValidate);
}

class LoadValidatePedidoState extends ClusterPickingState {}

class TimeSeparateSuccess extends ClusterPickingState {
  final String date;
  const TimeSeparateSuccess(this.date);
}

class TimeSeparateError extends ClusterPickingState {
  final String message;
  const TimeSeparateError(this.message);
}

class LoadingSendProductEdit extends ClusterPickingState {}

class SendProductEditOdooStateSuccess extends ClusterPickingState {
  final bool isOk;
  const SendProductEditOdooStateSuccess(this.isOk);
}

class SendProductEditOdooStateError extends ClusterPickingState {
  final String msg;
  const SendProductEditOdooStateError(this.msg);
}

class ValidatePedidoStateError extends ClusterPickingState {
  final String msg;
  const ValidatePedidoStateError(this.msg);
}
