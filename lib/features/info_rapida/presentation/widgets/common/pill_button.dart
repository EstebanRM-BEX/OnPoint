import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Botón tipo píldora de las barras de acciones de las listas.
class PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primaryColorApp.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColorApp.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primaryColorApp),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryColorApp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contador redondo junto a los títulos de lista.
class CountBadge extends StatelessWidget {
  final int count;

  const CountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primaryColorApp.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: primaryColorApp,
        ),
      ),
    );
  }
}
