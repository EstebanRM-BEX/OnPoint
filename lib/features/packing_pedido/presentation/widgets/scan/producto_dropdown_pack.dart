import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';

/// Dropdown "Producto" de la tarjeta de producto (mismo diseño que el
/// módulo anterior). Solo ofrece el producto actual: confirmar a mano no
/// permite elegir otro. Habilitado con permiso, con la ubicación confirmada
/// y el producto todavía pendiente.
class ProductoDropdownPack extends StatelessWidget {
  final ProductoPacking producto;

  /// null = deshabilitado.
  final VoidCallback? onConfirmar;

  const ProductoDropdownPack({
    super.key,
    required this.producto,
    this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Center(
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
            'assets/icons/producto.png',
            color: primaryColorApp,
            width: 20,
          ),
          value: null,
          items: [
            DropdownMenuItem<String>(
              value: producto.productName,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green[100],
                ),
                width: MediaQuery.sizeOf(context).width * 0.9,
                child: Text(
                  producto.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: black),
                ),
              ),
            ),
          ],
          onChanged: onConfirmar == null ? null : (_) => onConfirmar!(),
        ),
      ),
    );
  }
}
