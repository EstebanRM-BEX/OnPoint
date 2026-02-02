part of 'info_rapida_bloc.dart';

@immutable
sealed class InfoRapidaState {}

final class InfoRapidaInitial extends InfoRapidaState {}

class InfoRapidaLoading extends InfoRapidaState {}

class NeedUpdateVersionState extends InfoRapidaState {}

class InfoRapidaLoaded extends InfoRapidaState {
  final InfoRapidaResult infoRapidaResult;
  final String message;

  InfoRapidaLoaded(this.infoRapidaResult, this.message);
}

class InfoRapidaLoadedTransfer extends InfoRapidaState {
  final InfoRapidaResult infoRapidaResult;
  final String message;

  InfoRapidaLoadedTransfer(this.infoRapidaResult, this.message);
}

class InfoRapidaError extends InfoRapidaState {
  final String? error;
  InfoRapidaError({this.error});
}

//estado para decir que el dispositivo no esta autorizado
final class DeviceNotAuthorized extends InfoRapidaState {}

//*estado para actualizar el valor escaneado

class UpdateScannedValueState extends InfoRapidaState {
  final String scannedValue;
  UpdateScannedValueState(this.scannedValue);
}

class ClearScannedValueState extends InfoRapidaState {}

class SearchLoading extends InfoRapidaState {}

class SearchFailure extends InfoRapidaState {
  final String error;
  SearchFailure(this.error);
}

class SearchLocationSuccess extends InfoRapidaState {
  final List<ResultUbicaciones> locations;
  SearchLocationSuccess(this.locations);
}

class ShowKeyboardState extends InfoRapidaState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class IsEditState extends InfoRapidaState {
  final bool isEdit;
  IsEditState(this.isEdit);
}

class LoadLocationsLoading extends InfoRapidaState {}

class LoadLocationsSuccess extends InfoRapidaState {
  final List<ResultUbicaciones> locations;
  LoadLocationsSuccess(this.locations);
}

class LoadLocationsFailure extends InfoRapidaState {
  final String error;
  LoadLocationsFailure(this.error);
}

class SearchProductSuccess extends InfoRapidaState {
  final List<Product> products;
  SearchProductSuccess(this.products);
}

class GetProductsLoading extends InfoRapidaState {}

class GetProductsSuccess extends InfoRapidaState {
  final List<Product> products;
  GetProductsSuccess(this.products);
}

class GetProductsFailure extends InfoRapidaState {
  final String error;
  GetProductsFailure(this.error);
}

class FilterUbicacionesLoading extends InfoRapidaState {}

class FilterUbicacionesFailure extends InfoRapidaState {
  final String error;
  FilterUbicacionesFailure(this.error);
}

class FilterUbicacionesSuccess extends InfoRapidaState {
  final List<ResultUbicaciones> locations;
  FilterUbicacionesSuccess(this.locations);
}

class UpdateProducrtLoading extends InfoRapidaState {}

class UpdateProductFailure extends InfoRapidaState {
  final String error;
  UpdateProductFailure(this.error);
}

class UpdateProductSuccess extends InfoRapidaState {}

class ConfigurationLoadedInfoRapida extends InfoRapidaState {
  final Configurations configurations;

  ConfigurationLoadedInfoRapida(this.configurations);
}

class ConfigurationError extends InfoRapidaState {
  final String error;

  ConfigurationError(this.error);
}

class EditLocationLoading extends InfoRapidaState {}

class EditLocationSuccess extends InfoRapidaState {}

class EditLocationFailure extends InfoRapidaState {
  final String error;

  EditLocationFailure(this.error);
}

class ProductExpansionToggled extends InfoRapidaState {
  final bool isExpanded;

  ProductExpansionToggled(this.isExpanded);
}

class SortLocationsLoading extends InfoRapidaState {}

class SortLocationsSuccess extends InfoRapidaState {}

class SortLocationsFailure extends InfoRapidaState {
  final String error;
  SortLocationsFailure(this.error);
}

class SortProductsLoading extends InfoRapidaState {}

class SortProductsSuccess extends InfoRapidaState {}

class SortProductsFailure extends InfoRapidaState {
  final String error;
  SortProductsFailure(this.error);
}

class ViewProductImageLoading extends InfoRapidaState {}

class ViewProductImageSuccess extends InfoRapidaState {
  final String imageUrl;
  ViewProductImageSuccess(this.imageUrl);
}

class ViewProductImageFailure extends InfoRapidaState {
  final String error;
  ViewProductImageFailure(this.error);
}

class RemoveProductFromMassTransferLoading extends InfoRapidaState {}

class RemoveProductFromMassTransferSuccess extends InfoRapidaState {
  final List<Producto> products;
  RemoveProductFromMassTransferSuccess(this.products);
}

class RemoveProductFromMassTransferFailure extends InfoRapidaState {
  final String error;
  RemoveProductFromMassTransferFailure(this.error);
}

class ResetProductsFiltersMassTransferLoading extends InfoRapidaState {}

class ResetProductsFiltersMassTransferSuccess extends InfoRapidaState {
  final List<Producto> products;
  ResetProductsFiltersMassTransferSuccess(this.products);
}

class ResetProductsFiltersMassTransferFailure extends InfoRapidaState {
  final String error;
  ResetProductsFiltersMassTransferFailure(this.error);
}
