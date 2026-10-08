import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_header.dart';

/// Menú de la cabecera para filtrar ubicaciones por almacén. La opción
/// vacía (`''`) es "Todos los almacenes".
class AlmacenFilterMenu extends StatelessWidget {
  final List<String> almacenes;
  final String? seleccionado;
  final ValueChanged<String?> onSelected;

  const AlmacenFilterMenu({
    super.key,
    required this.almacenes,
    required this.seleccionado,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: white,
      padding: EdgeInsets.zero,
      onSelected: (value) => onSelected(value.isEmpty ? null : value),
      itemBuilder: (_) => [
        for (final almacen in ['', ...almacenes])
          PopupMenuItem<String>(
            value: almacen,
            child: Row(
              children: [
                Icon(
                  (seleccionado ?? '') == almacen
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: primaryColorApp,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  almacen.isEmpty ? 'Todos los almacenes' : almacen,
                  style: const TextStyle(color: black, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
      child: IgnorePointer(
        child: HeaderFilterButton(
          icon: Icons.warehouse_outlined,
          active: seleccionado != null,
          onTap: () {},
        ),
      ),
    );
  }
}
