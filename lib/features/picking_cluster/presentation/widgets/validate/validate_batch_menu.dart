import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';

/// Opciones de la pantalla de validación: `verificar`, `salir`, `filtros`.
class ValidateBatchMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const ValidateBatchMenu({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Opciones',
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onSelected,
      itemBuilder: (_) => [
        _item(
          'verificar',
          Icons.check_circle_outline,
          'Verificar unidades',
          ClusterPalette.brand600,
        ),
        const PopupMenuDivider(height: 1),
        _item(
          'salir',
          Icons.logout,
          'Salir al listado de batch',
          ClusterPalette.slate500,
        ),
        const PopupMenuDivider(height: 1),
        _item(
          'filtros',
          Icons.filter_alt_outlined,
          'Filtros',
          ClusterPalette.slate500,
        ),
      ],
    );
  }

  PopupMenuItem<String> _item(
    String value,
    IconData icon,
    String label,
    Color iconColor,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 46,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ClusterPalette.slate800,
            ),
          ),
        ],
      ),
    );
  }
}
