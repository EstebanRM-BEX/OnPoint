part of 'wms_packing_bloc.dart';

@immutable
sealed class WmsPackingState {}

final class WmsPackingInitial extends WmsPackingState {}

//*estados para cargar todos los batchs para packing
final class WmsPackingWMSLoading extends WmsPackingState {}

final class WmsPackingLoading extends WmsPackingState {}

final class WmsProductInfoLoading extends WmsPackingState {}

final class WmsProductInfoLoaded extends WmsPackingState {}

final class WmsPackingLoaded extends WmsPackingState {
  final List<BatchPackingModel> listOfBatchs;
  WmsPackingLoaded({required this.listOfBatchs});
}

final class WmsPackingLoadedBD extends WmsPackingState {}

final class WmsPackingError extends WmsPackingState {
  final String error;
  WmsPackingError(this.error);
}

class ChangeProductPackingIsOkState extends WmsPackingState {
  final bool isOk;
  ChangeProductPackingIsOkState(this.isOk);
}

class ChangeIsOkState extends WmsPackingState {
  final bool isOk;
  ChangeIsOkState(this.isOk);
}

class ChangeLocationPackingIsOkState extends WmsPackingState {
  final bool isOk;
  ChangeLocationPackingIsOkState(this.isOk);
}

class BatchsPackingLoadingState extends WmsPackingState {}

class ValidateFieldsPackingState extends WmsPackingState {
  final bool isOk;
  ValidateFieldsPackingState(this.isOk);
}

class ChangeQuantitySeparateState extends WmsPackingState {
  final dynamic quantity;
  ChangeQuantitySeparateState(this.quantity);
}

class ChangeStickerState extends WmsPackingState {
  final bool isSticker;
  ChangeStickerState(this.isSticker);
}

class ShowKeyboardState extends WmsPackingState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class ListOfProductsForPackingState extends WmsPackingState {
  final List<ProductoPedido> productos;
  ListOfProductsForPackingState(this.productos);
}

//estado de carga mientras se hace el packing
class WmsPackingLoadingState extends WmsPackingState {}

class WmsPackingSuccessState extends WmsPackingState {
  final String message;
  WmsPackingSuccessState(this.message);
}

class WmsPackingErrorState extends WmsPackingState {
  final String message;
  WmsPackingErrorState(this.message);
}

//*estados para cargar las novedades
class NovedadesPackingLoadedState extends WmsPackingState {
  final List<Novedad> listOfNovedades;
  NovedadesPackingLoadedState({required this.listOfNovedades});
}

class NovedadesPackingLoadingState extends WmsPackingState {}

class NovedadesPackingErrorState extends WmsPackingState {
  final String message;
  NovedadesPackingErrorState(this.message);
}

//*estasos para cargar la configuracion del usuario

class ConfigurationLoadingPack extends WmsPackingState {}

class ConfigurationLoadedPack extends WmsPackingState {
  final UserConfigurationModel configurations;

  ConfigurationLoadedPack(this.configurations);
}

class ConfigurationErrorPack extends WmsPackingState {
  final String error;

  ConfigurationErrorPack(this.error);
}

//*estados para desempacar
class UnPackignSuccess extends WmsPackingState {
  final String message;
  UnPackignSuccess(this.message);
}

class UnPackignError extends WmsPackingState {
  final String message;
  UnPackignError(this.message);
}

class UnPackingLoading extends WmsPackingState {}

//*estaos para dividir un producto
class SplitProductSuccess extends WmsPackingState {}

class SplitProductError extends WmsPackingState {
  final String message;
  SplitProductError(this.message);
}

class SplitProductLoading extends WmsPackingState {}

class ClearScannedValuePackState extends WmsPackingState {}

class UpdateScannedValuePackState extends WmsPackingState {
  final String scannedValue;
  final String scan;
  UpdateScannedValuePackState(this.scannedValue, this.scan);
}

class ShowQuantityPackState extends WmsPackingState {
  final bool showQuantity;
  ShowQuantityPackState(this.showQuantity);
}

class ShowDetailState extends WmsPackingState {
  final bool show;
  ShowDetailState(this.show);
}

//* metodo que se encarga para realizar el picking del packing

class SetPickingPackingOkState extends WmsPackingState {}

class SetPickingPackingErrorState extends WmsPackingState {
  final String message;
  SetPickingPackingErrorState(this.message);
}

class SetPickingPackingLoadingState extends WmsPackingState {}

//*tiempo de separacion
class TimeSeparatePackSuccess extends WmsPackingState {
  final String time;
  TimeSeparatePackSuccess(this.time);
}

class TimeSeparatePackError extends WmsPackingState {
  final String msg;
  TimeSeparatePackError(this.msg);
}

class SendTemperatureSuccess extends WmsPackingState {
  final String message;
  SendTemperatureSuccess(this.message);
}

class SendTemperatureLoading extends WmsPackingState {}

class SendTemperatureFailure extends WmsPackingState {
  final String error;
  SendTemperatureFailure(this.error);
}

class SendImageNovedadLoading extends WmsPackingState {}

class SendImageNovedadSuccess extends WmsPackingState {
  final dynamic cantidad;
  final ImageSendNovedad response;
  SendImageNovedadSuccess(this.response, this.cantidad);
}

class SendImageNovedadFailure extends WmsPackingState {
  final String error;
  SendImageNovedadFailure(this.error);
}

class GetTemperatureLoading extends WmsPackingState {}

class GetTemperatureSuccess extends WmsPackingState {
  final TemperatureIa temperature;
  GetTemperatureSuccess(this.temperature);
}

class GetTemperatureFailure extends WmsPackingState {
  final String error;
  GetTemperatureFailure(this.error);
}

class LoadDocOriginsState extends WmsPackingState {
  final List<Origin> listOfOrigins;
  LoadDocOriginsState({required this.listOfOrigins});
}

class DeleteProductFromTemporaryPackageLoading extends WmsPackingState {}

class DeleteProductFromTemporaryPackageError extends WmsPackingState {
  final String message;
  DeleteProductFromTemporaryPackageError(this.message);
}

class DeleteProductFromTemporaryPackageOkState extends WmsPackingState {}

class NeedUpdateVersionState extends WmsPackingState {}

class LoadAllPedidosFromBatchLoaded extends WmsPackingState {
  final List<PedidoPacking> listOfPedidos;

  LoadAllPedidosFromBatchLoaded({required this.listOfPedidos});
}

class ViewProductImageLoading extends WmsPackingState {}

class ViewProductImageSuccess extends WmsPackingState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends WmsPackingState {
  final String error;
  ViewProductImageFailure(this.error);
}
