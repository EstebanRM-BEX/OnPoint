// lib/features/inventario/data/models/resultado_crear_lote_model.dart

import 'package:wms_app/features/inventario/data/models/lote_producto_inventario_model.dart';
import 'package:wms_app/features/inventario/domain/entities/resultado_crear_lote.dart';

class ResultadoCrearLoteModel extends ResultadoCrearLote {
  const ResultadoCrearLoteModel({
    super.code,
    super.msg,
    super.lote,
  });

  factory ResultadoCrearLoteModel.fromMap(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>?;
    final loteJson = result?['result'];
    return ResultadoCrearLoteModel(
      code: result?['code'] as int?,
      msg: result?['msg'] as String?,
      lote: loteJson != null
          ? LoteProductoInventarioModel.fromMap(loteJson as Map<String, dynamic>)
          : null,
    );
  }
}
