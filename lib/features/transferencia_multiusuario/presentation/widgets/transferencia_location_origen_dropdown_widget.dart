import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Slot `locationDropdown` de LocationScannerWidget para la ubicación de
/// origen. Dropdown de un solo ítem para confirmarla sin escanear —
/// interactivo solo si el permiso `manualSourceLocationTransfer`
/// (tbl_configurations) está activo y todavía no se confirmó, mismo
/// permiso que usa LocationDropdownTransferWidget en el módulo legacy de
/// transferencia interna (transfer-interna/screens/widgets/location/).
///
/// Siempre muestra el nombre de la ubicación esperada debajo del dropdown
/// (igual que `Visibility(visible: isPDA, ...)` en
/// LocationDropdownTransferWidget) — es la única forma de ver qué ubicación
/// se espera, ya que LocationScannerWidget no trae su propio label/texto.
///
/// `value` se mantiene siempre en `null` a propósito (mismo truco que
/// TransferenciaProductDropdownWidget): así el único ítem nunca queda "ya
/// seleccionado" y cada toque dispara [onSelected].
class TransferenciaLocationOrigenDropdownWidget extends StatelessWidget {
  const TransferenciaLocationOrigenDropdownWidget({
    super.key,
    required this.locationName,
    required this.enabled,
    required this.onSelected,
  });

  final String locationName;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: DropdownButton<String>(
            underline: Container(height: 0),
            borderRadius: BorderRadius.circular(10),
            focusColor: Colors.white,
            isExpanded: true,
            hint: Text(
              'Ubicación de origen',
              style: TextStyle(fontSize: 13, color: primaryColorApp),
            ),
            icon: Image.asset(
              "assets/icons/ubicacion.png",
              color: primaryColorApp,
              width: 18,
            ),
            value: null,
            items: [
              DropdownMenuItem<String>(
                value: locationName,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    // Siempre verde: el único ítem del dropdown SIEMPRE es
                    // la ubicación de origen esperada del claim actual.
                    color: Colors.green[100],
                  ),
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Text(
                    locationName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: black),
                  ),
                ),
              ),
            ],
            onChanged: enabled ? (_) => onSelected() : null,
          ),
        ),
        if (locationName.isNotEmpty)
          Text(
            locationName,
            style: const TextStyle(fontSize: 14, color: black),
          ),
      ],
    );
  }
}
