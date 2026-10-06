import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/zona_trabajo.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';

/// Zonas de trabajo de un batch (desde la tarjeta de Pick Cluster): nombre de
/// la zona, estado y operario asignado.
class ClusterZonasTrabajoDialog extends StatelessWidget {
  final String batchName;
  final List<ZonaTrabajo> zonas;

  const ClusterZonasTrabajoDialog({
    super.key,
    required this.batchName,
    required this.zonas,
  });

  static Future<void> show(
    BuildContext context, {
    required String batchName,
    required List<ZonaTrabajo> zonas,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          ClusterZonasTrabajoDialog(batchName: batchName, zonas: zonas),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      Icons.map_outlined,
                      color: ClusterPalette.brand600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zonas de $batchName',
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
                          '${zonas.length} zona(s) de trabajo',
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
                  itemCount: zonas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ZonaRow(zona: zonas[i]),
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

class _ZonaRow extends StatelessWidget {
  final ZonaTrabajo zona;

  const _ZonaRow({required this.zona});

  @override
  Widget build(BuildContext context) {
    final asignada = zona.estado?.toLowerCase() == 'asignada';
    final tieneUsuario = zona.userName != null && zona.userName!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: asignada ? const Color(0xFFF3FBF7) : ClusterPalette.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: asignada ? const Color(0xFFA7F3D0) : ClusterPalette.slate200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zona.name ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ClusterPalette.brand700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 13,
                      color: ClusterPalette.slate400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tieneUsuario ? zona.userName! : 'Sin operario',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ClusterPalette.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: asignada
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _label(zona.estado),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: asignada
                    ? const Color(0xFF065F46)
                    : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String? estado) {
    if (estado == null || estado.isEmpty) return 'Sin estado';
    return estado[0].toUpperCase() + estado.substring(1);
  }
}
