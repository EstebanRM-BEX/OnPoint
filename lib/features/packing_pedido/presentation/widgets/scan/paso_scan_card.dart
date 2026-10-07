import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

enum EstadoPasoScan { pendiente, activo, hecho }

/// Paso del escaneo (ubicación / producto): título, datos, estado y, si hay
/// permiso, botón para confirmarlo a mano.
class PasoScanCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final EstadoPasoScan estado;
  final List<Widget> contenido;
  final String? textoManual;
  final VoidCallback? onManual;

  const PasoScanCard({
    super.key,
    required this.titulo,
    required this.icono,
    required this.estado,
    required this.contenido,
    this.textoManual,
    this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    final (borde, fondo, iconoEstado) = switch (estado) {
      EstadoPasoScan.hecho => (
        green,
        const Color(0xFFF0FDF4),
        Icons.check_circle,
      ),
      EstadoPasoScan.activo => (primaryColorApp, white, Icons.qr_code_scanner),
      EstadoPasoScan.pendiente => (
        const Color(0xFFE2E8F0),
        const Color(0xFFF8FAFC),
        Icons.radio_button_unchecked,
      ),
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borde,
          width: estado == EstadoPasoScan.activo ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: primaryColorApp, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColorApp,
                  ),
                ),
              ),
              Icon(iconoEstado, color: borde, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          ...contenido,
          if (estado == EstadoPasoScan.activo && onManual != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onManual,
                icon: Icon(Icons.touch_app, size: 16, color: primaryColorApp),
                label: Text(
                  textoManual ?? 'Confirmar a mano',
                  style: TextStyle(fontSize: 12, color: primaryColorApp),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
