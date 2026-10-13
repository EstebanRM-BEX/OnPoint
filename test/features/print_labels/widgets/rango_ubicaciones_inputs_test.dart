import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/features/print_labels/presentation/bloc/print_labels_bloc.dart';
import 'package:wms_app/features/print_labels/presentation/widgets/rango_ubicaciones_inputs.dart';

void main() {
  late PrintLabelsBloc bloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bloc = PrintLabelsBloc();
  });

  tearDown(() => bloc.close());

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: bloc,
          child: const RangoUbicacionesInputs(),
        ),
      ),
    ));
    await tester.pump();
  }

  /// Lectores invisibles: los dos primeros TextFormField del árbol.
  Finder lector(int i) => find.byType(TextFormField).at(i);
  bool tieneFoco(WidgetTester tester, int i) => tester
      .widget<EditableText>(
          find.descendant(of: lector(i), matching: find.byType(EditableText)))
      .focusNode
      .hasFocus;

  Future<void> escanear(WidgetTester tester, int i, String codigo) async {
    await tester.showKeyboard(lector(i));
    tester.testTextInput.enterText(codigo);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  testWidgets('escanear Inicio llena el campo y pasa el lector a Fin',
      (tester) async {
    await montar(tester);
    expect(tieneFoco(tester, 0), isTrue);

    await escanear(tester, 0, 'A0101');
    expect(bloc.rangeStartController.text, 'A0101');
    expect(tieneFoco(tester, 1), isTrue);

    await escanear(tester, 1, 'B0102');
    expect(bloc.rangeEndController.text, 'B0102');
    expect(bloc.rangeStartController.text, 'A0101');
  });
}
