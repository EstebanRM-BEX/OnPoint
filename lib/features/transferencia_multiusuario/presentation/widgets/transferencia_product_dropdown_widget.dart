import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Espejo de RecepcionProductDropdownWidget. Dropdown de un solo ítem (el
/// producto del claim actual) para ProductScannerWidget: permite confirmar
/// el producto de forma manual como alternativa a escanearlo.
///
/// `value` se mantiene siempre en `null` a propósito: así el único ítem
/// nunca queda "ya seleccionado" y cada toque dispara [onSelected].
class TransferenciaProductDropdownWidget extends StatelessWidget {
  const TransferenciaProductDropdownWidget({
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
                // Siempre verde: el único ítem del dropdown SIEMPRE es el
                // producto actual.
                color: Colors.green[100],
              ),
              width: MediaQuery.of(context).size.width * 0.9,
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
