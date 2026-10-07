import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/confirm/packing_confirm_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/detail/packing_pedido_detail_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/list/packing_pedido_list_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/packages/packing_packages_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/scan/packing_scan_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/pages/packing_pedido_detail_page.dart';
import 'package:wms_app/features/packing_pedido/presentation/pages/packing_pedido_list_page.dart';
import 'package:wms_app/features/packing_pedido/presentation/pages/packing_scan_page.dart';
import 'package:wms_app/injection_container.dart';

import '../domain/packing_test_data.dart';
import 'packing_widgets_test.dart' show FakeAudio, FakeVibration;

class MockListBloc
    extends MockBloc<PackingPedidoListEvent, PackingPedidoListState>
    implements PackingPedidoListBloc {}

class MockDetailBloc
    extends MockBloc<PackingPedidoDetailEvent, PackingPedidoDetailState>
    implements PackingPedidoDetailBloc {}

class MockPackagesBloc
    extends MockBloc<PackingPackagesEvent, PackingPackagesState>
    implements PackingPackagesBloc {}

class MockConfirmBloc extends MockBloc<PackingConfirmEvent, PackingConfirmState>
    implements PackingConfirmBloc {}

class MockScanBloc extends MockBloc<PackingScanEvent, PackingScanState>
    implements PackingScanBloc {}

class MockConnection extends MockCubit<ConnectionStatus>
    implements ConnectionStatusCubit {}

/// La barra superior muestra el aviso de conexión (cubit global en la app).
Widget conRed(Widget page) {
  final red = MockConnection();
  when(() => red.state).thenReturn(ConnectionStatus.online);
  return BlocProvider<ConnectionStatusCubit>.value(
    value: red,
    child: MaterialApp(home: page),
  );
}

void registrar<T extends Object>(T Function() f) {
  if (getIt.isRegistered<T>()) getIt.unregister<T>();
  getIt.registerFactory<T>(f);
}

void main() {
  const pedido = PedidoPack(
    id: 10,
    name: 'WH/PACK/0010',
    referencia: 'SO/123',
    zonaEntrega: 'ZONA NORTE',
    configPacking: 'cluster',
    responsableId: 7,
    responsable: 'Operario',
    startTimeTransfer: '2026-10-07 08:00:00',
    numeroItems: 20,
  );

  final detalle = PedidoPackDetalle(
    pedido: pedido,
    porHacer: [productoTest(id: 1, productName: 'Leche entera 1L')],
    listos: [
      productoTest(
        id: 2,
        estado: EstadoProductoPacking.listo,
        certificado: true,
        quantitySeparate: 6,
      ),
    ],
    empacados: [
      productoTest(
        id: 3,
        estado: EstadoProductoPacking.empacado,
        certificado: true,
        quantitySeparate: 4,
        idPackage: 1,
      ),
    ],
    paquetes: [
      paqueteTest(id: 1).copyWith(
        cantidadProductos: 1,
        productos: [
          productoTest(
            id: 3,
            estado: EstadoProductoPacking.empacado,
            idPackage: 1,
          ),
        ],
      ),
    ],
  );

  setUpAll(() {
    if (getIt.isRegistered<IAudioService>()) getIt.unregister<IAudioService>();
    getIt.registerSingleton<IAudioService>(FakeAudio());
    if (!getIt.isRegistered<IVibrationService>()) {
      getIt.registerSingleton<IVibrationService>(FakeVibration());
    }
  });

  testWidgets('lista: pinta los pedidos sin errores de layout', (t) async {
    final bloc = MockListBloc();
    when(() => bloc.state).thenReturn(
      const PackingPedidoListState(
        status: ListaPackStatus.listo,
        pedidos: [
          pedido,
          PedidoPack(id: 11, name: 'WH/PACK/0011'),
        ],
      ),
    );
    registrar<PackingPedidoListBloc>(() => bloc);

    await t.pumpWidget(conRed(const PackingPedidoListPage()));
    await t.pump();

    expect(find.text('PACKING PEDIDOS'), findsOneWidget);
    expect(find.text('WH/PACK/0010'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('detalle: recorre las 5 pestañas sin errores', (t) async {
    final detail = MockDetailBloc();
    final packages = MockPackagesBloc();
    final confirm = MockConfirmBloc();
    when(() => detail.state).thenReturn(
      PackingPedidoDetailState(
        pedidoId: 10,
        status: DetallePackStatus.listo,
        detalle: detalle,
        seleccionados: const {2},
        config: const ConfigPackingUsuario(scanProduct: true),
      ),
    );
    when(() => packages.state).thenReturn(
      PackingPackagesState(
        pedido: pedido,
        paquetes: detalle.paquetes,
        expandido: 1,
      ),
    );
    when(() => confirm.state).thenReturn(const PackingConfirmState());
    registrar<PackingPedidoDetailBloc>(() => detail);
    registrar<PackingPackagesBloc>(() => packages);
    registrar<PackingConfirmBloc>(() => confirm);

    await t.pumpWidget(conRed(const PackingPedidoDetailPage(pedidoId: 10)));
    await t.pump();
    expect(find.text('WH/PACK/0010'), findsWidgets);
    expect(find.text('Confirmar pedido'), findsOneWidget);

    for (final tab in ['Por hacer', 'Preparado', 'Listo', 'Paquetes']) {
      await t.tap(find.text(tab));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'pestaña $tab');
    }
    // En "Paquetes" la caja abierta muestra su producto con desempacar y el
    // QR de la caja, como en el módulo anterior.
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.qr_code), findsOneWidget);
  });

  testWidgets('escaneo: pinta los tres pasos sin errores', (t) async {
    final bloc = MockScanBloc();
    when(() => bloc.state).thenReturn(
      PackingScanState(
        status: ScanPackStatus.listo,
        producto: productoTest(quantity: 10).copyWith(locationOk: true),
        paso: PasoScanPack.producto,
        config: const ConfigPackingUsuario(
          manualProductSelectionPack: true,
          manualQuantityPack: true,
        ),
      ),
    );
    registrar<PackingScanBloc>(() => bloc);

    await t.pumpWidget(conRed(PackingScanPage(producto: productoTest())));
    await t.pump();

    expect(find.text('CERTIFICACION'), findsOneWidget);
    expect(find.text('Ubicación de origen'), findsOneWidget);
    expect(find.text('Producto'), findsOneWidget);
    expect(find.text('Recoger:'), findsOneWidget);
    expect(find.text('APLICAR CANTIDAD'), findsOneWidget);
    expect(t.takeException(), isNull);

    // Los íconos PNG del diseño anterior quedan cargando en el cache de
    // imágenes al terminar: se desmonta y se vacía para no reportar fuga.
    await t.pumpWidget(const SizedBox());
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });
}
