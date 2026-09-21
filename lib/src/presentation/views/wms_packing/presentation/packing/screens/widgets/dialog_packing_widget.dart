import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/selection_dialog.dart';

class DialogPacking extends StatelessWidget {
  const DialogPacking({super.key, required this.contextHome});

  final BuildContext contextHome;

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      icon: Icons.inventory_2_outlined,
      title: 'Selección de Packing',
      message:
          'Seleccione una de las siguientes opciones para realizar el '
          'proceso de packing',
      options: [
        SelectionOption(
          title: 'Por Batch',
          tag: 'Multi-orden',
          description: 'Empaque de varios pedidos por lote',
          icon: Icons.layers_outlined,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, 'wms-packing');
          },
        ),
        SelectionOption(
          title: 'Por Pedido',
          tag: 'Individual',
          description: 'Empaque directo, orden a orden',
          icon: Icons.receipt_long_outlined,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(contextHome, 'list-packing');
          },
        ),
        SelectionOption(
          title: 'Consolidado',
          description: 'Agrupa productos de varios pedidos en un empaque',
          icon: Icons.all_inbox_outlined,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(
              contextHome,
              'list-packing-consolidade',
            );
          },
        ),
      ],
    );
  }
}
