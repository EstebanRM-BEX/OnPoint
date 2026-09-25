import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Estado real del lector: activo mientras el campo de escaneo tiene el foco.
///
/// En las PDA el escáner (keyboard-wedge) solo entrega el código si ese
/// campo está enfocado; si algo le roba el foco, el lector "deja de
/// funcionar" sin aviso. Aquí se ve, y un toque lo reactiva.
class ScannerStatusPill extends StatelessWidget {
  final FocusNode focusNode;
  final VoidCallback onActivate;

  const ScannerStatusPill({
    super.key,
    required this.focusNode,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final active = focusNode.hasFocus;
        final color = active
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B);
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: active ? null : onActivate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.25),
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Lector PDA: ',
                        children: [
                          TextSpan(
                            text: active ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color.lerp(color, Colors.black, 0.15),
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColorApp.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: primaryColorApp.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      active ? 'Listo para escanear' : 'Toque para activar',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: primaryColorApp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
