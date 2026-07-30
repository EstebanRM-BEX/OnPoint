part of 'expedicion_scan_bloc.dart';

sealed class ExpedicionScanEvent extends Equatable {
  const ExpedicionScanEvent();

  @override
  List<Object> get props => [];
}

/// Confirma la validación del paquete o producto suelto mostrado en pantalla.
/// Trae exactamente uno de los dos: [paquete] o [itemSuelto].
///
/// [porEscaneo] indica que viene del escaneo directo en el tab "Por hacer"
/// (sin pasar por scan_product_screen ni diálogo de confirmación): en ese
/// caso el bloc emite los estados *Directo en vez de los normales, ver
/// ExpedicionScanValidatingDirecto en expedicion_scan_state.dart.
class ValidarExpedicionScanEvent extends ExpedicionScanEvent {
  final PaqueteExpedicion? paquete;
  final ItemSueltoExpedicion? itemSuelto;
  final bool porEscaneo;

  const ValidarExpedicionScanEvent({
    this.paquete,
    this.itemSuelto,
    this.porEscaneo = false,
  });

  @override
  List<Object> get props => [paquete ?? '', itemSuelto ?? '', porEscaneo];
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
