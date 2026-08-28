import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';

class RecepcionClaimCardWidget extends StatelessWidget {
  const RecepcionClaimCardWidget({
    super.key,
    required this.claim,
    required this.companyId,
    this.onRelease,
  });

  final RecepcionClaim claim;

  /// Almacén de la sesión (warehouse_id); se usa como company_id al imprimir.
  final dynamic companyId;

  /// Se llama al tocar "liberar asignación". null oculta el botón.
  final VoidCallback? onRelease;

  /// "2026-08-28 20:53:42" → "20:53". Evita overflow por mostrar la fecha
  /// completa y es lo único relevante para el operario (hoy).
  String? get _lockTime {
    final raw = claim.bloqueadoHasta;
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(' ');
    if (parts.length < 2) return raw;
    final time = parts[1];
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  @override
  Widget build(BuildContext context) {
    final asignada = claim.qtyAsignada ?? 0;
    final recibida = claim.qtyRecibida ?? 0;
    final progress = asignada > 0 ? (recibida / asignada).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Card(
        elevation: 3,
        color: white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      claim.productName ?? '',
                      style: TextStyle(
                        color: primaryColorApp,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.print, color: primaryColorApp, size: 20),
                    tooltip: 'Imprimir etiqueta',
                    onPressed: claim.productId == null
                        ? null
                        : () => ModalPrintersList.show(
                            context,
                            resIds: [claim.productId],
                            companyId: companyId ?? 1,
                          ),
                  ),
                  if (onRelease != null)
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: red,
                        size: 20,
                      ),
                      tooltip: 'Liberar asignación',
                      onPressed: onRelease,
                    ),
                ],
              ),
              Text(
                'Código: ${claim.barcode ?? '-'}',
                style: const TextStyle(fontSize: 12, color: black),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: grey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? green : primaryColorApp,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recibido: $recibida / $asignada ${claim.uom ?? ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: progress >= 1.0 ? green : primaryColorApp,
                ),
              ),
              if (_lockTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.lock_clock, color: yellow, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Bloqueado hasta $_lockTime',
                      style: const TextStyle(fontSize: 10, color: yellow),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
