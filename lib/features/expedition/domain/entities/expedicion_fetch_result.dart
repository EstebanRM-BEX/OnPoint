import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';

class ExpedicionFetchResult {
  final List<ExpedicionPedido> expediciones;
  final bool needsUpdate;

  const ExpedicionFetchResult({
    required this.expediciones,
    required this.needsUpdate,
  });
}
