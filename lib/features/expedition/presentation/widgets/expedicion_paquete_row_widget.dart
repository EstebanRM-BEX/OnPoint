import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';

class ExpedicionPaqueteRowWidget extends StatelessWidget {
  final PaqueteExpedicion paquete;

  /// Si es true, la fila entra en modo selección múltiple: aparece el
  /// checkbox y la card se resalta al estar marcada. Lo decide únicamente el
  /// permiso allow_validate_multiple (tab "Por hacer") — no depende de
  /// onSelectedChanged, que puede venir null por otro motivo (ej. el paquete
  /// no tiene packingId) sin que eso deba ocultar el checkbox, solo
  /// deshabilitarlo.
  final bool seleccionable;
  final bool isSelected;
  final ValueChanged<bool>? onSelectedChanged;

  const ExpedicionPaqueteRowWidget({
    super.key,
    required this.paquete,
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
            Image.asset(
              'assets/icons/package_barcode.png',
              width: 20,
              height: 20,
              color: primaryColorApp,
            ),
          ],
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
