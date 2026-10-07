part of 'validate_cluster_bloc.dart';

sealed class ValidateClusterState extends Equatable {
  const ValidateClusterState();

  @override
  List<Object?> get props => [];
}

class ValidateClusterInitial extends ValidateClusterState {}

// El barcode escaneado no corresponde a ningún pedido del batch
// Con timestamp: sin él Equatable descartaba el segundo "no encontrado"
// seguido y el operario no recibía ni sonido ni mensaje.
class BarcodeValidateNotFoundState extends ValidateClusterState {
  final int timestamp;
  BarcodeValidateNotFoundState()
    : timestamp = DateTime.now().microsecondsSinceEpoch;

  @override
  List<Object?> get props => [timestamp];
}

// El usuario intentó cerrar el batch sin haber validado todos los pedidos
class BatchNotAllValidatedState extends ValidateClusterState {
  final String message;
  const BatchNotAllValidatedState(this.message);

  @override
  List<Object?> get props => [message];
}

// Pedido marcado como validado exitosamente (scan o tap)
class MarkPedidoValidatedSuccessState extends ValidateClusterState {
  final List<PedidoValidate> pedidosValidate;
  const MarkPedidoValidatedSuccessState(this.pedidosValidate);

  @override
  List<Object?> get props => [pedidosValidate];
}

// Error al validar un pedido contra el backend (productos offline pendientes, etc.)
class ValidatePedidoErrorState extends ValidateClusterState {
  final String msg;
  final int timestamp;
  ValidatePedidoErrorState(this.msg)
    : timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [msg, timestamp];
}

// Cargando cierre de batch (muestra loading dialog)
class BatchCloseLoadingState extends ValidateClusterState {}

// Batch cerrado con éxito — la screen navega y refresca la lista
class BatchClosedSuccessState extends ValidateClusterState {}

// Error al cerrar el batch (fallo en API de end_time o similar)
class BatchCloseErrorState extends ValidateClusterState {
  final String message;
  const BatchCloseErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
