import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/selection_dialog.dart';

class DialogPicking extends StatelessWidget {
  const DialogPicking({super.key, required this.contextHome});

  final BuildContext contextHome;

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(contextHome, route);
  }

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      icon: Icons.shopping_basket_outlined,
      title: 'Selección de Picking',
      message:
          'Seleccione una de las siguientes opciones para realizar el '
          'proceso de picking',
      options: [
        SelectionOption(
          title: 'Por Batch',
          tag: 'Multi-orden',
          description: 'Consolidación de varios pedidos por lote',
          icon: Icons.layers_outlined,
          onTap: () => _go(context, 'wms-picking'),
        ),
        SelectionOption(
          title: 'Por Cluster',
          tag: 'Canastillas',
          description: 'Recolección simultánea de varios pedidos',
          icon: Icons.hub_outlined,
          onTap: () => _go(context, 'picking-cluster'),
        ),
        SelectionOption(
          title: 'Por Pedido',
          tag: 'Individual',
          description: 'Preparación directa, orden a orden',
          icon: Icons.receipt_long_outlined,
          onTap: () => _go(context, 'pick'),
        ),
      ],
    );
  }
}
