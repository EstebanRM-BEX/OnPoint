import 'package:wms_app/src/presentation/views/wms_packing/models/un_pack_response_model.dart';

/// Respuesta de `transferencias/delete_pack` (eliminar un paquete completo).
///
/// `result.result` trae el paquete eliminado y los stock.move que estaban
/// dentro. Cada item tiene la misma forma que los de `transferencias/unpacking`
/// (por eso se reutiliza [UnPackedMove]), así que la reconciliación con "por
/// hacer" es la misma que al desempacar una sola línea.
class DeletePackResponse {
  final int? code;
  final String? msg;
  final DeletedPackage? paquete;
  final List<UnPackedMove> items;

  DeletePackResponse({
    this.code,
    this.msg,
    this.paquete,
    this.items = const [],
  });

  factory DeletePackResponse.fromMap(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is! Map<String, dynamic>) return DeletePackResponse();

    final data = result['result'];
    final paquete = (data is Map<String, dynamic> && data['paquete'] is Map)
        ? DeletedPackage.fromMap(Map<String, dynamic>.from(data['paquete']))
        : null;

    final rawItems = (data is Map<String, dynamic> && data['items'] is List)
        ? data['items'] as List
        : const [];

    return DeletePackResponse(
      code: result['code'],
      msg: (result['mensaje'] ?? result['msg'])?.toString(),
      paquete: paquete,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(UnPackedMove.fromMap)
          .toList(),
    );
  }
}

class DeletedPackage {
  final int? id;
  final String? name;
  final String? packingBarcode;
  final int? pedidoId;
  final int? cantidadProductos;
  final dynamic consecutivo;

  DeletedPackage({
    this.id,
    this.name,
    this.packingBarcode,
    this.pedidoId,
    this.cantidadProductos,
    this.consecutivo,
  });

  factory DeletedPackage.fromMap(Map<String, dynamic> json) => DeletedPackage(
    id: json['id'],
    name: json['name'],
    packingBarcode: json['packing_barcode'],
    pedidoId: json['pedido_id'],
    cantidadProductos: json['cantidad_productos'],
    consecutivo: json['consecutivo'],
  );
}
