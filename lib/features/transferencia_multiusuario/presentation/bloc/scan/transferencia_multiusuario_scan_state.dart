part of 'transferencia_multiusuario_scan_bloc.dart';

sealed class TransferenciaMultiusuarioScanState extends Equatable {
  const TransferenciaMultiusuarioScanState();

  @override
  List<Object> get props => [];
}

final class TransferenciaMultiusuarioScanInitial
    extends TransferenciaMultiusuarioScanState {
  const TransferenciaMultiusuarioScanInitial();
}

final class ClaimProductLoading extends TransferenciaMultiusuarioScanState {
  const ClaimProductLoading();
}

final class ClaimProductSuccess extends TransferenciaMultiusuarioScanState {
  final TransferenciaClaim claim;
  const ClaimProductSuccess(this.claim);

  @override
  List<Object> get props => [claim, Object()];
}

final class ClaimProductError extends TransferenciaMultiusuarioScanState {
  final String message;
  const ClaimProductError(this.message);

  @override
  List<Object> get props => [message];
}
