import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/asignacion_observacion.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/dialog_deshacer_recepcion_widget.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_novedades_dialog_widget.dart';

/// Card de una recepción ya terminada (tab "Terminados"): producto, quién
/// la envió, cantidad, fecha, el detalle de novedades de TODAS las
/// asignaciones de este producto (ver [RecepcionNovedadesDialogWidget] —
/// es una lista, hace scroll), y el ícono para deshacerla
/// (ver [DialogDeshacerRecepcionWidget]).
class RecepcionTerminadoCardWidget extends StatelessWidget {
  const RecepcionTerminadoCardWidget({
    super.key,
    required this.item,
    required this.asignacion,
  });

  final RecepcionPoolItem item;
  final AsignacionObservacion asignacion;

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
                  const Icon(Icons.check_circle, color: green, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Operario:',
                value: asignacion.operario ?? '—',
              ),
              _InfoRow(
                icon: Icons.inventory_2_outlined,
                label: 'Cantidad enviada:',
                value:
                    '${asignacion.qtyRecibida ?? 0} de ${asignacion.qtyAsignada ?? 0} ${item.uom ?? ''}',
              ),
              if (asignacion.fechaCompletado != null)
                _InfoRow(
                  icon: Icons.event_available_outlined,
                  label: 'Fecha:',
                  value: asignacion.fechaCompletado!,
                ),
              if (asignacion.locationDestName != null)
                _InfoRow(
                  icon: Icons.pin_drop_outlined,
                  label: 'Ubicación destino:',
                  value: asignacion.locationDestName!,
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => RecepcionNovedadesDialogWidget(
                        productName: item.productName ?? '',
                        observaciones: item.observaciones,
                        uom: item.uom,
                      ),
                    ),
                    icon: Icon(
                      Icons.report_gmailerrorred_outlined,
                      color: primaryColorApp,
                      size: 18,
                    ),
                    label: Text(
                      'Ver novedades (${item.observaciones.length})',
                      style: TextStyle(color: primaryColorApp, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Deshacer',
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => DialogDeshacerRecepcionWidget(
                        productName: item.productName ?? '',
                        claimId: asignacion.claimId,
                        sessionId: item.sessionId,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, color: red),
                  ),
                ],
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
          Icon(icon, size: 16, color: grey),
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
