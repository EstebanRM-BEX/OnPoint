import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/claim_recepcion_product_usecase.dart';

part 'recepcion_multiusuario_scan_event.dart';
part 'recepcion_multiusuario_scan_state.dart';

/// Bloc de la acción "reclamar producto" (POST /api/receipt/claim), previa a
/// entrar a scan_product_screen. Solo maneja esta acción async — los campos
/// de validación de esa pantalla (producto/lote/cantidad escaneados) viven
/// como estado local del widget, igual que ExpedicionScanBloc.
@injectable
class RecepcionMultiusuarioScanBloc
    extends
        Bloc<RecepcionMultiusuarioScanEvent, RecepcionMultiusuarioScanState> {
  final ClaimRecepcionProductUseCase claimRecepcionProductUseCase;

  RecepcionMultiusuarioScanBloc({required this.claimRecepcionProductUseCase})
    : super(const RecepcionMultiusuarioScanInitial()) {
    on<ClaimProductEvent>(_onClaimProduct);
  }

  Future<void> _onClaimProduct(
    ClaimProductEvent event,
    Emitter<RecepcionMultiusuarioScanState> emit,
  ) async {
    emit(const ClaimProductLoading());

    final result = await claimRecepcionProductUseCase(
      ClaimRecepcionProductParams(
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
