import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/zona_trabajo.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';

/// Confirmación para liberar las zonas del usuario en el batch. Al aceptar,
/// el usuario sale del batch y otro operario puede continuar esas zonas.
class DialogLiberarZonasWidget extends StatelessWidget {
  final List<ZonaTrabajo> zonas;
  final VoidCallback onAccepted;

  const DialogLiberarZonasWidget({
    super.key,
    required this.zonas,
    required this.onAccepted,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: ClusterPalette.slate100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_open_outlined,
                    color: ClusterPalette.slate600,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Liberar zonas',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ClusterPalette.slate900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Se liberarán las zonas que tiene asignadas en este batch. Otro '
              'operario podrá continuarlas y usted volverá al listado de '
              'batches.',
              style: TextStyle(fontSize: 13, color: ClusterPalette.slate700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final zona in zonas)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      zona.name ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
              ],
            ),
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
                    child: const Text('Liberar'),
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
