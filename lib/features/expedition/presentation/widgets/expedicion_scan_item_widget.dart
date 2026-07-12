import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/item_expedicion.dart';

/// Fila con la información completa de un producto dentro de un paquete,
/// listada debajo de ExpedicionScanPaqueteCardWidget en scan_product_screen.
class ExpedicionScanItemWidget extends StatelessWidget {
  final ItemExpedicion item;

  const ExpedicionScanItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.inventory_2_outlined,
            size: 20, color: primaryColorApp),
        title: Text(
          item.productName ?? 'Producto sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${item.productCode ?? "Sin código"}',
                style: const TextStyle(fontSize: 12, color: black)),
            Row(
              children: [
                Icon(Icons.qr_code_scanner_sharp,
                    size: 12, color: primaryColorApp),
                const SizedBox(width: 4),
                Text(
                  (item.barcode == null || item.barcode!.isEmpty)
                      ? 'Sin barcode'
                      : item.barcode!,
                  style: TextStyle(
                      fontSize: 12,
                      color: (item.barcode == null || item.barcode!.isEmpty)
                          ? red
                          : black),
                ),
              ],
            ),
            Text('${item.quantity ?? 0} ${item.uom ?? ""}',
                style: const TextStyle(fontSize: 12, color: black)),
            Text('Días de vencimiento: ${item.diasVencimiento ?? 0}',
                style: const TextStyle(fontSize: 12, color: black)),
            if (item.tracking != null && item.tracking!.isNotEmpty)
              Text('Trazabilidad: ${item.tracking}',
                  style: const TextStyle(fontSize: 12, color: black)),
          ],
        ),
      ),
    );
  }
}
