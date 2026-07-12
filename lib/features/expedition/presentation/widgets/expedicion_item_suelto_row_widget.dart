import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';

class ExpedicionItemSueltoRowWidget extends StatelessWidget {
  final ItemSueltoExpedicion item;

  /// Si se provee, se muestra un ícono de deshacer en vez de la flecha
  /// (usado en la tab "Listo", que es de solo lectura y no navega).
  final VoidCallback? onUndo;

  /// Si es true, la fila entra en modo selección múltiple: aparece el
  /// checkbox y la card se resalta al estar marcada. Lo decide únicamente el
  /// permiso allow_validate_multiple (tab "Por hacer") — no depende de
  /// onSelectedChanged, que puede venir null por otro motivo (ej. el item no
  /// tiene packingId) sin que eso deba ocultar el checkbox, solo
  /// deshabilitarlo.
  final bool seleccionable;
  final bool isSelected;
  final ValueChanged<bool>? onSelectedChanged;

  const ExpedicionItemSueltoRowWidget({
    super.key,
    required this.item,
    this.onUndo,
    this.seleccionable = false,
    this.isSelected = false,
    this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: seleccionable && isSelected ? primaryColorAppLigth : white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        trailing: onUndo != null
            ? IconButton(
                icon: const Icon(Icons.delete, color: red,size: 20),
                tooltip: 'Deshacer validación',
                onPressed: onUndo,
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: primaryColorApp,
              ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (seleccionable)
              Checkbox(
                activeColor: primaryColorApp,
                value: isSelected,
                onChanged: onSelectedChanged == null
                    ? null
                    : (value) => onSelectedChanged!(value ?? false),
              ),
            Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: primaryColorApp,
            ),
          ],
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
