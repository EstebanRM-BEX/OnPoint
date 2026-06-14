// lib/features/inventario/domain/entities/resultado_envio_inventario.dart

class ResultadoEnvioInventario {
  final String? status;
  final String? message;
  final int? data;

  const ResultadoEnvioInventario({
    this.status,
    this.message,
    this.data,
  });
}
