import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';

/// Vista agregada de una expedición para la pantalla de detalle: el pedido +
/// sus paquetes (con items) + productos sueltos, ya leídos desde SQLite.
class ExpedicionDetail {
  final ExpedicionPedido pedido;
  final List<PaqueteExpedicion> paquetes;
  final List<ItemSueltoExpedicion> itemsSueltos;

  const ExpedicionDetail({
    required this.pedido,
    this.paquetes = const [],
    this.itemsSueltos = const [],
  });

  List<PaqueteExpedicion> get paquetesPendientes =>
      paquetes.where((p) => p.isValidate != true).toList();

  List<PaqueteExpedicion> get paquetesListos =>
      paquetes.where((p) => p.isValidate == true).toList();

  List<ItemSueltoExpedicion> get itemsSueltosPendientes =>
      itemsSueltos.where((i) => i.isValidate != true).toList();

  List<ItemSueltoExpedicion> get itemsSueltosListos =>
      itemsSueltos.where((i) => i.isValidate == true).toList();

  /// true si hay algún paquete o producto suelto validado sin conexión que
  /// todavía no se envió al backend. Con esto se bloquea la confirmación del
  /// pedido completo hasta que el coordinator los sincronice.
  bool get tienePendientesDeSync =>
      paquetes.any((p) => p.syncPending == true) ||
      itemsSueltos.any((i) => i.syncPending == true);
}
