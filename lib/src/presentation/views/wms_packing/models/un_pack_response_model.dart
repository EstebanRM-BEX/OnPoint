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
}

class UnPackedMove {
  final int? idMove;
  final int? pedidoId;
  final int? idProduct;
  final String? productName;

  /// Cantidad desempacada de esta línea.
  final double? quantity;
  final double? quantityOrdered;
  final double? quantityToTransfer;

  /// Total pendiente (sin empacar) del move en el backend tras desempacar.
  final double? cantidadFaltante;
  final int? idPaquete;
  final String? namePaquete;
  final int? cantidadProductosEnElPaquete;

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
  });

  static double? _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('${value ?? ''}');

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
  );
}
