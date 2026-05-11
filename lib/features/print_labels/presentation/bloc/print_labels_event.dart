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
  final Product product;
  AddSelectedProductEvent(this.product);
}

class RemoveSelectedProductEvent extends PrintLabelsEvent {
  final int productId;
  RemoveSelectedProductEvent(this.productId);
}
