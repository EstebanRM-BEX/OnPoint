import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/picking/domain/entities/scan_send_result.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/submeuelle_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';

/// Repositorio abstracto para el módulo scan del picking.
abstract class PickScanRepository {
  // ── Validaciones SQLite ──────────────────────────────────────────────────

  Future<Either<Failure, Unit>> markLocationOk(
      int batchId, int productId, int idMove);

  Future<Either<Failure, Unit>> markLocationDestOk(
      int batchId, int productId, int idMove, bool isOk);

  Future<Either<Failure, Unit>> markProductOk(
      int batchId, int productId, int idMove);

  Future<Either<Failure, Unit>> markQuantityOk(
      int batchId, int productId, int idMove, bool isOk);

  Future<Either<Failure, Unit>> updateQuantitySeparate(
      int pickId, int productId, int idMove, dynamic quantity);

  Future<Either<Failure, Unit>> incrementQuantitySeparate(
      int pickId, int productId, int idMove, dynamic quantity);

  // ── Lecturas SQLite ──────────────────────────────────────────────────────

  Future<Either<Failure, PickWithProducts>> getPickWithProducts(int pickId);

  Future<Either<Failure, List<Barcodes>>> getBarcodesProduct(
      int pickId, int productId, int idMove);

  Future<Either<Failure, List<ProductsBatch>>> getProductsForEdit(int pickId);

  // ── Odoo API ─────────────────────────────────────────────────────────────

  Future<Either<Failure, List<Muelles>>> getMuelles(int muelleId);

  Future<Either<Failure, String>> getProductImageUrl(int productId);

  Future<Either<Failure, String>> validateConfirmPick(
      int pickId, bool isBackOrder);

  Future<Either<Failure, String>> validateTransfer(
      int pickId, bool isBackOrder);

  // ── Mixto (SQLite + Odoo) ────────────────────────────────────────────────

  Future<Either<Failure, Unit>> markPickAsDone(int pickId);

  Future<Either<Failure, Unit>> recordPickTime(int pickId, String timeType);

  Future<Either<Failure, ScanSendResult>> sendProductToOdoo(
      int pickId, int productId, int idMove, int currentBatchId);

  Future<Either<Failure, String>> assignMuelle(List<ProductsBatch> products,
      Muelles muelle, bool isOccupied, int currentBatchId);
}
