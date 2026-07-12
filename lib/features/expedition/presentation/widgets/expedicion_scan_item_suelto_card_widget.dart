import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';

/// Card con el detalle completo de un producto suelto (sin paquete),
/// mostrada en scan_product_screen cuando venimos de items_pendientes.
class ExpedicionScanItemSueltoCardWidget extends StatelessWidget {
  final ItemSueltoExpedicion item;

  const ExpedicionScanItemSueltoCardWidget({super.key, required this.item});

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
              item.productName ?? 'Producto sin nombre',
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
                Text(
                  (item.barcode == null || item.barcode!.isEmpty)
                      ? 'Sin código'
                      : item.barcode!,
                  style: TextStyle(
                      fontSize: 12,
                      color: (item.barcode == null || item.barcode!.isEmpty)
                          ? red
                          : black),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.tag_outlined, size: 14, color: primaryColorApp),
                const SizedBox(width: 4),
                Text('Código de producto: ${item.productCode ?? "Sin código"}',
                    style: const TextStyle(fontSize: 12, color: black)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.sort_outlined, size: 14, color: primaryColorApp),
                const SizedBox(width: 4),
                Text('Orden: ${item.orderPacking ?? 0}',
                    style: const TextStyle(fontSize: 12, color: black)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.add_box_outlined, size: 14, color: primaryColorApp),
                const SizedBox(width: 4),
                Text('Cantidad: ${item.quantity ?? 0} ${item.uom ?? ""}',
                    style: const TextStyle(fontSize: 12, color: black)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
