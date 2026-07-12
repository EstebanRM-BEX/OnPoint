import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';

class ExpedicionItemSueltoRowWidget extends StatelessWidget {
  final ItemSueltoExpedicion item;

  const ExpedicionItemSueltoRowWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: primaryColorApp,
        ),
        leading: Icon(
          Icons.inventory_2_outlined,
          size: 20,
          color: primaryColorApp,
        ),
        title: Text(
          item.productName ?? 'Producto sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          children: [
            Align(
                alignment: Alignment.centerLeft,
              child: Text(
                ' ${item.quantity ?? 0} ${item.uom ?? ""}',
                style: const TextStyle(fontSize: 12, color: black),
              ),
            ),
            //mostramos el 
                        // "product_code": "159753",
            Row(
              children: [
                 Icon(
                  Icons.qr_code_scanner_sharp,
                  size: 12,
                  color: primaryColorApp,
                ),
                const SizedBox(width: 4),
                  Text(
                  item.barcode == "" ? 'sin barcode' : '${item.barcode}'  ,
                  style:  TextStyle(fontSize: 12, color: (item.barcode == "" ||
                                item.barcode!.isEmpty)
                            ? red
                            : black), 
                ),
              ],
            )
                       
          ],
        ),
      ),
    );
  }
}
