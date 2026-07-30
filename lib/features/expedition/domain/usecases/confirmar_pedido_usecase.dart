import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/repositories/expedition_repository.dart';

class ConfirmarPedidoParams {
  final int expeditionId;
  final bool forzarVencidos;
  final bool crearBackorder;

  const ConfirmarPedidoParams({
    required this.expeditionId,
    this.forzarVencidos = false,
    this.crearBackorder = false,
  });
}

@lazySingleton
class ConfirmarPedidoUseCase implements UseCase<Unit, ConfirmarPedidoParams> {
  final ExpeditionRepository repository;

  ConfirmarPedidoUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ConfirmarPedidoParams params) async {
    return await repository.confirmarPedido(
      expeditionId: params.expeditionId,
      forzarVencidos: params.forzarVencidos,
      crearBackorder: params.crearBackorder,
    );
  }
}
