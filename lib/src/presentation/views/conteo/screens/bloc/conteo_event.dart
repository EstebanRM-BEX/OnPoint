part of 'conteo_bloc.dart';

@immutable
sealed class ConteoEvent {}

class GetConteosEvent extends ConteoEvent {}

class GetConteosFromDBEvent extends ConteoEvent {}

class LoadConteoAndProductsEvent extends ConteoEvent {
  final int ordenConteoId;

  LoadConteoAndProductsEvent({required this.ordenConteoId});
}

class ValidateFieldsEvent extends ConteoEvent {
  final String field;
  final bool isOk;
  ValidateFieldsEvent({required this.field, required this.isOk});
}

class LoadCurrentProductEvent extends ConteoEvent {
  final CountedLine currentProduct;

  LoadCurrentProductEvent({required this.currentProduct});
}

class LoadConfigurationsUserConteo extends ConteoEvent {
  LoadConfigurationsUserConteo();
}

class ChangeLocationIsOkEvent extends ConteoEvent {
  final bool isNewProduct;
  final ResultUbicaciones locationSelect;
  final int productId;
  final int orden;
  final int idMove;
  ChangeLocationIsOkEvent(this.isNewProduct, this.locationSelect,
      this.productId, this.orden, this.idMove);
}

class ChangeIsOkQuantity extends ConteoEvent {
  final int idOrder;
  final bool isOk;
  final int productId;
  final int idMove;
  ChangeIsOkQuantity(this.idOrder, this.isOk, this.productId, this.idMove);
}

class ChangeQuantitySeparate extends ConteoEvent {
  final bool isNewProduct;
  final dynamic quantity;
  final int productId;
  final int idOrder;
  final int idMove;
  ChangeQuantitySeparate(this.isNewProduct, this.quantity, this.productId,
      this.idOrder, this.idMove);
}

class ChangeProductIsOkEvent extends ConteoEvent {
  final bool isNewProduct;
  final Product productSelect;
  final int idOrder;
  final bool productIsOk;
  final int productId;
  final dynamic quantity;
  final int idMove;

  ChangeProductIsOkEvent(this.isNewProduct, this.productSelect, this.idOrder,
      this.productIsOk, this.productId, this.quantity, this.idMove);
}

class ExpandLocationEvent extends ConteoEvent {
  final String ubicacion;
  ExpandLocationEvent(this.ubicacion);
}

class ExpandLocationState extends ConteoState {
  final String ubicacion;
  ExpandLocationState(this.ubicacion);
}

class ResetValuesEvent extends ConteoEvent {
  final bool resetAll;
  final bool isLoading;
  ResetValuesEvent({required this.resetAll, required this.isLoading});
}

class ShowQuantityEvent extends ConteoEvent {
  final bool showQuantity;
  ShowQuantityEvent(this.showQuantity);
}

class AddQuantitySeparate extends ConteoEvent {
  final int productId;
  final int idOrder;
  final int idMove;
  final dynamic quantity;
  final bool isOk;
  AddQuantitySeparate(
      this.productId, this.idOrder, this.idMove, this.quantity, this.isOk);
}

class FetchBarcodesProductEvent extends ConteoEvent {
  final bool isNewProduct;

  FetchBarcodesProductEvent(this.isNewProduct);
}

class GetLotesProduct extends ConteoEvent {
  final bool isManual;
  final int idLote;
  GetLotesProduct({this.isManual = false, this.idLote = 0});
}

class SelectecLoteEvent extends ConteoEvent {
  final LotesProduct lote;
  SelectecLoteEvent(this.lote);
}

class SearchLotevent extends ConteoEvent {
  final String query;

  SearchLotevent(
    this.query,
  );
}

class CreateLoteProduct extends ConteoEvent {
  final String nameLote;
  final String fechaCaducidad;
  CreateLoteProduct(this.nameLote, this.fechaCaducidad);
}

class SendProductConteoEvent extends ConteoEvent {
  final bool isNewProduct;
  final dynamic cantidad;
  final CountedLine currentProduct;

  SendProductConteoEvent(this.isNewProduct, this.cantidad, this.currentProduct);
}

class DeleteProductConteoEvent extends ConteoEvent {
  final CountedLine currentProduct;
  DeleteProductConteoEvent(this.currentProduct);
}

class GetLocationsConteoEvent extends ConteoEvent {}

class LoadNewProductEvent extends ConteoEvent {
  LoadNewProductEvent();
}

class SearchLocationEvent extends ConteoEvent {
  final String query;

  SearchLocationEvent(
    this.query,
  );
}

class SearchProductEvent extends ConteoEvent {
  final String query;

  SearchProductEvent(
    this.query,
  );
}

class GetProductsFromDBEvent extends ConteoEvent {}

class UpdateProductConteoEvent extends ConteoEvent {
  final CountedLine product; //producto que voy a enviar
  final CountedLine productExist; //producto que ya existe
  final dynamic quantity;
  final bool isOverwrite;

  UpdateProductConteoEvent(
      this.product, this.productExist, this.quantity, this.isOverwrite);
}

class OrderConteosByStateEvent extends ConteoEvent {
  final String stateOrder;
  OrderConteosByStateEvent(this.stateOrder);
}

class ViewProductImageEvent extends ConteoEvent {
  final int idProduct;
  ViewProductImageEvent(this.idProduct);
}
