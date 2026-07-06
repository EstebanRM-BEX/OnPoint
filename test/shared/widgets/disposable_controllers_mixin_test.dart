import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/shared/widgets/disposable_controllers_mixin.dart';

class _PantallaConMixin extends StatefulWidget {
  const _PantallaConMixin();

  @override
  State<_PantallaConMixin> createState() => _PantallaConMixinState();
}

class _PantallaConMixinState extends State<_PantallaConMixin>
    with DisposableControllersMixin {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  @override
  List<ChangeNotifier> get disposables => [controller, focusNode];

  @override
  Widget build(BuildContext context) => Scaffold(
      body: TextField(controller: controller, focusNode: focusNode));
}

void main() {
  testWidgets(
      'DisposableControllersMixin libera controllers y nodes al destruir el State',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _PantallaConMixin()));

    final state = tester.state<_PantallaConMixinState>(
        find.byType(_PantallaConMixin));
    final controller = state.controller;
    final focusNode = state.focusNode;

    // Desmontar la pantalla debe disparar el dispose del mixin.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    // Un ChangeNotifier ya liberado lanza assert en debug al usarlo.
    expect(() => controller.addListener(() {}), throwsFlutterError);
    expect(() => focusNode.addListener(() {}), throwsFlutterError);
  });
}
