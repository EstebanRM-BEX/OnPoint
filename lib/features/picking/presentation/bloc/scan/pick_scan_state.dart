part of 'pick_scan_bloc.dart';

@immutable
sealed class PickScanState {}

final class PickScanInitial extends PickScanState {}

// ── Carga del pick con productos ──────────────────────────────────────────

final class LoadProductsBatchSuccesStateBD extends PickScanState {
  final List<ProductsBatch> listOfProductsBatch;
  LoadProductsBatchSuccesStateBD({required this.listOfProductsBatch});
}

final class LoadProductsPickSuccesState extends PickScanState {
  final List<ProductsBatch> listOfProductsBatch;
  LoadProductsPickSuccesState({required this.listOfProductsBatch});
}

final class EmptyProductsPick extends PickScanState {}

// ── Info / data vars ──────────────────────────────────────────────────────

class LoadDataInfoSuccess extends PickScanState {}

class LoadDataInfoLoading extends PickScanState {}

class LoadDataInfoError extends PickScanState {
  final String msg;
  LoadDataInfoError(this.msg);
}

// ── Validación de campos ───────────────────────────────────────────────────

class ValidateFieldsStateSuccess extends PickScanState {
  final bool isOk;
  ValidateFieldsStateSuccess(this.isOk);
}

class ValidateFieldsStateError extends PickScanState {
  final String msg;
  ValidateFieldsStateError(this.msg);
}

class ChangeLocationIsOkState extends PickScanState {
  final bool isOk;
  ChangeLocationIsOkState(this.isOk);
}

class ChangeLocationDestIsOkState extends PickScanState {
  final bool isOk;
  ChangeLocationDestIsOkState(this.isOk);
}

class ChangeProductIsOkState extends PickScanState {
  final bool isOk;
  ChangeProductIsOkState(this.isOk);
}

class ChangeQuantityIsOkState extends PickScanState {
  final bool isOk;
  ChangeQuantityIsOkState(this.isOk);
}

// ── Cantidad ──────────────────────────────────────────────────────────────

class ChangeQuantitySeparateStateSuccess extends PickScanState {
  final dynamic quantity;
  ChangeQuantitySeparateStateSuccess(this.quantity);
}

class ChangeQuantitySeparateStateError extends PickScanState {
  final String msg;
  ChangeQuantitySeparateStateError(this.msg);
}

class ShowQuantityState extends PickScanState {
  final bool showQuantity;
  ShowQuantityState(this.showQuantity);
}

// ── Cambio de producto ────────────────────────────────────────────────────

class CurrentProductChangedStateLoading extends PickScanState {}

final class CurrentProductChangedState extends PickScanState {
  final ProductsBatch currentProduct;
  CurrentProductChangedState({required this.currentProduct});
}

class CurrentProductChangedStateError extends PickScanState {
  final String msg;
  CurrentProductChangedStateError(this.msg);
}

// ── Barcodes ──────────────────────────────────────────────────────────────

class BarcodesProductLoadedState extends PickScanState {
  final List<Barcodes> listOfBarcodes;
  BarcodesProductLoadedState({required this.listOfBarcodes});
}

// ── Muelles ───────────────────────────────────────────────────────────────

class MuellesLoadingState extends PickScanState {}

class MuellesLoadedState extends PickScanState {
  final List<Muelles> listOfMuelles;
  MuellesLoadedState({required this.listOfMuelles});
}

class MuellesErrorState extends PickScanState {
  final String error;
  MuellesErrorState(this.error);
}

class SelectSubMuelle extends PickScanState {
  final Muelles subMuelle;
  SelectSubMuelle(this.subMuelle);
}

class SubMuelleEditSusses extends PickScanState {
  final String message;
  SubMuelleEditSusses(this.message);
}

class SubMuelleEditFail extends PickScanState {
  final String message;
  SubMuelleEditFail(this.message);
}

class SubMuelleOcupadoError extends PickScanState {
  final String error;
  SubMuelleOcupadoError(this.error);
}

// ── Envío a Odoo ──────────────────────────────────────────────────────────

class SendProductPickOdooLoading extends PickScanState {}

class SendProductPickOdooSuccess extends PickScanState {}

class SendProductPickOdooError extends PickScanState {
  final String error;
  SendProductPickOdooError(this.error);
}

// ── Finalización del pick ─────────────────────────────────────────────────

class PickingOkState extends PickScanState {}

class PickingOkError extends PickScanState {}

class PickingOkLoading extends PickScanState {}

class PickOkEventSuccess extends PickScanState {
  final String message;
  PickOkEventSuccess(this.message);
}

// ── Backorder / validación ────────────────────────────────────────────────

class CreateBackOrderOrNotLoading extends PickScanState {}

class CreateBackOrderOrNotSuccess extends PickScanState {
  final bool isBackorder;
  final String msg;
  CreateBackOrderOrNotSuccess(this.isBackorder, this.msg);
}

class CreateBackOrderOrNotFailure extends PickScanState {
  final String error;
  final bool isBackorder;
  CreateBackOrderOrNotFailure(this.error, this.isBackorder);
}

class ValidateConfirmLoading extends PickScanState {}

class ValidateConfirmSuccess extends PickScanState {
  final bool isBackorder;
  final String msg;
  ValidateConfirmSuccess(this.isBackorder, this.msg);
}

class ValidateConfirmFailure extends PickScanState {
  final String error;
  ValidateConfirmFailure(this.error);
}

// ── Tiempo ────────────────────────────────────────────────────────────────

class StartOrStopTimeTransferSuccess extends PickScanState {
  final String isStarted;
  StartOrStopTimeTransferSuccess(this.isStarted);
}

class StartOrStopTimeTransferFailure extends PickScanState {
  final String error;
  StartOrStopTimeTransferFailure(this.error);
}

// ── Imagen producto ───────────────────────────────────────────────────────

class ViewProductImageLoading extends PickScanState {}

class ViewProductImageSuccess extends PickScanState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends PickScanState {
  final String error;
  ViewProductImageFailure(this.error);
}

// ── Procesamiento ─────────────────────────────────────────────────────────

class SetIsProcessingState extends PickScanState {
  final bool isProcessing;
  SetIsProcessingState(this.isProcessing);
}

// ── Novedades ─────────────────────────────────────────────────────────────

class SelectNovedadStateSuccess extends PickScanState {
  final String novedad;
  SelectNovedadStateSuccess(this.novedad);
}

class SelectNovedadStateError extends PickScanState {
  final String msg;
  SelectNovedadStateError(this.msg);
}

// ── Producto seleccionado (lista) ─────────────────────────────────────────

class LoadSelectedProductState extends PickScanState {
  final ProductsBatch selectedProduct;
  LoadSelectedProductState(this.selectedProduct);
}
