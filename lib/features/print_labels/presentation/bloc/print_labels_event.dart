part of 'print_labels_bloc.dart';

@immutable
abstract class PrintLabelsEvent {}

class GetListLocationsEvent extends PrintLabelsEvent {}

class GetProductsList extends PrintLabelsEvent {}

class LoadConfigurationsUserInfo extends PrintLabelsEvent {}

class SearchLocationEvent extends PrintLabelsEvent {
  final String query;
  SearchLocationEvent(this.query);
}

class SearchProductEvent extends PrintLabelsEvent {
  final String query;
  SearchProductEvent(this.query);
}

class SearchRangeLocationEvent extends PrintLabelsEvent {
  final String start;
  final String end;
  SearchRangeLocationEvent(this.start, this.end);
}

class RemoveRangeLocationEvent extends PrintLabelsEvent {
  final int locationId;
  RemoveRangeLocationEvent(this.locationId);
}

class AddRangeLocationEvent extends PrintLabelsEvent {
  final ResultUbicaciones location;
  AddRangeLocationEvent(this.location);
}

class AddSelectedProductEvent extends PrintLabelsEvent {
  final int productId;
  AddSelectedProductEvent(this.productId);
}

class RemoveSelectedProductEvent extends PrintLabelsEvent {
  final int productId;
  RemoveSelectedProductEvent(this.productId);
}

/// Limpia toda la selección de productos (tras una impresión exitosa).
class ClearSelectedProductsEvent extends PrintLabelsEvent {}

/// Limpia el rango de ubicaciones seleccionadas (tras una impresión exitosa).
class ClearRangeLocationsEvent extends PrintLabelsEvent {}
