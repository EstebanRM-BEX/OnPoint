part of 'recepcion_batch_bloc.dart';

@immutable
sealed class RecepcionBatchEvent {}

class FetchRecepcionBatchEvent extends RecepcionBatchEvent {
  final bool isLoadinDialog;

  FetchRecepcionBatchEvent({required this.isLoadinDialog});
}

class FetchRecepcionBatchEventFromBD extends RecepcionBatchEvent {}

class SearchReceptionEvent extends RecepcionBatchEvent {
  final String query;
  SearchReceptionEvent(this.query);
}

class AssignUserToReception extends RecepcionBatchEvent {
  final ReceptionBatch order;
  AssignUserToReception(
    this.order,
  );
}

class StartOrStopTimeOrder extends RecepcionBatchEvent {
  final int idRecepcion;
  final String value;

  StartOrStopTimeOrder(
    this.idRecepcion,
    this.value,
  );
}

class GetPorductsToEntradaBatch extends RecepcionBatchEvent {
  final int idEntrada;
  GetPorductsToEntradaBatch(this.idEntrada);
}

class CurrentOrdenesCompraBatch extends RecepcionBatchEvent {
  final ReceptionBatch resultEntrada;
  CurrentOrdenesCompraBatch(this.resultEntrada);
}

class ValidateFieldsOrderEvent extends RecepcionBatchEvent {
  final String field;
  final bool isOk;
  ValidateFieldsOrderEvent({required this.field, required this.isOk});
}

class ChangeQuantitySeparate extends RecepcionBatchEvent {
  final dynamic quantity;
  final int productId;
  final int idRecepcion;
  final int idMove;
  ChangeQuantitySeparate(
      this.quantity, this.productId, this.idRecepcion, this.idMove);
}

class AddQuantitySeparate extends RecepcionBatchEvent {
  final int idRecepcion;
  final int productId;
  final int idMove;
  final dynamic quantity;
  AddQuantitySeparate(
    this.idRecepcion,
    this.productId,
    this.idMove,
    this.quantity,
  );
}

class ChangeProductIsOkEvent extends RecepcionBatchEvent {
  final int idEntrada;
  final bool productIsOk;
  final int productId;
  final dynamic quantity;
  final int idMove;
  ChangeProductIsOkEvent(this.idEntrada, this.productIsOk, this.productId,
      this.quantity, this.idMove);
}

class ChangeIsOkQuantity extends RecepcionBatchEvent {
  final int idEntrada;
  final bool isOk;
  final int productId;
  final int idMove;
  ChangeIsOkQuantity(this.idEntrada, this.isOk, this.productId, this.idMove);
}

class ChangeLocationDestIsOkEvent extends RecepcionBatchEvent {
  final int idEntrada;
  final bool isOk;
  final int productId;
  final int idMove;
  final ResultUbicaciones locationSelect;
  ChangeLocationDestIsOkEvent(
    this.idEntrada,
    this.isOk,
    this.productId,
    this.idMove,
    this.locationSelect,
  );
}

class ShowQuantityOrderEvent extends RecepcionBatchEvent {
  final bool showQuantity;
  ShowQuantityOrderEvent(this.showQuantity);
}

class LoadAllNovedadesReceptionEvent extends RecepcionBatchEvent {}

class FetchPorductOrder extends RecepcionBatchEvent {
  final LineasRecepcionBatch product;
  FetchPorductOrder(
    this.product,
  );
}

class GetLotesProduct extends RecepcionBatchEvent {}

class FilterUbicacionesAlmacenEvent extends RecepcionBatchEvent {
  final String almacen;
  FilterUbicacionesAlmacenEvent(this.almacen);
}

class SearchLocationEvent extends RecepcionBatchEvent {
  final String query;

  SearchLocationEvent(
    this.query,
  );
}

class GetLocationsDestReceptionBatchEvent extends RecepcionBatchEvent {}

class LoadConfigurationsUserReception extends RecepcionBatchEvent {}

class CleanFieldsEvent extends RecepcionBatchEvent {}

class SendProductToOrder extends RecepcionBatchEvent {
  final bool isSplit;
  final dynamic quantity;

  SendProductToOrder(this.isSplit, this.quantity);
}

class FinalizarRecepcionProducto extends RecepcionBatchEvent {}

class FinalizarRecepcionProductoSplit extends RecepcionBatchEvent {
  final dynamic quantity;

  FinalizarRecepcionProductoSplit(this.quantity);
}

class CreateLoteProduct extends RecepcionBatchEvent {
  final String nameLote;
  final String fechaCaducidad;
  CreateLoteProduct(this.nameLote, this.fechaCaducidad);
}

class SearchLotevent extends RecepcionBatchEvent {
  final String query;

  SearchLotevent(
    this.query,
  );
}

class SelectecLoteEvent extends RecepcionBatchEvent {
  final LotesProduct lote;
  SelectecLoteEvent(this.lote);
}

class ViewProductImageEvent extends RecepcionBatchEvent {
  final int idProduct;
  ViewProductImageEvent(this.idProduct);
}
