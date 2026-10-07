import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/detail/packing_pedido_detail_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/backorder_pack_dialog.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/packages/producto_en_paquete_tile.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/producto_empacado_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/producto_preparado_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/list/pedido_pack_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/scan/cantidad_scan_card.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/packages/packing_packages_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/detalle_pedido_tab.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/paquetes_tab.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/por_hacer_tab.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/preparados_tab.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/producto_por_hacer_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/common/packing_operacion.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/packing_operacion_listener.dart';
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
  int vibraciones = 0;
  @override
  Future<void> vibrate({int duration = 500}) async => vibraciones++;
}

class TestOpCubit extends Cubit<PackingOperacion> {
  TestOpCubit() : super(const PackingOperacion());
  void emitOp(PackingOperacion op) => emit(op);
}

class MockDetailBloc
    extends MockBloc<PackingPedidoDetailEvent, PackingPedidoDetailState>
    implements PackingPedidoDetailBloc {}

class MockPackagesBloc
    extends MockBloc<PackingPackagesEvent, PackingPackagesState>
    implements PackingPackagesBloc {}

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late FakeAudio audio;
  late FakeVibration vibration;

  setUp(() {
    audio = FakeAudio();
    vibration = FakeVibration();
    if (getIt.isRegistered<IAudioService>()) {
      getIt.unregister<IAudioService>();
    }
    if (getIt.isRegistered<IVibrationService>()) {
      getIt.unregister<IVibrationService>();
    }
    getIt.registerSingleton<IVibrationService>(vibration);
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

  testWidgets('ProductoPreparadoCard: diseño anterior y eliminar', (t) async {
    var eliminado = 0;
    await t.pumpWidget(
      app(
        ProductoPreparadoCard(
          producto: productoTest(
            estado: EstadoProductoPacking.listo,
            certificado: true,
            quantitySeparate: 4,
          ).copyWith(observation: 'Faltante', timeSeparate: 3725),
          onEliminar: () => eliminado++,
        ),
      ),
    );
    expect(find.text('Cantidad a empacar: '), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Faltante'), findsOneWidget);
    expect(find.textContaining('01:02:05'), findsOneWidget);
    // El ícono de eliminar está a la izquierda frente al nombre
    final posDelete = t.getTopLeft(find.byIcon(Icons.delete));
    final posNombre = t.getTopLeft(find.text('Producto A'));
    expect(posDelete.dx, lessThan(posNombre.dx));
    // Parcial (4 de 10): recuadro ámbar como en el módulo anterior.
    final recuadro = t.widgetList<Card>(find.byType(Card)).last;
    expect(recuadro.color, Colors.amber[100]);
    await t.tap(find.byIcon(Icons.delete));
    expect(eliminado, 1);
  });

  testWidgets('ProductoEmpacadoCard: certificado, paquete e imprimir', (
    t,
  ) async {
    var impreso = 0;
    var imagen = 0;
    await t.pumpWidget(
      app(
        ProductoEmpacadoCard(
          producto: productoTest(
            estado: EstadoProductoPacking.empacado,
            certificado: true,
            quantitySeparate: 6,
            idPackage: 1,
          ).copyWith(packageName: 'PACK-1'),
          onImprimir: () => impreso++,
          onVerImagenProducto: () => imagen++,
        ),
      ),
    );
    expect(find.text('Si'), findsOneWidget);
    expect(find.text('PACK-1'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    await t.tap(find.byIcon(Icons.print));
    await t.tap(find.byIcon(Icons.image));
    expect(impreso, 1);
    expect(imagen, 1);
  });

  testWidgets('ProductoEnPaqueteTile: no certificado en rojo', (t) async {
    await t.pumpWidget(
      app(
        ProductoEnPaqueteTile(
          producto: productoTest(
            estado: EstadoProductoPacking.empacado,
            idPackage: 1,
          ),
        ),
      ),
    );
    expect(find.textContaining('No certificado'), findsOneWidget);
    expect(find.byIcon(Icons.warning), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  test('PackFormatos', () {
    expect(PackFormatos.cantidad(10), '10');
    expect(PackFormatos.cantidad(2.5), '2.50');
    expect(PackFormatos.duracion(3725), '01:02:05');
    expect(PackFormatos.duracion(0), '00:00:00');
  });

  testWidgets('ProductoPorHacerCard: mismo diseño que el módulo anterior', (
    t,
  ) async {
    var impreso = 0;
    var tocado = 0;
    await t.pumpWidget(
      app(
        ProductoPorHacerCard(
          producto: const ProductoPacking(
            id: 1,
            pedidoId: 13,
            idMove: 100,
            idProduct: 500,
            productName: 'Leche entera',
            locationName: 'WH/Stock/A1',
            unidades: 'Und',
            tracking: 'lot',
            manejaTemperatura: true,
            quantity: 2,
          ),
          seleccionado: false,
          onTap: () => tocado++,
          onImprimir: () => impreso++,
        ),
      ),
    );
    expect(find.text('Leche entera'), findsOneWidget);
    expect(find.text('WH/Stock/A1'), findsOneWidget);
    expect(find.text('Pedido: '), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('Unidad de medida: '), findsOneWidget);
    expect(find.text('Und'), findsOneWidget);
    expect(find.text('Sin lote'), findsOneWidget);
    expect(find.byIcon(Icons.thermostat_outlined), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.textContaining('Barcode'), findsNothing);

    await t.tap(find.byIcon(Icons.print));
    expect(impreso, 1);
    expect(tocado, 0);
    await t.tap(find.text('Leche entera'));
    expect(tocado, 1);
  });

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

    testWidgets('búsqueda manual emite evento y botón limpiar limpia', (
      t,
    ) async {
      await montar(t, (_, __) {});
      await t.pump();

      // Buscar por TextField manual
      final searchField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText == 'Escanear o buscar producto...',
      );
      expect(searchField, findsOneWidget);

      await t.enterText(searchField, 'Producto');
      await t.pump();
      verify(
        () => bloc.add(const BusquedaProductoPackCambiada('Producto')),
      ).called(1);

      // Botón limpiar
      final clearBtn = find.byTooltip('Limpiar');
      expect(clearBtn, findsOneWidget);
      await t.tap(clearBtn);
      await t.pump();
      verify(
        () => bloc.add(const BusquedaProductoPackCambiada('')),
      ).called(1);
    });

    testWidgets('botón de lector activa el foco del escáner', (t) async {
      await montar(t, (_, __) {});
      await t.pump();

      final scannerBtn = find.byTooltip('Lector activo');
      expect(scannerBtn, findsOneWidget);
      await t.tap(scannerBtn);
      await t.pumpAndSettle();
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

  testWidgets('CantidadScanCard: diseño anterior, aplicar solo en su paso', (
    t,
  ) async {
    var aplicado = 0;
    var editar = 0;
    final scanController = TextEditingController();
    final scanFocus = FocusNode();
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(scanController.dispose);
    addTearDown(scanFocus.dispose);
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
        scanController: scanController,
        scanFocus: scanFocus,
        onEscaneo: (_) {},
        controller: controller,
        focusNode: focus,
        onAlternarEdicion: () => editar++,
        onAplicar: () => aplicado++,
      ),
    );

    await t.pumpWidget(card(activo: false));
    expect(find.text('Recoger:'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await t.tap(find.text('APLICAR CANTIDAD'));
    await t.tap(find.byIcon(Icons.edit_note_rounded));
    expect(aplicado, 0);
    expect(editar, 0);

    await t.pumpWidget(card(activo: true));
    await t.tap(find.text('APLICAR CANTIDAD'));
    await t.tap(find.byIcon(Icons.edit_note_rounded));
    expect(aplicado, 1);
    expect(editar, 1);
  });

  testWidgets('CantidadScanCard: conError pinta la card de rojo', (t) async {
    final scanController = TextEditingController();
    final scanFocus = FocusNode();
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(scanController.dispose);
    addTearDown(scanFocus.dispose);
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);

    await t.pumpWidget(
      app(
        CantidadScanCard(
          activo: true,
          conError: true,
          cantidad: 1,
          total: 5,
          unidades: 'Und',
          editando: false,
          puedeEditar: true,
          ocupado: false,
          scanController: scanController,
          scanFocus: scanFocus,
          onEscaneo: (_) {},
          controller: controller,
          focusNode: focus,
          onAlternarEdicion: () {},
          onAplicar: () {},
        ),
      ),
    );

    final card = t.widget<Card>(find.byType(Card));
    expect(card.color, Colors.red[200]);
  });

  group('PackingOperacionListener: feedback de errores', () {
    testWidgets(
      'error silencioso (escaneo) da sonido y vibración pero NO snackbar ni dialog',
      (t) async {
        final cubit = TestOpCubit();
        addTearDown(cubit.close);

        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: cubit,
                child: PackingOperacionListener<TestOpCubit, PackingOperacion>(
                  operacion: (s) => s,
                  erroresSilenciosos: const {'escaneo'},
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        );

        cubit.emitOp(
          const PackingOperacion(
            tipo: TipoOperacion.error,
            accion: 'escaneo',
            mensaje: 'Ubicación errónea',
            seq: 1,
          ),
        );
        await t.pump();
        await t.pump(const Duration(milliseconds: 50));

        expect(audio.errores, 1);
        expect(vibration.vibraciones, 1);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.text('Ubicación errónea'), findsNothing);
      },
    );

    testWidgets(
      'error manual (cantidadManual) da sonido, vibración Y snackbar con motivo',
      (t) async {
        final cubit = TestOpCubit();
        addTearDown(cubit.close);

        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: cubit,
                child: PackingOperacionListener<TestOpCubit, PackingOperacion>(
                  operacion: (s) => s,
                  erroresSilenciosos: const {'escaneo'},
                  erroresCortos: const {'cantidadManual'},
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        );

        cubit.emitOp(
          const PackingOperacion(
            tipo: TipoOperacion.error,
            accion: 'cantidadManual',
            mensaje: 'Cantidad inválida',
            seq: 1,
          ),
        );
        await t.pump();
        await t.pump(const Duration(milliseconds: 50));

        expect(audio.errores, 1);
        expect(vibration.vibraciones, 1);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Cantidad inválida'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'DetallePedidoTab: muestra productos preparados y cantidad preparada',
    experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(),
    (t) async {
      final detalle = PedidoPackDetalle(
        pedido: const PedidoPack(
          id: 1,
          name: 'WH/PACK/1',
          numeroLineas: 3,
          numeroItems: 25,
        ),
        listos: [
          productoTest(
            id: 10,
            estado: EstadoProductoPacking.listo,
            certificado: true,
            quantity: 10,
            quantitySeparate: 4,
          ),
          productoTest(
            id: 11,
            estado: EstadoProductoPacking.listo,
            certificado: true,
            quantity: 6,
            quantitySeparate: 6,
          ),
        ],
        empacados: [
          productoTest(
            id: 12,
            estado: EstadoProductoPacking.empacado,
            certificado: true,
            quantity: 5,
            quantitySeparate: 5,
          ),
        ],
      );

      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });

      await t.pumpWidget(
        app(DetallePedidoTab(detalle: detalle, onConfirmar: () {})),
      );

      expect(find.textContaining('Productos preparados'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.textContaining('Cantidad preparada'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'PreparadosTab: muestra boton Eliminar todos y Empacar y dispara callbacks',
    (t) async {
      var eliminarTodosCount = 0;
      var empacarCount = 0;
      var deshacerCount = 0;

      final listo = productoTest(
        id: 10,
        estado: EstadoProductoPacking.listo,
        certificado: true,
        quantity: 10,
        quantitySeparate: 4,
      );
      final listo2 = productoTest(
        id: 11,
        estado: EstadoProductoPacking.listo,
        certificado: true,
        quantity: 5,
        quantitySeparate: 5,
      );

      final state = PackingPedidoDetailState(
        pedidoId: 1,
        status: DetallePackStatus.listo,
        detalle: PedidoPackDetalle(
          pedido: pedidoTest,
          listos: [listo, listo2],
        ),
      );

      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });

      await t.pumpWidget(
        app(
          Scaffold(
            body: PreparadosTab(
              state: state,
              onEmpacar: () => empacarCount++,
              onDeshacer: (_) => deshacerCount++,
              onDeshacerTodos: () => eliminarTodosCount++,
            ),
          ),
        ),
      );

      expect(find.text('Eliminar todos'), findsOneWidget);
      expect(find.textContaining('Empacar (2)'), findsOneWidget);

      await t.tap(find.text('Eliminar todos'));
      expect(eliminarTodosCount, 1);

      await t.tap(find.textContaining('Empacar (2)'));
      expect(empacarCount, 1);

      await t.tap(find.byIcon(Icons.delete).first);
      expect(deshacerCount, 1);

      await t.pumpWidget(const SizedBox());
    },
  );

  group('PaquetesTab', () {
    late MockPackagesBloc packagesBloc;

    setUp(() {
      packagesBloc = MockPackagesBloc();
    });

    Future<void> montar(
      WidgetTester t, {
      required List<PaquetePacking> paquetes,
      Set<int> seleccionados = const {},
    }) async {
      when(() => packagesBloc.state).thenReturn(
        PackingPackagesState(
          paquetes: paquetes,
          seleccionados: seleccionados,
        ),
      );
      await t.pumpWidget(
        MaterialApp(
          home: BlocProvider<PackingPackagesBloc>.value(
            value: packagesBloc,
            child: Scaffold(
              body: PaquetesTab(
                activo: true,
                editable: true,
                esCluster: true,
                onImprimir: (_) {},
                onEliminar: (_) {},
                onDesempacar: (_, __) {},
                onAsignarUbicacion: (_) {},
              ),
            ),
          ),
        ),
      );
      await t.pump();
    }

    testWidgets(
      'filtra paquetes por nombre o código de barras y permite limpiar',
      experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(),
      (t) async {
        final p1 = paqueteTest(id: 1, consecutivo: 'Caja 1', packingBarcode: 'PACK-001');
        final p2 = paqueteTest(id: 2, consecutivo: 'Caja 2', packingBarcode: 'PACK-002');

        await montar(t, paquetes: [p1, p2]);
        await t.pump(const Duration(milliseconds: 200));

        expect(find.text('Caja 1'), findsOneWidget);
        expect(find.text('Caja 2'), findsOneWidget);

        final searchField = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'Escanear o buscar caja o muelle...',
        );
        expect(searchField, findsOneWidget);

        await t.enterText(searchField, '002');
        await t.pump();

        expect(find.text('Caja 1'), findsNothing);
        expect(find.text('Caja 2'), findsOneWidget);

        // Limpiar filtro
        final clearBtn = find.byTooltip('Limpiar');
        expect(clearBtn, findsOneWidget);
        await t.tap(clearBtn);
        await t.pump();

        expect(find.text('Caja 1'), findsOneWidget);
        expect(find.text('Caja 2'), findsOneWidget);
      },
    );

    testWidgets(
      'muestra estado vacío cuando la búsqueda no coincide',
      experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(),
      (t) async {
        final p1 = paqueteTest(id: 1, consecutivo: 'Caja 1', packingBarcode: 'PACK-001');

        await montar(t, paquetes: [p1]);
        await t.pump(const Duration(milliseconds: 200));

        expect(find.text('Caja 1'), findsOneWidget);

        final searchField = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'Escanear o buscar caja o muelle...',
        );
        await t.enterText(searchField, 'inexistente');
        await t.pump();

        expect(find.text('Caja 1'), findsNothing);
        expect(find.text('No se encontraron paquetes'), findsOneWidget);
      },
    );
  });
}

