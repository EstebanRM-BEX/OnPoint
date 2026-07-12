import 'package:wms_app/features/expedition/data/models/expedicion_json_utils.dart';
import 'package:wms_app/features/expedition/data/models/item_expedicion_model.dart';
import 'package:wms_app/features/expedition/domain/entities/item_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_paquetes/expedicion_paquetes_table.dart';

class PaqueteExpedicionModel extends PaqueteExpedicion {
  const PaqueteExpedicionModel({
    super.expeditionId,
    super.packingId,
    super.packageName,
    super.packingBarcode,
    super.packingType,
    super.orderPacking,
    super.isValidate,
    super.items = const [],
  });

  factory PaqueteExpedicionModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'] == null
        ? <ItemExpedicion>[]
        : List<ItemExpedicion>.from((json['items'] as List)
            .map((x) => ItemExpedicionModel.fromJson(x as Map<String, dynamic>)));

    return PaqueteExpedicionModel(
      expeditionId: dynamicToInt(json['expedition_id']),
      packingId: dynamicToInt(json['packing_id']),
      packageName: dynamicToString(json['package_name']),
      packingBarcode: dynamicToString(json['packing_barcode']),
      packingType: dynamicToString(json['packing_type']),
      orderPacking: dynamicToInt(json['order_packing']),
      isValidate: dynamicToBool(json['is_validate']),
      items: items,
    );
  }

  factory PaqueteExpedicionModel.fromMap(Map<String, dynamic> map) {
    return PaqueteExpedicionModel(
      expeditionId: map[ExpedicionPaquetesTable.columnExpeditionId] as int?,
      packingId: map[ExpedicionPaquetesTable.columnPackingId] as int?,
      packageName: map[ExpedicionPaquetesTable.columnPackageName] as String?,
      packingBarcode:
          map[ExpedicionPaquetesTable.columnPackingBarcode] as String?,
      packingType: map[ExpedicionPaquetesTable.columnPackingType] as String?,
      orderPacking: map[ExpedicionPaquetesTable.columnOrderPacking] as int?,
      isValidate:
          (map[ExpedicionPaquetesTable.columnIsValidate] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ExpedicionPaquetesTable.columnExpeditionId: expeditionId,
      ExpedicionPaquetesTable.columnPackingId: packingId,
      ExpedicionPaquetesTable.columnPackageName: packageName,
      ExpedicionPaquetesTable.columnPackingBarcode: packingBarcode,
      ExpedicionPaquetesTable.columnPackingType: packingType,
      ExpedicionPaquetesTable.columnOrderPacking: orderPacking,
      ExpedicionPaquetesTable.columnIsValidate: isValidate == true ? 1 : 0,
    };
  }

  /// Usado al leer de SQLite: los items de un paquete se consultan aparte
  /// (tbl_expedicion_items, por packing_id) y se adjuntan acá.
  PaqueteExpedicionModel copyWithItems(List<ItemExpedicion> newItems) {
    return PaqueteExpedicionModel(
      expeditionId: expeditionId,
      packingId: packingId,
      packageName: packageName,
      packingBarcode: packingBarcode,
      packingType: packingType,
      orderPacking: orderPacking,
      isValidate: isValidate,
      items: newItems,
    );
  }
}
