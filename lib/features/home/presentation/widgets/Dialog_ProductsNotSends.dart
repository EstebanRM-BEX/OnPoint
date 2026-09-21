// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/selection_dialog.dart';

class DialogProductsNotSends extends StatelessWidget {
  const DialogProductsNotSends({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnPointModal(
      icon: Icons.warning_amber_rounded,
      iconGradient: [Color(0xFFD97706), Color(0xFFFBBF24)],
      title: 'Hay productos sin enviar',
      message:
          'Por favor verifica los productos que están pendientes de '
          'enviar en los batchs, para poder cargar más procesos',
      footerLabel: 'Cerrar',
      footerIcon: null,
      footerPrimary: true,
    );
  }
}
