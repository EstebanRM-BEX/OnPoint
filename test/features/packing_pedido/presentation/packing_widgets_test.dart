import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/detail/packing_pedido_detail_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/producto_pack_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/backorder_pack_dialog.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/list/pedido_pack_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/scan/cantidad_scan_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/por_hacer_tab.dart';
import 'package:wms_app/injection_container.dart';

import '../domain/packing_test_data.dart';

class FakeAudio implements IAudioService {
  int errores = 0;
  @override
  Future<void> playErrorSound() async => errores++;
  @override
  Future<void> stopSound() async {}
  @override
  Future<void> dispose() async {}
}

class FakeVibration implements IVibrationService {
  @override
  Future<void> vibrate({int duration = 500}) async {}
}

class MockDetailBloc
    extends MockBloc<PackingPedidoDetailEvent, PackingPedidoDetailState>
    implements PackingPedidoDetailBloc {}

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late FakeAudio audio;

  setUp(() {
    audio = FakeAudio();
    if (getIt.isRegistered<IAudioService>()) {
      getIt.unregister<IAudioService>();
    }
    if (!getIt.isRegistered<IVibrationService>()) {
      getIt.registerSingleton<IVibrationService>(FakeVibration());
    }
    getIt.registerSingleton<IAudioService>(audio);
  });

  testWidgets('PedidoPackCard: prioridad, faltantes en rojo y tap', (t) async {
    var tocado = false;
    await t.pumpWidget(
      app(
        PedidoPackCard(
          pedido: const PedidoPack(id: 1, name: 'WH/PACK/1', priority: '1'),
          onTap: () => tocado = true,
        ),
      ),
    );
    expect(find.text('WH/PACK/1'), findsOneWidget);
    expect(find.text('Alta'), findsOneWidget);
    expect(find.text('Sin responsable'), findsOneWidget);
    expect(find.text('Sin proveedor'), findsOneWidget);
    await t.tap(find.text('WH/PACK/1'));
    expect(tocado, isTrue);
  });

  testWidgets('ProductoPackCard: novedad, checkbox y separado parcial', (
    t,
  ) async {
    bool? marcado;
    await t.pumpWidget(
      app(
        ProductoPackCard(
          producto: productoTest(
            estado: EstadoProductoPacking.listo,
            certificado: true,
            quantitySeparate: 4,
          ).copyWith(observation: 'Faltante'),
          seleccionado: false,
          onSeleccionar: (v) => marcado = v,
        ),
      ),
    );
    expect(find.text('Faltante'), findsOneWidget);
    expect(find.text('Separado: 4'), findsOneWidget);
    await t.tap(find.byType(Checkbox));
    expect(marcado, isTrue);
  });

  testWidgets(
    'ProductoPackCard: sin barcode no muestra la fila; pedido e imprimir',
    (t) async {
      var impreso = 0;
      await t.pumpWidget(
        app(
          ProductoPackCard(
            producto: ProductoPacking(
              id: 1,
              pedidoId: 13,
              idMove: 100,
              idProduct: 500,
              productName: 'Sin código',
              unidades: 'Und',
              quantity: 2,
            ),
            mostrarPedido: true,
            onImprimir: () => impreso++,
          ),
        ),
      );
      expect(find.textContaining('Barcode'), findsNothing);
      expect(find.text('Unidad de medida: '), findsOneWidget);
      expect(find.text('Und'), findsOneWidget);
      expect(find.text('Cantidad: 2'), findsOneWidget);
      expect(find.text('Pedido: '), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
      await t.tap(find.byIcon(Icons.print));
      expect(impreso, 1);
    },
  );

  group('PorHacerTab', () {
    late MockDetailBloc bloc;
    final producto = productoTest(id: 7);
    final state = PackingPedidoDetailState(
      pedidoId: 10,
      status: DetallePackStatus.listo,
      detalle: PedidoPackDetalle(
        pedido: pedidoTest,
        porHacer: [producto],
        barcodes: const [
          BarcodeProductoPacking(
            idMove: 100,
            idProduct: 500,
            barcode: 'CAJA12',
          ),
        ],
      ),
    );

    setUp(() {
      bloc = MockDetailBloc();
      when(() => bloc.state).thenReturn(state);
    });

    Future<void> montar(
      WidgetTester t,
      void Function(ProductoPacking, bool) onAbrir,
    ) => t.pumpWidget(
      MaterialApp(
        home: BlocProvider<PackingPedidoDetailBloc>.value(
          value: bloc,
          child: PorHacerTab(
            state: state,
            activo: true,
            onAbrir: onAbrir,
            onEmpacar: () {},
          ),
        ),
      ),
    );

    testWidgets('escanear un código alterno abre el producto en cantidad', (
      t,
    ) async {
      ProductoPacking? abierto;
      bool? escaneado;
      await montar(t, (p, e) {
        abierto = p;
        escaneado = e;
      });
      await t.pump();
      await t.enterText(find.byType(TextFormField).first, 'CAJA12');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(abierto?.id, 7);
      expect(escaneado, isTrue);
    });

    testWidgets('código desconocido suena error y no abre nada', (t) async {
      var abiertos = 0;
      await montar(t, (_, __) => abiertos++);
      await t.pump();
      await t.enterText(find.byType(TextFormField).first, 'NADA');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(abiertos, 0);
      expect(audio.errores, 1);
      expect(find.text('Código no encontrado en por hacer'), findsOneWidget);
    });

    testWidgets('tocar el producto abre el flujo completo', (t) async {
      bool? escaneado;
      await montar(t, (_, e) => escaneado = e);
      await t.tap(find.text('Producto A'));
      expect(escaneado, isFalse);
    });
  });

  group('showBackorderPackDialog', () {
    Future<bool?> abrir(
      WidgetTester t, {
      required double progreso,
      required String politica,
      required String boton,
    }) async {
      bool? resultado;
      var cerrado = false;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultado = await showBackorderPackDialog(
                  context,
                  progresoEmpacado: progreso,
                  hayPendientes: false,
                  createBackorder: politica,
                );
                cerrado = true;
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ElevatedButton, boton));
      await t.pumpAndSettle();
      expect(cerrado, isTrue);
      return resultado;
    }

    testWidgets('ask e incompleto ofrece crear backorder', (t) async {
      expect(
        await abrir(
          t,
          progreso: 50,
          politica: 'ask',
          boton: 'Confirmar y Crear un Backorder',
        ),
        isTrue,
      );
    });

    testWidgets('ask: confirmar sin backorder devuelve false', (t) async {
      expect(
        await abrir(
          t,
          progreso: 50,
          politica: 'ask',
          boton: 'Confirmar Pedido',
        ),
        isFalse,
      );
    });

    testWidgets('always crea backorder al confirmar', (t) async {
      expect(
        await abrir(
          t,
          progreso: 50,
          politica: 'always',
          boton: 'Confirmar Pedido',
        ),
        isTrue,
      );
    });

    testWidgets('cancelar devuelve null', (t) async {
      expect(
        await abrir(t, progreso: 100, politica: 'ask', boton: 'Cancelar'),
        isNull,
      );
    });
  });

  testWidgets('CantidadScanCard: aplicar deshabilitado fuera del paso', (
    t,
  ) async {
    var aplicado = 0;
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    Widget card({required bool activo}) => app(
      CantidadScanCard(
        activo: activo,
        cantidad: 3,
        total: 10,
        unidades: 'Und',
        editando: false,
        puedeEditar: true,
        ocupado: false,
        controller: controller,
        focusNode: focus,
        onAlternarEdicion: () {},
        onAplicar: () => aplicado++,
      ),
    );

    await t.pumpWidget(card(activo: false));
    await t.tap(find.text('APLICAR CANTIDAD'));
    expect(aplicado, 0);

    await t.pumpWidget(card(activo: true));
    await t.tap(find.text('APLICAR CANTIDAD'));
    expect(aplicado, 1);
    expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
  });
}
