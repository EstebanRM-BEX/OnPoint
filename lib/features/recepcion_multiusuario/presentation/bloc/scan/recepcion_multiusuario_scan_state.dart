part of 'recepcion_multiusuario_scan_bloc.dart';

sealed class RecepcionMultiusuarioScanState extends Equatable {
  const RecepcionMultiusuarioScanState();

  @override
  List<Object> get props => [];
}

final class RecepcionMultiusuarioScanInitial
    extends RecepcionMultiusuarioScanState {
  const RecepcionMultiusuarioScanInitial();
}

final class ClaimProductLoading extends RecepcionMultiusuarioScanState {
  const ClaimProductLoading();
}

final class ClaimProductSuccess extends RecepcionMultiusuarioScanState {
  final RecepcionClaim claim;
  const ClaimProductSuccess(this.claim);

  @override
  List<Object> get props => [claim, Object()];
}

final class ClaimProductError extends RecepcionMultiusuarioScanState {
  final String message;
  const ClaimProductError(this.message);

  @override
  List<Object> get props => [message];
}
