import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

/// Resultado de reclamar ("tomar") un producto libre de una sesión de
/// transferencia multiusuario (POST /api/transfer/claim). Mientras
/// [bloqueadoHasta] no venza, el producto queda bloqueado para el operario
/// que lo reclamó — nadie más puede tomarlo.
///
/// Espejo de RecepcionClaim, con bastantes campos extra que trae esta
/// respuesta (algunos duplicados en dos idiomas de clave — se guardan
/// ambos porque no está confirmado cuál usan las pantallas siguientes):
/// [ubicacionOrigen]/[ubicacionDestino] duplican [locationId]/
/// [locationDestId]; [claimedAt]/[lockedUntil]/[doneAt]/[observation]/
/// [correctionNote] duplican sus equivalentes en español.
class TransferenciaClaim {
  final int? id;
  final int? taskId;
  final int? productId;
  final String? productName;
  final String? barcode;
  final double? qtyAsignada;
  final double? qtyAlmacenada;
  final double? qtyRecibida;
  final String? uom;
  final String? state;
  final int? lotId;
  final String? lotName;
  final double? timeSeconds;
  final double? time;
  final double? tiempoHoras;
  final String? fechaAsignacion;
  final String? fechaCompletado;
  final String? bloqueadoHasta;
  final String? observacion;
  final String? notaCorreccion;
  final double? qtyClaimed;
  final double? qtyDone;
  final String? claimedAt;
  final String? lockedUntil;
  final String? doneAt;
  final String? observation;
  final String? correctionNote;

  /// Modelo Odoo subyacente de esta línea (ej. "stock.move").
  final String? model;

  /// Ubicación de origen del producto.
  final int? locationId;
  final String? locationName;
  final String? locationBarcode;
  final int? ubicacionOrigen;

  /// Ubicación destino del producto.
  final int? locationDestId;
  final String? locationDestName;
  final String? locationDestBarcode;
  final int? ubicacionDestino;
  final int? locationDestDefaultId;
  final String? locationDestDefaultName;
  final int? locationStockId;
  final String? locationStockName;
  final bool? esIntAlmacenamiento;
  final bool? recepcionUnPaso;

  /// Resto de la info de la línea (stock.move) que viene enriquecida en
  /// /api/transfer/claim.
  final int? idMove;
  final String? productCode;
  final String? productBarcode;
  final String? productTracking;
  final String? fechaVencimiento;
  final int? diasVencimiento;
  final bool? useExpirationDate;
  final double? weight;
  final double? cantidadFaltante;
  final bool? manejaTemperatura;
  final double? temperatura;
  final bool? manejaSegundaUnidad;
  final String? uomSegundaUnidad;
  final List<Barcodes> otherBarcodes;
  final List<Barcodes> productPacking;

  const TransferenciaClaim({
    this.id,
    this.taskId,
    this.productId,
    this.productName,
    this.barcode,
    this.qtyAsignada,
    this.qtyAlmacenada,
    this.qtyRecibida,
    this.uom,
    this.state,
    this.lotId,
    this.lotName,
    this.timeSeconds,
    this.time,
    this.tiempoHoras,
    this.fechaAsignacion,
    this.fechaCompletado,
    this.bloqueadoHasta,
    this.observacion,
    this.notaCorreccion,
    this.qtyClaimed,
    this.qtyDone,
    this.claimedAt,
    this.lockedUntil,
    this.doneAt,
    this.observation,
    this.correctionNote,
    this.model,
    this.locationId,
    this.locationName,
    this.locationBarcode,
    this.ubicacionOrigen,
    this.locationDestId,
    this.locationDestName,
    this.locationDestBarcode,
    this.ubicacionDestino,
    this.locationDestDefaultId,
    this.locationDestDefaultName,
    this.locationStockId,
    this.locationStockName,
    this.esIntAlmacenamiento,
    this.recepcionUnPaso,
    this.idMove,
    this.productCode,
    this.productBarcode,
    this.productTracking,
    this.fechaVencimiento,
    this.diasVencimiento,
    this.useExpirationDate,
    this.weight,
    this.cantidadFaltante,
    this.manejaTemperatura,
    this.temperatura,
    this.manejaSegundaUnidad,
    this.uomSegundaUnidad,
    this.otherBarcodes = const [],
    this.productPacking = const [],
  });

  /// true si este producto maneja lote. `lot_id` no sirve para esto: llega
  /// null también cuando SÍ maneja lote pero todavía no se le asignó uno —
  /// lo que indica si maneja lote es `product_tracking`: "lot" maneja,
  /// "none" no. Mismo criterio que RecepcionClaim.
  bool get manejaLote => productTracking == 'lot';
}
