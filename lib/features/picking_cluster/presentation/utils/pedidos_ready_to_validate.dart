import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';

/// Avance de envío al WMS de los productos de un pedido.
class PedidoSendProgress {
  final int sent;
  final int total;

  const PedidoSendProgress({required this.sent, required this.total});

  /// 0.0 – 1.0. Un pedido sin productos en el batch queda en 0.
  double get ratio => total == 0 ? 0 : sent / total;

  int get missing => total - sent;

  /// Se puede validar solo si tiene productos y todos ya se enviaron.
  bool get isComplete => total > 0 && sent == total;
}

/// Un producto cuenta como enviado solo con `is_send_odoo == 1`: los
/// guardados offline (0) o sin procesar (null) bloquean la validación. Un
/// producto separado con faltante cuenta igual si ya se envió.
PedidoSendProgress pedidoSendProgress(
  int? idPedido,
  List<BatchProduct> products,
) {
  final pedidoProducts = products.where((p) => p.pedidoId == idPedido);
  return PedidoSendProgress(
    sent: pedidoProducts.where((p) => p.isSendOdoo == 1).length,
    total: pedidoProducts.length,
  );
}

/// Pedidos del batch que ya se pueden validar: aún no validados y con todos
/// sus productos enviados al WMS.
List<PedidoValidate> pedidosReadyToValidate(
  List<PedidoValidate> pedidos,
  List<BatchProduct> products,
) {
  return pedidos
      .where(
        (pedido) =>
            pedido.isValidated != true &&
            pedido.idPedido != null &&
            pedidoSendProgress(pedido.idPedido, products).isComplete,
      )
      .toList();
}
