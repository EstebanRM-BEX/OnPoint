import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/validate_cluster/validate_cluster_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/validate/pedidos_ready_dialog.dart';
import 'package:wms_app/injection_container.dart';

class _MockValidateBloc
    extends MockBloc<ValidateClusterEvent, ValidateClusterState>
    implements ValidateClusterBloc {}

class _MockAudio extends Mock implements IAudioService {}

class _MockVibration extends Mock implements IVibrationService {}

void main() {
  late _MockValidateBloc bloc;
  late StreamController<ValidateClusterState> states;
  late _MockAudio audio;

  const pedidoA = PedidoValidate(
    batchId: 10,
    idPedido: 1,
    namePedido: '7081576',
    muelle: '25/Packing/MUA001',
    barcodeMuelle: 'AMUA001',
  );
  const pedidoB = PedidoValidate(
    batchId: 10,
    idPedido: 2,
    namePedido: '7081914',
    muelle: '25/Packing/MUA005',
    barcodeMuelle: 'AMUA005',
  );
  const products = [
    BatchProduct(pedidoId: 1, idMove: 101, isSendOdoo: 1),
    BatchProduct(pedidoId: 1, idMove: 102, isSendOdoo: 1),
    BatchProduct(pedidoId: 2, idMove: 201, isSendOdoo: 1),
  ];

  setUpAll(() {
    registerFallbackValue(const TapMarkPedidoEvent(
        batchId: 0, namePedido: '', listIdMove: []));
  });

  setUp(() {
    bloc = _MockValidateBloc();
    states = StreamController<ValidateClusterState>.broadcast();
    whenListen(bloc, states.stream, initialState: ValidateClusterInitial());
    audio = _MockAudio();
    when(() => audio.playErrorSound()).thenAnswer((_) async {});
    final vibration = _MockVibration();
    when(() => vibration.vibrate(duration: any(named: 'duration')))
        .thenAnswer((_) async {});
    getIt
      ..allowReassignment = true
      ..registerSingleton<IAudioService>(audio)
      ..registerSingleton<IVibrationService>(vibration);
  });

  tearDown(() => states.close());

  Future<void> pumpDialog(WidgetTester tester, {bool allowTap = false}) {
    return tester.pumpWidget(MaterialApp(
      home: BlocProvider<ValidateClusterBloc>.value(
        value: bloc,
        child: const Scaffold(
          body: PedidosReadyDialog(
            pedidos: [pedidoA, pedidoB],
            products: products,
            allowTapValidate: false,
          ),
        ),
      ),
    )).then((_) async {
      if (allowTap) {
        await tester.pumpWidget(MaterialApp(
          home: BlocProvider<ValidateClusterBloc>.value(
            value: bloc,
            child: const Scaffold(
              body: PedidosReadyDialog(
                pedidos: [pedidoA, pedidoB],
                products: products,
                allowTapValidate: true,
              ),
            ),
          ),
        ));
      }
    });
  }

  Future<void> scan(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextFormField), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    // Deja vencer el debounce del lector y el refoco diferido.
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('sin permiso no muestra el botón Validar', (tester) async {
    await pumpDialog(tester);
    expect(find.text('7081576'), findsOneWidget);
    expect(find.text('7081914'), findsOneWidget);
    expect(find.text('Validar'), findsNothing);
    expect(find.text('Ahora no'), findsOneWidget);
  });

  testWidgets('con permiso muestra Validar en cada pedido', (tester) async {
    await pumpDialog(tester, allowTap: true);
    expect(find.text('Validar'), findsNWidgets(2));
  });

  testWidgets('escanear el muelle valida ese pedido con sus movimientos',
      (tester) async {
    await pumpDialog(tester);

    await scan(tester, 'amua001');

    final event = verify(() => bloc.add(captureAny())).captured.single
        as TapMarkPedidoEvent;
    expect(event.namePedido, '7081576');
    expect(event.batchId, 10);
    expect(event.listIdMove, [101, 102]);

    states.add(const MarkPedidoValidatedSuccessState([]));
    await tester.pump();
    expect(find.text('Validado'), findsOneWidget);
    expect(find.text('Ahora no'), findsOneWidget,
        reason: 'aún queda un pedido sin validar');
  });

  testWidgets('al validar todos cambia a Continuar', (tester) async {
    await pumpDialog(tester);

    await scan(tester, 'AMUA001');
    states.add(const MarkPedidoValidatedSuccessState([pedidoA]));
    await tester.pump();

    await scan(tester, 'AMUA005');
    states.add(const MarkPedidoValidatedSuccessState([pedidoA, pedidoB]));
    await tester.pump();

    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('un muelle que no está en la lista muestra error y no valida',
      (tester) async {
    await pumpDialog(tester);

    await scan(tester, 'OTRO');

    verifyNever(() => bloc.add(any()));
    verify(() => audio.playErrorSound()).called(1);
    expect(find.textContaining('no corresponde'), findsOneWidget);
  });

  testWidgets('un error del backend se muestra y permite reintentar',
      (tester) async {
    await pumpDialog(tester);

    await scan(tester, 'AMUA001');
    states.add(ValidatePedidoErrorState('Pedido con pendientes'));
    await tester.pump();

    expect(find.text('Pedido con pendientes'), findsOneWidget);
    expect(find.text('Validado'), findsNothing);
  });

  testWidgets(
      'el lector recupera el foco si la pantalla de fondo se lo quita',
      (tester) async {
    final background = FocusNode();
    addTearDown(background.dispose);

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<ValidateClusterBloc>.value(
        value: bloc,
        child: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextField(focusNode: background),
                ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => BlocProvider<ValidateClusterBloc>.value(
                      value: bloc,
                      child: const PedidosReadyDialog(
                        pedidos: [pedidoA],
                        products: products,
                        allowTapValidate: false,
                      ),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));

    bool scannerFocused() => tester
        .widget<EditableText>(find.descendant(
          of: find.byType(PedidosReadyDialog),
          matching: find.byType(EditableText),
        ))
        .focusNode
        .hasFocus;

    await tester.tap(find.text('abrir'));
    // La pantalla de fondo pide foco en el mismo frame en que abre el diálogo.
    background.requestFocus();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));
    expect(scannerFocused(), isTrue);

    // ...y otra vez con retraso, como los Future.delayed de scan_product.
    background.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(scannerFocused(), isTrue);
  });

  testWidgets(
      'el lector toma el foco al cerrarse un loader abierto encima del diálogo',
      (tester) async {
    late BuildContext pageContext;
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<ValidateClusterBloc>.value(
        value: bloc,
        child: Scaffold(
          body: Builder(builder: (context) {
            pageContext = context;
            return const SizedBox.expand();
          }),
        ),
      ),
    ));

    showDialog(
      context: pageContext,
      builder: (_) => BlocProvider<ValidateClusterBloc>.value(
        value: bloc,
        child: const PedidosReadyDialog(
          pedidos: [pedidoA],
          products: products,
          allowTapValidate: false,
        ),
      ),
    );
    // Loader que se abre encima en el mismo frame (LoadingDialogMixin).
    showDialog(
      context: pageContext,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    Navigator.of(pageContext).pop(); // se cierra el loader
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final scanner = tester.widget<EditableText>(find.descendant(
      of: find.byType(PedidosReadyDialog),
      matching: find.byType(EditableText),
    ));
    expect(scanner.focusNode.hasFocus, isTrue);
  });

  testWidgets(
      'con un pedido desplegado el lector se apaga; al cerrarlo se prende',
      (tester) async {
    await pumpDialog(tester);
    await tester.pump(const Duration(milliseconds: 200));

    bool scannerFocused() => tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode
        .hasFocus;
    expect(scannerFocused(), isTrue, reason: 'todas cerradas: lector activo');

    await tester.tap(find.text('7081576')); // desplegar
    await tester.pumpAndSettle();
    expect(scannerFocused(), isFalse);

    await scan(tester, 'AMUA001');
    verifyNever(() => bloc.add(any()));
    expect(scannerFocused(), isFalse,
        reason: 'el foco vuelve a estacionarse fuera del lector');

    await tester.tap(find.text('7081576')); // cerrar
    await tester.pumpAndSettle();
    expect(scannerFocused(), isTrue);

    await scan(tester, 'AMUA001');
    verify(() => bloc.add(any(that: isA<TapMarkPedidoEvent>()))).called(1);
  });

  testWidgets('cada pedido despliega sus productos', (tester) async {
    await pumpDialog(tester);
    await tester.tap(find.text('7081914'));
    await tester.pumpAndSettle();
    expect(find.text('Listo para validar'), findsNWidgets(2));
    expect(find.text('Sin novedad'), findsOneWidget,
        reason: 'el pedido 7081914 tiene 1 producto');
  });
}
