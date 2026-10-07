import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/features/home/presentation/widgets/operational_summary_card.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    SummaryMetric novedades = const SummaryMetric(count: 3),
  }) async {
    tester.view.physicalSize = const Size(720, 1280); // 360x640
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OperationalSummaryCard(
            expanded: true,
            onToggle: () {},
            productos: const SummaryMetric(count: 7079),
            ubicaciones: const SummaryMetric(count: 28),
            novedades: novedades,
            almacenes: const SummaryMetric(count: 2),
          ),
        ),
      ),
    ));
  }

  testWidgets('las métricas de productos y ubicaciones no llevan icono y ya '
      'no hay Terceros', (tester) async {
    await pump(tester);

    expect(find.byIcon(Icons.group_outlined), findsNothing);
    expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
    expect(find.byIcon(Icons.grid_view), findsNothing);
    expect(find.text('TERCEROS'), findsNothing);
    expect(find.text('PRODUCTOS'), findsOneWidget);
    expect(find.text('UBICACIONES'), findsOneWidget);
  });

  testWidgets('novedades en espera: el letrero va DEBAJO del texto y cabe '
      'dentro del tile', (tester) async {
    await pump(
      tester,
      novedades: const SummaryMetric(count: 0, pending: true),
    );
    expect(tester.takeException(), isNull);

    final esperas = find.text('En espera');
    expect(esperas, findsOneWidget);

    final caption = tester.getRect(find.text('Registradas'));
    final tile = tester.getRect(
      find.ancestor(
        of: find.text('Registradas'),
        matching: find.byType(Container),
      ).first,
    );

    final novedades = tester.getRect(esperas);
    expect(novedades.top, greaterThanOrEqualTo(caption.bottom - 1));
    expect(novedades.left, closeTo(caption.left, 1)); // alineado al texto
    expect(novedades.right, lessThanOrEqualTo(tile.right));
  });

  testWidgets('con novedades cargadas muestra el contador a la derecha',
      (tester) async {
    await pump(tester);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('En espera'), findsNothing);
  });
}
