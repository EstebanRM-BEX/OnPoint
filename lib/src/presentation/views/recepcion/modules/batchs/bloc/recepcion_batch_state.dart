part of 'recepcion_batch_bloc.dart';

@immutable
sealed class RecepcionBatchState {}

final class RecepcionBatchInitial extends RecepcionBatchState {}

class FetchRecepcionBatchLoading extends RecepcionBatchState {}

class NeedUpdateVersionState extends RecepcionBatchState {}

class FetchRecepcionBatchFailure extends RecepcionBatchState {
  final String error;
  FetchRecepcionBatchFailure(this.error);
}

class FetchRecepcionBatchSuccess extends RecepcionBatchState {
  final List<ReceptionBatch> listReceptionBatch;

  FetchRecepcionBatchSuccess({required this.listReceptionBatch});
}

class FetchRecepcionBatchLoadingFromBD extends RecepcionBatchState {}

class FetchRecepcionBatchFailureFromBD extends RecepcionBatchState {
  final String error;
  FetchRecepcionBatchFailureFromBD(this.error);
}

class FetchRecepcionBatchSuccessFromBD extends RecepcionBatchState {
  final List<ReceptionBatch> listReceptionBatch;

  FetchRecepcionBatchSuccessFromBD({required this.listReceptionBatch});
}

class ShowKeyboardState extends RecepcionBatchState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class SearchOrdenCompraSuccess extends RecepcionBatchState {
  final List<ReceptionBatch> ordenesCompra;
  SearchOrdenCompraSuccess(this.ordenesCompra);
}

class SearchOrdenCompraFailure extends RecepcionBatchState {
  final String error;
  SearchOrdenCompraFailure(this.error);
}

///metodo para asignar un usuario a una orden de compra
class AssignUserToOrderLoading extends RecepcionBatchState {}

class AssignUserToOrderSuccess extends RecepcionBatchState {
  final ReceptionBatch ordenCompra;
  AssignUserToOrderSuccess(this.ordenCompra);
}

class AssignUserToOrderFailure extends RecepcionBatchState {
  final String error;
  AssignUserToOrderFailure(this.error);
}

class StartOrStopTimeOrderSuccess extends RecepcionBatchState {
  final String isStarted;
  StartOrStopTimeOrderSuccess(this.isStarted);
}

class StartOrStopTimeOrderFailure extends RecepcionBatchState {
  final String error;
  StartOrStopTimeOrderFailure(this.error);
}

//metodo para obtener los productos de una entrada
class GetProductsToEntradaLoading extends RecepcionBatchState {}

class GetProductsToEntradaSuccess extends RecepcionBatchState {
  final List<LineasRecepcionBatch> productos;
  GetProductsToEntradaSuccess(this.productos);
}

class GetProductsToEntradaFailure extends RecepcionBatchState {
  final String error;
  GetProductsToEntradaFailure(this.error);
}

class CurrentOrdenesCompraState extends RecepcionBatchState {
  final ReceptionBatch ordenCompra;
  CurrentOrdenesCompraState(this.ordenCompra);
}

class ValidateFieldsOrderState extends RecepcionBatchState {
  final bool isOk;
  ValidateFieldsOrderState({required this.isOk});
}

class ChangeQuantitySeparateState extends RecepcionBatchState {
  final dynamic quantity;
  ChangeQuantitySeparateState(this.quantity);
}

class ChangeQuantitySeparateErrorOrder extends RecepcionBatchState {
  final String error;
  ChangeQuantitySeparateErrorOrder(this.error);
}

class ChangeProductOrderIsOkState extends RecepcionBatchState {
  final bool isOk;
  ChangeProductOrderIsOkState(this.isOk);
}

class ChangeIsOkState extends RecepcionBatchState {
  final bool isOk;
  ChangeIsOkState(this.isOk);
}

class ClearScannedValueOrderState extends RecepcionBatchState {}

class ChangeLocationDestIsOkState extends RecepcionBatchState {
  final bool isOk;
  ChangeLocationDestIsOkState(this.isOk);
}

class UpdateScannedValueOrderState extends RecepcionBatchState {
  final String scannedValue;
  final String scan;
  UpdateScannedValueOrderState(this.scannedValue, this.scan);
}

class ShowQuantityOrderState extends RecepcionBatchState {
  final bool showQuantity;
  ShowQuantityOrderState(this.showQuantity);
}

//*estados para cargar las novedades
class NovedadesOrderLoadedState extends RecepcionBatchState {
  final List<Novedad> listOfNovedades;
  NovedadesOrderLoadedState({required this.listOfNovedades});
}

class NovedadesOrderLoadingState extends RecepcionBatchState {}

class NovedadesOrderErrorState extends RecepcionBatchState {
  final String message;
  NovedadesOrderErrorState(this.message);
}

//metodo para cargar la informacion del producto actual
class FetchPorductOrderLoading extends RecepcionBatchState {}

class FetchPorductOrderSuccess extends RecepcionBatchState {
  final LineasRecepcionBatch producto;
  FetchPorductOrderSuccess(this.producto);
}

class FetchPorductOrderFailure extends RecepcionBatchState {
  final String error;
  FetchPorductOrderFailure(this.error);
}

class GetLotesProductLoading extends RecepcionBatchState {}

class GetLotesProductSuccess extends RecepcionBatchState {
  final List<LotesProduct> lotesProduct;
  GetLotesProductSuccess(this.lotesProduct);
}

class GetLotesProductFailure extends RecepcionBatchState {
  final String error;
  GetLotesProductFailure(this.error);
}

class FilterUbicacionesLoading extends RecepcionBatchState {}

class FilterUbicacionesFailure extends RecepcionBatchState {
  final String error;
  FilterUbicacionesFailure(this.error);
}

class FilterUbicacionesSuccess extends RecepcionBatchState {
  final List<ResultUbicaciones> locations;
  FilterUbicacionesSuccess(this.locations);
}

class SearchLoading extends RecepcionBatchState {}

class SearchFailure extends RecepcionBatchState {
  final String error;
  SearchFailure(this.error);
}

class SearchLocationSuccess extends RecepcionBatchState {
  final List<ResultUbicaciones> locations;
  SearchLocationSuccess(this.locations);
}

class SearchLoteSuccess extends RecepcionBatchState {
  final List<LotesProduct> locations;
  SearchLoteSuccess(this.locations);
}

class LoadLocationsLoading extends RecepcionBatchState {}

class LoadLocationsSuccess extends RecepcionBatchState {
  final List<ResultUbicaciones> locations;
  LoadLocationsSuccess(this.locations);
}

class LoadLocationsFailure extends RecepcionBatchState {
  final String error;
  LoadLocationsFailure(this.error);
}

class ConfigurationLoadedOrder extends RecepcionBatchState {
  final UserConfigurationModel configurations;

  ConfigurationLoadedOrder(this.configurations);
}

class ConfigurationErrorOrder extends RecepcionBatchState {
  final String error;

  ConfigurationErrorOrder(this.error);
}

class SendProductToOrderLoading extends RecepcionBatchState {}

class SendProductToOrderSuccess extends RecepcionBatchState {}

class SendProductToOrderFailure extends RecepcionBatchState {
  final String error;
  SendProductToOrderFailure(this.error);
}

class FinalizarRecepcionProductoLoading extends RecepcionBatchState {}

class FinalizarRecepcionProductoSuccess extends RecepcionBatchState {}

class FinalizarRecepcionProductoFailure extends RecepcionBatchState {
  final String error;
  FinalizarRecepcionProductoFailure(this.error);
}

class FinalizarRecepcionProductoSplitLoading extends RecepcionBatchState {}

class FinalizarRecepcionProductoSplitSuccess extends RecepcionBatchState {}

class FinalizarRecepcionProductoSplitFailure extends RecepcionBatchState {
  final String error;
  FinalizarRecepcionProductoSplitFailure(this.error);
}

class CreateLoteProductLoading extends RecepcionBatchState {}

class CreateLoteProductSuccess extends RecepcionBatchState {}

class CreateLoteProductFailure extends RecepcionBatchState {
  final String error;
  CreateLoteProductFailure(this.error);
}

class ChangeLoteOrderIsOkState extends RecepcionBatchState {
  final bool isOk;
  ChangeLoteOrderIsOkState(this.isOk);
}

//estado para decir que el dispositivo no esta autorizado
final class DeviceNotAuthorized extends RecepcionBatchState {}

class ViewProductImageLoading extends RecepcionBatchState {}

class ViewProductImageSuccess extends RecepcionBatchState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends RecepcionBatchState {
  final String error;
  ViewProductImageFailure(this.error);
}
