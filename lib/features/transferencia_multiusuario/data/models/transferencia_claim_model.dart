import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_multiusuario_json_utils.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_claim.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

class TransferenciaClaimModel extends TransferenciaClaim {
  const TransferenciaClaimModel({
    super.id,
    super.taskId,
    super.productId,
    super.productName,
    super.barcode,
    super.qtyAsignada,
    super.qtyAlmacenada,
    super.qtyRecibida,
    super.uom,
    super.state,
    super.lotId,
    super.lotName,
    super.timeSeconds,
    super.time,
    super.tiempoHoras,
    super.fechaAsignacion,
    super.fechaCompletado,
    super.bloqueadoHasta,
    super.observacion,
    super.notaCorreccion,
    super.qtyClaimed,
    super.qtyDone,
    super.claimedAt,
    super.lockedUntil,
    super.doneAt,
    super.observation,
    super.correctionNote,
    super.model,
    super.locationId,
    super.locationName,
    super.locationBarcode,
    super.ubicacionOrigen,
    super.locationDestId,
    super.locationDestName,
    super.locationDestBarcode,
    super.ubicacionDestino,
    super.locationDestDefaultId,
    super.locationDestDefaultName,
    super.locationStockId,
    super.locationStockName,
    super.esIntAlmacenamiento,
    super.recepcionUnPaso,
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

  // other_barcodes/product_packing son la misma forma en todos los modelos
  // de este backend (id_product, id_move, cantidad, barcode, batch_id) —
  // confirmado, se reusa Barcodes (wms_picking/models/picking_batch_model.dart)
  // igual que RecepcionClaimModel.
  static List<Barcodes> _parseBarcodes(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((json) => Barcodes.fromMap(json))
        .toList();
  }

  /// `result.data` de POST /api/transfer/claim.
  factory TransferenciaClaimModel.fromJson(Map<String, dynamic> json) {
    return TransferenciaClaimModel(
      id: dynamicToInt(json['id']),
      taskId: dynamicToInt(json['task_id']),
      productId: dynamicToInt(json['product_id']),
      productName: dynamicToString(json['product_name']),
      barcode: dynamicToString(json['barcode']),
      qtyAsignada: dynamicToDouble(json['qty_asignada']),
      qtyAlmacenada: dynamicToDouble(json['qty_almacenada']),
      qtyRecibida: dynamicToDouble(json['qty_recibida']),
      uom: dynamicToString(json['uom']),
      state: dynamicToString(json['state']),
      // lot_id llega en `false` cuando el producto no maneja lote.
      lotId: dynamicToInt(json['lot_id']),
      lotName: dynamicToString(json['lot_name']),
      timeSeconds: dynamicToDouble(json['time_seconds']),
      time: dynamicToDouble(json['time']),
      tiempoHoras: dynamicToDouble(json['tiempo_horas']),
      fechaAsignacion: dynamicToString(json['fecha_asignacion']),
      fechaCompletado: dynamicToString(json['fecha_completado']),
      bloqueadoHasta: dynamicToString(json['bloqueado_hasta']),
      observacion: dynamicToString(json['observacion']),
      notaCorreccion: dynamicToString(json['nota_correccion']),
      qtyClaimed: dynamicToDouble(json['qty_claimed']),
      qtyDone: dynamicToDouble(json['qty_done']),
      claimedAt: dynamicToString(json['claimed_at']),
      lockedUntil: dynamicToString(json['locked_until']),
      doneAt: dynamicToString(json['done_at']),
      observation: dynamicToString(json['observation']),
      correctionNote: dynamicToString(json['correction_note']),
      model: dynamicToString(json['model']),
      locationId: dynamicToInt(json['location_id']),
      locationName: dynamicToString(json['location_name']),
      locationBarcode: dynamicToString(json['location_barcode']),
      ubicacionOrigen: dynamicToInt(json['ubicacion_origen']),
      locationDestId: dynamicToInt(json['location_dest_id']),
      locationDestName: dynamicToString(json['location_dest_name']),
      locationDestBarcode: dynamicToString(json['location_dest_barcode']),
      ubicacionDestino: dynamicToInt(json['ubicacion_destino']),
      locationDestDefaultId: dynamicToInt(json['location_dest_default_id']),
      locationDestDefaultName: dynamicToString(
        json['location_dest_default_name'],
      ),
      locationStockId: dynamicToInt(json['location_stock_id']),
      locationStockName: dynamicToString(json['location_stock_name']),
      esIntAlmacenamiento: dynamicToBool(json['es_int_almacenamiento']),
      recepcionUnPaso: dynamicToBool(json['recepcion_un_paso']),
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
