import 'picking_batch.dart';

/// Resultado de GET api/cluster/picking_batchs: los batches más los
/// encabezados secuencia_wms / placa_wms de la respuesta ('' si no llegan).
class PickingClusterFetchResult {
  final List<PickingBatch> batches;
  final String secuencia;
  final String placa;

  const PickingClusterFetchResult({
    required this.batches,
    this.secuencia = '',
    this.placa = '',
  });
}
