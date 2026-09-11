import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_claim.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/claim_transferencia_product_usecase.dart';

part 'transferencia_multiusuario_scan_event.dart';
part 'transferencia_multiusuario_scan_state.dart';

/// Bloc de la acción "reclamar producto" (POST /api/transfer/claim), previa
/// a entrar a la pantalla de procesar el producto. Espejo de
/// RecepcionMultiusuarioScanBloc: solo maneja esta acción async.
@injectable
class TransferenciaMultiusuarioScanBloc
    extends
        Bloc<
          TransferenciaMultiusuarioScanEvent,
          TransferenciaMultiusuarioScanState
        > {
  final ClaimTransferenciaProductUseCase claimTransferenciaProductUseCase;

  TransferenciaMultiusuarioScanBloc({
    required this.claimTransferenciaProductUseCase,
  }) : super(const TransferenciaMultiusuarioScanInitial()) {
    on<ClaimProductEvent>(_onClaimProduct);
  }

  Future<void> _onClaimProduct(
    ClaimProductEvent event,
    Emitter<TransferenciaMultiusuarioScanState> emit,
  ) async {
    emit(const ClaimProductLoading());

    final result = await claimTransferenciaProductUseCase(
      ClaimTransferenciaProductParams(
        sessionId: event.sessionId,
        productId: event.productId,
      ),
    );

    result.fold(
      (failure) => emit(ClaimProductError(_mapFailureMessage(failure))),
      (claim) => emit(ClaimProductSuccess(claim)),
    );
  }

  String _mapFailureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'Sin conexión a Internet',
      ServerFailure() => failure.message,
      _ => 'Error inesperado',
    };
  }
}
