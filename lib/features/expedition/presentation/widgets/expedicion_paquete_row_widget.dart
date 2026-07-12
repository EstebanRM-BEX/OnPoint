import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';

class ExpedicionPaqueteRowWidget extends StatelessWidget {
  final PaqueteExpedicion paquete;

  const ExpedicionPaqueteRowWidget({super.key, required this.paquete});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        leading: Image.asset(
          'assets/icons/package_barcode.png',
          width: 20,
          height: 20,
          color: primaryColorApp,
        ),
        title: Text(
          paquete.packageName ?? 'Paquete sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 15, color: primaryColorApp),
        subtitle: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${paquete.items.length} producto(s)',
                style: const TextStyle(fontSize: 12, color: black),
              ),
            ),

            Row(
              children: [
                Icon(
                  Icons.qr_code_scanner_sharp,
                  size: 12,
                  color: primaryColorApp,
                ),
                const SizedBox(width: 4),
                Text(
                  '${paquete.packingBarcode}',
                  style: const TextStyle(fontSize: 12, color: black),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Tipo de paquete:',
                  style: const TextStyle(fontSize: 12, color: black),
                ),
                const SizedBox(width: 4),
                Text(
                  '${paquete.packingType}',
                  style: const TextStyle(fontSize: 12, color: black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
