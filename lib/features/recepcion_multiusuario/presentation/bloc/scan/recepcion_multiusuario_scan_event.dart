part of 'recepcion_multiusuario_scan_bloc.dart';

sealed class RecepcionMultiusuarioScanEvent extends Equatable {
  const RecepcionMultiusuarioScanEvent();

  @override
  List<Object> get props => [];
}

/// Reclama ("toma") [productId] de [sessionId] antes de navegar a
/// scan_product_screen (POST /api/receipt/claim).
class ClaimProductEvent extends RecepcionMultiusuarioScanEvent {
  final int sessionId;
  final int productId;
  const ClaimProductEvent({required this.sessionId, required this.productId});

  @override
  List<Object> get props => [sessionId, productId];
}
