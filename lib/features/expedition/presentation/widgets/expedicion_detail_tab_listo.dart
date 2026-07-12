import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_item_suelto_row_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_paquete_row_widget.dart';

/// Tab "Listo": paquetes e items sueltos ya validados. Solo lectura.
class ExpedicionDetailTabListo extends StatelessWidget {
  final ExpedicionDetail detail;

  const ExpedicionDetailTabListo({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final paquetes = detail.paquetesListos;
    final itemsSueltos = detail.itemsSueltosListos;

    if (paquetes.isEmpty && itemsSueltos.isEmpty) {
      return const Center(
        child: Text('No hay productos listos',
            style: TextStyle(color: grey, fontSize: 14)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (paquetes.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text('Paquetes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          ...paquetes.map((p) => ExpedicionPaqueteRowWidget(paquete: p)),
        ],
        if (itemsSueltos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text('Productos sueltos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          ...itemsSueltos.map((i) => ExpedicionItemSueltoRowWidget(item: i)),
        ],
      ],
    );
  }
}
