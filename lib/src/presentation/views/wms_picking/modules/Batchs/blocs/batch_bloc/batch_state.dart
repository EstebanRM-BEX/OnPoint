part of 'batch_bloc.dart';

@immutable
sealed class BatchState {}

final class BatchInitial extends BatchState {}

final class ProductsBatchLoadingState extends BatchState {}

final class LoadProductsBatchSuccesState extends BatchState {
  final List<ProductsBatch> listOfProductsBatch;
  LoadProductsBatchSuccesState({required this.listOfProductsBatch});
}

final class LoadProductsBatchSuccesStateBD extends BatchState {
  final List<ProductsBatch> listOfProductsBatch;
  LoadProductsBatchSuccesStateBD({required this.listOfProductsBatch});
}

class ShowKeyboardState extends BatchState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class ShouldRunDependenciesState extends BatchState {
  final bool shouldRunDependencies;
  ShouldRunDependenciesState({required this.shouldRunDependencies});
}

final class BatchErrorState extends BatchState {
  final String error;
  BatchErrorState(this.error);
}

final class EmptyroductsBatch extends BatchState {}

final class GetProductByIdLoaded extends BatchState {
  final Products product;
  GetProductByIdLoaded(this.product);
}

class ChangeQuantityIsOkState extends BatchState {
  final bool isOk;
  ChangeQuantityIsOkState(this.isOk);
}

class ChangeLocationDestIsOkState extends BatchState {
  final bool isOk;
  ChangeLocationDestIsOkState(this.isOk);
}

class ChangeProductIsOkState extends BatchState {
  final bool isOk;
  ChangeProductIsOkState(this.isOk);
}

class ChangeLocationIsOkState extends BatchState {
  final bool isOk;
  ChangeLocationIsOkState(this.isOk);
}

//*estado para cambiar de producto
final class CurrentProductChangedState extends BatchState {
  final ProductsBatch currentProduct;
  final int index;
  CurrentProductChangedState(
      {required this.currentProduct, required this.index});
}

class CurrentProductChangedStateError extends BatchState {
  final String msg;
  CurrentProductChangedStateError(this.msg);
}

class CurrentProductChangedStateLoading extends BatchState {}

final class QuantityChangedState extends BatchState {
  final dynamic quantity;
  QuantityChangedState(this.quantity);
}

//*estados para seleccionar una novedad
class SelectNovedadStateSuccess extends BatchState {
  final String novedad;
  SelectNovedadStateSuccess(this.novedad);
}

class SelectNovedadStateError extends BatchState {
  final String msg;
  SelectNovedadStateError(this.msg);
}

//*estado para validar campos
class ValidateFieldsStateSuccess extends BatchState {
  final bool isOk;
  ValidateFieldsStateSuccess(this.isOk);
}

class ValidateFieldsStateError extends BatchState {
  final String msg;
  ValidateFieldsStateError(this.msg);
}

//*estado para cargar las vairbales d estado
class LoadDataInfoSuccess extends BatchState {}

class LoadDataInfoError extends BatchState {
  final String msg;
  LoadDataInfoError(this.msg);
}

class LoadDataInfoLoading extends BatchState {}

//*estado para separar la cantidad
class ChangeQuantitySeparateStateSuccess extends BatchState {
  final dynamic quantity;
  ChangeQuantitySeparateStateSuccess(this.quantity);
}

class ChangeQuantitySeparateStateError extends BatchState {
  final String msg;
  ChangeQuantitySeparateStateError(this.msg);
}

//*estados para finalizar la separacion
class PickingOkState extends BatchState {}

class PickingOkError extends BatchState {}

class PickingOkLoading extends BatchState {}

class ConfigurationLoading extends BatchState {}

class ConfigurationPickingLoaded extends BatchState {
  final UserConfigurationModel configurations;

  ConfigurationPickingLoaded(this.configurations);
}

class ConfigurationError extends BatchState {
  final String error;

  ConfigurationError(this.error);
}

class ProductPendingState extends BatchState {
  final List<ProductsBatch> listOfProductsBatch;
  ProductPendingState({required this.listOfProductsBatch});
}

class LoadingSendProductEdit extends BatchState {}

class ProductEditOk extends BatchState {}

class ProductEditError extends BatchState {
  final String error;
  ProductEditError(this.error);
}

class ScanBarcodeState extends BatchState {
  final String barcode;
  ScanBarcodeState(this.barcode);
}

class NovedadesLoadedState extends BatchState {
  final List<Novedad> listOfNovedades;
  NovedadesLoadedState({required this.listOfNovedades});
}

class SelectSubMuelle extends BatchState {
  final Muelles subMuelle;
  SelectSubMuelle(this.subMuelle);
}

class SubMuelleEditSusses extends BatchState {
  final String message;
  SubMuelleEditSusses(this.message);
}

class SubMuelleOcupadoError extends BatchState {
  final String error;
  SubMuelleOcupadoError(this.error);
}

class SubMuelleEditFail extends BatchState {
  final String message;
  SubMuelleEditFail(this.message);
}

class BarcodesProductLoadedState extends BatchState {
  final List<Barcodes> listOfBarcodes;
  BarcodesProductLoadedState({required this.listOfBarcodes});
}

class InfoDeviceLoadedState extends BatchState {
  InfoDeviceLoadedState();
}

//*estados para pasar el producto a pendiente
class ProductPendingSuccess extends BatchState {}

class ProductPendingError extends BatchState {}

class ProductPendingLoading extends BatchState {}

//*estados para enviar un producto a odoo

class SendProductOdooLoading extends BatchState {}

class SendProductOdooSuccess extends BatchState {}

class SendProductOdooError extends BatchState {
  final String error;
  SendProductOdooError(this.error);
}

//*estado para actualizar el valor escaneado

class UpdateScannedValueState extends BatchState {
  final String scannedValue;
  final String scan;
  UpdateScannedValueState(this.scannedValue, this.scan);
}

class ClearScannedValueState extends BatchState {}

class ShowQuantityState extends BatchState {
  final bool showQuantity;
  ShowQuantityState(this.showQuantity);
}

class SetIsProcessingState extends BatchState {
  final bool isProcessing;
  SetIsProcessingState(this.isProcessing);
}

class CloseState extends BatchState {}

class LoadingFetchBatch extends BatchState {}

//*tiempo de separacion
class TimeSeparateSuccess extends BatchState {
  final String time;
  TimeSeparateSuccess(this.time);
}

class TimeSeparateError extends BatchState {
  final String msg;
  TimeSeparateError(this.msg);
}

class MuellesLoadingState extends BatchState {}

class MuellesLoadedState extends BatchState {
  final List<Muelles> listOfMuelles;
  MuellesLoadedState({required this.listOfMuelles});
}

class MuellesErrorState extends BatchState {
  final String error;
  MuellesErrorState(this.error);
}

class LoadSelectedProductState extends BatchState {
  final ProductsBatch selectedProduct;
  LoadSelectedProductState(this.selectedProduct);
}

class ViewProductImageLoading extends BatchState {}

class ViewProductImageSuccess extends BatchState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends BatchState {
  final String error;
  ViewProductImageFailure(this.error);
}
