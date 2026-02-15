part of 'packing_pedido_bloc.dart';

@immutable
sealed class PackingPedidoState {}

final class PackingPedidoInitial extends PackingPedidoState {}

final class FetchProductLoadingState extends PackingPedidoState {}

class FetchProductLoadedState extends PackingPedidoState {}

class FetchProductErrorState extends PackingPedidoState {
  final String error;
  FetchProductErrorState(this.error);
}

class ShowKeyboardState extends PackingPedidoState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

final class WmsPackingPedidoWMSLoading extends PackingPedidoState {}

final class WmsPackingPedidoWMSLoaded extends PackingPedidoState {
  final List<PedidoPackingResult> listOfPedidos;
  WmsPackingPedidoWMSLoaded({required this.listOfPedidos});
}

class NeedUpdateVersionState extends PackingPedidoState {}

final class PackingPedidoError extends PackingPedidoState {
  final String error;
  PackingPedidoError(this.error);
}

class PackingPedidoLoadingState extends PackingPedidoState {}

class PackingPedidoLoadedFromDBState extends PackingPedidoState {
  final List<PedidoPackingResult> listOfPedidos;
  PackingPedidoLoadedFromDBState({required this.listOfPedidos});
}

class AssignUserToPedidoLoading extends PackingPedidoState {}

class AssignUserToPedidoLoaded extends PackingPedidoState {
  final int id;
  AssignUserToPedidoLoaded({required this.id});
}

class AssignUserToPedidoError extends PackingPedidoState {
  final String error;
  AssignUserToPedidoError(this.error);
}

class StartOrStopTimeTransferSuccess extends PackingPedidoState {
  final String isStarted;
  StartOrStopTimeTransferSuccess(this.isStarted);
}

class StartOrStopTimeTransferFailure extends PackingPedidoState {
  final String error;
  StartOrStopTimeTransferFailure(this.error);
}

class ConfigurationLoading extends PackingPedidoState {}

class ConfigurationPickingLoaded extends PackingPedidoState {
  final UserConfigurationModel configurations;

  ConfigurationPickingLoaded(this.configurations);
}

class ConfigurationError extends PackingPedidoState {
  final String error;

  ConfigurationError(this.error);
}

class LoadPedidoAndProductsLoading extends PackingPedidoState {}

class LoadPedidoAndProductsLoaded extends PackingPedidoState {
  final PedidoPackingResult pedidoPackingResult;

  LoadPedidoAndProductsLoaded(this.pedidoPackingResult);
}

class LoadPedidoAndProductsError extends PackingPedidoState {
  final String error;

  LoadPedidoAndProductsError(this.error);
}

class ShowDetailPackState extends PackingPedidoState {
  final bool showViewDetail;
  ShowDetailPackState(this.showViewDetail);
}

class ValidateFieldsPackingState extends PackingPedidoState {
  final bool isOk;
  ValidateFieldsPackingState(this.isOk);
}

//* CAMBIAR VALORES DE VARIABLES

class ChangeLocationPackingIsOkState extends PackingPedidoState {
  final bool isOk;
  ChangeLocationPackingIsOkState(this.isOk);
}

class ChangeIsOkState extends PackingPedidoState {
  final bool isOk;
  ChangeIsOkState(this.isOk);
}

class ChangeProductPackingIsOkState extends PackingPedidoState {
  final bool isOk;
  ChangeProductPackingIsOkState(this.isOk);
}

class UpdateScannedValuePackState extends PackingPedidoState {
  final String scannedValue;
  final String scan;
  UpdateScannedValuePackState(this.scannedValue, this.scan);
}

class ClearScannedValuePackState extends PackingPedidoState {}

class ChangeQuantitySeparateState extends PackingPedidoState {
  final dynamic quantity;
  ChangeQuantitySeparateState(this.quantity);
}

class SendImageNovedadLoading extends PackingPedidoState {}

class SendImageNovedadSuccess extends PackingPedidoState {
  final dynamic cantidad;
  final ImageSendNovedad response;
  SendImageNovedadSuccess(this.response, this.cantidad);
}

class SendImageNovedadFailure extends PackingPedidoState {
  final String error;
  SendImageNovedadFailure(this.error);
}

class SendTemperatureSuccess extends PackingPedidoState {
  final String message;
  SendTemperatureSuccess(this.message);
}

class SendTemperatureLoading extends PackingPedidoState {}

class SendTemperatureFailure extends PackingPedidoState {
  final String error;
  SendTemperatureFailure(this.error);
}

class GetTemperatureLoading extends PackingPedidoState {}

class GetTemperatureSuccess extends PackingPedidoState {
  final TemperatureIa temperature;
  GetTemperatureSuccess(this.temperature);
}

class GetTemperatureFailure extends PackingPedidoState {
  final String error;
  GetTemperatureFailure(this.error);
}

//*estados para cargar las novedades
class NovedadesPackingLoadedState extends PackingPedidoState {
  final List<Novedad> listOfNovedades;
  NovedadesPackingLoadedState({required this.listOfNovedades});
}

class NovedadesPackingLoadingState extends PackingPedidoState {}

class NovedadesPackingErrorState extends PackingPedidoState {
  final String message;
  NovedadesPackingErrorState(this.message);
}

class SetPickingPackingLoadingState extends PackingPedidoState {}

class SetPickingPackingOkState extends PackingPedidoState {}

class SplitProductError extends PackingPedidoState {
  final String message;
  SplitProductError(this.message);
}

class SetPickingPackingErrorState extends PackingPedidoState {
  final String message;
  SetPickingPackingErrorState(this.message);
}

class ShowQuantityPackState extends PackingPedidoState {
  final bool showQuantity;
  ShowQuantityPackState(this.showQuantity);
}

class ChangeStickerState extends PackingPedidoState {
  final bool isSticker;
  ChangeStickerState(this.isSticker);
}

class WmsPackingLoadingState extends PackingPedidoState {}

class WmsPackingErrorState extends PackingPedidoState {
  final String error;
  WmsPackingErrorState(this.error);
}

class WmsPackingSuccessState extends PackingPedidoState {
  final String msg;
  WmsPackingSuccessState(this.msg);
}

class ListOfProductsForPackingState extends PackingPedidoState {
  final List<ProductoPedido> productos;
  ListOfProductsForPackingState(this.productos);
}

//*estados para desempacar
class UnPackignSuccess extends PackingPedidoState {
  final String message;
  UnPackignSuccess(this.message);
}

class UnPackignError extends PackingPedidoState {
  final String message;
  UnPackignError(this.message);
}

class UnPackingLoading extends PackingPedidoState {}

class StartOrStopTimePackSuccess extends PackingPedidoState {
  final String isStarted;
  StartOrStopTimePackSuccess(this.isStarted);
}

class StartOrStopTimePackFailure extends PackingPedidoState {
  final String error;
  StartOrStopTimePackFailure(this.error);
}

class CreateBackOrderOrNotLoading extends PackingPedidoState {}

class CreateBackOrderOrNotSuccess extends PackingPedidoState {
  final bool isBackorder;
  final String msg;
  CreateBackOrderOrNotSuccess(this.isBackorder, this.msg);
}

class CreateBackOrderOrNotFailure extends PackingPedidoState {
  final String error;
  final bool isBackorder;
  CreateBackOrderOrNotFailure(this.error, this.isBackorder);
}

class ValidateConfirmLoading extends PackingPedidoState {}

class ValidateConfirmSuccess extends PackingPedidoState {
  final bool isBackorder;
  final String msg;

  ValidateConfirmSuccess(this.isBackorder, this.msg);
}

class ValidateConfirmFailure extends PackingPedidoState {
  final String error;
  ValidateConfirmFailure(this.error);
}

class DeleteProductFromTemporaryPackageError extends PackingPedidoState {
  final String message;
  DeleteProductFromTemporaryPackageError(this.message);
}

class DeleteProductFromTemporaryPackageOkState extends PackingPedidoState {}

class DeleteProductFromTemporaryPackageLoading extends PackingPedidoState {}

class ViewProductImageLoading extends PackingPedidoState {}

class ViewProductImageSuccess extends PackingPedidoState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends PackingPedidoState {
  final String error;
  ViewProductImageFailure(this.error);
}

// Estado para indicar que la lista de picks se cargó o actualizó (filtro/orden)
class PackingPackSuccess extends PackingPedidoState {
  // Opcional: Puedes pasar la lista aquí para ser más puro en el patrón BLoC
  final List<PedidoPackingResult> picks;

  PackingPackSuccess(this.picks);
  @override
  List<Object> get props => [picks, DateTime.now()];
  // Tip: Agregar DateTime.now() o UniqueKey() en props asegura que
  // Flutter redibuje aunque la lista sea "técnicamente" la misma pero en diferente orden.
}
