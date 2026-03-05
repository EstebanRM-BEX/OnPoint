part of 'cluster_picking_bloc.dart';

sealed class ClusterPickingEvent extends Equatable {
  const ClusterPickingEvent();

  @override
  List<Object> get props => [];
}

class FetchPickingClustersEvent extends ClusterPickingEvent {
  const FetchPickingClustersEvent();
}

class LoadLocalPickingClustersEvent extends ClusterPickingEvent {
  const LoadLocalPickingClustersEvent();
}

class FetchBatchProductsEvent extends ClusterPickingEvent {
  final PickingBatch batch;
  const FetchBatchProductsEvent(this.batch);

  @override
  List<Object> get props => [batch];
}

class LoadCurrentProductEvent extends ClusterPickingEvent {
  final BatchProduct product;
  const LoadCurrentProductEvent(this.product);

  @override
  List<Object> get props => [product];
}

class LoadConfigurationsUserEvent extends ClusterPickingEvent {
  const LoadConfigurationsUserEvent();
}

class ValidateFieldsEvent extends ClusterPickingEvent {
  final String field;
  final bool isOk;
  const ValidateFieldsEvent({required this.field, required this.isOk});
}

class ChangeProductIsOkEvent extends ClusterPickingEvent {
  final bool productIsOk;
  final int productId;
  final int batchId;
  final dynamic quantity;
  final int idMove;
  final String type;
  const ChangeProductIsOkEvent(this.productIsOk, this.productId, this.batchId,
      this.quantity, this.idMove, this.type);
}

class ChangeLocationIsOkEvent extends ClusterPickingEvent {
  final int productId;
  final int batchId;
  final int idMove;
  final String type;
  const ChangeLocationIsOkEvent(
      this.productId, this.batchId, this.idMove, this.type);
}

class ClearFieldsEvent extends ClusterPickingEvent {
  const ClearFieldsEvent();
}

class FetchBarcodesProductEvent extends ClusterPickingEvent {}

class ChangeQuantitySeparate extends ClusterPickingEvent {
  final dynamic quantity;
  final int productId;
  final int idMove;
  final String type;
  const ChangeQuantitySeparate(
      this.quantity, this.productId, this.idMove, this.type);
}

class ChangeIsOkQuantity extends ClusterPickingEvent {
  final bool isOk;
  final int productId;
  final int batchId;
  final int idMove;
  final String type;
  const ChangeIsOkQuantity(
      this.isOk, this.productId, this.batchId, this.idMove, this.type);
}

class AddQuantitySeparate extends ClusterPickingEvent {
  final int productId;
  final int idMove;
  final dynamic quantity;
  final bool isOk;
  final String type;
  const AddQuantitySeparate(
      this.productId, this.idMove, this.quantity, this.isOk, this.type);
}

class ShowQuantityEvent extends ClusterPickingEvent {
  final bool showQuantity;
  const ShowQuantityEvent(this.showQuantity);
}

class UpdateNovedadProductEvent extends ClusterPickingEvent {
  final String selectedNovedad;
  const UpdateNovedadProductEvent(this.selectedNovedad);
}

class SetIsProcessingEvent extends ClusterPickingEvent {
  final bool isProcessing;
  const SetIsProcessingEvent(this.isProcessing);
}

class SeparateProductEvent extends ClusterPickingEvent {
  final int productId;
  final int batchId;
  final int idMove;
  final String type;
  const SeparateProductEvent(
      this.productId, this.batchId, this.idMove, this.type);
}

class ChangeCurrentProduct extends ClusterPickingEvent {
  final BatchProduct currentProduct;
  final String type;

  const ChangeCurrentProduct({
    required this.currentProduct,
    required this.type,
  });
}

class ViewProductImageEvent extends ClusterPickingEvent {
  final int idProduct;
  ViewProductImageEvent(this.idProduct);
}

class LoadSelectedProductEvent extends ClusterPickingEvent {
  final BatchProduct selectedProduct;
  final String type;
  LoadSelectedProductEvent(this.selectedProduct, this.type);
}
