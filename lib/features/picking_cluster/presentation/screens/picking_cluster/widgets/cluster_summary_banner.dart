import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';

/// Resumen operativo: cantidad de clusters visibles y, si todos comparten
/// bodega, la etiqueta de la bodega.
class ClusterSummaryBanner extends StatelessWidget {
  final int count;
  final String? warehouse;

  const ClusterSummaryBanner({super.key, required this.count, this.warehouse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ClusterPalette.slate200)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: count > 0
                  ? ClusterPalette.emerald500
                  : ClusterPalette.slate400,
              shape: BoxShape.circle,
              boxShadow: [
                if (count > 0)
                  BoxShadow(
                    color: ClusterPalette.emerald500.withOpacity(0.3),
                    spreadRadius: 3,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'Cluster Disponible' : 'Clusters Disponibles'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ClusterPalette.slate700,
              ),
            ),
          ),
          if (warehouse != null && warehouse!.isNotEmpty)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ClusterPalette.slate100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ClusterPalette.slate200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warehouse_rounded,
                      size: 12,
                      color: ClusterPalette.brand600,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        warehouse!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: ClusterPalette.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
