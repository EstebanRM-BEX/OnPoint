import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';

/// Pedidos de un batch (desde la tarjeta de Pick Cluster): número, muelle,
/// barcode del muelle y si ya fue validado.
class BatchPedidosDialog extends StatelessWidget {
  final String batchName;
  final List<PedidoValidate> pedidos;

  const BatchPedidosDialog({
    super.key,
    required this.batchName,
    required this.pedidos,
  });

  static Future<void> show(
    BuildContext context, {
    required String batchName,
    required List<PedidoValidate> pedidos,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          BatchPedidosDialog(batchName: batchName, pedidos: pedidos),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validated = pedidos.where((p) => p.isValidated == true).length;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ClusterPalette.brand50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: ClusterPalette.brand600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedidos de $batchName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ClusterPalette.slate900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pedidos.length} pedido(s) · $validated validado(s)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ClusterPalette.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pedidos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _PedidoRow(pedido: pedidos[i]),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PedidoRow extends StatelessWidget {
  final PedidoValidate pedido;

  const _PedidoRow({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final validated = pedido.isValidated == true;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: validated ? const Color(0xFFF3FBF7) : ClusterPalette.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: validated ? const Color(0xFFA7F3D0) : ClusterPalette.slate200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pedido.namePedido ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ClusterPalette.brand700,
                  ),
                ),
                const SizedBox(height: 4),
                _InfoLine(
                  icon: Icons.domain,
                  text: pedido.muelle ?? 'Sin muelle',
                ),
                const SizedBox(height: 2),
                _InfoLine(
                  icon: Icons.qr_code_2,
                  text: pedido.barcodeMuelle ?? 'N/A',
                  monospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: validated
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              validated ? 'Validado' : 'Por validar',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: validated
                    ? const Color(0xFF065F46)
                    : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool monospace;

  const _InfoLine({
    required this.icon,
    required this.text,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: ClusterPalette.slate400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontFamily: monospace ? 'monospace' : null,
              color: ClusterPalette.slate600,
            ),
          ),
        ),
      ],
    );
  }
}
