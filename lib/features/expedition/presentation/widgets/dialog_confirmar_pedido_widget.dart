import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Diálogo de confirmación antes de confirmar (cerrar) el pedido completo de
/// expedición, en expedicion_detail_tab_detalles.dart. Mismo diseño visual
/// que DialogBackorderPack (wms_packing): fondo blanco, icono svg arriba y
/// botones de ancho completo apilados.
///
/// Cuando [onAcceptedConBackorder] no es null (quedan paquetes o productos
/// sueltos pendientes en "Por hacer") se agrega un botón extra para
/// confirmar creando backorder con lo pendiente.
class DialogConfirmarPedidoWidget extends StatelessWidget {
  final String message;
  final VoidCallback onAccepted;
  final VoidCallback onCancel;
  final VoidCallback? onAcceptedConBackorder;

  const DialogConfirmarPedidoWidget({
    super.key,
    required this.message,
    required this.onAccepted,
    required this.onCancel,
    this.onAcceptedConBackorder,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hayBackorder = onAcceptedConBackorder != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Text(
          'Confirmar Pedido',
          style: TextStyle(color: primaryColorApp, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 200,
              child: SvgPicture.asset(
                "assets/images/icono.svg",
                height: 150,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                message,
                style: TextStyle(color: black, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          if (hayBackorder)
            ElevatedButton(
              onPressed: onAcceptedConBackorder,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(size.width * 0.9, 40),
              ),
              child: const Text(
                'Confirmar y Crear un Backorder',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ElevatedButton(
            onPressed: onAccepted,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              minimumSize: Size(size.width * 0.9, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              hayBackorder ? 'Confirmar sin Backorder' : 'Confirmar Pedido',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(size.width * 0.9, 40),
              backgroundColor: grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
