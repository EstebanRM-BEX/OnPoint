part of 'picking_pick_bloc.dart';

@immutable
sealed class PickingPickState {}

final class PickingPickInitial extends PickingPickState {}

final class PickingPickLoading extends PickingPickState {}

final class PickingPickBDLoading extends PickingPickState {}

final class PickingPickCompoBDLoading extends PickingPickState {}

final class PickingPickLoaded extends PickingPickState {
  final List<ResultPick> result;
  PickingPickLoaded(this.result);
}

final class PickingPickCompoLoading extends PickingPickState {}

final class PickingPickCompoLoaded extends PickingPickState {
  final List<ResultPick> result;
  PickingPickCompoLoaded(this.result);
}

final class PickingPickLoadedBD extends PickingPickState {
  final List<ResultPick> result;
  PickingPickLoadedBD(this.result);
}

final class PickingPickCompoLoadedBD extends PickingPickState {
  final List<ResultPick> result;
  PickingPickCompoLoadedBD(this.result);
}

final class PickingPickError extends PickingPickState {
  final String error;
  PickingPickError(this.error);
}

final class PickingPickCompoError extends PickingPickState {
  final String error;
  PickingPickCompoError(this.error);
}

class NovedadesLoadedState extends PickingPickState {
  final List<Novedad> listOfNovedades;
  NovedadesLoadedState({required this.listOfNovedades});
}

final class EmptyProductsPick extends PickingPickState {}

class BarcodesProductLoadedState extends PickingPickState {
  final List<Barcodes> listOfBarcodes;
  BarcodesProductLoadedState({required this.listOfBarcodes});
}

final class LoadProductsBatchSuccesStateBD extends PickingPickState {
  final List<ProductsBatch> listOfProductsBatch;
  LoadProductsBatchSuccesStateBD({required this.listOfProductsBatch});
}

//*estado para cargar las variables de estado
class LoadDataInfoSuccess extends PickingPickState {}

class LoadDataInfoLoading extends PickingPickState {}

class LoadDataInfoError extends PickingPickState {
  final String msg;
  LoadDataInfoError(this.msg);
}

class ConfigurationLoading extends PickingPickState {}

class ConfigurationPickingLoaded extends PickingPickState {
  final UserConfigurationModel configurations;

  ConfigurationPickingLoaded(this.configurations);
}

class ConfigurationError extends PickingPickState {
  final String error;

  ConfigurationError(this.error);
}

class ShowKeyboardState extends PickingPickState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class CurrentProductChangedStateLoading extends PickingPickState {}

//*estado para cambiar de producto
final class CurrentProductChangedState extends PickingPickState {
  final ProductsBatch currentProduct;
  CurrentProductChangedState({
    required this.currentProduct,
  });
}

class CurrentProductChangedStateError extends PickingPickState {
  final String msg;
  CurrentProductChangedStateError(this.msg);
}

class ChangeQuantityIsOkState extends PickingPickState {
  final bool isOk;
  ChangeQuantityIsOkState(this.isOk);
}

class ChangeLocationDestIsOkState extends PickingPickState {
  final bool isOk;
  ChangeLocationDestIsOkState(this.isOk);
}

class ChangeProductIsOkState extends PickingPickState {
  final bool isOk;
  ChangeProductIsOkState(this.isOk);
}

class ChangeLocationIsOkState extends PickingPickState {
  final bool isOk;
  ChangeLocationIsOkState(this.isOk);
}

//*estado para validar campos
class ValidateFieldsStateSuccess extends PickingPickState {
  final bool isOk;
  ValidateFieldsStateSuccess(this.isOk);
}

class ValidateFieldsStateError extends PickingPickState {
  final String msg;
  ValidateFieldsStateError(this.msg);
}

class UpdateScannedValueState extends PickingPickState {
  final String scannedValue;
  final String scan;
  UpdateScannedValueState(this.scannedValue, this.scan);
}

class ClearScannedValueState extends PickingPickState {}

//*estado para separar la cantidad
class ChangeQuantitySeparateStateSuccess extends PickingPickState {
  final dynamic quantity;
  ChangeQuantitySeparateStateSuccess(this.quantity);
}

class ChangeQuantitySeparateStateError extends PickingPickState {
  final String msg;
  ChangeQuantitySeparateStateError(this.msg);
}

class ShowQuantityState extends PickingPickState {
  final bool showQuantity;
  ShowQuantityState(this.showQuantity);
}

class SelectSubMuelle extends PickingPickState {
  final Muelles subMuelle;
  SelectSubMuelle(this.subMuelle);
}

class SubMuelleEditSusses extends PickingPickState {
  final String message;
  SubMuelleEditSusses(this.message);
}

class SubMuelleEditFail extends PickingPickState {
  final String message;
  SubMuelleEditFail(this.message);
}

class SetIsProcessingState extends PickingPickState {
  final bool isProcessing;
  SetIsProcessingState(this.isProcessing);
}

//*estados para seleccionar una novedad
class SelectNovedadStateSuccess extends PickingPickState {
  final String novedad;
  SelectNovedadStateSuccess(this.novedad);
}

class SelectNovedadStateError extends PickingPickState {
  final String msg;
  SelectNovedadStateError(this.msg);
}

//*estados para pasar el producto a pendiente
class ProductPendingSuccess extends PickingPickState {}

class ProductPendingError extends PickingPickState {}

class ProductPendingLoading extends PickingPickState {}

final class LoadProductsPickSuccesState extends PickingPickState {
  final List<ProductsBatch> listOfProductsBatch;
  LoadProductsPickSuccesState({required this.listOfProductsBatch});
}

class SendProductPickOdooLoading extends PickingPickState {}

class SendProductPickOdooSuccess extends PickingPickState {}

class SendProductPickOdooError extends PickingPickState {
  final String error;
  SendProductPickOdooError(
    this.error,
  );
}

//*est

class LoadingSendProductEdit extends PickingPickState {}

class ProductEditOk extends PickingPickState {}

class ProductEditError extends PickingPickState {}

//*estados para finalizar la separacion
class PickingOkState extends PickingPickState {}

class PickingOkError extends PickingPickState {}

class PickingOkLoading extends PickingPickState {}

class StartOrStopTimeTransferSuccess extends PickingPickState {
  final String isStarted;
  StartOrStopTimeTransferSuccess(this.isStarted);
}

class StartOrStopTimeTransferFailure extends PickingPickState {
  final String error;
  StartOrStopTimeTransferFailure(this.error);
}

class LoadSearchPickingState extends PickingPickState {}

class AssignUserToPickLoading extends PickingPickState {}

class AssignUserToPickSuccess extends PickingPickState {
  final int id;
  AssignUserToPickSuccess(this.id);
}

class AssignUserToPickError extends PickingPickState {
  final String error;
  AssignUserToPickError(this.error);
}

class CreateBackOrderOrNotLoading extends PickingPickState {}

class CreateBackOrderOrNotSuccess extends PickingPickState {
  final bool isBackorder;
  final String msg;
  CreateBackOrderOrNotSuccess(this.isBackorder, this.msg);
}

class CreateBackOrderOrNotFailure extends PickingPickState {
  final String error;
  final bool isBackorder;
  CreateBackOrderOrNotFailure(this.error, this.isBackorder);
}

class ValidateConfirmLoading extends PickingPickState {}

class ValidateConfirmSuccess extends PickingPickState {
  final bool isBackorder;
  final String msg;

  ValidateConfirmSuccess(this.isBackorder, this.msg);
}

class ValidateConfirmFailure extends PickingPickState {
  final String error;
  ValidateConfirmFailure(this.error);
}

class MuellesLoadingState extends PickingPickState {}

class MuellesLoadedState extends PickingPickState {
  final List<Muelles> listOfMuelles;
  MuellesLoadedState({required this.listOfMuelles});
}

class MuellesErrorState extends PickingPickState {
  final String error;
  MuellesErrorState(this.error);
}

class SubMuelleOcupadoError extends PickingPickState {
  final String error;
  SubMuelleOcupadoError(this.error);
}

class PickOkEventSuccess extends PickingPickState {
  final String message;

  PickOkEventSuccess(this.message);
}

class LoadSelectedProductState extends PickingPickState {
  final ProductsBatch selectedProduct;
  LoadSelectedProductState(this.selectedProduct);
}

class PickingLoadingState extends PickingPickState {}

class LoadHistoryPicksState extends PickingPickState {
  final List<ResultPick> listOfBatchs;
  LoadHistoryPicksState({required this.listOfBatchs});
}

class PickingErrorState extends PickingPickState {
  final String error;
  PickingErrorState(this.error);
}

class BatchHistoryLoadedState extends PickingPickState {
  final RespondePickDoneId historyBatchId;
  BatchHistoryLoadedState(this.historyBatchId);
}

class BatchsPickingErrorState extends PickingPickState {
  final String error;
  BatchsPickingErrorState(this.error);
}

class NeedUpdateVersionState extends PickingPickState {}

class ViewProductImageLoading extends PickingPickState {}

class ViewProductImageSuccess extends PickingPickState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends PickingPickState {
  final String error;
  ViewProductImageFailure(this.error);
}

// Estado para indicar que la lista de picks se cargó o actualizó (filtro/orden)
class PickingPickSuccess extends PickingPickState {
  // Opcional: Puedes pasar la lista aquí para ser más puro en el patrón BLoC
  final List<ResultPick> picks;

  PickingPickSuccess(this.picks);

  @override
  List<Object> get props => [picks, DateTime.now()];
  // Tip: Agregar DateTime.now() o UniqueKey() en props asegura que
  // Flutter redibuje aunque la lista sea "técnicamente" la misma pero en diferente orden.
}
