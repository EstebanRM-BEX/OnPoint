import '../../domain/entities/pedido_validate.dart';

class PedidoValidateModel {
  final int? batchId;
  final String? namePedido;
  final int? idPicking;
  final int? idPedido;
  final String? muelle;
  final int? idMuelle;
  final String? barcodeMuelle;
  final bool? isValidated;

  PedidoValidateModel({
    this.batchId,
    this.namePedido,
    this.idPicking,
    this.idPedido,
    this.muelle,
    this.idMuelle,
    this.barcodeMuelle,
    this.isValidated,
  });

  factory PedidoValidateModel.fromJson(Map<String, dynamic> json) =>
      PedidoValidateModel(
        batchId: json["batch_id"],
        namePedido: json["name_pedido"],
        idPicking: json["id_picking"],
        idPedido: json["id_pedido"],
        muelle: json["muelle"],
        idMuelle: json["id_muelle"],
        barcodeMuelle: json["barcode_muelle"],
        isValidated: json["is_validated"] is bool
            ? json["is_validated"]
            : (json["is_validated"] == 1 || json["is_validated"] == "true"),
      );

  Map<String, dynamic> toJson() => {
        "batch_id": batchId,
        "name_pedido": namePedido,
        "id_picking": idPicking,
        "id_pedido": idPedido,
        "muelle": muelle,
        "id_muelle": idMuelle,
        "barcode_muelle": barcodeMuelle,
        "is_validated": isValidated,
      };

  PedidoValidate toEntity() => PedidoValidate(
        batchId: batchId,
        namePedido: namePedido,
        idPicking: idPicking,
        idPedido: idPedido,
        muelle: muelle,
        idMuelle: idMuelle,
        barcodeMuelle: barcodeMuelle,
        isValidated: isValidated,
      );

  factory PedidoValidateModel.fromEntity(PedidoValidate entity) =>
      PedidoValidateModel(
        batchId: entity.batchId,
        namePedido: entity.namePedido,
        idPicking: entity.idPicking,
        idPedido: entity.idPedido,
        muelle: entity.muelle,
        idMuelle: entity.idMuelle,
        barcodeMuelle: entity.barcodeMuelle,
        isValidated: entity.isValidated,
      );
}
