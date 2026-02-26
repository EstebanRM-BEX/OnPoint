part of 'crate_transfer_bloc.dart';

@immutable
sealed class CreateTransferEvent {}

class LoadConfigurationsUserCreateTransferEvent extends CreateTransferEvent {
  LoadConfigurationsUserCreateTransferEvent();
}

class ValidateFieldsEvent extends CreateTransferEvent {
  final String field;
  final bool isOk;
  ValidateFieldsEvent({required this.field, required this.isOk});
}

class GetLocationsEvent extends CreateTransferEvent {}

class GetProductsFromDBEvent extends CreateTransferEvent {}

class SearchLocationEvent extends CreateTransferEvent {
  final String query;

  SearchLocationEvent(
    this.query,
  );
}

class SearchProductEvent extends CreateTransferEvent {
  final String query;

  SearchProductEvent(
    this.query,
  );
}

class ChangeLocationIsOkEvent extends CreateTransferEvent {
  final ResultUbicaciones locationSelect;
  final bool isLocationDest;
  ChangeLocationIsOkEvent(this.locationSelect, this.isLocationDest);
}

class ChangeProductIsOkEvent extends CreateTransferEvent {
  final Product productSelect;
  final bool productIsOk;

  ChangeProductIsOkEvent(this.productSelect, this.productIsOk);
}

class CreateLoteProduct extends CreateTransferEvent {
  final String nameLote;
  final String fechaCaducidad;
  CreateLoteProduct(this.nameLote, this.fechaCaducidad);
}

class SearchLotevent extends CreateTransferEvent {
  final String query;

  SearchLotevent(
    this.query,
  );
}

class GetLotesProduct extends CreateTransferEvent {
  final bool isManual;
  final int idLote;
  GetLotesProduct({this.isManual = false, this.idLote = 0});
}

class SelectecLoteEvent extends CreateTransferEvent {
  final LotesProduct lote;
  SelectecLoteEvent(this.lote);
}

class ChangeIsOkQuantity extends CreateTransferEvent {
  final bool isOk;
  final int productId;
  ChangeIsOkQuantity(
    this.isOk,
    this.productId,
  );
}

class ShowQuantityEvent extends CreateTransferEvent {
  final bool showQuantity;
  ShowQuantityEvent(this.showQuantity);
}

class ChangeQuantitySeparate extends CreateTransferEvent {
  final dynamic quantity;
  final int productId;

  ChangeQuantitySeparate(
    this.quantity,
    this.productId,
  );
}

class ClearDataCreateTransferEvent extends CreateTransferEvent {
  final bool isClearProduct;
  ClearDataCreateTransferEvent({required this.isClearProduct});
}

class AddQuantitySeparate extends CreateTransferEvent {
  final int productId;
  final dynamic quantity;
  final bool isOk;
  AddQuantitySeparate(this.productId, this.quantity, this.isOk);
}

class FetchBarcodesProductEvent extends CreateTransferEvent {}

class FetchAllBarcodesInventarioEvent extends CreateTransferEvent {
  FetchAllBarcodesInventarioEvent();
}

class AddProductCreateTransferEvent extends CreateTransferEvent {
  final dynamic quantity;
  final Product product;
  AddProductCreateTransferEvent(
    this.quantity,
    this.product,
  );
}

class RemoveProductFromTransferEvent extends CreateTransferEvent {
  final Product product;
  RemoveProductFromTransferEvent(this.product);
}

class GetProductsCreateTransferEvent extends CreateTransferEvent {}

class CreateNewTransferEvent extends CreateTransferEvent {
  CreateNewTransferEvent();
}

class ValidateStockProductEvent extends CreateTransferEvent {
  final dynamic quantity;

  ValidateStockProductEvent(this.quantity);
}
