import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/shared/widgets/scanner_locationDest_widget.dart';

void main() {
  testWidgets('la ubicación de destino (hint) tiene altura para no cortarse',
      (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocationDestScannerWidget(
          isLocationDestOk: true,
          locationDestIsOk: false,
          locationIsOk: true,
          productIsOk: true,
          quantityIsOk: false,
          size: const Size(360, 640),
          muelleHint: 'a1/Packing',
          onValidateMuelle: (_) {},
          focusNode: focus,
          controller: controller,
          dropdownWidget: const Text('Ubicación de destino'),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('a1/Packing'), findsOneWidget);

    // El campo vive en un contenedor de altura fija: debe alcanzar para un
    // texto de 14 px con sus descendentes (la "g" de "Packing").
    final field = tester.getSize(find.byType(TextFormField));
    expect(field.height, greaterThanOrEqualTo(22));

    final hint = tester.getSize(find.text('a1/Packing'));
    expect(hint.height, lessThanOrEqualTo(field.height));
  });
}
