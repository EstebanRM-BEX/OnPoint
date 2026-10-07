import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/onpoint_header_surface.dart';

/// Barra superior del escaneo: fondo OnPoint con el contenido del módulo
/// anterior (volver, "CERTIFICACION" e imprimir).
class ScanPackHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onImprimir;

  const ScanPackHeader({
    super.key,
    required this.onBack,
    required this.onImprimir,
  });

  @override
  Widget build(BuildContext context) {
    return OnPointHeaderSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 10, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: white, size: 30),
            ),
            const Expanded(
              child: Text(
                'CERTIFICACION',
                textAlign: TextAlign.center,
                style: TextStyle(color: white, fontSize: 18),
              ),
            ),
            GestureDetector(
              onTap: onImprimir,
              child: const Icon(Icons.print, color: white, size: 25),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
