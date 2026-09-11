part of 'transferencia_multiusuario_scan_bloc.dart';

sealed class TransferenciaMultiusuarioScanEvent extends Equatable {
  const TransferenciaMultiusuarioScanEvent();

  @override
  List<Object> get props => [];
}

/// Reclama ("toma") [productId] de [sessionId] (POST /api/transfer/claim).
class ClaimProductEvent extends TransferenciaMultiusuarioScanEvent {
  final int sessionId;
  final int productId;
  const ClaimProductEvent({required this.sessionId, required this.productId});

  @override
  List<Object> get props => [sessionId, productId];
}
