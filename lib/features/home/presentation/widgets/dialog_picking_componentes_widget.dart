import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/selection_dialog.dart';

class DialogPickingComponentes extends StatelessWidget {
  const DialogPickingComponentes({super.key, required this.contextHome});

  final BuildContext contextHome;

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      icon: Icons.settings_suggest_outlined,
      title: 'Picking Componentes',
      message:
          'Seleccione una de las siguientes opciones para realizar el '
          'proceso de picking de componentes',
      options: [
        SelectionOption(
          title: 'Por Batch',
          tag: 'Multi-orden',
          description: 'Componentes agrupados por lote',
          icon: Icons.layers_outlined,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(
              contextHome,
              'picking-componentes-batch',
            );
          },
        ),
        SelectionOption(
          title: 'Por Pick',
          tag: 'Individual',
          description: 'Un pick de componentes a la vez',
          icon: Icons.receipt_long_outlined,
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, 'picking-componentes');
          },
        ),
      ],
    );
  }
}
