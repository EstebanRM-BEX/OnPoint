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
}
