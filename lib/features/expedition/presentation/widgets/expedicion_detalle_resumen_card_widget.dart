import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Tarjeta superior de la tab "Detalles": número de despacho, badge de
/// estado, tiles de operación / zona de entrega y bloque de observación.
class ExpedicionDetalleResumenCardWidget extends StatelessWidget {
  final String nombre;
  final String? estado;
  final String? operacion;
  final String? zonaEntrega;
  final String? observacion;
  final VoidCallback? onVerObservacion;

  const ExpedicionDetalleResumenCardWidget({
    super.key,
    required this.nombre,
    this.estado,
    this.operacion,
    this.zonaEntrega,
    this.observacion,
    this.onVerObservacion,
  });

  static const _mono = 'monospace';
  static const _amber = Color(0xFFD97706);

  Widget _tile(IconData icon, Color color, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF64748B))),
                  Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tieneObs = observacion != null && observacion!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NÚMERO DE DESPACHO',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text(nombre,
                        style: TextStyle(
                            fontFamily: _mono,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: primaryColorApp)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: _amber),
                    const SizedBox(width: 5),
                    Text(estado ?? 'Sin estado',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _amber)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              _tile(Icons.logout, primaryColorApp, 'OPERACIÓN',
                  operacion ?? ''),
              const SizedBox(width: 10),
              _tile(Icons.location_on_outlined, green, 'ZONA ENTREGA',
                  (zonaEntrega == null || zonaEntrega!.isEmpty)
                      ? 'Sin zona'
                      : zonaEntrega!),
            ],
          ),
          if (tieneObs) ...[
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, size: 16, color: _amber),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text('Observación:',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E))),
                      ),
                      InkWell(
                        onTap: onVerObservacion,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryColorApp),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Ver más',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColorApp)),
                              const SizedBox(width: 4),
                              Icon(Icons.visibility_outlined,
                                  size: 14, color: primaryColorApp),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(observacion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _mono,
                          fontSize: 12,
                          color: Color(0xFF334155))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
