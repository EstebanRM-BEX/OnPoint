import 'package:equatable/equatable.dart';

class PedidoValidate extends Equatable {
  final int? batchId;
  final String? namePedido;
  final int? idPicking;
  final int? idPedido;
  final String? muelle;
  final int? idMuelle;
  final String? barcodeMuelle;
  final bool? isValidated;

  const PedidoValidate({
    this.batchId,
    this.namePedido,
    this.idPicking,
    this.idPedido,
    this.muelle,
    this.idMuelle,
    this.barcodeMuelle,
    this.isValidated,
  });

  @override
  List<Object?> get props => [
        batchId,
        namePedido,
        idPicking,
        idPedido,
        muelle,
        idMuelle,
        barcodeMuelle,
        isValidated,
      ];
}
