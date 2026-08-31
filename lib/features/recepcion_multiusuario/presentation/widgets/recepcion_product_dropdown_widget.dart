import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Dropdown de un solo ítem (el producto del claim actual) para
/// ProductScannerWidget: permite confirmar el producto de forma manual como
/// alternativa a escanearlo. A diferencia de recepción individual, acá no
/// hay "otros productos pendientes" entre los que elegir — solo este.
///
/// `value` se mantiene siempre en `null` a propósito (mismo truco que
/// ProductDropdownOrderWidget): así el único ítem nunca queda "ya
/// seleccionado" y cada toque dispara [onSelected].
class RecepcionProductDropdownWidget extends StatelessWidget {
  const RecepcionProductDropdownWidget({
    super.key,
    required this.productName,
    required this.enabled,
    required this.onSelected,
  });

  final String productName;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DropdownButton<String>(
        underline: Container(height: 0),
        borderRadius: BorderRadius.circular(10),
        focusColor: Colors.white,
        isExpanded: true,
        hint: Text(
          'Producto',
          style: TextStyle(fontSize: 14, color: primaryColorApp),
        ),
        icon: Image.asset(
          "assets/icons/producto.png",
          color: primaryColorApp,
          width: 20,
        ),
        value: null,
        items: [
          DropdownMenuItem<String>(
            value: productName,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Text(
                productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: black),
              ),
            ),
          ),
        ],
        onChanged: enabled ? (_) => onSelected() : null,
      ),
    );
  }
}
