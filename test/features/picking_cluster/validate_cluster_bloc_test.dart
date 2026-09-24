import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/end_time_pick_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/get_pending_send_products_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/send_product_odoo_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/set_cluster_batch_pedido_field_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/set_cluster_batch_product_field_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/validate_pedido_usecase.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/validate_cluster/validate_cluster_bloc.dart';

class _MockClusterPickingBloc extends Mock implements ClusterPickingBloc {}

class _MockValidatePedido extends Mock implements ValidatePedidoUseCase {}

class _MockSetPedidoField extends Mock
    implements SetClusterBatchPedidoFieldUseCase {}

class _MockGetPending extends Mock implements GetPendingSendProductsUseCase {}

class _MockSendProduct extends Mock implements SendProductOdooUseCase {}

class _MockSetProductField extends Mock
    implements SetClusterBatchProductFieldUseCase {}

class _MockEndTime extends Mock implements EndTimePickUseCase {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late _MockClusterPickingBloc clusterBloc;
  late _MockValidatePedido validatePedido;
  late _MockSetPedidoField setPedidoField;
  late _MockGetPending getPending;

  const pedido = PedidoValidate(
    batchId: 10,
    idPedido: 1,
    namePedido: '7081576',
    idMuelle: 5,
    barcodeMuelle: 'AMUA001',
  );

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(
        ValidatePedidoParams(idPedido: 0, idLocation: 0, listItems: []));
    registerFallbackValue(SetClusterBatchPedidoFieldParams(
        batchId: 0, namePedido: '', field: '', value: null));
  });

  setUp(() {
    clusterBloc = _MockClusterPickingBloc();
    validatePedido = _MockValidatePedido();
    setPedidoField = _MockSetPedidoField();
    getPending = _MockGetPending();

    when(() => clusterBloc.pedidosValidate).thenReturn([pedido]);
    when(() => getPending(any()))
        .thenAnswer((_) async => const Right(<BatchProduct>[]));
    when(() => validatePedido(any())).thenAnswer((_) async => const Right(true));
    when(() => setPedidoField(any())).thenAnswer((_) async => const Right(null));
  });

  ValidateClusterBloc buildBloc() => ValidateClusterBloc(
        clusterPickingBloc: clusterBloc,
        validatePedidoUseCase: validatePedido,
        setClusterBatchPedidoFieldUseCase: setPedidoField,
        getPendingSendProductsUseCase: getPending,
        sendProductOdooUseCase: _MockSendProduct(),
        setClusterBatchProductFieldUseCase: _MockSetProductField(),
        endTimePickUseCase: _MockEndTime(),
        networkInfo: _MockNetworkInfo(),
      );

  const tapPedido = TapMarkPedidoEvent(
      batchId: 10, namePedido: '7081576', listIdMove: [101, 102]);

  blocTest<ValidateClusterBloc, ValidateClusterState>(
    'bloquea la validación si algún producto del pedido no se ha enviado',
    setUp: () => when(() => clusterBloc.filteredProducts).thenReturn(const [
      BatchProduct(pedidoId: 1, idMove: 101, isSendOdoo: 1),
      BatchProduct(pedidoId: 1, idMove: 102), // sin procesar (null)
    ]),
    build: buildBloc,
    act: (bloc) => bloc.add(tapPedido),
    expect: () => [
      isA<ValidatePedidoErrorState>().having(
          (s) => s.msg, 'msg', contains('faltan 1 producto(s) por enviar')),
    ],
    verify: (_) => verifyNever(() => validatePedido(any())),
  );

  blocTest<ValidateClusterBloc, ValidateClusterState>(
    'bloquea el escaneo del muelle de un pedido incompleto',
    setUp: () => when(() => clusterBloc.filteredProducts).thenReturn(const [
      BatchProduct(pedidoId: 1, idMove: 101, isSendOdoo: 0),
    ]),
    build: buildBloc,
    act: (bloc) => bloc.add(const ScanBarcodeValidateEvent('amua001')),
    expect: () => [isA<ValidatePedidoErrorState>()],
    verify: (_) => verifyNever(() => validatePedido(any())),
  );

  blocTest<ValidateClusterBloc, ValidateClusterState>(
    'valida contra el backend cuando todos los productos están enviados',
    setUp: () => when(() => clusterBloc.filteredProducts).thenReturn(const [
      BatchProduct(pedidoId: 1, idMove: 101, isSendOdoo: 1),
      BatchProduct(pedidoId: 1, idMove: 102, isSendOdoo: 1),
      BatchProduct(pedidoId: 2, idMove: 201), // otro pedido: no influye
    ]),
    build: buildBloc,
    act: (bloc) => bloc.add(tapPedido),
    expect: () => [isA<MarkPedidoValidatedSuccessState>()],
    verify: (_) => verify(() => validatePedido(any())).called(1),
  );
}
