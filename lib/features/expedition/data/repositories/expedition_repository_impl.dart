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
}
