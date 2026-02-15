part of 'conteo_bloc.dart';

@immutable
sealed class ConteoState {}

final class ConteoInitial extends ConteoState {}

class ConteoLoading extends ConteoState {}

class NeedUpdateVersionState extends ConteoState {}

final class ConteoLoaded extends ConteoState {
  final List<DatumConteo> conteos;

  ConteoLoaded(this.conteos);
}

final class ConteoError extends ConteoState {
  final String message;

  ConteoError(this.message);
}

class LoadConteoSuccess extends ConteoState {
  final DatumConteo ordenConteo;
  LoadConteoSuccess(this.ordenConteo);
}

//estados para cargar la lista de conteos desde la bd
class ConteoFromDBLoaded extends ConteoState {
  final List<DatumConteo> conteos;

  ConteoFromDBLoaded(this.conteos);
}

class ConteoFromDBLoading extends ConteoState {}

class ConteoFromDBError extends ConteoState {
  final String message;

  ConteoFromDBError(this.message);
}

//*estado para validar campos
class ValidateFieldsStateSuccess extends ConteoState {
  final bool isOk;
  ValidateFieldsStateSuccess(this.isOk);
}

class ValidateFieldsStateError extends ConteoState {
  final String msg;
  ValidateFieldsStateError(this.msg);
}

class LoadCurrentProductError extends ConteoState {
  final String message;
  LoadCurrentProductError(this.message);
}

class LoadCurrentProductSuccess extends ConteoState {
  final CountedLine currentProduct;
  LoadCurrentProductSuccess(this.currentProduct);
}

//*estado para actualizar el valor escaneado

class UpdateScannedValueState extends ConteoState {
  final String scannedValue;
  final String scan;
  UpdateScannedValueState(this.scannedValue, this.scan);
}

class ClearScannedValueState extends ConteoState {}

class ConfigurationLoading extends ConteoState {}

class ConfigurationPickingLoaded extends ConteoState {
  final UserConfigurationModel configurations;

  ConfigurationPickingLoaded(this.configurations);
}

class ConfigurationError extends ConteoState {
  final String error;

  ConfigurationError(this.error);
}

class ChangeLocationIsOkState extends ConteoState {
  final bool isOk;
  ChangeLocationIsOkState(this.isOk);
}

class ChangeIsOkState extends ConteoState {
  final bool isOk;
  ChangeIsOkState(this.isOk);
}

class ChangeQuantitySeparateState extends ConteoState {
  final dynamic quantity;
  ChangeQuantitySeparateState(this.quantity);
}

class ChangeProductOrderIsOkState extends ConteoState {
  final bool isOk;
  ChangeProductOrderIsOkState(this.isOk);
}

class ClearExpandedLocationState extends ConteoState {
  ClearExpandedLocationState();
}

class ShowQuantityState extends ConteoState {
  final bool showQuantity;
  ShowQuantityState(this.showQuantity);
}

//*estado para separar la cantidad
class ChangeQuantitySeparateStateSuccess extends ConteoState {
  final dynamic quantity;
  ChangeQuantitySeparateStateSuccess(this.quantity);
}

class ChangeQuantitySeparateStateError extends ConteoState {
  final String msg;
  ChangeQuantitySeparateStateError(this.msg);
}

class BarcodesProductLoadedState extends ConteoState {
  final List<Barcodes> listOfBarcodes;
  BarcodesProductLoadedState({required this.listOfBarcodes});
}

class GetLotesProductLoading extends ConteoState {}

class GetLotesProductSuccess extends ConteoState {
  final List<LotesProduct> lotesProduct;
  GetLotesProductSuccess(this.lotesProduct);
}

class GetLotesProductFailure extends ConteoState {
  final String error;
  GetLotesProductFailure(this.error);
}

class ChangeLoteIsOkState extends ConteoState {
  final bool isOk;
  ChangeLoteIsOkState(this.isOk);
}

class ShowKeyboardState extends ConteoState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class SearchLoading extends ConteoState {}

class SearchLoteSuccess extends ConteoState {
  final List<LotesProduct> locations;
  SearchLoteSuccess(this.locations);
}

class SearchFailure extends ConteoState {
  final String error;
  SearchFailure(this.error);
}

class CreateLoteProductLoading extends ConteoState {}

class CreateLoteProductSuccess extends ConteoState {}

class CreateLoteProductFailure extends ConteoState {
  final String error;
  CreateLoteProductFailure(this.error);
}

class SendProductConteoLoading extends ConteoState {}

class SendProductConteoSuccess extends ConteoState {
  final ResponseSendProductConteo response;
  SendProductConteoSuccess(this.response);
}

class SendProductConteoFailure extends ConteoState {
  final String error;
  SendProductConteoFailure(this.error);
}

//estado  si el produto ya fue enviado y ya existe en la lista
class ProductAlreadySentState extends ConteoState {
  final CountedLine product;
  final CountedLine productExist;
  ProductAlreadySentState(this.product, this.productExist);
}

class DeleteProductConteoLoading extends ConteoState {}

class DeleteProductConteoSuccess extends ConteoState {}

class DeleteProductConteoFailure extends ConteoState {
  final String error;
  DeleteProductConteoFailure(this.error);
}

class LoadLocationsLoading extends ConteoState {}

class LoadLocationsSuccess extends ConteoState {
  final List<ResultUbicaciones> locations;
  LoadLocationsSuccess(this.locations);
}

class LoadLocationsFailure extends ConteoState {
  final String error;
  LoadLocationsFailure(this.error);
}

class LoadNewProductSuccess extends ConteoState {}

class LoadNewProductFailure extends ConteoState {
  final String error;
  LoadNewProductFailure(this.error);
}

class SearchLocationSuccess extends ConteoState {
  final List<ResultUbicaciones> locations;
  SearchLocationSuccess(this.locations);
}

class SearchProductSuccess extends ConteoState {
  final List<Product> products;
  SearchProductSuccess(this.products);
}

class GetProductsLoadingBD extends ConteoState {}

class GetProductsSuccessBD extends ConteoState {
  final List<Product> products;
  GetProductsSuccessBD(this.products);
}

class GetProductsFailure extends ConteoState {
  final String error;
  GetProductsFailure(this.error);
}

class UpdateProductLoadingEvent extends ConteoState {}

class ResetValuesState extends ConteoState {}

class ResetValuesLoadingState extends ConteoState {}

class OrderConteosByStateSuccess extends ConteoState {
  final List<DatumConteo> conteos;
  OrderConteosByStateSuccess(this.conteos);
}

class ViewProductImageLoading extends ConteoState {}

class ViewProductImageSuccess extends ConteoState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends ConteoState {
  final String error;
  ViewProductImageFailure(this.error);
}
