import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/expedition/data/datasources/expedition_local_data_source.dart';
import 'package:wms_app/features/expedition/data/datasources/expedition_remote_data_source.dart';
import 'package:wms_app/features/expedition/data/models/item_expedicion_model.dart';
import 'package:wms_app/features/expedition/data/models/item_suelto_expedicion_model.dart';
import 'package:wms_app/features/expedition/data/models/paquete_expedicion_model.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_fetch_result.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';
import 'package:wms_app/src/presentation/views/transferencias/data/transferencias_repository.dart';

@LazySingleton(as: ExpeditionRepository)
class ExpeditionRepositoryImpl implements ExpeditionRepository {
  final ExpeditionRemoteDataSource remoteDataSource;
  final ExpeditionLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final TransferenciasRepository transferRepository;

  ExpeditionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.transferRepository,
  });

  @override
  Future<Either<Failure, ExpedicionFetchResult>> fetchExpediciones({
    required bool isLoadinDialog,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No hay conexión a Internet'));
    }

    try {
      final response = await remoteDataSource.fetchExpediciones(
        isLoadinDialog: isLoadinDialog,
      );
      final pedidos = response.result;

      // El backend manda la foto completa de lo que está pendiente, así que
      // lo local se reemplaza entero. Va después del fetch (no antes) para no
      // dejar la lista vacía si la petición falla, y también cuando `pedidos`
      // viene vacío: en ese caso justamente no debe quedar nada.
      await localDataSource.limpiarExpediciones();

      if (pedidos.isNotEmpty) {
        await localDataSource.saveExpediciones(pedidos);

        // itemsPackValidados/Pendientes siempre vienen de
        // ExpedicionPedidoModel.fromJson, que los puebla con
        // PaqueteExpedicionModel (y sus items con ItemExpedicionModel) — el
        // cast es seguro dentro de este flujo (remoto → persistencia local).
        for (final pedido in pedidos) {
          if (pedido.expeditionId == null) continue;

          final paquetes = <PaqueteExpedicionModel>[
            ...pedido.itemsPackValidados.cast<PaqueteExpedicionModel>(),
            ...pedido.itemsPackPendientes.cast<PaqueteExpedicionModel>(),
          ];

          await localDataSource.savePaquetesForExpedicion(
            pedido.expeditionId!,
            paquetes,
          );

          for (final paquete in paquetes) {
            if (paquete.packingId == null) continue;
            await localDataSource.saveItemsForPaquete(
              paquete.packingId!,
              paquete.items.cast<ItemExpedicionModel>(),
            );
          }

          // items_validados/items_pendientes: productos sueltos (sin
          // paquete) de este pedido, mismo cast seguro que arriba.
          final itemsSueltos = <ItemSueltoExpedicionModel>[
            ...pedido.itemsValidados.cast<ItemSueltoExpedicionModel>(),
            ...pedido.itemsPendientes.cast<ItemSueltoExpedicionModel>(),
          ];
          await localDataSource.saveItemsSueltosForExpedicion(
            pedido.expeditionId!,
            itemsSueltos,
          );
        }
      }

      final localPedidos = await localDataSource.getExpedicionesFromDb();

      return Right(ExpedicionFetchResult(
        expediciones: localPedidos,
        needsUpdate: response.updateVersion ?? false,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener expediciones: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ExpedicionPedido>>> getExpedicionesFromDb() async {
    try {
      final localPedidos = await localDataSource.getExpedicionesFromDb();
      return Right(localPedidos);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al leer expediciones locales: $e'));
    }
  }

  // ── asignarResponsable ────────────────────────────────────────────────────
  // Mismo flujo que _onAssignUserToPedido + _onStartOrStopTimePedido de
  // PackingPedidoBloc: asignar responsable, actualizar local, iniciar tiempo
  // (local primero, luego request remoto), releer y retornar el pedido.
  @override
  Future<Either<Failure, ExpedicionPedido>> asignarResponsable(
      int expeditionId) async {
    try {
      final userId = await PrefUtils.getUserId();
      final userName = await PrefUtils.getUserName();

      final ok = await transferRepository.assignUserToTransfer(
        false,
        userId,
        expeditionId,
      );

      if (!ok) {
        return const Left(
            ServerFailure('La expedición ya tiene un responsable asignado'));
      }

      await localDataSource.updateResponsable(expeditionId, userId, userName);

      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      await localDataSource.updateStartTime(expeditionId, time);
      await transferRepository.sendTime(
        expeditionId,
        'start_time_transfer',
        time,
        false,
      );

      final updated = await localDataSource.getExpedicionById(expeditionId);
      if (updated == null) {
        return const Left(
            CacheFailure('No se encontró la expedición actualizada'));
      }
      return Right(updated);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al asignar responsable: $e'));
    }
  }

  @override
  Future<Either<Failure, ExpedicionDetail>> getExpedicionDetail(
      int expeditionId) async {
    try {
      final detail = await localDataSource.getExpedicionDetail(expeditionId);
      if (detail == null) {
        return const Left(CacheFailure('No se encontró la expedición'));
      }
      return Right(detail);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al obtener el detalle: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> validarPaquete({
    required int expeditionId,
    required int packingId,
  }) async {
    try {
      final ok = await remoteDataSource.validarPaquete(
        expeditionId: expeditionId,
        packingId: packingId,
      );
      if (!ok) {
        return const Left(ServerFailure('No se pudo validar el paquete'));
      }
      await localDataSource.actualizarValidacionPaquete(packingId, true);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al validar el paquete: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> validarItemSuelto({
    required int expeditionId,
    required int packingId,
  }) async {
    try {
      final ok = await remoteDataSource.validarItemSuelto(
        expeditionId: expeditionId,
        packingId: packingId,
      );
      if (!ok) {
        return const Left(ServerFailure('No se pudo validar el producto'));
      }
      await localDataSource.actualizarValidacionItemSuelto(
          expeditionId, packingId, true);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al validar el producto: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> validarMultiple({
    required int expeditionId,
    required List<int> packingIdsPaquetes,
    required List<int> packingIdsItemsSueltos,
  }) async {
    final todos = [...packingIdsPaquetes, ...packingIdsItemsSueltos];
    if (todos.isEmpty) {
      return const Left(ServerFailure('No hay elementos seleccionados'));
    }

    try {
      final ok = await remoteDataSource.validarMultiple(
        expeditionId: expeditionId,
        packingIds: todos,
      );
      if (!ok) {
        return const Left(ServerFailure('No se pudo validar la selección'));
      }

      // El backend confirmó todos los packing_id de una sola vez; recién ahí
      // los marcamos como validados en local, cada tipo en su tabla.
      for (final packingId in packingIdsPaquetes) {
        await localDataSource.actualizarValidacionPaquete(packingId, true);
      }
      for (final packingId in packingIdsItemsSueltos) {
        await localDataSource.actualizarValidacionItemSuelto(
            expeditionId, packingId, true);
      }
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al validar la selección: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deshacerPaquete({
    required int expeditionId,
    required int packingId,
  }) async {
    try {
      final ok = await remoteDataSource.deshacerPaquete(
        expeditionId: expeditionId,
        packingId: packingId,
      );
      if (!ok) {
        return const Left(
            ServerFailure('No se pudo deshacer la validación del paquete'));
      }
      await localDataSource.actualizarValidacionPaquete(packingId, false);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Error al deshacer la validación del paquete: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deshacerItemSuelto({
    required int expeditionId,
    required int packingId,
  }) async {
    try {
      final ok = await remoteDataSource.deshacerItemSuelto(
        expeditionId: expeditionId,
        packingId: packingId,
      );
      if (!ok) {
        return const Left(
            ServerFailure('No se pudo deshacer la validación del producto'));
      }
      await localDataSource.actualizarValidacionItemSuelto(
          expeditionId, packingId, false);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Error al deshacer la validación del producto: $e'));
    }
  }

  // ── confirmarPedido ───────────────────────────────────────────────────────
  // El flujo normal ya no pasa por complete_transfer de transferencias: usa
  // api/complete_out, propio de expedition. El reintento por productos
  // vencidos sigue yendo a complete_transfer/expire (confirmationValidate),
  // que es el único endpoint /expire disponible hoy.
  @override
  Future<Either<Failure, Unit>> confirmarPedido({
    required int expeditionId,
    bool forzarVencidos = false,
    bool crearBackorder = false,
  }) async {
    try {
      if (forzarVencidos) {
        final response = await transferRepository.confirmationValidate(
            expeditionId, crearBackorder, false);

        if (response.result?.code != 200) {
          return Left(ServerFailure(
              response.result?.msg ?? 'Error al confirmar la expedición'));
        }
      } else {
        // Lanza ServerException con el msg del backend si no responde 200;
        // ese msg es el que la UI inspecta para detectar vencidos.
        await remoteDataSource.confirmarPedido(
          expeditionId: expeditionId,
          crearBackorder: crearBackorder,
        );
      }

      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      await localDataSource.marcarPedidoTerminado(expeditionId, time);
      await transferRepository.sendTime(
        expeditionId,
        'end_time_transfer',
        time,
        false,
      );

      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al confirmar la expedición: $e'));
    }
  }
}
