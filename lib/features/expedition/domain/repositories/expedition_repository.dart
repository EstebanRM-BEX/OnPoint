import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_fetch_result.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';

abstract class ExpeditionRepository {
  Future<Either<Failure, ExpedicionFetchResult>> fetchExpediciones({
    required bool isLoadinDialog,
  });

  Future<Either<Failure, List<ExpedicionPedido>>> getExpedicionesFromDb();

  Future<Either<Failure, ExpedicionPedido>> asignarResponsable(int expeditionId);

  Future<Either<Failure, ExpedicionDetail>> getExpedicionDetail(int expeditionId);

  /// Valida un paquete completo (y todos sus productos) de una expedición.
  Future<Either<Failure, Unit>> validarPaquete({
    required int expeditionId,
    required int packingId,
  });

  /// Valida un producto suelto (sin paquete) de una expedición.
  Future<Either<Failure, Unit>> validarItemSuelto({
    required int expeditionId,
    required int packingId,
  });

  /// Valida en una sola llamada varios paquetes y/o productos sueltos de una
  /// misma expedición. Las listas van separadas porque el backend recibe todos
  /// los packing_id juntos, pero en SQLite cada tipo se marca en su tabla.
  Future<Either<Failure, Unit>> validarMultiple({
    required int expeditionId,
    required List<int> packingIdsPaquetes,
    required List<int> packingIdsItemsSueltos,
  });

  /// Revierte la validación de un paquete (y todos sus productos): vuelve a
  /// aparecer en "Por hacer".
  Future<Either<Failure, Unit>> deshacerPaquete({
    required int expeditionId,
    required int packingId,
  });

  /// Revierte la validación de un producto suelto: vuelve a "Por hacer".
  Future<Either<Failure, Unit>> deshacerItemSuelto({
    required int expeditionId,
    required int packingId,
  });

  /// Confirma (cierra) el pedido de expedición completo. [forzarVencidos]
  /// reintenta con el endpoint que ignora productos con fecha de vencimiento
  /// superada (mismo patrón que packing: se usa solo tras un primer intento
  /// fallido con error `expiry.picking.confirmation`).
  Future<Either<Failure, Unit>> confirmarPedido({
    required int expeditionId,
    bool forzarVencidos = false,
  });
}
