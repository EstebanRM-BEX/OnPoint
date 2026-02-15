part of 'recepcion_bloc.dart';

@immutable
sealed class RecepcionState {}

final class RecepcionInitial extends RecepcionState {}

//estados para obtener todas las orndes de compras
class FetchOrdenesCompraLoading extends RecepcionState {}

class NeedUpdateVersionState extends RecepcionState {}

class FetchOrdenesCompraSuccess extends RecepcionState {
  final List<ResultEntrada> ordenesCompra;
  FetchOrdenesCompraSuccess(this.ordenesCompra);
}

class FetchOrdenesCompraFailure extends RecepcionState {
  final String error;
  FetchOrdenesCompraFailure(this.error);
}

class FetchDevolucionesLoading extends RecepcionState {}

class FetchDevolucionesSuccess extends RecepcionState {
  final List<ResultEntrada> ordenesCompra;
  FetchDevolucionesSuccess(this.ordenesCompra);
}

class FetchDevolucionesFailure extends RecepcionState {
  final String error;
  FetchDevolucionesFailure(this.error);
}

class ShowKeyboardState extends RecepcionState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

//estados para buscar una  orden de compra

class SearchOrdenCompraSuccess extends RecepcionState {
  final List<ResultEntrada> ordenesCompra;
  SearchOrdenCompraSuccess(this.ordenesCompra);
}

class SearchDevolucionSuccess extends RecepcionState {
  final List<ResultEntrada> ordenesCompra;
  SearchDevolucionSuccess(this.ordenesCompra);
}

class SearchOrdenCompraFailure extends RecepcionState {
  final String error;
  SearchOrdenCompraFailure(this.error);
}

class SearchDevolucionFailure extends RecepcionState {
  final String error;
  SearchDevolucionFailure(this.error);
}

///metodo para asignar un usuario a una orden de compra
class AssignUserToOrderLoading extends RecepcionState {}

class AssignUserToOrderSuccess extends RecepcionState {
  final ResultEntrada ordenCompra;
  AssignUserToOrderSuccess(this.ordenCompra);
}

class AssignUserToOrderFailure extends RecepcionState {
  final String error;
  AssignUserToOrderFailure(this.error);
}

//metodo para obtener todas las entradas de recepcion dsde la bd
class FetchOrdenesCompraOfBdLoading extends RecepcionState {}

class FetchOrdenesCompraOfBdSuccess extends RecepcionState {
  final List<ResultEntrada> ordenesCompra;
  FetchOrdenesCompraOfBdSuccess(this.ordenesCompra);
}

class FetchOrdenesCompraOfBdFailure extends RecepcionState {
  final String error;
  FetchOrdenesCompraOfBdFailure(this.error);
}

//metodo para obtener los productos de una entrada
class GetProductsToEntradaLoading extends RecepcionState {}

class GetProductsToEntradaSuccess extends RecepcionState {
  final List<LineasTransferencia> productos;
  GetProductsToEntradaSuccess(this.productos);
}

class GetProductsToEntradaFailure extends RecepcionState {
  final String error;
  GetProductsToEntradaFailure(this.error);
}

//metodo para cargar la informacion del producto actual
class FetchPorductOrderLoading extends RecepcionState {}

class FetchPorductOrderSuccess extends RecepcionState {
  final LineasTransferencia producto;
  FetchPorductOrderSuccess(this.producto);
}

class FetchPorductOrderFailure extends RecepcionState {
  final String error;
  FetchPorductOrderFailure(this.error);
}

class ValidateFieldsOrderState extends RecepcionState {
  final bool isOk;
  ValidateFieldsOrderState({required this.isOk});
}

class ClearScannedValueOrderState extends RecepcionState {}

class UpdateScannedValueOrderState extends RecepcionState {
  final String scannedValue;
  final String scan;
  UpdateScannedValueOrderState(this.scannedValue, this.scan);
}

class ChangeIsOkState extends RecepcionState {
  final bool isOk;
  ChangeIsOkState(this.isOk);
}

class ChangeProductOrderIsOkState extends RecepcionState {
  final bool isOk;
  ChangeProductOrderIsOkState(this.isOk);
}

class ChangeLoteOrderIsOkState extends RecepcionState {
  final bool isOk;
  ChangeLoteOrderIsOkState(this.isOk);
}

class ConfigurationLoadedOrder extends RecepcionState {
  final UserConfigurationModel configurations;

  ConfigurationLoadedOrder(this.configurations);
}

class ConfigurationErrorOrder extends RecepcionState {
  final String error;

  ConfigurationErrorOrder(this.error);
}

class ChangeQuantitySeparateState extends RecepcionState {
  final dynamic quantity;
  ChangeQuantitySeparateState(this.quantity);
}

class ShowQuantityOrderState extends RecepcionState {
  final bool showQuantity;
  ShowQuantityOrderState(this.showQuantity);
}

class ChangeQuantitySeparateOrder extends RecepcionState {
  final dynamic quantity;
  ChangeQuantitySeparateOrder(this.quantity);
}

class ChangeQuantitySeparateErrorOrder extends RecepcionState {
  final String error;
  ChangeQuantitySeparateErrorOrder(this.error);
}

//*estados para cargar las novedades
class NovedadesOrderLoadedState extends RecepcionState {
  final List<Novedad> listOfNovedades;
  NovedadesOrderLoadedState({required this.listOfNovedades});
}

class NovedadesOrderLoadingState extends RecepcionState {}

class NovedadesOrderErrorState extends RecepcionState {
  final String message;
  NovedadesOrderErrorState(this.message);
}

class FinalizarRecepcionProductoLoading extends RecepcionState {}

class FinalizarRecepcionProductoSuccess extends RecepcionState {}

class FinalizarRecepcionProductoFailure extends RecepcionState {
  final String error;
  FinalizarRecepcionProductoFailure(this.error);
}

class FinalizarRecepcionProductoSplitLoading extends RecepcionState {}

class FinalizarRecepcionProductoSplitSuccess extends RecepcionState {}

class FinalizarRecepcionProductoSplitFailure extends RecepcionState {
  final String error;
  FinalizarRecepcionProductoSplitFailure(this.error);
}

class GetLotesProductLoading extends RecepcionState {}

class GetLotesProductSuccess extends RecepcionState {
  final List<LotesProduct> lotesProduct;
  GetLotesProductSuccess(this.lotesProduct);
}

class GetLotesProductFailure extends RecepcionState {
  final String error;
  GetLotesProductFailure(this.error);
}

class SendProductToOrderLoading extends RecepcionState {}

class SendProductToOrderSuccess extends RecepcionState {}

class GetTemperatureProduct extends RecepcionState {
  final int moveLineId;
  GetTemperatureProduct({required this.moveLineId});
}

class SendProductToOrderFailure extends RecepcionState {
  final String error;
  SendProductToOrderFailure(this.error);
}

class CreateLoteProductLoading extends RecepcionState {}

class CreateLoteProductSuccess extends RecepcionState {}

class CreateLoteProductFailure extends RecepcionState {
  final String error;
  CreateLoteProductFailure(this.error);
}

class CurrentOrdenesCompraState extends RecepcionState {
  final ResultEntrada ordenCompra;
  CurrentOrdenesCompraState(this.ordenCompra);
}

class StartOrStopTimeOrderSuccess extends RecepcionState {
  final String isStarted;
  StartOrStopTimeOrderSuccess(this.isStarted);
}

class StartOrStopTimeOrderFailure extends RecepcionState {
  final String error;
  StartOrStopTimeOrderFailure(this.error);
}

class CreateBackOrderOrNotLoading extends RecepcionState {}

class CreateBackOrderOrNotSuccess extends RecepcionState {
  final bool isBackorder;
  final String message;
  CreateBackOrderOrNotSuccess(this.isBackorder, this.message);
}

class CreateBackOrderOrNotFailure extends RecepcionState {
  final String error;
  CreateBackOrderOrNotFailure(this.error);
}

class SearchLoading extends RecepcionState {}

class SearchFailure extends RecepcionState {
  final String error;
  SearchFailure(this.error);
}

class SearchLoteSuccess extends RecepcionState {
  final List<LotesProduct> locations;
  SearchLoteSuccess(this.locations);
}

class LoadLocationsLoading extends RecepcionState {}

class LoadLocationsSuccess extends RecepcionState {
  final List<ResultUbicaciones> locations;
  LoadLocationsSuccess(this.locations);
}

class LoadLocationsFailure extends RecepcionState {
  final String error;
  LoadLocationsFailure(this.error);
}

class SearchLocationSuccess extends RecepcionState {
  final List<ResultUbicaciones> locations;
  SearchLocationSuccess(this.locations);
}

class ChangeLocationDestIsOkState extends RecepcionState {
  final bool isOk;
  ChangeLocationDestIsOkState(this.isOk);
}

class FilterReceptionByTypeLoading extends RecepcionState {}

class FilterReceptionByTypeSuccess extends RecepcionState {
  final List<ResultEntrada> receptions;
  FilterReceptionByTypeSuccess(this.receptions);
}

class FilterReceptionByTypeFailure extends RecepcionState {
  final String error;
  FilterReceptionByTypeFailure(this.error);
}

class FilterUbicacionesLoading extends RecepcionState {}

class FilterUbicacionesFailure extends RecepcionState {
  final String error;
  FilterUbicacionesFailure(this.error);
}

class FilterUbicacionesSuccess extends RecepcionState {
  final List<ResultUbicaciones> locations;
  FilterUbicacionesSuccess(this.locations);
}

class SendTemperatureSuccess extends RecepcionState {
  final String message;
  SendTemperatureSuccess(this.message);
}

class SendTemperatureLoading extends RecepcionState {}

class GetTemperatureLoading extends RecepcionState {}

class SendTemperatureFailure extends RecepcionState {
  final String error;
  SendTemperatureFailure(this.error);
}

class GetTemperatureFailure extends RecepcionState {
  final String error;
  GetTemperatureFailure(this.error);
}

class GetTemperatureSuccess extends RecepcionState {
  final TemperatureIa temperature;
  GetTemperatureSuccess(this.temperature);
}

//todo devoluciones
class FetchDevolucionesLoadingDB extends RecepcionState {}

class FetchDevolucionesSuccessDB extends RecepcionState {
  final List<ResultEntrada> ordenesCompra;
  FetchDevolucionesSuccessDB(this.ordenesCompra);
}

class FetchDevolucionesFailureDB extends RecepcionState {
  final String error;
  FetchDevolucionesFailureDB(this.error);
}

class DelectedProductWmsLoading extends RecepcionState {}

class DelectedProductWmsSuccess extends RecepcionState {
  final String message;
  DelectedProductWmsSuccess(this.message);
}

class DelectedProductWmsFailure extends RecepcionState {
  final String error;
  DelectedProductWmsFailure(this.error);
}

class SendImageNovedadLoading extends RecepcionState {}

class SendImageNovedadSuccess extends RecepcionState {
  final ImageSendNovedad response;
  SendImageNovedadSuccess(this.response);
}

class SendImageNovedadFailure extends RecepcionState {
  final String error;
  SendImageNovedadFailure(this.error);
}

//estado para decir que el dispositivo no esta autorizado
final class DeviceNotAuthorized extends RecepcionState {}

class ProductExpansionToggled extends RecepcionState {
  final bool isExpanded;

  ProductExpansionToggled(this.isExpanded);
}

class ViewProductImageLoading extends RecepcionState {}

class ViewProductImageSuccess extends RecepcionState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends RecepcionState {
  final String error;
  ViewProductImageFailure(this.error);
}
