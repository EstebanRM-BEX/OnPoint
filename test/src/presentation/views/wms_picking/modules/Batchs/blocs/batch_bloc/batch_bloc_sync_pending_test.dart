import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/data/wms_picking_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/item_picking_request.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/response_send_picking.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockDataBaseSqlite extends Mock implements DataBaseSqlite {}

class MockWmsPickingRepository extends Mock implements WmsPickingRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNetworkInfo mockNetworkInfo;
  late MockDataBaseSqlite mockDb;
  late MockWmsPickingRepository mockRepository;
  late StreamController<ConnectionStatus> statusController;
  late BatchBloc bloc;

  ProductsBatch buildPendiente({
    required int idProduct,
    required int idMove,
    int batchId = 10,
  }) =>
      ProductsBatch(
        batchId: batchId,
        idProduct: idProduct,
        idMove: idMove,
        isSendOdoo: 0,
        quantity: 5,
        quantitySeparate: 5,
        lotId: '',
        observation: '',
        muelleId: 1,
      );

  SendPickingResponse respuesta(int code) =>
      SendPickingResponse(result: Data(code: code, msg: '', result: []));

  void stubSendPickingOk() {
    when(() => mockRepository.sendPicking(
          tipoPicking: any(named: 'tipoPicking'),
          idBatch: any(named: 'idBatch'),
          timeTotal: any(named: 'timeTotal'),
          cantItemsSeparados: any(named: 'cantItemsSeparados'),
          listItem: any(named: 'listItem'),
        )).thenAnswer((_) async => respuesta(200));
  }

  void stubSetField() {
    when(() => mockDb.setFieldTableBatchProducts(
        any(), any(), any(), any(), any(), any())).thenAnswer((_) async => 1);
  }

  setUpAll(() {
    registerFallbackValue(<Item>[]);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockNetworkInfo = MockNetworkInfo();
    mockDb = MockDataBaseSqlite();
    mockRepository = MockWmsPickingRepository();
    statusController = StreamController<ConnectionStatus>.broadcast();

    // El constructor del bloc se suscribe a onStatusChanged y resuelve
    // NetworkInfo vía getIt: debe estar registrado antes de crear el bloc.
    when(() => mockNetworkInfo.onStatusChanged)
        .thenAnswer((_) => statusController.stream);
    getIt.registerSingleton<NetworkInfo>(mockNetworkInfo);

    bloc = BatchBloc();
    // Los campos db/repository son públicos en el bloc legacy: se reemplazan
    // tras la construcción.
    bloc.db = mockDb;
    bloc.repository = mockRepository;

    // getBatchWithProducts se usa solo para cantItemsSeparados; null es válido.
    when(() => mockDb.getBatchWithProducts(any(), any()))
        .thenAnswer((_) async => null);
  });

  tearDown(() async {
    await bloc.close();
    await statusController.close();
    await getIt.reset();
  });

  group('SyncPendingProductsEvent', () {
    test('sin conexión: no envía nada ni emite estados de sync', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final states = <BatchState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(SyncPendingProductsEvent('batch'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verifyNever(() => mockRepository.sendPicking(
            tipoPicking: any(named: 'tipoPicking'),
            idBatch: any(named: 'idBatch'),
            timeTotal: any(named: 'timeTotal'),
            cantItemsSeparados: any(named: 'cantItemsSeparados'),
            listItem: any(named: 'listItem'),
          ));
      expect(states.whereType<SyncPendingProductsLoading>(), isEmpty);
      expect(states.whereType<SyncPendingProductsSuccess>(), isEmpty);
      await sub.cancel();
    });

    test('con conexión y sin pendientes: no envía ni emite', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockDb.getProducts('batch')).thenAnswer((_) async => [
            ProductsBatch(idProduct: 3, isSendOdoo: 1), // ya enviado
            ProductsBatch(idProduct: 4, isSendOdoo: null), // sin procesar
          ]);

      final states = <BatchState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(SyncPendingProductsEvent('batch'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verifyNever(() => mockRepository.sendPicking(
            tipoPicking: any(named: 'tipoPicking'),
            idBatch: any(named: 'idBatch'),
            timeTotal: any(named: 'timeTotal'),
            cantItemsSeparados: any(named: 'cantItemsSeparados'),
            listItem: any(named: 'listItem'),
          ));
      expect(states.whereType<SyncPendingProductsSuccess>(), isEmpty);
      await sub.cancel();
    });

    test('con 2 pendientes: envía uno por uno en orden y marca is_send_odoo=1',
        () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockDb.getProducts('batch')).thenAnswer((_) async => [
            buildPendiente(idProduct: 1, idMove: 100),
            buildPendiente(idProduct: 2, idMove: 200, batchId: 20),
            ProductsBatch(idProduct: 3, isSendOdoo: 1), // no debe reenviarse
          ]);
      stubSetField();

      // Registramos el orden de los envíos para validar "uno por uno"
      final ordenEnviado = <int>[];
      when(() => mockRepository.sendPicking(
            tipoPicking: any(named: 'tipoPicking'),
            idBatch: any(named: 'idBatch'),
            timeTotal: any(named: 'timeTotal'),
            cantItemsSeparados: any(named: 'cantItemsSeparados'),
            listItem: any(named: 'listItem'),
          )).thenAnswer((invocation) async {
        final items = invocation.namedArguments[#listItem] as List<Item>;
        ordenEnviado.add(items.first.idMove);
        return respuesta(200);
      });

      final states = <BatchState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(SyncPendingProductsEvent('batch'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Se enviaron los 2 pendientes, uno por uno, en orden
      expect(ordenEnviado, [100, 200]);

      // Cada uno quedó marcado como enviado
      verify(() => mockDb.setFieldTableBatchProducts(
          10, 1, 'is_send_odoo', 1, 100, 'batch')).called(1);
      verify(() => mockDb.setFieldTableBatchProducts(
          20, 2, 'is_send_odoo', 1, 200, 'batch')).called(1);

      expect(states.whereType<SyncPendingProductsLoading>().length, 1);
      final success = states.whereType<SyncPendingProductsSuccess>().single;
      expect(success.enviados, 2);
      expect(success.total, 2);
      await sub.cancel();
    });

    test('si un envío falla: el resto continúa y el fallido queda pendiente',
        () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockDb.getProducts('batch')).thenAnswer((_) async => [
            buildPendiente(idProduct: 1, idMove: 100),
            buildPendiente(idProduct: 2, idMove: 200),
          ]);
      stubSetField();

      when(() => mockRepository.sendPicking(
            tipoPicking: any(named: 'tipoPicking'),
            idBatch: any(named: 'idBatch'),
            timeTotal: any(named: 'timeTotal'),
            cantItemsSeparados: any(named: 'cantItemsSeparados'),
            listItem: any(named: 'listItem'),
          )).thenAnswer((invocation) async {
        final items = invocation.namedArguments[#listItem] as List<Item>;
        // El producto con idMove 100 falla, el 200 pasa
        return respuesta(items.first.idMove == 100 ? 400 : 200);
      });

      final states = <BatchState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(SyncPendingProductsEvent('batch'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Solo el exitoso se marca como enviado
      verify(() => mockDb.setFieldTableBatchProducts(
          10, 2, 'is_send_odoo', 1, 200, 'batch')).called(1);
      verifyNever(() => mockDb.setFieldTableBatchProducts(
          10, 1, 'is_send_odoo', 1, 100, 'batch'));

      final success = states.whereType<SyncPendingProductsSuccess>().single;
      expect(success.enviados, 1);
      expect(success.total, 2);
      await sub.cancel();
    });

    test('al recuperar conexión se dispara la sincronización automática',
        () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockDb.getProducts('batch')).thenAnswer(
          (_) async => [buildPendiente(idProduct: 1, idMove: 100)]);
      stubSetField();
      stubSendPickingOk();

      // El listener del constructor solo dispara si typePicking está seteado
      bloc.typePicking = 'batch';

      final states = <BatchState>[];
      final sub = bloc.stream.listen(states.add);

      statusController.add(ConnectionStatus.online);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verify(() => mockRepository.sendPicking(
            tipoPicking: any(named: 'tipoPicking'),
            idBatch: any(named: 'idBatch'),
            timeTotal: any(named: 'timeTotal'),
            cantItemsSeparados: any(named: 'cantItemsSeparados'),
            listItem: any(named: 'listItem'),
          )).called(1);
      expect(states.whereType<SyncPendingProductsSuccess>().single.enviados, 1);
      await sub.cancel();
    });
  });
}
