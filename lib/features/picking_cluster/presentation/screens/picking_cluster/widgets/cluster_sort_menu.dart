import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';

/// Menú "más opciones" de Pick Cluster: orden por fecha / consecutivo y
/// acceso al filtro de propietario (`filter_propietario`).
class ClusterSortMenu extends StatelessWidget {
  final String currentSortKey;
  final String? selectedPropietario;
  final ValueChanged<String> onSelected;

  const ClusterSortMenu({
    super.key,
    required this.currentSortKey,
    required this.selectedPropietario,
    required this.onSelected,
  });

  static const _ownerColor = Colors.amber;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Más opciones',
      icon: Icon(
        Icons.more_vert,
        color: selectedPropietario != null ? _ownerColor : Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      onSelected: onSelected,
      itemBuilder: (_) => [
        _section('FECHA'),
        _option('date_asc', Icons.calendar_month_outlined, 'Más Antiguas'),
        _option('date_desc', Icons.calendar_month_outlined, 'Más Recientes'),
        const PopupMenuDivider(),
        _section('CONSECUTIVO'),
        _option('name_asc', Icons.arrow_upward, 'Consecutivo (A-Z)'),
        _option('name_desc', Icons.arrow_downward, 'Consecutivo (Z-A)'),
        const PopupMenuDivider(),
        _section('PROPIETARIO'),
        _ownerOption(),
      ],
    );
  }

  PopupMenuItem<String> _section(String title) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 30,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.8,
          color: ClusterPalette.slate400,
        ),
      ),
    );
  }

  PopupMenuItem<String> _option(String key, IconData icon, String label) {
    final active = currentSortKey == key;
    final color = active ? ClusterPalette.brand600 : ClusterPalette.slate700;
    return PopupMenuItem<String>(
      value: key,
      height: 40,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: active ? ClusterPalette.brand600 : ClusterPalette.slate400,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: color,
            ),
          ),
          if (active) ...[
            const Spacer(),
            const Icon(Icons.check, size: 15, color: ClusterPalette.brand600),
          ],
        ],
      ),
    );
  }

  PopupMenuItem<String> _ownerOption() {
    final active = selectedPropietario != null;
    return PopupMenuItem<String>(
      value: 'filter_propietario',
      height: 40,
      child: Row(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 16,
            color: active ? _ownerColor : ClusterPalette.slate400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedPropietario ?? 'Filtrar propietario',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: active ? _ownerColor : ClusterPalette.slate700,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (active) const Icon(Icons.check, size: 15, color: _ownerColor),
        ],
      ),
    );
  }
}
