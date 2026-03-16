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
  final BatchProduct product;
  const UpdateNovedadProductEvent(this.selectedNovedad, this.product);
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
  const ViewProductImageEvent(this.idProduct);
}

class LoadSelectedProductEvent extends ClusterPickingEvent {
  final BatchProduct selectedProduct;
  final String type;
  const LoadSelectedProductEvent(this.selectedProduct, this.type);
}

class ValidatePedidoEvent extends ClusterPickingEvent {
  final int productId;
  final int batchId;
  final int idMove;
  final String type;
  const ValidatePedidoEvent(
      this.productId, this.batchId, this.idMove, this.type);
}

class MarkPedidoAsValidatedEvent extends ClusterPickingEvent {
  final int batchId;
  final String namePedido;
  final bool isValidated;

  const MarkPedidoAsValidatedEvent({
    required this.batchId,
    required this.namePedido,
    required this.isValidated,
  });

  @override
  List<Object> get props => [batchId, namePedido, isValidated];
}

class EndTimePick extends ClusterPickingEvent {
  final int batchId;
  final DateTime time;
  const EndTimePick(this.batchId, this.time);
}

class StartTimePick extends ClusterPickingEvent {
  final int batchId;
  final DateTime time;
  final String type;

  const StartTimePick(this.batchId, this.time, this.type);

  @override
  List<Object> get props => [batchId, time, type];
}

class SendProductEditOdooEvent extends ClusterPickingEvent {
  final BatchProduct product;
  final dynamic cantidad;

  const SendProductEditOdooEvent(
    this.product,
    this.cantidad,
  );
}

class SelectLoteEventCluster extends ClusterPickingEvent {
  final LoteProducto selectedLote;

  const SelectLoteEventCluster(this.selectedLote);

  @override
  List<Object> get props => [selectedLote];
}

class ProductPendingEvent extends ClusterPickingEvent {
  final int batchId;

  final BatchProduct product;
  final String type;
  const ProductPendingEvent(this.batchId, this.product, this.type);
}
