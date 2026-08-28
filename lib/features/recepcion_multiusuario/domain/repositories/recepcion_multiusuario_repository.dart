import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';

abstract class RecepcionMultiusuarioRepository {
  /// Trae las sesiones desde el backend (POST /api/receipt/sessions) y las
  /// persiste en SQLite.
  Future<Either<Failure, List<RecepcionSession>>> fetchSessions({
    required bool isLoadinDialog,
  });

  /// Lee las sesiones desde SQLite (caché local, offline-first).
  Future<Either<Failure, List<RecepcionSession>>> getSessionsFromDb();

  /// Trae el pool de productos libres de [sessionId]
  /// (POST /api/receipt/session/{sessionId}/pool) y reemplaza por completo
  /// el pool local de esa sesión.
  Future<Either<Failure, List<RecepcionPoolItem>>> fetchPool({
    required int sessionId,
    required bool isLoadinDialog,
  });

  /// Lee el pool local de [sessionId] (caché local, offline-first).
  Future<Either<Failure, List<RecepcionPoolItem>>> getPoolFromDb(int sessionId);

  /// Reclama ("toma") [productId] de [sessionId] (POST /api/receipt/claim).
  /// Un rechazo de negocio (ej. otro operario ya lo tomó) llega como
  /// [ServerFailure] con el mensaje del backend.
  Future<Either<Failure, RecepcionClaim>> claimProduct({
    required int sessionId,
    required int productId,
  });

  /// Productos que el usuario actual ya reclamó y sigue trabajando en
  /// [sessionId] (POST /api/receipt/session/{sessionId}/my_claims).
  Future<Either<Failure, List<RecepcionClaim>>> fetchMyClaims({
    required int sessionId,
    required bool isLoadinDialog,
  });

  /// Libera la asignación [claimId] (POST /api/receipt/claim/{claimId}/release):
  /// vuelve a quedar libre en el pool para cualquier operario.
  Future<Either<Failure, Unit>> releaseClaim({required int claimId});
}
