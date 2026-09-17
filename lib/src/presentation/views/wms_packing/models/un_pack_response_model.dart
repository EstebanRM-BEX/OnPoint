// Respuesta de `transferencias/unpacking` (packing por pedido).
//
// `result.result` mezcla dos tipos de item:
//  - un stock.move por cada producto desempacado (trae `id_move`)
//  - opcionalmente `{code, msg}` cuando el paquete quedó vacío y se eliminó
class UnPackResponse {
  final int? code;
  final String? msg;
  final List<UnPackedMove> moves;

  /// true si el backend eliminó el paquete (item `{code, msg}` sin `id_move`).
  final bool packageDeleted;

  UnPackResponse({
    this.code,
    this.msg,
    this.moves = const [],
    this.packageDeleted = false,
  });

  factory UnPackResponse.fromMap(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is! Map<String, dynamic>) return UnPackResponse();

    final items = result['result'] is List ? result['result'] as List : [];
    final moves = <UnPackedMove>[];
    bool packageDeleted = false;
    String? msg = result['msg']?.toString();

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      if (item['id_move'] != null) {
        moves.add(UnPackedMove.fromMap(item));
      } else if (item['msg'] != null && item['code'] == 200) {
        packageDeleted = true;
        msg ??= item['msg'].toString();
      }
    }

    return UnPackResponse(
      code: result['code'],
      msg: msg,
      moves: moves,
      packageDeleted: packageDeleted,
    );
  }

  UnPackedMove? moveFor(int idMove) {
    for (final move in moves) {
      if (move.idMove == idMove) return move;
    }
    return null;
  }

  /// Busca el move desempacado por producto, lote y ubicación de origen.
  ///
  /// NO sirve buscar por `id_move`: al dividir, Odoo le da un movimiento nuevo
  /// a la parte empacada, mientras que esta respuesta trae el movimiento donde
  /// queda la cantidad en "por hacer". Si solo viene un item, ese es.
  UnPackedMove? moveForProduct({
    int? idProduct,
    dynamic loteId,
    String? barcodeLocation,
  }) {
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;

    final porProducto = moves
        .where((m) => idProduct == null || m.idProduct == idProduct)
        .toList();
    if (porProducto.length == 1) return porProducto.first;
    if (porProducto.isEmpty) return null;

    for (final move in porProducto) {
      final mismoLote =
          loteId == null || '${move.raw['lote_id'] ?? 0}' == '${loteId ?? 0}';
      final mismaUbicacion = barcodeLocation == null ||
          '${move.raw['barcode_location'] ?? ''}' == barcodeLocation;
      if (mismoLote && mismaUbicacion) return move;
    }
    return porProducto.first;
  }
}

class UnPackedMove {
  final int? idMove;
  final int? pedidoId;
  final int? idProduct;
  final String? productName;

  /// Total del move que queda POR HACER tras desempacar (no es lo desempacado):
  /// incluye lo que el operario ya tenga separado sin empacar en el dispositivo.
  final double? quantity;
  final double? quantityOrdered;
  final double? quantityToTransfer;
  final double? cantidadFaltante;
  final int? idPaquete;
  final String? namePaquete;
  final int? cantidadProductosEnElPaquete;

  /// Mapa crudo del item, para refrescar en SQLite los campos que manda el
  /// backend (ubicaciones, barcodes, lote, uom…) al devolver la fila a
  /// "por hacer".
  final Map<String, dynamic> raw;

  UnPackedMove({
    this.idMove,
    this.pedidoId,
    this.idProduct,
    this.productName,
    this.quantity,
    this.quantityOrdered,
    this.quantityToTransfer,
    this.cantidadFaltante,
    this.idPaquete,
    this.namePaquete,
    this.cantidadProductosEnElPaquete,
    this.raw = const {},
  });

  static double? _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}');

  /// Primer elemento de un campo Odoo `[id, nombre]`.
  static int? _refId(dynamic value) =>
      (value is List && value.isNotEmpty && value.first is int)
      ? value.first as int
      : null;

  /// Segundo elemento de un campo Odoo `[id, nombre]`.
  static String? _refName(dynamic value) =>
      (value is List && value.length > 1) ? '${value[1]}' : null;

  int? get idLocation => _refId(raw['location_id']);
  String? get locationName => _refName(raw['location_id']);
  int? get idLocationDest => _refId(raw['location_dest_id']);
  String? get locationDestName => _refName(raw['location_dest_id']);
  String? get barcodeLocation => raw['barcode_location']?.toString();
  String? get barcodeLocationDest => raw['barcode_location_dest']?.toString();
  String? get tracking => raw['tracking']?.toString();
  String? get unidades => raw['unidades']?.toString();
  double? get weight => _toDouble(raw['weight']);

  factory UnPackedMove.fromMap(Map<String, dynamic> json) => UnPackedMove(
    idMove: json['id_move'],
    pedidoId: json['pedido_id'],
    idProduct: json['id_product'],
    productName: json['product_name'],
    quantity: _toDouble(json['quantity']),
    quantityOrdered: _toDouble(json['quantity_ordered']),
    quantityToTransfer: _toDouble(json['quantity_to_transfer']),
    cantidadFaltante: _toDouble(json['cantidad_faltante']),
    idPaquete: json['id_paquete'],
    namePaquete: json['name_paquete'],
    cantidadProductosEnElPaquete: json['cantidad_productos_en_el_paquete'],
    raw: json,
  );
}
