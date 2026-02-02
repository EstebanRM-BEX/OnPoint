part of 'info_rapida_bloc.dart';

@immutable
sealed class InfoRapidaEvent {}

class GetInfoRapida extends InfoRapidaEvent {
  final String barcode;
  final bool isManual;
  final bool isProduct;
  final bool isTransfer;
  GetInfoRapida(this.barcode, this.isManual, this.isProduct, this.isTransfer);
}

class UpdateScannedValueEvent extends InfoRapidaEvent {
  final String scannedValue;
  UpdateScannedValueEvent(this.scannedValue);
}

class ClearScannedValueEvent extends InfoRapidaEvent {
  ClearScannedValueEvent();
}

class SearchLocationEvent extends InfoRapidaEvent {
  final String query;

  SearchLocationEvent(
    this.query,
  );
}

class ShowKeyboardInfoEvent extends InfoRapidaEvent {
  final bool showKeyboard;
  final bool isNumeric;
  final TextEditingController controllerActivo;
  ShowKeyboardInfoEvent(this.showKeyboard, this.controllerActivo,
      {this.isNumeric = false});
}

class IsEditEvent extends InfoRapidaEvent {
  final bool isEdit;
  IsEditEvent(this.isEdit);
}

class GetListLocationsEvent extends InfoRapidaEvent {
  GetListLocationsEvent();
}

class SearchProductEvent extends InfoRapidaEvent {
  final String query;

  SearchProductEvent(
    this.query,
  );
}

class GetProductsList extends InfoRapidaEvent {
  GetProductsList();
}

class FilterUbicacionesAlmacenEvent extends InfoRapidaEvent {
  final String almacen;
  FilterUbicacionesAlmacenEvent(this.almacen);
}

class UpdateProductEvent extends InfoRapidaEvent {
  final UpdateProductRequest request;
  UpdateProductEvent(this.request);
}

class LoadConfigurationsUserInfo extends InfoRapidaEvent {}

class EditLocationEvent extends InfoRapidaEvent {
  final int locationId;
  final String name;
  final String barcode;

  EditLocationEvent(
    this.locationId,
    this.name,
    this.barcode,
  );
}

class ToggleProductExpansionEvent extends InfoRapidaEvent {
  final bool isExpanded;

  ToggleProductExpansionEvent(this.isExpanded);
}

class SortProductsEvent extends InfoRapidaEvent {
  final bool ascending;
  SortProductsEvent(this.ascending);
}

class ViewProductImageEvent extends InfoRapidaEvent {
  final int idProduct;
  ViewProductImageEvent(this.idProduct);
}

class SortLocationsEvent extends InfoRapidaEvent {
  final String criteria; // 'location', 'lote', 'date'
  final bool ascending;
  SortLocationsEvent(this.criteria, this.ascending);
}

class RemoveProductFromMassTransferEvent extends InfoRapidaEvent {
  final int idProduct;
  RemoveProductFromMassTransferEvent(this.idProduct);
}

class ResetProductsFiltersMassTransferEvent extends InfoRapidaEvent {}
