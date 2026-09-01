import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

/// Resultado de reclamar ("tomar") un producto libre de una sesión de
/// recepción multiusuario (POST /api/receipt/claim). Mientras
/// [bloqueadoHasta] no venza, el producto queda bloqueado para el operario
/// que lo reclamó — nadie más puede tomarlo.
class RecepcionClaim {
  final int? id;
  final int? taskId;
  final int? productId;
  final String? productName;
  final String? barcode;
  final double? qtyAsignada;
  final double? qtyRecibida;
  final String? uom;
  final String? state;
  final int? lotId;
  final String? lotName;
  final String? fechaAsignacion;
  final String? bloqueadoHasta;
  final String? observacion;
  final String? notaCorreccion;

  /// Ubicación de origen del producto.
  final int? locationId;
  final String? locationName;
  final String? locationBarcode;

  /// Ubicación destino del producto.
  final int? locationDestId;
  final String? locationDestName;
  final String? locationDestBarcode;

  /// Resto de la info de la línea (stock.move) que viene enriquecida en
  /// /api/receipt/claim y /api/receipt/session/{id}/my_claims — no en la
  /// respuesta original y más chica del claim.
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

  const RecepcionClaim({
    this.id,
    this.taskId,
    this.productId,
    this.productName,
    this.barcode,
    this.qtyAsignada,
    this.qtyRecibida,
    this.uom,
    this.state,
    this.lotId,
    this.lotName,
    this.fechaAsignacion,
    this.bloqueadoHasta,
    this.observacion,
    this.notaCorreccion,
    this.locationId,
    this.locationName,
    this.locationBarcode,
    this.locationDestId,
    this.locationDestName,
    this.locationDestBarcode,
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
  /// null también cuando SÍ maneja lote pero todavía no se le asignó uno
  /// (lote pendiente de escanear/crear) — lo que indica si maneja lote es
  /// `product_tracking`: "lot" maneja, "none" no.
  bool get manejaLote => productTracking == 'lot';
}
