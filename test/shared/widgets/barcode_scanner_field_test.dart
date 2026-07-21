import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;
  late List<String> scans;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
    scans = [];
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Widget buildScanner({
    Duration debounce = const Duration(milliseconds: 200),
    bool clearOnScan = false,
    bool refocusOnScan = false,
    bool autofocus = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BarcodeScannerField(
          controller: controller,
          focusNode: focusNode,
          debounce: debounce,
          clearOnScan: clearOnScan,
          refocusOnScan: refocusOnScan,
          autofocus: autofocus,
          onBarcodeScanned: (value, context) => scans.add(value),
        ),
      ),
    );
  }

  group('BarcodeScannerField — disparo por debounce (sin sufijo Enter)', () {
    testWidgets('dispara una sola vez después del debounce', (tester) async {
      await tester.pumpWidget(buildScanner());

      await tester.enterText(find.byType(TextFormField), 'ABC123');
      expect(scans, isEmpty, reason: 'no debe disparar antes del debounce');

      await tester.pump(const Duration(milliseconds: 200));
      expect(scans, ['ABC123']);
    });

    testWidgets('teclas dentro de la ventana de debounce se acumulan en un solo disparo',
        (tester) async {
      await tester.pumpWidget(buildScanner());

      await tester.enterText(find.byType(TextFormField), 'ABC');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextFormField), 'ABC123');
      await tester.pump(const Duration(milliseconds: 200));

      expect(scans, ['ABC123'],
          reason: 'el debounce se reinicia con cada tecla');
    });

    testWidgets('buffer vacío o solo espacios no dispara', (tester) async {
      await tester.pumpWidget(buildScanner());

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.pump(const Duration(milliseconds: 300));

      expect(scans, isEmpty);
    });

    testWidgets('respeta un debounce personalizado', (tester) async {
      await tester.pumpWidget(
          buildScanner(debounce: const Duration(milliseconds: 500)));

      await tester.enterText(find.byType(TextFormField), 'ABC123');
      await tester.pump(const Duration(milliseconds: 300));
      expect(scans, isEmpty, reason: 'aún dentro del debounce de 500ms');

      await tester.pump(const Duration(milliseconds: 200));
      expect(scans, ['ABC123']);
    });
  });

  group('BarcodeScannerField — disparo por sufijo Enter', () {
    testWidgets('dispara inmediato con Enter, sin esperar debounce',
        (tester) async {
      await tester.pumpWidget(buildScanner());

      await tester.enterText(find.byType(TextFormField), 'ABC123');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(scans, ['ABC123']);
    });

    testWidgets('Enter cancela el debounce pendiente (no doble disparo)',
        (tester) async {
      await tester.pumpWidget(buildScanner());

      await tester.enterText(find.byType(TextFormField), 'ABC123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 300));

      expect(scans, ['ABC123'],
          reason: 'el timer cancelado no debe volver a disparar');
    });

    testWidgets(
        'GUARD: debounce vencido + Enter tardío del mismo buffer = un solo disparo',
        (tester) async {
      await tester.pumpWidget(buildScanner());

      await tester.enterText(find.byType(TextFormField), 'ABC123');
      // El debounce vence primero (escáner lento en mandar el Enter)
      await tester.pump(const Duration(milliseconds: 200));
      expect(scans, ['ABC123']);

      // El Enter llega tarde con el mismo buffer
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(scans, ['ABC123'],
          reason: 'el mismo buffer no debe procesarse dos veces');
    });

    testWidgets('doble Enter consecutivo dispara una sola vez', (tester) async {
      await tester.pumpWidget(buildScanner());

      await tester.enterText(find.byType(TextFormField), 'ABC123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(scans, ['ABC123']);
    });
  });

  group('BarcodeScannerField — re-escaneo legítimo', () {
    testWidgets('el mismo código en escaneos consecutivos dispara cada vez',
        (tester) async {
      await tester.pumpWidget(buildScanner());

      // Primer escaneo
      await tester.enterText(find.byType(TextFormField), 'ABC123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(scans, ['ABC123']);

      // La pantalla limpia el buffer (como hacen las pantallas actuales)
      controller.clear();
      await tester.pump();

      // Segundo escaneo del MISMO producto (flujo normal de conteo)
      await tester.enterText(find.byType(TextFormField), 'ABC123');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(scans, ['ABC123', 'ABC123'],
          reason: 'repetir código en escaneos distintos es flujo válido');
    });
  });

  group('BarcodeScannerField — opciones opt-in', () {
    testWidgets('clearOnScan limpia el buffer tras disparar', (tester) async {
      await tester.pumpWidget(buildScanner(clearOnScan: true));

      await tester.enterText(find.byType(TextFormField), 'ABC123');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(scans, ['ABC123']);
      expect(controller.text, isEmpty);
    });

    testWidgets('con clearOnScan, re-escanear el mismo código dispara de nuevo',
        (tester) async {
      await tester.pumpWidget(buildScanner(clearOnScan: true));

      await tester.enterText(find.byType(TextFormField), 'ABC123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.enterText(find.byType(TextFormField), 'ABC123');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(scans, ['ABC123', 'ABC123']);
    });

    testWidgets('refocusOnScan recupera el foco tras disparar', (tester) async {
      await tester.pumpWidget(buildScanner(refocusOnScan: true));

      await tester.enterText(find.byType(TextFormField), 'ABC123');
      focusNode.unfocus();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(); // procesa el microtask del refocus

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('autofocus=false no roba el foco al montarse', (tester) async {
      await tester.pumpWidget(buildScanner(autofocus: false));
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('autofocus=true (default) toma el foco al montarse',
        (tester) async {
      await tester.pumpWidget(buildScanner());
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });
  });

  group('BarcodeScannerField — ciclo de vida', () {
    testWidgets('el valor entregado llega sin espacios en los bordes',
        (tester) async {
      await tester.pumpWidget(buildScanner());

      await tester.enterText(find.byType(TextFormField), '  ABC123  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(scans, ['ABC123']);
    });

    testWidgets('desmontar el widget cancela el debounce pendiente',
        (tester) async {
      await tester.pumpWidget(buildScanner());

      await tester.enterText(find.byType(TextFormField), 'ABC123');
      // Se desmonta antes de que venza el debounce
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(scans, isEmpty,
          reason: 'ningún callback debe dispararse tras dispose');
      expect(tester.takeException(), isNull);
    });

    testWidgets('el teclado del sistema nunca se solicita', (tester) async {
      await tester.pumpWidget(buildScanner());

      final field = tester.widget<TextField>(find.byType(TextField));
      // TextInputType.none: el wedge escribe pero el teclado no aparece
      expect(field.keyboardType, TextInputType.none);
    });
  });
}
