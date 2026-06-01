import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/formats_utils.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/picking/data/datasources/pick_scan_local_data_source.dart';
import 'package:wms_app/features/picking/data/datasources/pick_scan_remote_data_source.dart';
import 'package:wms_app/features/picking/domain/entities/scan_send_result.dart';
import 'package:wms_app/features/picking/domain/repositories/pick_scan_repository.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/requets_transfer_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/submeuelle_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';

@LazySingleton(as: PickScanRepository)
class PickScanRepositoryImpl implements PickScanRepository {
  final PickScanRemoteDataSource remoteDataSource;
  final PickScanLocalDataSource localDataSource;
  // ignore: unused_field
  final NetworkInfo networkInfo;

  PickScanRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ── Validaciones SQLite ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> markLocationOk(
      int batchId, int productId, int idMove) async {
    try {
      await localDataSource.setProductField(
          batchId, productId, 'is_location_is_ok', 1, idMove);
      await localDataSource.setPickField(batchId, 'is_selected', 1);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error en markLocationOk: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markLocationDestOk(
      int batchId, int productId, int idMove, bool isOk) async {
    try {
      if (isOk) {
        await localDataSource.setProductField(
            batchId, productId, 'location_dest_is_ok', 1, idMove);
      }
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error en markLocationDestOk: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markProductOk(
      int batchId, int productId, int idMove) async {
    try {
      final now = DateTime.now();
      await localDataSource.startStopwatch(
          batchId, productId, idMove, now.toString());
      await localDataSource.setTransactionDate(
          batchId, formatoFecha(now), productId, idMove);
      await localDataSource.setProductField(
          batchId, productId, 'is_quantity_is_ok', 1, idMove);
      await localDataSource.setProductField(
          batchId, productId, 'is_selected', 1, idMove);
      await localDataSource.setProductField(
          batchId, productId, 'product_is_ok', 1, idMove);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error en markProductOk: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markQuantityOk(
      int batchId, int productId, int idMove, bool isOk) async {
    try {
      if (isOk) {
        await localDataSource.setProductField(
            batchId, productId, 'is_quantity_is_ok', 1, idMove);
      }
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error en markQuantityOk: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateQuantitySeparate(
      int pickId, int productId, int idMove, dynamic quantity) async {
    try {
      await localDataSource.setProductField(
          pickId, productId, 'quantity_separate', quantity, idMove);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error en updateQuantitySeparate: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> incrementQuantitySeparate(
      int pickId, int productId, int idMove, dynamic quantity) async {
    try {
      final db = DataBaseSqlite();
      await db.pickProductsRepository
          .incremenQtyProductSeparate(pickId, productId, idMove, quantity);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error en incrementQuantitySeparate: $e'));
    }
  }

  // ── Lecturas SQLite ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, PickWithProducts>> getPickWithProducts(
      int pickId) async {
    try {
      final result = await localDataSource.getPickWithProducts(pickId);
      if (result == null) {
        return const Left(CacheFailure('Pick no encontrado'));
      }
      return Right(result);
    } catch (e) {
      return Left(CacheFailure('Error en getPickWithProducts: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Barcodes>>> getBarcodesProduct(
      int pickId, int productId, int idMove) async {
    try {
      final result =
          await localDataSource.getBarcodesProduct(pickId, productId, idMove);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure('Error en getBarcodesProduct: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProductsBatch>>> getProductsForEdit(
      int pickId) async {
    try {
      final pickData = await localDataSource.getPickWithProducts(pickId);
      if (pickData == null || pickData.products == null) {
        return const Right([]);
      }
      final products = pickData.products!
          .where((p) =>
              p.quantitySeparate != p.quantity || p.isSendOdoo == 0)
          .toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure('Error en getProductsForEdit: $e'));
    }
  }

  // ── Odoo API ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Muelles>>> getMuelles(int muelleId) async {
    try {
      final all = await remoteDataSource.getMuelles();
      final filtered =
          all.where((m) => m.locationId == muelleId).toList();
      return Right(filtered);
    } catch (e) {
      return Left(ServerFailure('Error en getMuelles: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getProductImageUrl(int productId) async {
    try {
      final url = await remoteDataSource.getProductImageUrl(productId);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure('Error en getProductImageUrl: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> validateConfirmPick(
      int pickId, bool isBackOrder) async {
    try {
      final msg =
          await remoteDataSource.validateConfirmPick(pickId, isBackOrder);
      return Right(msg);
    } catch (e) {
      return Left(ServerFailure('Error en validateConfirmPick: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> validateTransfer(
      int pickId, bool isBackOrder) async {
    try {
      final msg =
          await remoteDataSource.validateTransfer(pickId, isBackOrder);
      return Right(msg);
    } catch (e) {
      return Left(ServerFailure('Error en validateTransfer: $e'));
    }
  }

  // ── Mixto (SQLite + Odoo) ────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> markPickAsDone(int pickId) async {
    try {
      await localDataSource.setPickField(pickId, 'is_separate', 1);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error en markPickAsDone: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> recordPickTime(
      int pickId, String timeType) async {
    try {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      if (timeType == 'start_time_transfer') {
        await localDataSource.setPickField(
            pickId, 'start_time_transfer', time);
        await localDataSource.setPickField(pickId, 'is_selected', 1);
      } else if (timeType == 'end_time_transfer') {
        await localDataSource.setPickField(
            pickId, 'end_time_transfer', time);
      }

      await remoteDataSource.sendTime(pickId, timeType, time);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure('Error en recordPickTime: $e'));
    }
  }

  @override
  Future<Either<Failure, ScanSendResult>> sendProductToOdoo(
      int pickId, int productId, int idMove, int currentBatchId) async {
    try {
      final product =
          await localDataSource.getProductPick(pickId, productId, idMove);

      if (product == null) {
        return const Left(
            CacheFailure('No se pudo obtener el producto localmente'));
      }

      final userId = await PrefUtils.getUserId();
      final fechaFormateada = formatoFecha(DateTime.now());

      final request = TransferRequest(
        idTransferencia: currentBatchId,
        listItems: [
          ListItem(
            idMove: product.idMove ?? 0,
            idProducto: product.idProduct ?? 0,
            idLote: product.loteId ?? 0,
            idUbicacionDestino: product.muelleId ?? 0,
            cantidadEnviada:
                (product.quantitySeparate ?? 0.0) > (product.quantity ?? 0.0)
                    ? (product.quantitySeparate ?? 0.0)
                    : (product.quantitySeparate ?? 0.0),
            idOperario: userId,
            timeLine: product.timeSeparate == null
                ? 30.0
                : (product.timeSeparate as num).toDouble(),
            fechaTransaccion: (product.fechaTransaccion == '' ||
                    product.fechaTransaccion == null)
                ? fechaFormateada
                : product.fechaTransaccion ?? '',
            observacion: (product.observation == '' ||
                    product.observation == null)
                ? 'Sin novedad'
                : product.observation ?? '',
            dividida: false,
          ),
        ],
      );

      try {
        await remoteDataSource.sendProductTransferPick(request);

        // Marcar como enviado en SQLite
        final db = DataBaseSqlite();
        await db.pickProductsRepository.setFieldTablePickProducts(
          product.batchId ?? 0,
          product.idProduct ?? 0,
          'is_send_odoo',
          1,
          product.idMove ?? 0,
        );

        return Right(ScanSendResult(success: true, message: ''));
      } catch (remoteError) {
        // Marcar como fallido en SQLite
        final db = DataBaseSqlite();
        await db.pickProductsRepository.setFieldTablePickProducts(
          product.batchId ?? 0,
          product.idProduct ?? 0,
          'is_send_odoo',
          0,
          product.idMove ?? 0,
        );
          return Right(ScanSendResult(
            success: false, message: remoteError.toString()));
      }
    } catch (e) {
      return Left(ServerFailure('Error en sendProductToOdoo: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> assignMuelle(List<ProductsBatch> products,
      Muelles muelle, bool isOccupied, int currentBatchId) async {
    try {
      // 1. Verificar disponibilidad del muelle en Odoo
      final muelleOk = await remoteDataSource.ocuparMuelle(
          muelle.id ?? 0, isOccupied);
      if (!muelleOk) {
        return const Left(
            ServerFailure('No se pudo ocupar el muelle seleccionado'));
      }

      // 2. Actualizar SQLite para cada producto
      for (final product in products) {
        await localDataSource.setProductField(
            product.batchId ?? 0, product.idProduct ?? 0, 'is_muelle', 1,
            product.idMove ?? 0);
        await localDataSource.setProductField(
            product.batchId ?? 0, product.idProduct ?? 0, 'muelle_id',
            muelle.id ?? 0, product.idMove ?? 0);
        await localDataSource.setProductFieldString(
            product.batchId ?? 0, product.idProduct ?? 0, 'location_dest_id',
            muelle.completeName ?? '', product.idMove ?? 0);
        await localDataSource.setProductFieldString(
            product.batchId ?? 0, product.idProduct ?? 0,
            'barcode_location_dest', muelle.barcode ?? '',
            product.idMove ?? 0);
      }

      // 3. Enviar todos los productos a Odoo en una sola petición
      final userId = await PrefUtils.getUserId();
      final fechaFormateada = formatoFecha(DateTime.now());

      final items = products
          .map((product) => ListItem(
                idMove: product.idMove ?? 0,
                idProducto: product.idProduct ?? 0,
                idLote: product.loteId ?? 0,
                idUbicacionDestino: muelle.id ?? 0,
                cantidadEnviada:
                    (product.quantitySeparate ?? 0) > (product.quantity ?? 0)
                        ? product.quantity ?? 0
                        : product.quantitySeparate ?? 0,
                idOperario: userId,
                timeLine: product.timeSeparate == null
                    ? 30.0
                    : (product.timeSeparate as num).toDouble(),
                fechaTransaccion: (product.fechaTransaccion == '' ||
                        product.fechaTransaccion == null)
                    ? fechaFormateada
                    : product.fechaTransaccion ?? '',
                observacion:
                    (product.observation == '' || product.observation == null)
                        ? 'Sin novedad'
                        : product.observation ?? '',
                dividida: false,
              ))
          .toList();

      final msg = await remoteDataSource.sendProductTransferPick(
        TransferRequest(
          idTransferencia: currentBatchId,
          listItems: items,
        ),
      );

      return Right(msg);
    } catch (e) {
      return Left(ServerFailure('Error en assignMuelle: $e'));
    }
  }
}
