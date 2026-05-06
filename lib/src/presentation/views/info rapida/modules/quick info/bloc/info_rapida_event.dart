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

class SearchLocationEvent extends InfoRapidaEvent {
  final String query;
  SearchLocationEvent(
    this.query,
  );
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

class SearchProductLocationEvent extends InfoRapidaEvent {
  final String query;
  SearchProductLocationEvent(
    this.query,
  );
}

class SearchLocationProductsEvent extends InfoRapidaEvent {
  final String query;
  SearchLocationProductsEvent(
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

class ChangeLocationIsOkEvent extends InfoRapidaEvent {
  final ResultUbicaciones locationSelect;
  final bool isLocationDest;
  ChangeLocationIsOkEvent(this.locationSelect, this.isLocationDest);
}

class ValidateFieldsEvent extends InfoRapidaEvent {
  final String field;
  final bool isOk;
  ValidateFieldsEvent({required this.field, required this.isOk});
}

class ChangeProductIsOkEvent extends InfoRapidaEvent {
  final Producto productSelect;
  final bool productIsOk;

  ChangeProductIsOkEvent(this.productSelect, this.productIsOk);
}

class CreateNewMassTransferEvent extends InfoRapidaEvent {
  CreateNewMassTransferEvent();
}

class ActivateMassTransferEvent extends InfoRapidaEvent {
  final bool activate;
  ActivateMassTransferEvent(this.activate);
}

class ToggleProductMassTransferEvent extends InfoRapidaEvent {
  final Producto product;
  final bool isSelected;

  ToggleProductMassTransferEvent(this.product, this.isSelected);
}

class SelectAllAvailableProductsEvent extends InfoRapidaEvent {}
