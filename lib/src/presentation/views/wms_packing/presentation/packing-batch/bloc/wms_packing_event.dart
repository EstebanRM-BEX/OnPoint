part of 'wms_packing_bloc.dart';

@immutable
sealed class WmsPackingEvent {}

class LoadAllPackingEvent extends WmsPackingEvent {
  final bool isLoadinDialog;
  LoadAllPackingEvent(
    this.isLoadinDialog,
  );
}

class LoadBatchPackingFromDBEvent extends WmsPackingEvent {
  LoadBatchPackingFromDBEvent();
}

class LoadAllPedidosFromBatchEvent extends WmsPackingEvent {
  final int batchId;
  LoadAllPedidosFromBatchEvent(
    this.batchId,
  );
}

class FetchProductEvent extends WmsPackingEvent {
  final ProductoPedido pedido;
  FetchProductEvent(
    this.pedido,
  );
}

class LoadAllProductsFromPedidoEvent extends WmsPackingEvent {
  final int pedidoId;
  LoadAllProductsFromPedidoEvent(
    this.pedidoId,
  );
}

class SearchBatchPackingEvent extends WmsPackingEvent {
  final String query;
  final int indexMenu;

  SearchBatchPackingEvent(this.query, this.indexMenu);
}

class SearchPedidoPackingEvent extends WmsPackingEvent {
  final String query;
  final int idBatch;

  SearchPedidoPackingEvent(this.query, this.idBatch);
}

class ValidateFieldsPackingEvent extends WmsPackingEvent {
  final String field;
  final bool isOk;
  ValidateFieldsPackingEvent({required this.field, required this.isOk});
}

class ChangeQuantitySeparate extends WmsPackingEvent {
  final dynamic quantity;
  final int productId;
  final int pedidoId;
  final int idMove;
  ChangeQuantitySeparate(
      this.quantity, this.productId, this.pedidoId, this.idMove);
}

//
class AddProductPackingEvent extends WmsPackingEvent {}

//* CAMBIAR VALORES DE VARIABLES
class ChangeLocationIsOkEvent extends WmsPackingEvent {
  final int productId;
  final int pedidoId;
  final int idMove;
  ChangeLocationIsOkEvent(this.productId, this.pedidoId, this.idMove);
}

class ChangeLocationDestIsOkEvent extends WmsPackingEvent {
  final bool locationDestIsOk;
  ChangeLocationDestIsOkEvent(this.locationDestIsOk);
}

class ChangeProductIsOkEvent extends WmsPackingEvent {
  final bool productIsOk;
  final int productId;
  final int pedidoId;
  final dynamic quantity;
  final int idMove;
  ChangeProductIsOkEvent(this.productIsOk, this.productId, this.pedidoId,
      this.quantity, this.idMove);
}

class ChangeIsOkQuantity extends WmsPackingEvent {
  final bool isOk;
  final int productId;
  final int pedidoId;
  final int idMove;
  ChangeIsOkQuantity(this.isOk, this.productId, this.pedidoId, this.idMove);
}

class AddQuantitySeparate extends WmsPackingEvent {
  final int productId;
  final int idMove;
  final dynamic quantity;
  final int pedidoId;
  AddQuantitySeparate(
      this.quantity, this.idMove, this.productId, this.pedidoId);
}

class SetPackingsEvent extends WmsPackingEvent {
  final List<ProductoPedido> productos;
  final bool isSticker;
  final bool isCertificate;

  SetPackingsEvent(
    this.productos,
    this.isSticker,
    this.isCertificate,
  );
}

class ChangeStickerEvent extends WmsPackingEvent {
  final bool isSticker;
  ChangeStickerEvent(this.isSticker);
}

class FilterBatchPackingStatusEvent extends WmsPackingEvent {
  final String status;

  FilterBatchPackingStatusEvent(this.status);
}

class SearchProductPackingEvent extends WmsPackingEvent {
  final String query;

  SearchProductPackingEvent(
    this.query,
  );
}

class SelectProductPackingEvent extends WmsPackingEvent {
  final ProductoPedido producto;
  SelectProductPackingEvent(this.producto);
}

class UnSelectProductPackingEvent extends WmsPackingEvent {
  final ProductoPedido producto;
  UnSelectProductPackingEvent(this.producto);
}

class LoadAllNovedadesPackingEvent extends WmsPackingEvent {}

class LoadConfigurationsUserPack extends WmsPackingEvent {
  LoadConfigurationsUserPack();
}

class SetPickingSplitEvent extends WmsPackingEvent {
  final ProductoPedido producto;
  final int idMove;
  final dynamic quantity;
  final int productId;
  final int pedidoId;
  SetPickingSplitEvent(
      this.producto, this.idMove, this.quantity, this.productId, this.pedidoId);
}

class SetPickingsEvent extends WmsPackingEvent {
  final int productId;
  final int pedidoId;
  final int idMove;

  SetPickingsEvent(this.productId, this.pedidoId, this.idMove);
}

class UnPackingEvent extends WmsPackingEvent {
  final UnPackingRequest request;
  final int pedidoId;
  final dynamic consecutivoPackage;

  UnPackingEvent(this.request, this.pedidoId, this.consecutivoPackage);
}

class ShowQuantityPackEvent extends WmsPackingEvent {
  final bool showQuantity;
  ShowQuantityPackEvent(this.showQuantity);
}

class ShowDetailvent extends WmsPackingEvent {
  final bool show;
  ShowDetailvent(this.show);
}

//*empezar el tiempo de separacion
class StartTimePack extends WmsPackingEvent {
  final int batchId;
  final DateTime time;
  StartTimePack(this.batchId, this.time);
}

class EndTimePack extends WmsPackingEvent {
  final int batchId;
  final DateTime time;
  EndTimePack(this.batchId, this.time);
}

class SendTemperatureEvent extends WmsPackingEvent {
  final File file;
  final int moveLineId;
  SendTemperatureEvent({
    required this.file,
    required this.moveLineId,
  });
}

class SendTemperaturePackingEvent extends WmsPackingEvent {
  final int moveLineId;
  SendTemperaturePackingEvent({
    required this.moveLineId,
  });
}

class SendImageNovedad extends WmsPackingEvent {
  final dynamic cantidad;
  final File file;
  final int moveLineId;
  final int pedidoId;
  final int productId;

  SendImageNovedad({
    required this.cantidad,
    required this.file,
    required this.moveLineId,
    required this.pedidoId,
    required this.productId,
  });
}

class GetTemperatureEvent extends WmsPackingEvent {
  final File file;

  GetTemperatureEvent({
    required this.file,
  });
}

class LoadDocOriginsEvent extends WmsPackingEvent {
  final int idBatch;
  LoadDocOriginsEvent(this.idBatch);
}

class DeleteProductFromTemporaryPackageEvent extends WmsPackingEvent {
  final ProductoPedido product;

  DeleteProductFromTemporaryPackageEvent({
    required this.product,
  });
}

class ViewProductImageEvent extends WmsPackingEvent {
  final int idProduct;
  ViewProductImageEvent(this.idProduct);
}
