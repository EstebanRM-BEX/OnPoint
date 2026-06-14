// lib/features/inventario/domain/entities/resultado_crear_lote.dart

import 'package:wms_app/features/inventario/domain/entities/lote_producto_inventario.dart';

class ResultadoCrearLote {
  final int? code;
  final String? msg;
  final LoteProductoInventario? lote;

  const ResultadoCrearLote({
    this.code,
    this.msg,
    this.lote,
  });
}
