import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_asignacion_observacion.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_pool_item.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_novedades_dialog_widget.dart';

/// Card de un producto con transferencias terminadas (tab "Terminados").
/// Espejo de RecepcionTerminadoCardWidget: usa qtyAlmacenada en vez de
/// qtyRecibida (alias de transferencia para lo mismo, ver
/// TransferenciaClaimCardWidget).
///
/// El encabezado muestra SOLO lo del producto/tarea en sí: nombre,
/// cantidad demandada/almacenada/disponible, unidad y estado de la tarea
/// (`task_state`) — no mezcla datos de ninguna asignación puntual.
///
/// El detalle de cada asignación (operario, cantidad, fecha, ubicación
/// destino, novedad, tiempo, y el ícono para deshacerla) vive en el
/// diálogo [TransferenciaNovedadesDialogWidget], abierto con "Ver detalles".
class TransferenciaTerminadoCardWidget extends StatelessWidget {
  const TransferenciaTerminadoCardWidget({
    super.key,
    required this.item,
    required this.observaciones,
    required this.sessionId,
  });

  final TransferenciaPoolItem item;

  /// Asignaciones terminadas de este producto (ya deduplicadas por quien
  /// arma la lista, ver transferencia_multiusuario_detail_tab_terminados.dart).
  final List<TransferenciaAsignacionObservacion> observaciones;

  /// Necesario para refrescar el pool tras un deshacer exitoso (ver
  /// [TransferenciaNovedadesDialogWidget]).
  final int? sessionId;

  String _taskStateLabel(String? state) {
    switch (state) {
      case 'open':
        return 'Abierta';
      case 'done':
        return 'Completada';
      case 'cancel':
        return 'Cancelada';
      default:
        return state ?? '';
    }
  }

  Color _taskStateColor(String? state) {
    switch (state) {
      case 'open':
        return Colors.orange;
      case 'done':
        return green;
      case 'cancel':
        return red;
      default:
        return grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Card(
        color: white,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // encabezado del producto — solo datos de la tarea
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.productName ?? '',
                      style: TextStyle(
                        color: primaryColorApp,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.taskState != null && item.taskState!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _taskStateColor(
                          item.taskState,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _taskStateLabel(item.taskState),
                        style: TextStyle(
                          color: _taskStateColor(item.taskState),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.assignment_outlined,
                label: 'Demandada:',
                value: '${item.qtyDemanded ?? 0} ${item.uom ?? ''}',
              ),
              _InfoRow(
                icon: Icons.inventory_2_outlined,
                label: 'Almacenada:',
                value: '${item.qtyAlmacenada ?? 0} ${item.uom ?? ''}',
              ),
              _InfoRow(
                icon: Icons.inventory_outlined,
                label: 'Por hacer:',
                value: '${item.qtyAvailable ?? 0} ${item.uom ?? ''}',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => TransferenciaNovedadesDialogWidget(
                      productName: item.productName ?? '',
                      observaciones: item.observaciones,
                      sessionId: sessionId,
                      uom: item.uom,
                    ),
                  ),
                  icon: Icon(
                    Icons.report_gmailerrorred_outlined,
                    color: primaryColorApp,
                    size: 18,
                  ),
                  label: Text(
                    'Ver detalles (${item.observaciones.length})',
                    style: TextStyle(color: primaryColorApp, fontSize: 13),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 14, color: grey),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: black)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
