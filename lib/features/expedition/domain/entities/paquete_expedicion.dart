import 'package:wms_app/features/expedition/domain/entities/item_expedicion.dart';

class PaqueteExpedicion {
  final int? expeditionId;
  final int? packingId;
  final String? packageName;
  final String? packingBarcode;
  final String? packingType;
  final int? orderPacking;
  final bool? isValidate;
  final List<ItemExpedicion> items;

  const PaqueteExpedicion({
    this.expeditionId,
    this.packingId,
    this.packageName,
    this.packingBarcode,
    this.packingType,
    this.orderPacking,
    this.isValidate,
    this.items = const [],
  });
}
