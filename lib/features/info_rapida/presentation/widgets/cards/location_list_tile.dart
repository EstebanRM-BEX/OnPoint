import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';

/// Fila del catálogo de ubicaciones (búsqueda manual).
class LocationListTile extends StatelessWidget {
  const LocationListTile({
    super.key,
    required this.ubicacion,
    required this.isSelected,
    required this.onTap,
  });

  final UbicacionCatalogo ubicacion;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 3,
          color: isSelected ? Colors.green[100] : white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              children: [
                _row('Nombre', ubicacion.name, 'Sin nombre'),
                _row('Barcode', ubicacion.barcode, 'Sin barcode'),
                _row('Almacen', ubicacion.warehouseName, 'Sin almacen'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String? value, String vacio) {
    final empty = value == null || value.trim().isEmpty;
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: black, fontSize: 12)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            empty ? vacio : value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: empty ? red : primaryColorApp,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
