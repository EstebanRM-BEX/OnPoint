import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/zona_trabajo.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';

/// Diálogo al abrir un batch de Pick Cluster. Según el caso muestra:
/// - [mostrarInicioTiempo]: el aviso de que se registrará la hora de inicio
///   (solo si el batch aún no tiene tiempo iniciado).
/// - [zonasSinAsignar]: el aviso de que se asignarán al usuario todas las
///   zonas pendientes, que podrá liberar luego en los detalles del batch.
class DialogIniciarPickingClusterWidget extends StatelessWidget {
  final bool mostrarInicioTiempo;
  final List<ZonaTrabajo> zonasSinAsignar;
  final VoidCallback onAccepted;

  const DialogIniciarPickingClusterWidget({
    super.key,
    required this.mostrarInicioTiempo,
    required this.zonasSinAsignar,
    required this.onAccepted,
  });

  @override
  Widget build(BuildContext context) {
    final conZonas = zonasSinAsignar.isNotEmpty;
    final titulo = mostrarInicioTiempo ? 'Iniciar Picking' : 'Iniciar zona';

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                  child: Icon(
                    conZonas ? Icons.map_outlined : Icons.play_arrow_rounded,
                    color: ClusterPalette.brand600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ClusterPalette.slate900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (mostrarInicioTiempo)
              const Text(
                'Recuerde que una vez iniciado el proceso se registrará en el '
                'sistema su fecha y hora de inicio.',
                style: TextStyle(fontSize: 13, color: ClusterPalette.slate700),
              ),
            if (mostrarInicioTiempo && conZonas) const SizedBox(height: 12),
            if (conZonas) ...[
              const Text(
                'Se le asignarán todas las zonas pendientes de este batch como '
                'responsable. Podrá liberarlas más adelante desde los detalles '
                'del batch.',
                style: TextStyle(fontSize: 13, color: ClusterPalette.slate700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final zona in zonasSinAsignar)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        zona.name ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccepted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClusterPalette.brand600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Iniciar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
