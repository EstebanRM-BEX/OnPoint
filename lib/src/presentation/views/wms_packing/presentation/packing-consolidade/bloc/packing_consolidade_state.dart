part of 'packing_consolidade_bloc.dart';

@immutable
sealed class PackingConsolidateState {}

final class PackingConsolidateInitial extends PackingConsolidateState {}

//*estasos para cargar la configuracion del usuario

class ConfigurationLoadingPack extends PackingConsolidateState {}

class ConfigurationLoadedPack extends PackingConsolidateState {
  final UserConfigurationModel configurations;

  ConfigurationLoadedPack(this.configurations);
}

class ConfigurationErrorPack extends PackingConsolidateState {
  final String error;

  ConfigurationErrorPack(this.error);
}

class PackingConsolidateLoading extends PackingConsolidateState {}

class PackingConsolidateLoaded extends PackingConsolidateState {
  final List<BatchPackingModel> listOfBatchs;

  PackingConsolidateLoaded({required this.listOfBatchs});
}

//error al cargar los batchs
class PackingConsolidateError extends PackingConsolidateState {
  final String error;

  PackingConsolidateError(this.error);
}

class NeedUpdateVersionState extends PackingConsolidateState {}

class ShowKeyboardState extends PackingConsolidateState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class ClearScannedValuePackState extends PackingConsolidateState {}

class UpdateScannedValuePackState extends PackingConsolidateState {
  final String scannedValue;
  final String scan;
  UpdateScannedValuePackState(this.scannedValue, this.scan);
}

class BatchsPackingLoadingState extends PackingConsolidateState {}

final class WmsPackingLoadedBD extends PackingConsolidateState {}

//*tiempo de separacion
class TimeSeparatePackSuccess extends PackingConsolidateState {
  final String time;
  TimeSeparatePackSuccess(this.time);
}

class TimeEndSeparatePackSuccess extends PackingConsolidateState {
  final String time;
  TimeEndSeparatePackSuccess(this.time);
}

class TimeSeparatePackError extends PackingConsolidateState {
  final String msg;
  TimeSeparatePackError(this.msg);
}

class LoadAllPedidosFromBatchLoaded extends PackingConsolidateState {
  final List<PedidoPacking> listOfPedidos;

  LoadAllPedidosFromBatchLoaded({required this.listOfPedidos});
}

class LoadDocOriginsState extends PackingConsolidateState {
  final List<Origin> listOfOrigins;
  LoadDocOriginsState({required this.listOfOrigins});
}

class ShowDetailState extends PackingConsolidateState {
  final bool show;
  ShowDetailState(this.show);
}

class LoadingLoadAllProductsFromPedido extends PackingConsolidateState {}

class LoadAllProductsFromPedidoLoaded extends PackingConsolidateState {
  final List<ProductoPedido> listOfProducts;

  LoadAllProductsFromPedidoLoaded({required this.listOfProducts});
}

class ErrorLoadAllProductsFromPedido extends PackingConsolidateState {
  final String error;

  ErrorLoadAllProductsFromPedido(this.error);
}

class SearPedidoPackingErrorState extends PackingConsolidateState {
  final String error;

  SearPedidoPackingErrorState(this.error);
}

class SearchPedidoPackingLoadedState extends PackingConsolidateState {
  final List<PedidoPacking> listOfPedidos;

  SearchPedidoPackingLoadedState({required this.listOfPedidos});
}

class ProductInfoLoading extends PackingConsolidateState {}

class ProductInfoLoaded extends PackingConsolidateState {}

class ProductInfoError extends PackingConsolidateState {
  final String error;

  ProductInfoError(this.error);
}

class ChangeLocationPackingIsOkState extends PackingConsolidateState {
  final bool isOk;
  ChangeLocationPackingIsOkState(this.isOk);
}

class ChangeStickerState extends PackingConsolidateState {
  final bool isSticker;
  ChangeStickerState(this.isSticker);
}

class UnSelectProductPackingErrorState extends PackingConsolidateState {
  final String error;

  UnSelectProductPackingErrorState(this.error);
}

class SelectProductPackingErrorState extends PackingConsolidateState {
  final String error;

  SelectProductPackingErrorState(this.error);
}

class SelectProductPackingLoadedState extends PackingConsolidateState {
  final List<ProductoPedido> listOfProductsForPacking;

  SelectProductPackingLoadedState({required this.listOfProductsForPacking});
}

class UnSelectProductPackingLoadedState extends PackingConsolidateState {
  final List<ProductoPedido> listOfProductsForPacking;

  UnSelectProductPackingLoadedState({required this.listOfProductsForPacking});
}

class DeleteProductFromTemporaryPackageLoading
    extends PackingConsolidateState {}

class DeleteProductFromTemporaryPackageError extends PackingConsolidateState {
  final String message;
  DeleteProductFromTemporaryPackageError(this.message);
}

class DeleteProductFromTemporaryPackageOkState
    extends PackingConsolidateState {}

class SetPickingPackingOkState extends PackingConsolidateState {}

class SplitProductError extends PackingConsolidateState {
  final String message;
  SplitProductError(this.message);
}

class SetPickingPackingErrorState extends PackingConsolidateState {
  final String message;
  SetPickingPackingErrorState(this.message);
}

class SetPickingPackingLoadingState extends PackingConsolidateState {}

class SetPackingsErrorState extends PackingConsolidateState {
  final String message;
  SetPackingsErrorState(this.message);
}

class SetPackingsOkState extends PackingConsolidateState {
  final String message;
  SetPackingsOkState(this.message);
}

class SetPackingsLoadingState extends PackingConsolidateState {}

class ValidateFieldsPackingState extends PackingConsolidateState {
  final bool isOk;
  ValidateFieldsPackingState(this.isOk);
}

class GetTemperatureLoading extends PackingConsolidateState {}

class GetTemperatureSuccess extends PackingConsolidateState {
  final TemperatureIa temperature;
  GetTemperatureSuccess(this.temperature);
}

class GetTemperatureFailure extends PackingConsolidateState {
  final String error;
  GetTemperatureFailure(this.error);
}

class ChangeQuantitySeparateState extends PackingConsolidateState {
  final dynamic quantity;
  ChangeQuantitySeparateState(this.quantity);
}

class ChangeProductPackingIsOkState extends PackingConsolidateState {
  final bool isOk;
  ChangeProductPackingIsOkState(this.isOk);
}

class SendImageNovedadLoading extends PackingConsolidateState {}

class SendImageNovedadSuccess extends PackingConsolidateState {
  final dynamic cantidad;
  final ImageSendNovedad response;
  SendImageNovedadSuccess(this.response, this.cantidad);
}

class SendImageNovedadFailure extends PackingConsolidateState {
  final String error;
  SendImageNovedadFailure(this.error);
}

class ShowQuantityPackState extends PackingConsolidateState {
  final bool showQuantity;
  ShowQuantityPackState(this.showQuantity);
}

//*estados para cargar las novedades
class NovedadesPackingLoadedState extends PackingConsolidateState {
  final List<Novedad> listOfNovedades;
  NovedadesPackingLoadedState({required this.listOfNovedades});
}

class NovedadesPackingLoadingState extends PackingConsolidateState {}

class NovedadesPackingErrorState extends PackingConsolidateState {
  final String message;
  NovedadesPackingErrorState(this.message);
}

class SendTemperatureLoading extends PackingConsolidateState {}

class SendTemperatureFailure extends PackingConsolidateState {
  final String error;
  SendTemperatureFailure(this.error);
}

class SendTemperatureSuccess extends PackingConsolidateState {
  final String message;
  SendTemperatureSuccess(this.message);
}

//*estados para desempacar
class UnPackignSuccess extends PackingConsolidateState {
  final String message;
  UnPackignSuccess(this.message);
}

class UnPackignError extends PackingConsolidateState {
  final String message;
  UnPackignError(this.message);
}

class UnPackingLoading extends PackingConsolidateState {}

class ChangeIsOkState extends PackingConsolidateState {
  final bool isOk;
  ChangeIsOkState(this.isOk);
}

class AssignUserToBatchLoading extends PackingConsolidateState {}

class AssignUserToBatchLoaded extends PackingConsolidateState {
  final int batchId;
  final BatchPackingModel batchPackingModel;
  AssignUserToBatchLoaded(
      {required this.batchId, required this.batchPackingModel});
}

class AssignUserToBatchError extends PackingConsolidateState {
  final String error;
  AssignUserToBatchError(this.error);
}

class ViewProductImageLoading extends PackingConsolidateState {}

class ViewProductImageSuccess extends PackingConsolidateState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends PackingConsolidateState {
  final String error;
  ViewProductImageFailure(this.error);
}
