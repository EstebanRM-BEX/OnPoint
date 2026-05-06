import 'dart:convert';

class MovimientoPack {
  final int idTransferencia;
  final int idPaquete;
  final int idUbicacionDestino;

  MovimientoPack({
    required this.idTransferencia,
    required this.idPaquete,
    required this.idUbicacionDestino,
  });

  Map<String, dynamic> toMap() => {
        "id_transferencia": idTransferencia,
        "id_paquete": idPaquete,
        "id_ubicacion_destino": idUbicacionDestino,
      };
}

class AssignLocationPackRequest {
  final List<MovimientoPack> movimientos;

  AssignLocationPackRequest({required this.movimientos});

  Map<String, dynamic> toMap() => {
        "params": {
          "movimientos": movimientos.map((m) => m.toMap()).toList(),
        }
      };

  String toJson() => json.encode(toMap());
}
