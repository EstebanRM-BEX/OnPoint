import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';

class _Host extends StatefulWidget {
  const _Host({super.key});

  @override
  State<_Host> createState() => HostState();
}

class HostState extends State<_Host> with LoadingDialogMixin {
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('host'));
}

void main() {
  Future<HostState> pump(WidgetTester tester) async {
    final key = GlobalKey<HostState>();
    await tester.pumpWidget(MaterialApp(home: _Host(key: key)));
    return key.currentState!;
  }

  testWidgets('show → hide → otro diálogo en el mismo frame: el loading se '
      'cierra y el otro diálogo sigue abierto', (tester) async {
    final host = await pump(tester);

    // Caso real de Devoluciones: GetProductLoading y GetProductSuccess llegan
    // juntos; el listener muestra el loading, lo oculta y abre otro diálogo
    // antes de que el loading llegue a montarse.
    host.showLoadingDialog('Buscando información...');
    host.hideLoadingDialog();
    showDialog(
      context: host.context,
      builder: (_) => const AlertDialog(content: Text('EDITAR PRODUCTO')),
    );
    await tester.pumpAndSettle();

    expect(find.text('EDITAR PRODUCTO'), findsOneWidget);
    expect(find.text('Buscando información...'), findsNothing);
    expect(host.isLoadingDialogVisible, isFalse);
  });

  testWidgets('show es idempotente y hide cierra solo el loading',
      (tester) async {
    final host = await pump(tester);

    host.showLoadingDialog('uno');
    host.showLoadingDialog('dos'); // no apila otro
    await tester.pump();
    expect(find.text('uno'), findsOneWidget);
    expect(find.text('dos'), findsNothing);

    host.hideLoadingDialog();
    await tester.pumpAndSettle();
    expect(find.text('uno'), findsNothing);
    expect(find.text('host'), findsOneWidget); // la pantalla sigue
    expect(host.isLoadingDialogVisible, isFalse);
  });

  testWidgets('hide sin diálogo abierto no hace nada', (tester) async {
    final host = await pump(tester);
    host.hideLoadingDialog();
    await tester.pumpAndSettle();
    expect(find.text('host'), findsOneWidget);
  });
}
