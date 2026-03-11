import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/lote_producto.dart';
import '../entities/batch_product.dart';
import '../entities/picking_batch.dart';

/// Contrato del repositorio de la feature picking_cluster.
/// Todas las operaciones devuelven [Either] con [Failure] o el dato esperado.
abstract class IPickingClusterRepository {
  // ─── Remote ──────────────────────────────────────────────────────────────
  Future<Either<Failure, List<PickingBatch>>> getPickingBatches();
  Future<Either<Failure, List<LoteProducto>>> getLotesProducto(int productId);
  Future<Either<Failure, LoteProducto>> crearLoteProducto(
      int productId, String name, String? expirationDate);
  Future<Either<Failure, String>> sendPickingProduct({
    required int idBatch,
    required double timeTotal,
    required int cantItemsSeparados,
    required List<Map<String, dynamic>> listItem,
    required String tipoPicking,
  });
  Future<Either<Failure, String>> viewProductImage(
      int idProduct, bool isLoadinDialog);

  Future<Either<Failure, bool>> timePickingUser(
      int batchId, String time, String endpoint, String field);

  Future<Either<Failure, bool>> timePickingBatch(
      int batchId, String time, String endpoint, String field, String field2);

  Future<Either<Failure, bool>> validatePedido(int idPedido, int idLocation);

  // ─── Local ───────────────────────────────────────────────────────────────
  Future<Either<Failure, List<PickingBatch>>> getCachedPickingBatches();
  Future<Either<Failure, List<BatchProduct>>> getBatchProducts(int batchId);
  Future<Either<Failure, void>> setFieldTableBatchProducts(int batchId,
      int productId, String field, dynamic value, int idMove, String type);
  Future<Either<Failure, void>> setFieldTableBatch(
      int batchId, String field, dynamic value, String type);
  Future<Either<Failure, List<BatchBarcode>>> getBarcodesProduct(
      int batchId, int productId, int idMove, String type);
  Future<Either<Failure, void>> incremenQtytProductSeparate(
      int batchId, int productId, int idMove, dynamic quantity, String type);
  Future<Either<Failure, void>> incrementProductSeparateQty(
      int batchId, String type);
  Future<Either<Failure, String>> getFieldTableProducts(
      int batchId, int productId, int moveId, String field, String type);
  Future<Either<Failure, BatchProduct?>> getProductBatch(
      int batchId, int productId, int idMove, String type);
  Future<Either<Failure, void>> setFieldTableBatchPedidoValidate(
      int batchId, String namePedido, String field, dynamic value);

  Future<Either<Failure, void>> endStopwatchBatch(
      int batchId, String time, String typePicking);

  Future<Either<Failure, void>> startStopwatchBatch(
      int batchId, String time, String typePicking);
}
