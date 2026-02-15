part of 'devoluciones_bloc.dart';

@immutable
sealed class DevolucionesState {}

final class DevolucionesInitial extends DevolucionesState {}

//*estado para actualizar el valor escaneado

class UpdateScannedValueState extends DevolucionesState {
  final String scannedValue;
  final String scan;

  UpdateScannedValueState(this.scannedValue, this.scan);
}

class ClearScannedValueState extends DevolucionesState {}

class GetProductLoading extends DevolucionesState {}

class GetProductsLoading extends DevolucionesState {}

class GetProductsSuccess extends DevolucionesState {
  final List<Product> products;
  GetProductsSuccess(this.products);
}

class GetProductsFailure extends DevolucionesState {
  final String error;
  GetProductsFailure(this.error);
}

class GetProductSuccess extends DevolucionesState {
  final Product product;
  final bool isLoading;
  GetProductSuccess(this.product, this.isLoading);
}

class GetProductFailure extends DevolucionesState {
  final String error;
  GetProductFailure(this.error);
}

class GetProductExists extends DevolucionesState {
  final ProductDevolucion product;
  final List<ProductDevolucion> productosRelacionados;
  GetProductExists(this.product, this.productosRelacionados);
}

class AddProductSuccess extends DevolucionesState {
  final ProductDevolucion product;
  AddProductSuccess(this.product);
}

class AddProductFailure extends DevolucionesState {
  final String error;
  AddProductFailure(this.error);
}

class RemoveProductSuccess extends DevolucionesState {}

class RemoveProductFailure extends DevolucionesState {
  final String error;
  RemoveProductFailure(this.error);
}

class SetQuantityState extends DevolucionesState {}

class ShowQuantityState extends DevolucionesState {
  final bool showQuantity;
  ShowQuantityState(this.showQuantity);
}

class LoadCurrentProductState extends DevolucionesState {
  final Product product;
  LoadCurrentProductState(this.product);
}

class UpdateProductInfoState extends DevolucionesState {}

class LoadTercerosFailure extends DevolucionesState {
  final String error;
  LoadTercerosFailure(this.error);
}

class LoadTercerosSuccess extends DevolucionesState {
  final List<Terceros> terceros;
  LoadTercerosSuccess(this.terceros);
}

class ShowKeyboardState extends DevolucionesState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class SelectTerceroState extends DevolucionesState {
  final Terceros tercero;
  SelectTerceroState(this.tercero);
}

class SearchLoading extends DevolucionesState {}

class SearchFailure extends DevolucionesState {
  final String error;
  SearchFailure(this.error);
}

class SearchProductSuccess extends DevolucionesState {
  final List<Product> products;
  SearchProductSuccess(this.products);
}

class SearchTerceroSuccess extends DevolucionesState {
  final List<Terceros> terceros;
  SearchTerceroSuccess(this.terceros);
}

class FilterTercerosLoading extends DevolucionesState {}

class FilterTercerosSuccess extends DevolucionesState {
  final List<Terceros> tercerosFilters;
  FilterTercerosSuccess(this.tercerosFilters);
}

class FilterTercerosFailure extends DevolucionesState {
  final String error;
  FilterTercerosFailure(this.error);
}

class LoadingLocationsState extends DevolucionesState {}

class LoadLocationsSuccessState extends DevolucionesState {
  final List<ResultUbicaciones> locations;
  LoadLocationsSuccessState(this.locations);
}

class LoadLocationsFailureState extends DevolucionesState {
  final String error;
  LoadLocationsFailureState(this.error);
}

class SearchLocationSuccess extends DevolucionesState {
  final List<ResultUbicaciones> locations;
  SearchLocationSuccess(this.locations);
}

class FilterLocationsLoading extends DevolucionesState {}

class FilterLocationsSuccess extends DevolucionesState {
  final List<ResultUbicaciones> locationsFilters;
  FilterLocationsSuccess(this.locationsFilters);
}

class FilterLocationsFailure extends DevolucionesState {
  final String error;
  FilterLocationsFailure(this.error);
}

class SelectLocationState extends DevolucionesState {
  final ResultUbicaciones location;
  SelectLocationState(this.location);
}

class SelectecLoteState extends DevolucionesState {
  final LotesProduct lote;
  SelectecLoteState(this.lote);
}

class SearchLoteSuccess extends DevolucionesState {
  final List<LotesProduct> locations;
  SearchLoteSuccess(this.locations);
}

class CreateLoteProductLoading extends DevolucionesState {}

class CreateLoteProductSuccess extends DevolucionesState {
  final LotesProduct loteProduct;
  CreateLoteProductSuccess(this.loteProduct);
}

class CreateLoteProductFailure extends DevolucionesState {
  final String error;
  CreateLoteProductFailure(this.error);
}

class GetLotesProductLoading extends DevolucionesState {}

class GetLotesProductSuccess extends DevolucionesState {
  final List<LotesProduct> lotesProduct;
  GetLotesProductSuccess(this.lotesProduct);
}

class GetLotesProductFailure extends DevolucionesState {
  final String error;
  GetLotesProductFailure(this.error);
}

class ClearValueState extends DevolucionesState {}

class SendDevolucionLoading extends DevolucionesState {}

class SendDevolucionSuccess extends DevolucionesState {
  final ResponseDevolucion response;
  SendDevolucionSuccess(this.response);
}

class SendDevolucionFailure extends DevolucionesState {
  final String error;
  SendDevolucionFailure(this.error);
}

class ChangeStateIsDialogVisibleState extends DevolucionesState {
  final bool isDialogVisible;
  ChangeStateIsDialogVisibleState(this.isDialogVisible);
}

class ConfigurationDevLoaded extends DevolucionesState {
  final UserConfigurationModel configurations;

  ConfigurationDevLoaded(this.configurations);
}

class ConfigurationError extends DevolucionesState {
  final String error;

  ConfigurationError(this.error);
}

//estado para decir que el dispositivo no esta autorizado
final class DeviceNotAuthorized extends DevolucionesState {}

class FetchAllBarcodesSuccess extends DevolucionesState {
  final List<BarcodeInventario> allBarcodes;
  FetchAllBarcodesSuccess(this.allBarcodes);
}

class FetchAllBarcodesFailure extends DevolucionesState {
  final String error;
  FetchAllBarcodesFailure(this.error);
}
