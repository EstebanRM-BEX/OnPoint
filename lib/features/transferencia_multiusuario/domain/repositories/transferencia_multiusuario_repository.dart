import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_claim.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_lote_producto.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_pool_item.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_snapshot.dart';

/// Contrato del módulo de transferencia multiusuario, espejo de
/// RecepcionMultiusuarioRepository. Se amplía con claim/lote/etc. a medida
/// que se construye cada pantalla siguiente.
abstract class TransferenciaMultiusuarioRepository {
  Future<Either<Failure, List<TransferenciaSession>>> fetchSessions({
    required bool isLoadinDialog,
  });

  Future<Either<Failure, List<TransferenciaSession>>> getSessionsFromDb();

  /// POST /api/transfer/session/{sessionId}/pool. En vivo, no se cachea
  /// localmente — mismo criterio que RecepcionMultiusuarioRepository
  /// (confirmado que ahí la caché de pool está declarada pero nunca se usa).
  Future<Either<Failure, List<TransferenciaPoolItem>>> fetchPool({
    required int sessionId,
    required bool isLoadinDialog,
    required bool verification,
  });

  /// POST /api/transfer/claim: reclama ("toma") un producto libre del pool.
  Future<Either<Failure, TransferenciaClaim>> claimProduct({
    required int sessionId,
    required int productId,
  });

  /// POST /api/transfer/session/{sessionId}: refresca el detalle de la
  /// sesión (tab "Detalle").
  Future<Either<Failure, TransferenciaSession>> fetchSessionDetail({
    required int sessionId,
    required bool isLoadinDialog,
  });

  /// POST /api/transfer/session/{sessionId}/my_claims.
  Future<Either<Failure, List<TransferenciaClaim>>> fetchMyClaims({
    required int sessionId,
    required bool isLoadinDialog,
  });

  /// POST /api/transfer/claim/{claimId}/release.
  Future<Either<Failure, Unit>> releaseClaim({required int claimId});

  /// POST /api/transfer/session/{sessionId}/snapshot: carga inicial de la
  /// pantalla de detalle en una sola llamada (cabecera + pool + mis
  /// asignados).
  Future<Either<Failure, TransferenciaSnapshot>> fetchSnapshot({
    required int sessionId,
    required bool isLoadinDialog,
  });

  /// GET /api/lotes/{productId}: lotes existentes del producto. Dato de
  /// producto, no de sesión — mismo endpoint genérico que recepción.
  Future<Either<Failure, List<TransferenciaLoteProducto>>> fetchLotesProduct({
    required int productId,
    required bool isLoadinDialog,
  });

  /// POST /api/create_lote: crea un lote nuevo para un producto. Puede
  /// devolver [ConfirmationRequiredFailure] si la fecha de vencimiento es
  /// anterior a hoy pero el usuario tiene permiso de forzarla.
  Future<Either<Failure, TransferenciaLoteProducto>> createLote({
    required int productId,
    required String nombreLote,
    required String fechaVencimiento,
    required bool priorityExpiration,
    required bool isLoadinDialog,
  });

  /// POST /api/transfer/claim/{claimId}/done: confirma la transferencia de
  /// [qtyDone] para este claim.
  Future<Either<Failure, TransferenciaClaim>> finishClaim({
    required int claimId,
    required double qtyDone,
    required int lotId,
    required int locationDestId,
    required int timeLine,
    required String observation,
  });

  /// POST /api/transfer/claim/{claimId}/undo: deshace una transferencia ya
  /// terminada (state "done"), liberando la cantidad para que vuelva a
  /// quedar disponible. Requiere [observacion] con el motivo.
  Future<Either<Failure, Unit>> undoClaim({
    required int claimId,
    required String observacion,
  });
}
