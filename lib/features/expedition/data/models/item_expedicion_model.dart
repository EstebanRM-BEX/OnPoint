import 'package:wms_app/features/expedition/data/models/expedicion_json_utils.dart';
import 'package:wms_app/features/expedition/domain/entities/item_expedicion.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_items/expedicion_items_table.dart';

class ItemExpedicionModel extends ItemExpedicion {
  const ItemExpedicionModel({
    super.packingId,
    super.packageName,
    super.expeditionId,
    super.isValidate,
    super.productoId,
    super.productName,
    super.productCode,
    super.barcode,
    super.tracking,
    super.diasVencimiento,
    super.quantity,
    super.uom,
  });

  factory ItemExpedicionModel.fromJson(Map<String, dynamic> json) {
    return ItemExpedicionModel(
      packingId: dynamicToInt(json['packing_id']),
      packageName: dynamicToString(json['package_name']),
      expeditionId: dynamicToInt(json['expedition_id']),
      isValidate: dynamicToBool(json['is_validate']),
      productoId: dynamicToInt(json['producto_id']),
      productName: dynamicToString(json['product_name']),
      productCode: dynamicToString(json['product_code']),
      barcode: dynamicToString(json['barcode']),
      tracking: dynamicToString(json['tracking']),
      diasVencimiento: dynamicToInt(json['dias_vencimiento']),
      quantity: dynamicToDouble(json['quantity']),
      uom: dynamicToString(json['uom']),
    );
  }

  factory ItemExpedicionModel.fromMap(Map<String, dynamic> map) {
    return ItemExpedicionModel(
      packingId: map[ExpedicionItemsTable.columnPackingId] as int?,
      packageName: map[ExpedicionItemsTable.columnPackageName] as String?,
      expeditionId: map[ExpedicionItemsTable.columnExpeditionId] as int?,
      isValidate: (map[ExpedicionItemsTable.columnIsValidate] as int?) == 1,
      productoId: map[ExpedicionItemsTable.columnProductoId] as int?,
      productName: map[ExpedicionItemsTable.columnProductName] as String?,
      productCode: map[ExpedicionItemsTable.columnProductCode] as String?,
      barcode: map[ExpedicionItemsTable.columnBarcode] as String?,
      tracking: map[ExpedicionItemsTable.columnTracking] as String?,
      diasVencimiento:
          map[ExpedicionItemsTable.columnDiasVencimiento] as int?,
      quantity: (map[ExpedicionItemsTable.columnQuantity] as num?)?.toDouble(),
      uom: map[ExpedicionItemsTable.columnUom] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ExpedicionItemsTable.columnPackingId: packingId,
      ExpedicionItemsTable.columnPackageName: packageName,
      ExpedicionItemsTable.columnExpeditionId: expeditionId,
      ExpedicionItemsTable.columnIsValidate: isValidate == true ? 1 : 0,
      ExpedicionItemsTable.columnProductoId: productoId,
      ExpedicionItemsTable.columnProductName: productName,
      ExpedicionItemsTable.columnProductCode: productCode,
      ExpedicionItemsTable.columnBarcode: barcode,
      ExpedicionItemsTable.columnTracking: tracking,
      ExpedicionItemsTable.columnDiasVencimiento: diasVencimiento,
      ExpedicionItemsTable.columnQuantity: quantity,
      ExpedicionItemsTable.columnUom: uom,
    };
  }
}
