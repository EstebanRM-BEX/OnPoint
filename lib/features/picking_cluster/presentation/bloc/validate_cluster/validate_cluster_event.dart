part of 'validate_cluster_bloc.dart';

sealed class ValidateClusterEvent extends Equatable {
  const ValidateClusterEvent();

  @override
  List<Object?> get props => [];
}

class ScanBarcodeValidateEvent extends ValidateClusterEvent {
  final String barcode;

  const ScanBarcodeValidateEvent(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

// Confirmar manualmente un pedido desde la tarjeta (sin scan)
class TapMarkPedidoEvent extends ValidateClusterEvent {
  final int batchId;
  final String namePedido;
  final List<int> listIdMove;

  const TapMarkPedidoEvent({
    required this.batchId,
    required this.namePedido,
    required this.listIdMove,
  });

  @override
  List<Object?> get props => [batchId, namePedido, listIdMove];
}

class CloseBatchEvent extends ValidateClusterEvent {
  final int batchId;

  const CloseBatchEvent(this.batchId);

  @override
  List<Object?> get props => [batchId];
}
