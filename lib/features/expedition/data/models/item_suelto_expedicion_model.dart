import 'package:wms_app/features/expedition/data/models/expedicion_json_utils.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_items_sueltos/expedicion_items_sueltos_table.dart';

class ItemSueltoExpedicionModel extends ItemSueltoExpedicion {
  /// 'validado' | 'pendiente' — de qué lista del response vino este item.
  /// Solo se usa para persistencia (no forma parte de la entidad de dominio).
  final String origen;

  const ItemSueltoExpedicionModel({
    super.expeditionId,
    super.packingId,
    super.productName,
    super.productCode,
    super.barcode,
    super.orderPacking,
    super.quantity,
    super.uom,
    super.isValidate,
    super.syncPending,
    required this.origen,
  });

  factory ItemSueltoExpedicionModel.fromJson(
    Map<String, dynamic> json, {
    required String origen,
  }) {
    return ItemSueltoExpedicionModel(
      expeditionId: dynamicToInt(json['expedition_id']),
      packingId: dynamicToInt(json['packing_id']),
      productName: dynamicToString(json['product_name']),
      productCode: dynamicToString(json['product_code']),
      barcode: dynamicToString(json['barcode']),
      orderPacking: dynamicToInt(json['order_packing']),
      quantity: dynamicToDouble(json['quantity']),
      uom: dynamicToString(json['uom']),
      isValidate: dynamicToBool(json['is_validate']),
      // El backend nunca manda pendientes de sync.
      syncPending: false,
      origen: origen,
    );
  }

  factory ItemSueltoExpedicionModel.fromMap(Map<String, dynamic> map) {
    return ItemSueltoExpedicionModel(
      expeditionId: map[ExpedicionItemsSueltosTable.columnExpeditionId] as int?,
      packingId: map[ExpedicionItemsSueltosTable.columnPackingId] as int?,
      productName: map[ExpedicionItemsSueltosTable.columnProductName] as String?,
      productCode: map[ExpedicionItemsSueltosTable.columnProductCode] as String?,
      barcode: map[ExpedicionItemsSueltosTable.columnBarcode] as String?,
      orderPacking: map[ExpedicionItemsSueltosTable.columnOrderPacking] as int?,
      quantity: (map[ExpedicionItemsSueltosTable.columnQuantity] as num?)
          ?.toDouble(),
      uom: map[ExpedicionItemsSueltosTable.columnUom] as String?,
      isValidate:
          (map[ExpedicionItemsSueltosTable.columnIsValidate] as int?) == 1,
      syncPending:
          (map[ExpedicionItemsSueltosTable.columnSyncPending] as int?) == 1,
      origen: map[ExpedicionItemsSueltosTable.columnOrigen] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ExpedicionItemsSueltosTable.columnExpeditionId: expeditionId,
      ExpedicionItemsSueltosTable.columnPackingId: packingId,
      ExpedicionItemsSueltosTable.columnProductName: productName,
      ExpedicionItemsSueltosTable.columnProductCode: productCode,
      ExpedicionItemsSueltosTable.columnBarcode: barcode,
      ExpedicionItemsSueltosTable.columnOrderPacking: orderPacking,
      ExpedicionItemsSueltosTable.columnQuantity: quantity,
      ExpedicionItemsSueltosTable.columnUom: uom,
      ExpedicionItemsSueltosTable.columnIsValidate: isValidate == true ? 1 : 0,
      ExpedicionItemsSueltosTable.columnOrigen: origen,
      ExpedicionItemsSueltosTable.columnSyncPending: syncPending == true ? 1 : 0,
    };
  }
}
