part of 'print_labels_bloc.dart';

@immutable
abstract class PrintLabelsState {}

class PrintLabelsInitial extends PrintLabelsState {}

class LoadLocationsLoading extends PrintLabelsState {}

class LoadLocationsSuccess extends PrintLabelsState {
  final List<ResultUbicaciones> locations;
  LoadLocationsSuccess(this.locations);
}

class LoadLocationsFailure extends PrintLabelsState {
  final String error;
  LoadLocationsFailure(this.error);
}

class GetProductsLoading extends PrintLabelsState {}

class GetProductsSuccess extends PrintLabelsState {
  final List<Product> products;
  GetProductsSuccess(this.products);
}

class GetProductsFailure extends PrintLabelsState {
  final String error;
  GetProductsFailure(this.error);
}

class ConfigurationLoadedPrintLabels extends PrintLabelsState {
  final UserConfigurationModel configuration;
  ConfigurationLoadedPrintLabels(this.configuration);
}

class ConfigurationError extends PrintLabelsState {
  final String error;
  ConfigurationError(this.error);
}

class SearchLocationSuccess extends PrintLabelsState {
  final List<ResultUbicaciones> locations;
  SearchLocationSuccess(this.locations);
}

class SearchProductSuccess extends PrintLabelsState {
  final List<Product> products;
  SearchProductSuccess(this.products);
}

class SearchRangeLocationSuccess extends PrintLabelsState {
  final List<ResultUbicaciones> locations;
  SearchRangeLocationSuccess(this.locations);
}
