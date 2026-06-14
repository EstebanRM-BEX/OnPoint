// lib/features/inventario/data/models/resultado_envio_inventario_model.dart

import 'package:wms_app/features/inventario/domain/entities/resultado_envio_inventario.dart';

class ResultadoEnvioInventarioModel extends ResultadoEnvioInventario {
  const ResultadoEnvioInventarioModel({
    super.status,
    super.message,
    super.data,
  });

  factory ResultadoEnvioInventarioModel.fromMap(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;
    return ResultadoEnvioInventarioModel(
      status: result?['status'] as String?,
      message: result?['message'] as String?,
      data: result?['data'] as int?,
    );
  }
}
