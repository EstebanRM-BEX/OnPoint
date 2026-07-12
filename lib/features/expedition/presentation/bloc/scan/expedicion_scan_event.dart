part of 'expedicion_scan_bloc.dart';

sealed class ExpedicionScanEvent extends Equatable {
  const ExpedicionScanEvent();

  @override
  List<Object> get props => [];
}

/// Confirma la validación del paquete o producto suelto mostrado en pantalla.
/// Trae exactamente uno de los dos: [paquete] o [itemSuelto].
class ValidarExpedicionScanEvent extends ExpedicionScanEvent {
  final PaqueteExpedicion? paquete;
  final ItemSueltoExpedicion? itemSuelto;

  const ValidarExpedicionScanEvent({this.paquete, this.itemSuelto});

  @override
  List<Object> get props => [paquete ?? '', itemSuelto ?? ''];
}

/// Valida de una sola vez varios paquetes y/o productos sueltos seleccionados
/// en el tab "Por hacer". Requiere el permiso `allow_validate_multiple`.
class ValidarMultipleExpedicionScanEvent extends ExpedicionScanEvent {
  final int expeditionId;
  final List<PaqueteExpedicion> paquetes;
  final List<ItemSueltoExpedicion> itemsSueltos;

  const ValidarMultipleExpedicionScanEvent({
    required this.expeditionId,
    required this.paquetes,
    required this.itemsSueltos,
  });

  @override
  List<Object> get props => [expeditionId, paquetes, itemsSueltos];
}

/// Revierte la validación de un paquete o producto suelto ya listo: vuelve
/// a aparecer en "Por hacer". Trae exactamente uno de los dos.
class DeshacerExpedicionScanEvent extends ExpedicionScanEvent {
  final PaqueteExpedicion? paquete;
  final ItemSueltoExpedicion? itemSuelto;

  const DeshacerExpedicionScanEvent({this.paquete, this.itemSuelto});

  @override
  List<Object> get props => [paquete ?? '', itemSuelto ?? ''];
}
