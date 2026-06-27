import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

part 'validate_cluster_event.dart';
part 'validate_cluster_state.dart';

class ValidateClusterBloc
    extends Bloc<ValidateClusterEvent, ValidateClusterState> {
  final ClusterPickingBloc clusterPickingBloc;
  final ValidatePedidoUseCase validatePedidoUseCase;
  final SetClusterBatchPedidoFieldUseCase setClusterBatchPedidoFieldUseCase;
  final GetPendingSendProductsUseCase getPendingSendProductsUseCase;
  final SendProductOdooUseCase sendProductOdooUseCase;
  final SetClusterBatchProductFieldUseCase setClusterBatchProductFieldUseCase;
  final EndTimePickUseCase endTimePickUseCase;
  final NetworkInfo networkInfo;

  ValidateClusterBloc({
    required this.clusterPickingBloc,
    required this.validatePedidoUseCase,
    required this.setClusterBatchPedidoFieldUseCase,
    required this.getPendingSendProductsUseCase,
    required this.sendProductOdooUseCase,
    required this.setClusterBatchProductFieldUseCase,
    required this.endTimePickUseCase,
    required this.networkInfo,
  }) : super(ValidateClusterInitial()) {
    on<ScanBarcodeValidateEvent>(_onScanBarcode);
    on<TapMarkPedidoEvent>(_onTapMarkPedido);
    on<CloseBatchEvent>(_onCloseBatch);
  }

  Future<void> _onScanBarcode(
    ScanBarcodeValidateEvent event,
    Emitter<ValidateClusterState> emit,
  ) async {
    final scan = event.barcode.trim().toLowerCase();

    final pedido = clusterPickingBloc.pedidosValidate.firstWhere(
      (p) => p.barcodeMuelle?.toLowerCase() == scan,
      orElse: () => const PedidoValidate(),
    );

    if (pedido.idPedido == null) {
      emit(BarcodeValidateNotFoundState());
      return;
    }

    final listIdMove = clusterPickingBloc.filteredProducts
        .where((p) => p.pedidoId == pedido.idPedido)
        .map((p) => p.idMove ?? 0)
        .toList();

    await _markPedidoAsValidated(
      emit: emit,
      batchId: pedido.batchId ?? 0,
      namePedido: pedido.namePedido ?? '',
      listIdMove: listIdMove,
    );
  }

  Future<void> _onTapMarkPedido(
    TapMarkPedidoEvent event,
    Emitter<ValidateClusterState> emit,
  ) async {
    await _markPedidoAsValidated(
      emit: emit,
      batchId: event.batchId,
      namePedido: event.namePedido,
      listIdMove: event.listIdMove,
    );
  }

  // Lógica compartida entre scan y tap
  Future<void> _markPedidoAsValidated({
    required Emitter<ValidateClusterState> emit,
    required int batchId,
    required String namePedido,
    required List<int> listIdMove,
  }) async {
    try {
      // 1. Si hay productos guardados offline para este pedido, intentamos
      //    sincronizarlos antes; si quedan pendientes, bloqueamos la validación.
      final idPedidoValidar = clusterPickingBloc.pedidosValidate
          .firstWhere(
            (p) => p.namePedido == namePedido,
            orElse: () => const PedidoValidate(),
          )
          .idPedido;

      final pendingResult =
          await getPendingSendProductsUseCase(NoParams());
      final pendientesPedido = pendingResult.fold(
        (failure) => <BatchProduct>[],
        (pendientes) => pendientes
            .where((p) =>
                p.batchId == batchId && p.pedidoId == idPedidoValidar)
            .toList(),
      );

      if (pendientesPedido.isNotEmpty) {
        int enviados = 0;
        if (await networkInfo.isConnected) {
          for (final pendiente in pendientesPedido) {
            if (await _resendPendingProduct(pendiente)) enviados++;
          }
        }
        final restantes = pendientesPedido.length - enviados;
        if (restantes > 0) {
          emit(ValidatePedidoErrorState(
              'No se puede validar: $restantes producto(s) pendiente(s) de envío. Conéctate a internet para sincronizar'));
          return;
        }
      }

      // 2. Validar contra el backend
      final pedidoToValidate = clusterPickingBloc.pedidosValidate.firstWhere(
        (p) => p.namePedido == namePedido,
        orElse: () => const PedidoValidate(),
      );

      final validateResult = await validatePedidoUseCase.call(
        ValidatePedidoParams(
          idPedido: pedidoToValidate.idPedido ?? 0,
          idLocation: pedidoToValidate.idMuelle ?? 0,
          listItems: listIdMove,
        ),
      );

      bool validateSuccess = false;
      String errorMessage = '';
      validateResult.fold(
        (failure) {
          validateSuccess = false;
          errorMessage = failure.message;
        },
        (success) => validateSuccess = success,
      );

      if (!validateSuccess) {
        emit(ValidatePedidoErrorState(errorMessage));
        return;
      }

      // 3. Guardar en DB local
      await setClusterBatchPedidoFieldUseCase.call(
        SetClusterBatchPedidoFieldParams(
          batchId: batchId,
          namePedido: namePedido,
          field: 'is_validated',
          value: 1,
        ),
      );

      // 4. Actualizar lista compartida y notificar al BLoC de sesión
      final updatedList = clusterPickingBloc.pedidosValidate.map((p) {
        if (p.namePedido == namePedido) {
          return PedidoValidate(
            batchId: p.batchId,
            namePedido: p.namePedido,
            idPicking: p.idPicking,
            idPedido: p.idPedido,
            muelle: p.muelle,
            idMuelle: p.idMuelle,
            barcodeMuelle: p.barcodeMuelle,
            isValidated: true,
          );
        }
        return p;
      }).toList();

      clusterPickingBloc.add(UpdatePedidosValidateEvent(updatedList));
      emit(MarkPedidoValidatedSuccessState(updatedList));
    } catch (e, s) {
      debugPrint('❌ Error en _markPedidoAsValidated: $e -> $s');
      emit(ValidatePedidoErrorState('Error al validar el pedido'));
    }
  }

  Future<void> _onCloseBatch(
    CloseBatchEvent event,
    Emitter<ValidateClusterState> emit,
  ) async {
    final allValidated = clusterPickingBloc.pedidosValidate
        .every((p) => p.isValidated == true);

    if (!allValidated) {
      emit(const BatchNotAllValidatedState(
          'No todos los pedidos están validados'));
      return;
    }

    emit(BatchCloseLoadingState());

    try {
      final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final formattedDate = formatter.format(DateTime.now());

      final result = await endTimePickUseCase.call(
        EndTimePickParams(
          batchId: event.batchId,
          formattedDate: formattedDate,
          typePicking: 'cluster',
        ),
      );

      result.fold(
        (failure) => emit(BatchCloseErrorState(failure.message)),
        (_) {
          // Limpiamos el estado compartido y navegamos
          clusterPickingBloc.add(ClearFieldsEvent());
          emit(BatchClosedSuccessState());
        },
      );
    } catch (e, s) {
      debugPrint('❌ Error en _onCloseBatch: $e -> $s');
      emit(BatchCloseErrorState('Error al cerrar el batch'));
    }
  }

  // Reenvía un producto que quedó guardado offline
  Future<bool> _resendPendingProduct(BatchProduct pendiente) async {
    try {
      final loteId = pendiente.productTracking == 'lot'
          ? int.tryParse(pendiente.loteId.toString()) ?? 0
          : 0;

      final response = await sendProductOdooUseCase.call(
        SendProductOdooParams(
          product: pendiente,
          loteId: loteId,
          type: 'cluster',
          configurations: clusterPickingBloc.configurations,
        ),
      );

      return await response.fold(
        (failure) async => false,
        (success) async {
          await setClusterBatchProductFieldUseCase.call(
            SetClusterBatchProductFieldParams(
              batchId: pendiente.batchId ?? 0,
              productId: pendiente.idProduct ?? 0,
              field: 'is_send_odoo',
              value: 1,
              idMove: pendiente.idMove ?? 0,
              type: 'cluster',
            ),
          );
          if (pendiente.productTracking == 'lot') {
            await setClusterBatchProductFieldUseCase.call(
              SetClusterBatchProductFieldParams(
                batchId: pendiente.batchId ?? 0,
                productId: pendiente.idProduct ?? 0,
                field: 'lote_id',
                value: pendiente.lotId ?? '',
                idMove: pendiente.idMove ?? 0,
                type: 'cluster',
              ),
            );
          }
          return true;
        },
      );
    } catch (e, s) {
      debugPrint('❌ Error en _resendPendingProduct: $e -> $s');
      return false;
    }
  }
}
