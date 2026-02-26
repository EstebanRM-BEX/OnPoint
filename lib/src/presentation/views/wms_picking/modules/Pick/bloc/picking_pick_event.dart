part of 'picking_pick_bloc.dart';

@immutable
sealed class PickingPickEvent {}

class FetchPickingPickEvent extends PickingPickEvent {
  final bool isLoadinDialog;

  FetchPickingPickEvent(this.isLoadinDialog);
}

class FetchPickingComponentesEvent extends PickingPickEvent {
  final bool isLoadinDialog;

  FetchPickingComponentesEvent(this.isLoadinDialog);
}

class FetchPickingPickFromDBEvent extends PickingPickEvent {
  final bool isLoadinDialog;

  FetchPickingPickFromDBEvent(this.isLoadinDialog);
}

class FetchPickingComponentesFromDBEvent extends PickingPickEvent {
  final bool isLoadinDialog;

  FetchPickingComponentesFromDBEvent(this.isLoadinDialog);
}

class LoadAllNovedadesPickEvent extends PickingPickEvent {}

class FetchPickWithProductsEvent extends PickingPickEvent {
  final int pickId;

  FetchPickWithProductsEvent(this.pickId);
}

class FetchBarcodesProductEvent extends PickingPickEvent {}

class LoadDataInfoEvent extends PickingPickEvent {}

class LoadConfigurationsUser extends PickingPickEvent {}

class ChangeLocationIsOkEvent extends PickingPickEvent {
  final int productId;
  final int batchId;
  final int idMove;
  ChangeLocationIsOkEvent(this.productId, this.batchId, this.idMove);
}

class ChangeLocationDestIsOkEvent extends PickingPickEvent {
  final bool locationDestIsOk;
  final int productId;
  final int batchId;
  final int idMove;
  ChangeLocationDestIsOkEvent(
      this.locationDestIsOk, this.productId, this.batchId, this.idMove);
}

class ChangeProductIsOkEvent extends PickingPickEvent {
  final bool productIsOk;
  final int productId;
  final int batchId;
  final dynamic quantity;
  final int idMove;
  ChangeProductIsOkEvent(this.productIsOk, this.productId, this.batchId,
      this.quantity, this.idMove);
}

class ChangeIsOkQuantity extends PickingPickEvent {
  final bool isOk;
  final int productId;
  final int batchId;
  final int idMove;
  ChangeIsOkQuantity(this.isOk, this.productId, this.batchId, this.idMove);
}

class ChangeCurrentProduct extends PickingPickEvent {
  final ProductsBatch currentProduct;

  ChangeCurrentProduct({
    required this.currentProduct,
  });
}

class QuantityChanged extends PickingPickEvent {
  final dynamic quantity;
  QuantityChanged(this.quantity);
}

class SelectNovedadEvent extends PickingPickEvent {
  final String novedad;
  SelectNovedadEvent(this.novedad);
}

class ValidateFieldsEvent extends PickingPickEvent {
  final String field;
  final bool isOk;
  ValidateFieldsEvent({required this.field, required this.isOk});
}

class ChangeQuantitySeparate extends PickingPickEvent {
  final dynamic quantity;
  final int productId;
  final int idMove;
  ChangeQuantitySeparate(this.quantity, this.productId, this.idMove);
}

class AddQuantitySeparate extends PickingPickEvent {
  final int productId;
  final int idMove;
  final dynamic quantity;
  final bool isOk;
  AddQuantitySeparate(this.productId, this.idMove, this.quantity, this.isOk);
}

class ShowQuantityEvent extends PickingPickEvent {
  final bool showQuantity;
  ShowQuantityEvent(this.showQuantity);
}

class SelectedSubMuelleEvent extends PickingPickEvent {
  final Muelles subMuelleSlected;

  SelectedSubMuelleEvent(this.subMuelleSlected);
}

class AssignSubmuelleEvent extends PickingPickEvent {
  final List<ProductsBatch> productsSeparate;
  final Muelles muelle;
  final bool isOccupied;

  AssignSubmuelleEvent(this.productsSeparate, this.muelle, this.isOccupied);
}

class SetIsProcessingEvent extends PickingPickEvent {
  final bool isProcessing;
  SetIsProcessingEvent(this.isProcessing);
}

class ProductPendingEvent extends PickingPickEvent {
  final int batchId;
  final ProductsBatch product;

  ProductPendingEvent(this.batchId, this.product);
}

class ClearSearchProudctsPickEvent extends PickingPickEvent {}

class SearchProductsPickEvent extends PickingPickEvent {
  final String query;

  SearchProductsPickEvent(this.query);
}

class SendProductOdooPickEvent extends PickingPickEvent {
  final ProductsBatch product;
  final bool isEdit;

  SendProductOdooPickEvent(this.product, this.isEdit);
}

class SendProductEditOdooEvent extends PickingPickEvent {
  final ProductsBatch product;
  final dynamic cantidad;

  SendProductEditOdooEvent(
    this.product,
    this.cantidad,
  );
}

class PickingOkEvent extends PickingPickEvent {
  final int batchId;
  final int productId;

  PickingOkEvent(this.batchId, this.productId);
}

class LoadProductEditEvent extends PickingPickEvent {}

class AssignUserToTransfer extends PickingPickEvent {
  final int id;
  AssignUserToTransfer(this.id);
}

class StartOrStopTimeTransfer extends PickingPickEvent {
  final int id;
  final String value;

  StartOrStopTimeTransfer(
    this.id,
    this.value,
  );
}

class SearchPickEvent extends PickingPickEvent {
  final String query;
  final bool isComponentes;

  SearchPickEvent(this.query, this.isComponentes);
}

class CreateBackOrderOrNot extends PickingPickEvent {
  final int idPick;
  final bool isBackOrder;
  final bool isExternalProduct;
  CreateBackOrderOrNot(this.idPick, this.isBackOrder, this.isExternalProduct);
}

class ValidateConfirmEvent extends PickingPickEvent {
  final int idPick;
  final bool isBackOrder;
  final bool isLoadinDialog;
  ValidateConfirmEvent(this.idPick, this.isBackOrder, this.isLoadinDialog);
}

class FetchMuellesEvent extends PickingPickEvent {}

class PickOkEvent extends PickingPickEvent {
  final int idPick;
  PickOkEvent(this.idPick);
}

class LoadSelectedProductEvent extends PickingPickEvent {
  final ProductsBatch selectedProduct;
  LoadSelectedProductEvent(this.selectedProduct);
}

class LoadHistoryPickEvent extends PickingPickEvent {
  final bool isLoadinDialog;
  final String date;
  LoadHistoryPickEvent(this.isLoadinDialog, this.date);
}

class LoadHistoryPickComponentEvent extends PickingPickEvent {
  final bool isLoadinDialog;
  final String date;
  LoadHistoryPickComponentEvent(this.isLoadinDialog, this.date);
}

class LoadHistoryPickIdEvent extends PickingPickEvent {
  final bool isLoadinDialog;
  final int idPicking;
  LoadHistoryPickIdEvent(this.isLoadinDialog, this.idPicking);
}

class ViewProductImageEvent extends PickingPickEvent {
  final int idProduct;
  ViewProductImageEvent(this.idProduct);
}

class SortPickListEvent extends PickingPickEvent {
  final String field;
  final bool ascending;
  SortPickListEvent(this.field, this.ascending);
}
