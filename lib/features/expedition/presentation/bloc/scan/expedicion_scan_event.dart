part of 'expedicion_scan_bloc.dart';

sealed class ExpedicionScanEvent extends Equatable {
  const ExpedicionScanEvent();

  @override
  List<Object> get props => [];
}

/// Confirma la validación del paquete o producto suelto mostrado en pantalla.
class ValidarExpedicionScanEvent extends ExpedicionScanEvent {
  const ValidarExpedicionScanEvent();
}
