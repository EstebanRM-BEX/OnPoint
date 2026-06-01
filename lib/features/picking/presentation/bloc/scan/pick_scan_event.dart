part of 'pick_scan_bloc.dart';

@immutable
sealed class PickScanEvent {}

// ── Validación de campos ───────────────────────────────────────────────────

class ValidateFieldsEvent extends PickScanEvent {
  final String field;
  final bool isOk;
  ValidateFieldsEvent({required this.field, required this.isOk});
}

class ChangeLocationIsOkEvent extends PickScanEvent {
  final int productId;
  final int batchId;
  final int idMove;
  ChangeLocationIsOkEvent(this.productId, this.batchId, this.idMove);
}

class ChangeLocationDestIsOkEvent extends PickScanEvent {
  final bool locationDestIsOk;
  final int productId;
  final int batchId;
  final int idMove;
  ChangeLocationDestIsOkEvent(
      this.locationDestIsOk, this.productId, this.batchId, this.idMove);
}

class ChangeProductIsOkEvent extends PickScanEvent {
  final bool productIsOk;
  final int productId;
  final int batchId;
  final dynamic quantity;
  final int idMove;
  ChangeProductIsOkEvent(
      this.productIsOk, this.productId, this.batchId, this.quantity, this.idMove);
}

class ChangeIsOkQuantity extends PickScanEvent {
  final bool isOk;
  final int productId;
  final int batchId;
  final int idMove;
  ChangeIsOkQuantity(this.isOk, this.productId, this.batchId, this.idMove);
}

// ── Manejo de cantidad ─────────────────────────────────────────────────────

class ChangeQuantitySeparate extends PickScanEvent {
  final dynamic quantity;
  final int productId;
  final int idMove;
  ChangeQuantitySeparate(this.quantity, this.productId, this.idMove);
}

class AddQuantitySeparate extends PickScanEvent {
  final int productId;
  final int idMove;
  final dynamic quantity;
  final bool isOk;
  AddQuantitySeparate(this.productId, this.idMove, this.quantity, this.isOk);
}

class ShowQuantityEvent extends PickScanEvent {
  final bool showQuantity;
  ShowQuantityEvent(this.showQuantity);
}

// ── Navegación de productos ────────────────────────────────────────────────

class ChangeCurrentProduct extends PickScanEvent {
  final ProductsBatch currentProduct;
  ChangeCurrentProduct({required this.currentProduct});
}

// ── Carga de datos del pick ────────────────────────────────────────────────

class FetchPickWithProductsEvent extends PickScanEvent {
  final int pickId;
  FetchPickWithProductsEvent(this.pickId);
}

class FetchBarcodesProductEvent extends PickScanEvent {}

class LoadProductEditEvent extends PickScanEvent {}

// ── Muelles ───────────────────────────────────────────────────────────────

class FetchMuellesEvent extends PickScanEvent {}

class AssignSubmuelleEvent extends PickScanEvent {
  final List<ProductsBatch> productsSeparate;
  final Muelles muelle;
  final bool isOccupied;
  AssignSubmuelleEvent(this.productsSeparate, this.muelle, this.isOccupied);
}

class SelectedSubMuelleEvent extends PickScanEvent {
  final Muelles subMuelleSlected;
  SelectedSubMuelleEvent(this.subMuelleSlected);
}

// ── Imagen del producto ────────────────────────────────────────────────────

class ViewProductImageEvent extends PickScanEvent {
  final int idProduct;
  ViewProductImageEvent(this.idProduct);
}

// ── Procesamiento ─────────────────────────────────────────────────────────

class SetIsProcessingEvent extends PickScanEvent {
  final bool isProcessing;
  SetIsProcessingEvent(this.isProcessing);
}

// ── Validación / cierre del pick ──────────────────────────────────────────

class ValidateConfirmEvent extends PickScanEvent {
  final int idPick;
  final bool isBackOrder;
  final bool isLoadinDialog;
  ValidateConfirmEvent(this.idPick, this.isBackOrder, this.isLoadinDialog);
}

class CreateBackOrderOrNot extends PickScanEvent {
  final int idPick;
  final bool isBackOrder;
  final bool isExternalProduct;
  CreateBackOrderOrNot(this.idPick, this.isBackOrder, this.isExternalProduct);
}

class PickOkEvent extends PickScanEvent {
  final int idPick;
  PickOkEvent(this.idPick);
}

// ── Eventos internos (usados dentro de handlers) ──────────────────────────

class PickingOkEvent extends PickScanEvent {
  final int batchId;
  final int productId;
  PickingOkEvent(this.batchId, this.productId);
}

class StartOrStopTimeTransfer extends PickScanEvent {
  final int id;
  final String value;
  StartOrStopTimeTransfer(this.id, this.value);
}

// ── Novedades ─────────────────────────────────────────────────────────────

class SelectNovedadEvent extends PickScanEvent {
  final String novedad;
  SelectNovedadEvent(this.novedad);
}
