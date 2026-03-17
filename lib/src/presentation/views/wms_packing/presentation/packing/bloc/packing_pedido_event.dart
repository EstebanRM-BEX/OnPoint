part of 'packing_pedido_bloc.dart';

@immutable
sealed class PackingPedidoEvent {}

class LoadAllPackingPedidoEvent extends PackingPedidoEvent {
  final bool isLoadinDialog;
  LoadAllPackingPedidoEvent(
    this.isLoadinDialog,
  );
}

class LoadPackingPedidoFromDBEvent extends PackingPedidoEvent {}

class SearchPedidoEvent extends PackingPedidoEvent {
  final String query;
  SearchPedidoEvent(
    this.query,
  );
}

class AssignUserToPedido extends PackingPedidoEvent {
  final int id;
  AssignUserToPedido(this.id);
}

class StartOrStopTimePedido extends PackingPedidoEvent {
  final int id;
  final String value;
  StartOrStopTimePedido(this.id, this.value);
}

class LoadConfigurationsUser extends PackingPedidoEvent {}

class LoadPedidoAndProductsEvent extends PackingPedidoEvent {
  final int idPedido;
  LoadPedidoAndProductsEvent(this.idPedido);
}

class ShowDetailvent extends PackingPedidoEvent {
  final bool show;
  ShowDetailvent(this.show);
}

class ValidateFieldsPackingEvent extends PackingPedidoEvent {
  final String field;
  final bool isOk;
  ValidateFieldsPackingEvent({required this.field, required this.isOk});
}

class ChangeLocationIsOkEvent extends PackingPedidoEvent {
  final int productId;
  final int pedidoId;
  final int idMove;
  ChangeLocationIsOkEvent(this.productId, this.pedidoId, this.idMove);
}

class ChangeLocationDestIsOkEvent extends PackingPedidoEvent {
  final bool locationDestIsOk;
  ChangeLocationDestIsOkEvent(this.locationDestIsOk);
}

class ChangeProductIsOkEvent extends PackingPedidoEvent {
  final bool productIsOk;
  final int productId;
  final int pedidoId;
  final dynamic quantity;
  final int idMove;
  ChangeProductIsOkEvent(this.productIsOk, this.productId, this.pedidoId,
      this.quantity, this.idMove);
}

class ChangeQuantitySeparate extends PackingPedidoEvent {
  final dynamic quantity;
  final int productId;
  final int pedidoId;
  final int idMove;
  ChangeQuantitySeparate(
      this.quantity, this.productId, this.pedidoId, this.idMove);
}

class ChangeIsOkQuantity extends PackingPedidoEvent {
  final bool isOk;
  final int productId;
  final int pedidoId;
  final int idMove;
  ChangeIsOkQuantity(this.isOk, this.productId, this.pedidoId, this.idMove);
}

class AddQuantitySeparate extends PackingPedidoEvent {
  final int productId;
  final int idMove;
  final dynamic quantity;
  final int pedidoId;
  AddQuantitySeparate(
      this.quantity, this.idMove, this.productId, this.pedidoId);
}

class FetchProductEvent extends PackingPedidoEvent {
  final ProductoPedido pedido;
  FetchProductEvent(
    this.pedido,
  );
}

class SendTemperatureEvent extends PackingPedidoEvent {
  final File file;
  final int moveLineId;
  SendTemperatureEvent({
    required this.file,
    required this.moveLineId,
  });
}

class SendTemperatureManualPackEvent extends PackingPedidoEvent {
  final int moveLineId;
  SendTemperatureManualPackEvent({
    required this.moveLineId,
  });
}

class SendImageNovedad extends PackingPedidoEvent {
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

class GetTemperatureEvent extends PackingPedidoEvent {
  final File file;

  GetTemperatureEvent({
    required this.file,
  });
}

class LoadAllNovedadesPackEvent extends PackingPedidoEvent {}

class SetPickingSplitEvent extends PackingPedidoEvent {
  final ProductoPedido producto;
  final int idMove;
  final dynamic quantity;
  final int productId;
  final int pedidoId;
  SetPickingSplitEvent(
      this.producto, this.idMove, this.quantity, this.productId, this.pedidoId);
}

class SetPickingsEvent extends PackingPedidoEvent {
  final int productId;
  final int pedidoId;
  final int idMove;

  SetPickingsEvent(this.productId, this.pedidoId, this.idMove);
}

class ShowQuantityPackEvent extends PackingPedidoEvent {
  final bool showQuantity;
  ShowQuantityPackEvent(this.showQuantity);
}

class ChangeStickerEvent extends PackingPedidoEvent {
  final bool isSticker;
  ChangeStickerEvent(this.isSticker);
}

class SetPackingsEvent extends PackingPedidoEvent {
  final List<ProductoPedido> productos;
  final bool isSticker;
  final bool isCertificate;
  final double peso;
  final String tipoEmpaque;
  final PackagingType packagingType;

  SetPackingsEvent(
      this.productos, this.isSticker, this.tipoEmpaque, this.isCertificate,
      [this.peso = 0.0,
      this.packagingType = const PackagingType(
        id: 0,
        name: '',
        barcode: '',
        maxWeight: 0.0,
        height: 0.0,
        width: 0.0,
        packagingLength: 0.0,
        size: '',
        carrier: '',
      )]);
}

class SelectProductPackingEvent extends PackingPedidoEvent {
  final ProductoPedido producto;
  SelectProductPackingEvent(this.producto);
}

class UnSelectProductPackingEvent extends PackingPedidoEvent {
  final ProductoPedido producto;
  UnSelectProductPackingEvent(this.producto);
}

class UnPackingEvent extends PackingPedidoEvent {
  final UnPackRequest request;

  final int pedidoId;
  final int productId;
  final dynamic consecutivoPackage;
  UnPackingEvent(
      this.request, this.pedidoId, this.productId, this.consecutivoPackage);
}

class StartOrStopTimePack extends PackingPedidoEvent {
  final int idPedido;
  final String value;

  StartOrStopTimePack(
    this.idPedido,
    this.value,
  );
}

class CreateBackPackOrNot extends PackingPedidoEvent {
  final int idPick;
  final bool isBackOrder;
  CreateBackPackOrNot(this.idPick, this.isBackOrder);
}

class ValidateConfirmEvent extends PackingPedidoEvent {
  final int idPedido;
  final bool isBackOrder;
  final bool isLoadinDialog;
  ValidateConfirmEvent(this.idPedido, this.isBackOrder, this.isLoadinDialog);
}

class DeleteProductFromTemporaryPackageEvent extends PackingPedidoEvent {
  final ProductoPedido product;

  DeleteProductFromTemporaryPackageEvent({
    required this.product,
  });
}

class ViewProductImageEvent extends PackingPedidoEvent {
  final int idProduct;
  ViewProductImageEvent(this.idProduct);
}

class SortPackingListEvent extends PackingPedidoEvent {
  final String field;
  final bool ascending;
  SortPackingListEvent(this.field, this.ascending);
}
