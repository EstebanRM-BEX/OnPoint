import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';

/// Card con el detalle completo del paquete, mostrada en la parte superior
/// de scan_product_screen cuando venimos de un item de items_pack_pendientes.
class ExpedicionScanPaqueteCardWidget extends StatelessWidget {
  final PaqueteExpedicion paquete;

  const ExpedicionScanPaqueteCardWidget({super.key, required this.paquete});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: white,
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paquete.packageName ?? 'Paquete sin nombre',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColorApp,
                  fontSize: 15),
            ),
            const Divider(),
            Row(
              children: [
                Icon(Icons.qr_code_scanner_sharp,
                    size: 14, color: primaryColorApp),
                const SizedBox(width: 4),
                Text('Código: ${paquete.packingBarcode ?? "Sin código"}',
                    style: const TextStyle(fontSize: 12, color: black)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 14, color: primaryColorApp),
                const SizedBox(width: 4),
                Text('Tipo de paquete: ${paquete.packingType}',
                    style: const TextStyle(fontSize: 12, color: black)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.sort_outlined, size: 14, color: primaryColorApp),
                const SizedBox(width: 4),
                Text('Orden: ${paquete.orderPacking ?? 0}',
                    style: const TextStyle(fontSize: 12, color: black)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 14, color: primaryColorApp),
                const SizedBox(width: 4),
                Text('${paquete.items.length} producto(s)',
                    style: const TextStyle(fontSize: 12, color: black)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
