part of 'inventario_bloc.dart';

@immutable
sealed class InventarioState {}

final class InventarioInitial extends InventarioState {}

class LoadLocationsLoading extends InventarioState {}

class LoadLocationsSuccess extends InventarioState {
  final List<ResultUbicaciones> locations;
  LoadLocationsSuccess(this.locations);
}

class LoadLocationsFailure extends InventarioState {
  final String error;
  LoadLocationsFailure(this.error);
}

//estados para buscar una ubicacion

class SearchLoading extends InventarioState {}

class SearchLocationSuccess extends InventarioState {
  final List<ResultUbicaciones> locations;
  SearchLocationSuccess(this.locations);
}

class SearchLoteSuccess extends InventarioState {
  final List<LotesProduct> locations;
  SearchLoteSuccess(this.locations);
}

class SearchProductSuccess extends InventarioState {
  final List<Product> products;
  SearchProductSuccess(this.products);
}

class SearchFailure extends InventarioState {
  final String error;
  SearchFailure(this.error);
}

class ShowKeyboardState extends InventarioState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class ClearScannedValueState extends InventarioState {}

class UpdateScannedValueState extends InventarioState {
  final String scannedValue;
  final String scan;
  UpdateScannedValueState(this.scannedValue, this.scan);
}

//*estado para validar campos
class ValidateFieldsStateSuccess extends InventarioState {
  final bool isOk;
  ValidateFieldsStateSuccess(this.isOk);
}

class ValidateFieldsStateError extends InventarioState {
  final String msg;
  ValidateFieldsStateError(this.msg);
}

class ChangeLocationIsOkState extends InventarioState {
  final bool isOk;
  ChangeLocationIsOkState(this.isOk);
}

class GetProductsLoadingInventory extends InventarioState {}

class GetProductsSuccess extends InventarioState {
  final List<Product> products;
  GetProductsSuccess(this.products);
}

class GetProductsLoadingBD extends InventarioState {}

class GetProductsSuccessBD extends InventarioState {
  final List<Product> products;
  GetProductsSuccessBD(this.products);
}

class GetProductsSuccessByLocation extends InventarioState {
  final List<Product> products;
  GetProductsSuccessByLocation(this.products);
}

class GetProductsFailureInventory extends InventarioState {
  final String error;
  GetProductsFailureInventory(this.error);
}

class GetProductsFailureByLocation extends InventarioState {
  final String error;
  GetProductsFailureByLocation(this.error);
}

class ChangeProductIsOkState extends InventarioState {
  final bool isOk;
  ChangeProductIsOkState(this.isOk);
}

class CleanFieldsState extends InventarioState {}

class GetLotesProductLoading extends InventarioState {}

class GetLotesProductSuccess extends InventarioState {
  final List<LotesProduct> lotesProduct;
  GetLotesProductSuccess(this.lotesProduct);
}

class GetLotesProductFailure extends InventarioState {
  final String error;
  GetLotesProductFailure(this.error);
}

class ChangeLoteIsOkState extends InventarioState {
  final bool isOk;
  ChangeLoteIsOkState(this.isOk);
}

class ChangeQuantityIsOkState extends InventarioState {
  final bool isOk;
  ChangeQuantityIsOkState(this.isOk);
}

class ShowQuantityState extends InventarioState {
  final bool showQuantity;
  ShowQuantityState(this.showQuantity);
}

class BarcodesProductLoadedState extends InventarioState {
  final List<BarcodeInventario> listOfBarcodes;
  BarcodesProductLoadedState({required this.listOfBarcodes});
}

//*estado para separar la cantidad
class ChangeQuantitySeparateStateSuccess extends InventarioState {
  final int quantity;
  ChangeQuantitySeparateStateSuccess(this.quantity);
}

class ChangeQuantitySeparateStateError extends InventarioState {
  final String msg;
  ChangeQuantitySeparateStateError(this.msg);
}

class SendProductLoading extends InventarioState {}

class SendProductSuccess extends InventarioState {}

class SendProductFailure extends InventarioState {
  final String error;
  SendProductFailure(this.error);
}

class CreateLoteProductLoading extends InventarioState {}

class CreateLoteProductSuccess extends InventarioState {}

class CreateLoteProductFailure extends InventarioState {
  final String error;
  CreateLoteProductFailure(this.error);
}

class ConfigurationLoadedInventory extends InventarioState {
  final UserConfigurationModel configurations;

  ConfigurationLoadedInventory(this.configurations);
}

class ConfigurationErrorInventory extends InventarioState {
  final String error;

  ConfigurationErrorInventory(this.error);
}

class FilterUbicacionesLoading extends InventarioState {}

class FilterUbicacionesFailure extends InventarioState {
  final String error;
  FilterUbicacionesFailure(this.error);
}

class FilterUbicacionesSuccess extends InventarioState {
  final List<ResultUbicaciones> locations;
  FilterUbicacionesSuccess(this.locations);
}

class FetchAllBarcodesSuccess extends InventarioState {
  final List<BarcodeInventario> allBarcodes;
  FetchAllBarcodesSuccess(this.allBarcodes);
}

class FetchAllBarcodesFailure extends InventarioState {
  final String error;
  FetchAllBarcodesFailure(this.error);
}
