import 'package:wms_app/features/expedition/domain/entities/item_expedicion.dart';

class PaqueteExpedicion {
  final int? expeditionId;
  final int? packingId;
  final String? packageName;
  final String? packingBarcode;
  final String? packingType;
  final int? orderPacking;
  final bool? isValidate;

  /// true = validado sin conexión, aún pendiente de enviar al backend.
  /// Con isValidate=true vive en "Listo" pero marcado como "por enviar".
  final bool? syncPending;
  final List<ItemExpedicion> items;

  const PaqueteExpedicion({
    this.expeditionId,
    this.packingId,
    this.packageName,
    this.packingBarcode,
    this.packingType,
    this.orderPacking,
    this.isValidate,
    this.syncPending,
    this.items = const [],
  });
}
