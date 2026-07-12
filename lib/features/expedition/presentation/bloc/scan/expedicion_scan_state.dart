part of 'expedicion_scan_bloc.dart';

sealed class ExpedicionScanState extends Equatable {
  const ExpedicionScanState();

  @override
  List<Object> get props => [];
}

final class ExpedicionScanInitial extends ExpedicionScanState {
  const ExpedicionScanInitial();
}

final class ExpedicionScanValidating extends ExpedicionScanState {
  const ExpedicionScanValidating();
}

final class ExpedicionScanValidated extends ExpedicionScanState {
  const ExpedicionScanValidated();
}

/// Estados propios de la validación múltiple (tab "Por hacer"). Son clases
/// aparte y NO extienden las de la validación de a uno a propósito: el tab
/// "Listo" está montado al mismo tiempo y escucha este mismo bloc, así que
/// reusar ExpedicionScanValidating/Validated/Error haría que su listener
/// reaccione a un flujo que no le corresponde y haga un pop de más.
final class ExpedicionScanValidatingMultiple extends ExpedicionScanState {
  const ExpedicionScanValidatingMultiple();
}

final class ExpedicionScanValidatedMultiple extends ExpedicionScanState {
  final int cantidad;

  const ExpedicionScanValidatedMultiple(this.cantidad);

  @override
  List<Object> get props => [cantidad];
}

final class ExpedicionScanErrorMultiple extends ExpedicionScanState {
  final String message;

  const ExpedicionScanErrorMultiple(this.message);

  @override
  List<Object> get props => [message];
}

final class ExpedicionScanUndoing extends ExpedicionScanState {
  const ExpedicionScanUndoing();
}

final class ExpedicionScanUndone extends ExpedicionScanState {
  const ExpedicionScanUndone();
}

final class ExpedicionScanError extends ExpedicionScanState {
  final String message;

  const ExpedicionScanError(this.message);

  @override
  List<Object> get props => [message];
}
