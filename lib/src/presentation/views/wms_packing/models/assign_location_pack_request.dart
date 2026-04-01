import 'dart:convert';

class AssignLocationPackRequest {
  final int idTransferencia;
  final int idPaquete;
  final int idUbicacionDestino;

  AssignLocationPackRequest({
    required this.idTransferencia,
    required this.idPaquete,
    required this.idUbicacionDestino,
  });

  Map<String, dynamic> toMap() {
    return {
      "params": {
        "id_transferencia": idTransferencia,
        "id_paquete": idPaquete,
        "id_ubicacion_destino": idUbicacionDestino,
      }
    };
  }

  String toJson() => json.encode(toMap());
}
