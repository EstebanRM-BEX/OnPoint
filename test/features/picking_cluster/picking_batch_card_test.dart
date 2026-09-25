import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/picking_batch.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/batch_pedidos_dialog.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/picking_batch_card.dart';

void main() {
  late int batchTaps;

  Future<void> pumpCard(WidgetTester tester, List<PedidoValidate> pedidos,
      {double width = 390}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    batchTaps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: PickingBatchCard(
            batch: PickingBatch(
              name: 'BATCH/00642',
              countItems: 3,
              totalQuantityItems: 10,
              listItems: const [],
              pedidosValidate: pedidos,
            ),
            onTap: () => batchTaps++,
          ),
        ),
      ),
    ));
  }

  const pedidos = [
    PedidoValidate(
        idPedido: 1,
        namePedido: '7081576',
        muelle: '25/Packing/MUA001',
        barcodeMuelle: 'AMUA001',
        isValidated: true),
    PedidoValidate(
        idPedido: 2,
        namePedido: '7081914',
        muelle: '25/Packing/MUA005',
        barcodeMuelle: 'AMUA005'),
  ];

  testWidgets('tocar Pedidos abre el diálogo y no abre el batch',
      (tester) async {
    await pumpCard(tester, pedidos);

    await tester.tap(find.text('Pedidos'));
    await tester.pumpAndSettle();

    expect(batchTaps, 0);
    expect(find.byType(BatchPedidosDialog), findsOneWidget);
    expect(find.text('Pedidos de BATCH/00642'), findsOneWidget);
    expect(find.text('2 pedido(s) · 1 validado(s)'), findsOneWidget);
    expect(find.text('7081576'), findsOneWidget);
    expect(find.text('Validado'), findsOneWidget);
    expect(find.text('Por validar'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(BatchPedidosDialog), findsNothing);
  });

  testWidgets('tocar fuera de Pedidos sigue abriendo el batch',
      (tester) async {
    await pumpCard(tester, pedidos);
    await tester.tap(find.text('BATCH/00642'));
    expect(batchTaps, 1);
  });

  testWidgets('sin pedidos el recuadro no es tocable', (tester) async {
    await pumpCard(tester, const []);
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await tester.tap(find.text('Pedidos'));
    await tester.pumpAndSettle();
    expect(find.byType(BatchPedidosDialog), findsNothing);
    expect(batchTaps, 1, reason: 'el toque cae en la tarjeta');
  });

  testWidgets('el diálogo no desborda en pantallas angostas', (tester) async {
    await pumpCard(tester, pedidos, width: 300);
    await tester.tap(find.text('Pedidos'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
