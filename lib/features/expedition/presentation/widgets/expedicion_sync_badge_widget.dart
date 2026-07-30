import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Chip de estado de sincronización para las cards de la tab "Listo":
/// - [syncPending] = true  → naranja "Pendiente de envío" (validado sin
///   conexión, aún no llega al backend; el coordinator lo reintenta solo).
/// - [syncPending] = false → verde "Enviado a WMS" (ya confirmado en el backend).
class ExpedicionSyncBadge extends StatelessWidget {
  final bool syncPending;

  const ExpedicionSyncBadge({super.key, required this.syncPending});

  @override
  Widget build(BuildContext context) {
    final color = syncPending ? Colors.orange[800]! : green;
    final icon = syncPending ? Icons.cloud_off : Icons.cloud_done;
    final label = syncPending ? 'Pendiente de envío' : 'Enviado a WMS';

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
