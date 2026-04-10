part of 'recepcion_bloc.dart';

@immutable
sealed class RecepcionEvent {}

class FetchOrdenesCompra extends RecepcionEvent {
  final bool isLoadinDialog;
  FetchOrdenesCompra(this.isLoadinDialog);
}

class FetchDevoluciones extends RecepcionEvent {
  final bool isLoadinDialog;
  FetchDevoluciones(this.isLoadinDialog);
}

class FetchOrdenesCompraOfBd extends RecepcionEvent {}

class FetchDevolucionesOfDB extends RecepcionEvent {}

class CurrentOrdenesCompra extends RecepcionEvent {
  ResultEntrada resultEntrada;
  CurrentOrdenesCompra(this.resultEntrada);
}

class SearchOrdenCompraEvent extends RecepcionEvent {
  final String query;
  SearchOrdenCompraEvent(this.query);
}

class SearchDevolucionEvent extends RecepcionEvent {
  final String query;
  SearchDevolucionEvent(this.query);
}

class AssignUserToOrder extends RecepcionEvent {
  final ResultEntrada order;
  AssignUserToOrder(
    this.order,
  );
}

class LoadConfigurationsUserOrder extends RecepcionEvent {}

class GetPorductsToEntrada extends RecepcionEvent {
  final int idEntrada;
  final String type;
  GetPorductsToEntrada(this.idEntrada, this.type);
}

class FetchPorductOrder extends RecepcionEvent {
  final LineasTransferencia product;
  FetchPorductOrder(
    this.product,
  );
}

class ValidateFieldsOrderEvent extends RecepcionEvent {
  final String field;
  final bool isOk;
  ValidateFieldsOrderEvent({required this.field, required this.isOk});
}

//* CAMBIAR VALORES DE VARIABLES

class ChangeProductIsOkEvent extends RecepcionEvent {
  final int idEntrada;
  final bool productIsOk;
  final int productId;
  final dynamic quantity;
  final int idMove;
  ChangeProductIsOkEvent(this.idEntrada, this.productIsOk, this.productId,
      this.quantity, this.idMove);
}

class SelectecLoteEvent extends RecepcionEvent {
  final LotesProduct lote;
  SelectecLoteEvent(this.lote);
}

class ChangeIsOkQuantity extends RecepcionEvent {
  final int idEntrada;
  final bool isOk;
  final int productId;
  final int idMove;
  ChangeIsOkQuantity(this.idEntrada, this.isOk, this.productId, this.idMove);
}

class ChangeQuantitySeparate extends RecepcionEvent {
  final dynamic quantity;
  final int productId;
  final int idRecepcion;
  final int idMove;
  ChangeQuantitySeparate(
      this.quantity, this.productId, this.idRecepcion, this.idMove);
}

class ShowQuantityOrderEvent extends RecepcionEvent {
  final bool showQuantity;
  ShowQuantityOrderEvent(this.showQuantity);
}

class AddQuantitySeparate extends RecepcionEvent {
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

class ChangeLocationDestIsOkEvent extends RecepcionEvent {
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

class LoadAllNovedadesOrderEvent extends RecepcionEvent {}

class FinalizarRecepcionProducto extends RecepcionEvent {}

class FinalizarRecepcionProductoSplit extends RecepcionEvent {
  final dynamic quantity;

  FinalizarRecepcionProductoSplit(this.quantity);
}

class GetLotesProduct extends RecepcionEvent {}

class SendProductToOrder extends RecepcionEvent {
  final bool isSplit;
  final dynamic quantity;

  SendProductToOrder(this.isSplit, this.quantity);
}

class CreateLoteProduct extends RecepcionEvent {
  final String nameLote;
  final String fechaCaducidad;
  CreateLoteProduct(this.nameLote, this.fechaCaducidad);
}

class StartOrStopTimeOrder extends RecepcionEvent {
  final int idRecepcion;
  final String value;

  StartOrStopTimeOrder(
    this.idRecepcion,
    this.value,
  );
}

class CreateBackOrderOrNot extends RecepcionEvent {
  final String type;
  final int idRecepcion;
  final bool isBackOrder;
  final bool forzarLoteVencido;
  CreateBackOrderOrNot(this.type, this.idRecepcion, this.isBackOrder,
      {this.forzarLoteVencido = false});
}

class ConfirmarLoteVencidoEvent extends RecepcionEvent {
  final String type;
  final int idRecepcion;
  final bool isBackOrder;
  ConfirmarLoteVencidoEvent(this.type, this.idRecepcion, this.isBackOrder);
}

class SearchLotevent extends RecepcionEvent {
  final String query;

  SearchLotevent(
    this.query,
  );
}

class GetLocationsDestEvent extends RecepcionEvent {}

class SearchLocationEvent extends RecepcionEvent {
  final String query;

  SearchLocationEvent(
    this.query,
  );
}

class FilterReceptionByTypeEvent extends RecepcionEvent {
  final String type;
  FilterReceptionByTypeEvent(this.type);
}

class CleanFieldsEvent extends RecepcionEvent {}

class FilterUbicacionesAlmacenEvent extends RecepcionEvent {
  final String almacen;
  FilterUbicacionesAlmacenEvent(this.almacen);
}

class SendTemperatureEvent extends RecepcionEvent {
  final File file;
  final int moveLineId;
  SendTemperatureEvent({
    required this.file,
    required this.moveLineId,
  });
}

class SendTemperatureManualEvent extends RecepcionEvent {
  final int moveLineId;
  SendTemperatureManualEvent({
    required this.moveLineId,
  });
}

class GetTemperatureEvent extends RecepcionEvent {
  final File file;

  GetTemperatureEvent({
    required this.file,
  });
}

class DelectedProductWmsEvent extends RecepcionEvent {
  final int idRecepcion;
  final List<int> listIdMove;
  DelectedProductWmsEvent(this.idRecepcion, this.listIdMove);
}

class SendImageNovedad extends RecepcionEvent {
  final File file;
  final int idRecepcion;
  final int moveLineId;

  SendImageNovedad({
    required this.file,
    required this.idRecepcion,
    required this.moveLineId,
  });
}

class ToggleProductExpansionEvent extends RecepcionEvent {
  final bool isExpanded;

  ToggleProductExpansionEvent(this.isExpanded);
}

class ViewProductImageEvent extends RecepcionEvent {
  final int idProduct;
  ViewProductImageEvent(this.idProduct);
}
