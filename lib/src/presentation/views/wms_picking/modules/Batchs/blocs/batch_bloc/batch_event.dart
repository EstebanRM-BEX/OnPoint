// ignore_for_file: must_be_immutable

part of 'batch_bloc.dart';

@immutable
sealed class BatchEvent {}

class InitialStateEvent extends BatchEvent {}

class LoadAllProductsBatchsEvent extends BatchEvent {
  int batchId;

  LoadAllProductsBatchsEvent({
    required this.batchId,
  });
}

class ClearSearchProudctsBatchEvent extends BatchEvent {
  final String type;
  ClearSearchProudctsBatchEvent(this.type);
}

class SearchProductsBatchEvent extends BatchEvent {
  final String query;
  final String type;

  SearchProductsBatchEvent(this.query, this.type);
}

class LoadProductsBatchFromDBEvent extends BatchEvent {
  int batchId;

  LoadProductsBatchFromDBEvent({required this.batchId});
}

class NextProductEvent extends BatchEvent {}

class FetchBatchWithProductsEvent extends BatchEvent {
  final int batchId;
  final String type;

  FetchBatchWithProductsEvent(this.batchId, this.type);
}

class GetProductById extends BatchEvent {
  final int productId;

  GetProductById(this.productId);
}

//*empezar el tiempo de separacion
class StartTimePick extends BatchEvent {
  final int batchId;
  final DateTime time;
  final String type;
  StartTimePick(this.batchId, this.time, this.type);
}

class EndTimePick extends BatchEvent {
  final int batchId;
  final DateTime time;
  EndTimePick(this.batchId, this.time);
}

//* CAMBIAR VALORES DE VARIABLES
class ChangeLocationIsOkEvent extends BatchEvent {
  final int productId;
  final int batchId;
  final int idMove;
  final String type;
  ChangeLocationIsOkEvent(this.productId, this.batchId, this.idMove, this.type);
}

class ChangeLocationDestIsOkEvent extends BatchEvent {
  final bool locationDestIsOk;
  final int productId;
  final int batchId;
  final int idMove;
  final String type;
  ChangeLocationDestIsOkEvent(
      this.locationDestIsOk, this.productId, this.batchId, this.idMove, this.type);
}

class ChangeProductIsOkEvent extends BatchEvent {
  final bool productIsOk;
  final int productId;
  final int batchId;
  final dynamic quantity;
  final int idMove;
  final String type;
  ChangeProductIsOkEvent(this.productIsOk, this.productId, this.batchId,
      this.quantity, this.idMove, this.type);
}

class ChangeIsOkQuantity extends BatchEvent {
  final bool isOk;
  final int productId;
  final int batchId;
  final int idMove;
  final String type;
  ChangeIsOkQuantity(this.isOk, this.productId, this.batchId, this.idMove, this.type);
}

class ChangeCurrentProduct extends BatchEvent {
  final ProductsBatch currentProduct;
  final String type;

  ChangeCurrentProduct({
    required this.currentProduct,
    required this.type,
  });
}

class QuantityChanged extends BatchEvent {
  final dynamic quantity;
  QuantityChanged(this.quantity);
}

class SelectNovedadEvent extends BatchEvent {
  final String novedad;
  SelectNovedadEvent(this.novedad);
}

class ValidateFieldsEvent extends BatchEvent {
  final String field;
  final bool isOk;
  ValidateFieldsEvent({required this.field, required this.isOk});
}

class LoadDataInfoEvent extends BatchEvent {}

class ChangeQuantitySeparate extends BatchEvent {
  final dynamic quantity;
  final int productId;
  final int idMove;
  final String type;
  ChangeQuantitySeparate(this.quantity, this.productId, this.idMove, this.type);
}

class AddQuantitySeparate extends BatchEvent {
  final int productId;
  final int idMove;
  final dynamic quantity;
  final bool isOk;
  final String type;
  AddQuantitySeparate(this.productId, this.idMove, this.quantity, this.isOk, this.type);
}

class PickingOkEvent extends BatchEvent {
  final int batchId;
  final int productId;
  final String type;

  PickingOkEvent(this.batchId, this.productId, this.type);
}

class ProductPendingEvent extends BatchEvent {
  final int batchId;

  final ProductsBatch product;
  final String type;
  ProductPendingEvent(this.batchId, this.product, this.type);
}

class LoadConfigurationsUser extends BatchEvent {
  LoadConfigurationsUser();
}

class LoadProductEditEvent extends BatchEvent {
  final String type;
  LoadProductEditEvent(this.type);
}

class SendProductEditOdooEvent extends BatchEvent {
  final ProductsBatch product;
  final dynamic cantidad;
  final String type;

  SendProductEditOdooEvent(
    this.product,
    this.cantidad,
    this.type,
  );
}

class AssignSubmuelleEvent extends BatchEvent {
  final List<ProductsBatch> productsSeparate;
  final Muelles muelle;
  final bool isOccupied;
  final String type;

  AssignSubmuelleEvent(
      this.productsSeparate, this.muelle, this.isOccupied, this.type);
}

class ScanBarcodeEvent extends BatchEvent {}

class LoadInfoDeviceEvent extends BatchEvent {}

class ShowKeyboard extends BatchEvent {
  final bool showKeyboard;

  ShowKeyboard(this.showKeyboard);
}

class LoadAllNovedadesEvent extends BatchEvent {}

class SelectedSubMuelleEvent extends BatchEvent {
  final Muelles subMuelleSlected;

  SelectedSubMuelleEvent(this.subMuelleSlected);
}

class FetchBarcodesProductEvent extends BatchEvent {}

class ResetValuesEvent extends BatchEvent {}

class SortProductsByLocation extends BatchEvent {}

//evento para enviar un producto a odoo
class SendProductOdooEvent extends BatchEvent {
  final ProductsBatch product;
  final String type;

  SendProductOdooEvent(
    this.product,
    this.type,
  );
}

class UpdateScannedValueEvent extends BatchEvent {
  final String scannedValue;
  final String scan;
  UpdateScannedValueEvent(this.scannedValue, this.scan);
}

class ClearScannedValueEvent extends BatchEvent {
  final String scan;
  ClearScannedValueEvent(this.scan);
}

class ShowQuantityEvent extends BatchEvent {
  final bool showQuantity;
  ShowQuantityEvent(this.showQuantity);
}

class SetIsProcessingEvent extends BatchEvent {
  final bool isProcessing;
  SetIsProcessingEvent(this.isProcessing);
}

class CloseStateEvent extends BatchEvent {}

class FetchMuellesEvent extends BatchEvent {}

class LoadSelectedProductEvent extends BatchEvent {
  final ProductsBatch selectedProduct;
  final String type;
  LoadSelectedProductEvent(this.selectedProduct, this.type);
}

class ViewProductImageEvent extends BatchEvent {
  final int idProduct;
  ViewProductImageEvent(this.idProduct);
}
