import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_multiusuario_json_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

class RecepcionClaimModel extends RecepcionClaim {
  const RecepcionClaimModel({
    super.id,
    super.taskId,
    super.productId,
    super.productName,
    super.barcode,
    super.qtyAsignada,
    super.qtyRecibida,
    super.uom,
    super.state,
    super.lotId,
    super.lotName,
    super.fechaAsignacion,
    super.bloqueadoHasta,
    super.observacion,
    super.notaCorreccion,
    super.locationId,
    super.locationName,
    super.locationBarcode,
    super.locationDestId,
    super.locationDestName,
    super.locationDestBarcode,
    super.idMove,
    super.productCode,
    super.productBarcode,
    super.productTracking,
    super.fechaVencimiento,
    super.diasVencimiento,
    super.useExpirationDate,
    super.weight,
    super.cantidadFaltante,
    super.manejaTemperatura,
    super.temperatura,
    super.manejaSegundaUnidad,
    super.uomSegundaUnidad,
    super.otherBarcodes,
    super.productPacking,
  });

  static List<Barcodes> _parseBarcodes(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((json) => Barcodes.fromMap(json))
        .toList();
  }

  /// `result.data` de POST /api/receipt/claim (o cada item de
  /// /api/receipt/session/{id}/my_claims) cuando `status == "success"`.
  factory RecepcionClaimModel.fromJson(Map<String, dynamic> json) {
    return RecepcionClaimModel(
      id: dynamicToInt(json['id']),
      taskId: dynamicToInt(json['task_id']),
      productId: dynamicToInt(json['product_id']),
      productName: dynamicToString(json['product_name']),
      barcode: dynamicToString(json['barcode']),
      qtyAsignada: dynamicToDouble(json['qty_asignada']),
      qtyRecibida: dynamicToDouble(json['qty_recibida']),
      uom: dynamicToString(json['uom']),
      state: dynamicToString(json['state']),
      // lot_id llega en `false` cuando el producto no maneja lote.
      lotId: dynamicToInt(json['lot_id']),
      lotName: dynamicToString(json['lot_name']),
      fechaAsignacion: dynamicToString(json['fecha_asignacion']),
      bloqueadoHasta: dynamicToString(json['bloqueado_hasta']),
      observacion: dynamicToString(json['observacion']),
      notaCorreccion: dynamicToString(json['nota_correccion']),
      locationId: dynamicToInt(json['location_id']),
      locationName: dynamicToString(json['location_name']),
      locationBarcode: dynamicToString(json['location_barcode']),
      locationDestId: dynamicToInt(json['location_dest_id']),
      locationDestName: dynamicToString(json['location_dest_name']),
      locationDestBarcode: dynamicToString(json['location_dest_barcode']),
      idMove: dynamicToInt(json['id_move']),
      productCode: dynamicToString(json['product_code']),
      productBarcode: dynamicToString(json['product_barcode']),
      productTracking: dynamicToString(json['product_tracking']),
      fechaVencimiento: dynamicToString(json['fecha_vencimiento']),
      diasVencimiento: dynamicToInt(json['dias_vencimiento']),
      useExpirationDate: dynamicToBool(json['use_expiration_date']),
      weight: dynamicToDouble(json['weight']),
      cantidadFaltante: dynamicToDouble(json['cantidad_faltante']),
      manejaTemperatura: dynamicToBool(json['maneja_temperatura']),
      temperatura: dynamicToDouble(json['temperatura']),
      manejaSegundaUnidad: dynamicToBool(json['maneja_segunda_unidad']),
      uomSegundaUnidad: dynamicToString(json['uom_segunda_unidad']),
      otherBarcodes: _parseBarcodes(json['other_barcodes']),
      productPacking: _parseBarcodes(json['product_packing']),
    );
  }
}
