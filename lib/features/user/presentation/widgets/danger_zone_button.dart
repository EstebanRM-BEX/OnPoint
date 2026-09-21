import 'package:flutter/material.dart';

/// Acción crítica al final de la pantalla (eliminar base de datos local).
class DangerZoneButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DangerZoneButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.delete_forever_outlined, size: 18),
              label: const Text('Eliminar Base de Datos'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF475569),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Esta acción restablecerá el caché local de la PDA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
