import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';
import 'package:wms_app/features/picking_cluster/presentation/utils/pedidos_ready_to_validate.dart';

BatchProduct _product(int pedidoId, int? isSendOdoo) =>
    BatchProduct(pedidoId: pedidoId, isSendOdoo: isSendOdoo);

void main() {
  const p1 = PedidoValidate(idPedido: 1, namePedido: 'P1');
  const p2 = PedidoValidate(idPedido: 2, namePedido: 'P2');
  const p3 = PedidoValidate(idPedido: 3, namePedido: 'P3', isValidated: true);
  const p4 = PedidoValidate(idPedido: 4, namePedido: 'P4');

  test('solo ofrece pedidos no validados con todos sus productos enviados',
      () {
    final products = [
      _product(1, 1), _product(1, 1), // P1: completo
      _product(2, 1), _product(2, 0), // P2: uno pendiente offline
      _product(3, 1), // P3: ya validado
      // P4: sin productos en el batch
    ];

    final ready = pedidosReadyToValidate([p1, p2, p3, p4], products);

    expect(ready.map((p) => p.namePedido), ['P1']);
  });

  test('un producto sin enviar (null) bloquea el pedido', () {
    final ready =
        pedidosReadyToValidate([p1], [_product(1, 1), _product(1, null)]);
    expect(ready, isEmpty);
  });

  group('pedidoSendProgress', () {
    test('cuenta solo los productos con is_send_odoo == 1', () {
      final progress = pedidoSendProgress(1, [
        _product(1, 1),
        _product(1, 0),
        _product(1, null),
        _product(1, 1),
        _product(2, 1),
      ]);
      expect(progress.sent, 2);
      expect(progress.total, 4);
      expect(progress.missing, 2);
      expect(progress.ratio, 0.5);
      expect(progress.isComplete, isFalse);
    });

    test('pedido sin productos no está completo', () {
      final progress = pedidoSendProgress(9, [_product(1, 1)]);
      expect(progress.total, 0);
      expect(progress.ratio, 0);
      expect(progress.isComplete, isFalse);
    });
  });
}
