part of 'crate_transfer_bloc.dart';

@immutable
sealed class CreateTransferState {}

final class CrateTransferInitial extends CreateTransferState {}

class UpdateScannedValueState extends CreateTransferState {
  final String scannedValue;
  final String scan;
  UpdateScannedValueState(this.scannedValue, this.scan);
}

class ClearScannedValueState extends CreateTransferState {}

class ConfigurationError extends CreateTransferState {
  final String message;
  ConfigurationError(this.message);
}

class ConfigurationLoaded extends CreateTransferState {
  final UserConfigurationModel configurations;
  ConfigurationLoaded(this.configurations);
}

//*estado para validar campos
class ValidateFieldsStateSuccess extends CreateTransferState {
  final bool isOk;
  ValidateFieldsStateSuccess(this.isOk);
}

class ValidateFieldsStateError extends CreateTransferState {
  final String msg;
  ValidateFieldsStateError(this.msg);
}

class LoadLocationsLoading extends CreateTransferState {}

class LoadLocationsSuccess extends CreateTransferState {
  final List<ResultUbicaciones> locations;
  LoadLocationsSuccess(this.locations);
}

class LoadLocationsFailure extends CreateTransferState {
  final String error;
  LoadLocationsFailure(this.error);
}

class ShowKeyboardState extends CreateTransferState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class GetProductsLoadingBD extends CreateTransferState {}

class GetProductsSuccessBD extends CreateTransferState {
  final List<Product> products;
  GetProductsSuccessBD(this.products);
}

class GetProductsFailure extends CreateTransferState {
  final String error;
  GetProductsFailure(this.error);
}

class SearchLoading extends CreateTransferState {}

class SearchFailure extends CreateTransferState {
  final String error;
  SearchFailure(this.error);
}

class SearchLocationSuccess extends CreateTransferState {
  final List<ResultUbicaciones> locations;
  SearchLocationSuccess(this.locations);
}

class SearchProductSuccess extends CreateTransferState {
  final List<Product> products;
  SearchProductSuccess(this.products);
}

class ChangeLocationIsOkState extends CreateTransferState {
  final bool isOk;
  final bool isLocationDest;
  ChangeLocationIsOkState(this.isOk, this.isLocationDest);
}

class ChangeProductOrderIsOkState extends CreateTransferState {
  final bool isOk;
  ChangeProductOrderIsOkState(this.isOk);
}

class SearchLoteSuccess extends CreateTransferState {
  final List<LotesProduct> locations;
  SearchLoteSuccess(this.locations);
}

class CreateLoteProductLoading extends CreateTransferState {}

class CreateLoteProductSuccess extends CreateTransferState {}

class CreateLoteProductFailure extends CreateTransferState {
  final String error;
  CreateLoteProductFailure(this.error);
}

class GetLotesProductLoading extends CreateTransferState {}

class GetLotesProductSuccess extends CreateTransferState {
  final List<LotesProduct> lotesProduct;
  GetLotesProductSuccess(this.lotesProduct);
}

class GetLotesProductFailure extends CreateTransferState {
  final String error;
  GetLotesProductFailure(this.error);
}

class ChangeLoteIsOkState extends CreateTransferState {
  final bool isOk;
  ChangeLoteIsOkState(this.isOk);
}

class ChangeQuantityIsOkState extends CreateTransferState {
  final bool isOk;
  ChangeQuantityIsOkState(this.isOk);
}

class ShowQuantityState extends CreateTransferState {
  final bool showQuantity;
  ShowQuantityState(this.showQuantity);
}

class ChangeQuantitySeparateState extends CreateTransferState {
  final dynamic quantity;
  ChangeQuantitySeparateState(this.quantity);
}

class ClearDataCreateTransferState extends CreateTransferState {}

class ClearDataCreateTransferLoadingState extends CreateTransferState {}

//*estado para separar la cantidad
class ChangeQuantitySeparateStateSuccess extends CreateTransferState {
  final dynamic quantity;
  ChangeQuantitySeparateStateSuccess(this.quantity);
}

class ChangeQuantitySeparateStateError extends CreateTransferState {
  final String msg;
  ChangeQuantitySeparateStateError(this.msg);
}

class BarcodesProductLoadedState extends CreateTransferState {
  final List<BarcodeInventario> listOfBarcodes;
  BarcodesProductLoadedState({required this.listOfBarcodes});
}

class FetchAllBarcodesSuccess extends CreateTransferState {
  final List<BarcodeInventario> allBarcodes;
  FetchAllBarcodesSuccess(this.allBarcodes);
}

class FetchAllBarcodesFailure extends CreateTransferState {
  final String error;
  FetchAllBarcodesFailure(this.error);
}

class ProductAddingToTransferLoadingState extends CreateTransferState {}

class ProductAddedToTransferState extends CreateTransferState {}

class ProductAddToTransferErrorState extends CreateTransferState {
  final String error;
  ProductAddToTransferErrorState(this.error);
}

class ProductRemovingFromTransferLoadingState extends CreateTransferState {}

class ProductRemovedFromTransferState extends CreateTransferState {}

class ProductRemoveFromTransferErrorState extends CreateTransferState {
  final String error;
  ProductRemoveFromTransferErrorState(this.error);
}

class CreateTransferLoading extends CreateTransferState {}

class CreateTransferFailure extends CreateTransferState {
  final String error;
  CreateTransferFailure(this.error);
}

class CreateTransferSuccess extends CreateTransferState {
  final RespondeCreateTransfer response;
  CreateTransferSuccess(this.response);
}

class ValidateStockLoading extends CreateTransferState {}

class ValidateStockSuccess extends CreateTransferState {
  final RespondeValidateStock responseValidateStock;
  ValidateStockSuccess(this.responseValidateStock);
}

class ValidateStockFailure extends CreateTransferState {
  final String error;
  ValidateStockFailure(this.error);
}
