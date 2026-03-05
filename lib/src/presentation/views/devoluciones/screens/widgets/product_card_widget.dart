// lib/src/presentation/views/devoluciones/screens/widgets/product_devolucion_card.dart (Nuevo archivo)

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/product_devolucion_model.dart';

class ProductDevolucionCard extends StatelessWidget {
  final ProductDevolucion product;
  final VoidCallback onRemove; // Callback para eliminar el producto
  final VoidCallback onEdit; // Callback para eliminar el producto

  const ProductDevolucionCard({
    super.key,
    required this.product,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono o imagen del producto
            // Puedes usar Image.network(product.imageUrl) si tienes URLs de imagen
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: size.width * 0.8,
                        child: Text(
                          product.name ?? "",
                          style: const TextStyle(
                            fontSize: 11,
                            color: black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onRemove, // Llama al callback para eliminar
                        child: Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                          // Añade un gesto para eliminar el producto
                          semanticLabel: 'Eliminar producto',
                        ),
                      ) // Usar un gesto para eliminar
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Código: ',
                        style: TextStyle(fontSize: 11, color: primaryColorApp),
                      ),
                      Text(
                        '${product.code}',
                        style: const TextStyle(fontSize: 11, color: black),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Cantidad: ',
                        style: TextStyle(fontSize: 11, color: primaryColorApp),
                      ),
                      Text(
                        '${product.quantity}',
                        style: const TextStyle(fontSize: 11, color: black),
                      ),
                      const Spacer(),
                      Text(
                        'unidad: ',
                        style: TextStyle(fontSize: 11, color: primaryColorApp),
                      ),
                      Text(
                        '${product.uom}',
                        style: const TextStyle(fontSize: 11, color: black),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onEdit, // Llama al callback para eliminar
                        child: Icon(
                          Icons.edit,
                          color: primaryColorApp,
                          size: 20,
                          // Añade un gesto para eliminar el producto
                        ),
                      ) // Usa
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      debugPrint('Producto seleccionado: ${product.toMap()}');
                    },
                    child: Row(
                      children: [
                        Text(
                          'Barcode: ',
                          style:
                              TextStyle(fontSize: 11, color: primaryColorApp),
                        ),
                        Text(
                          '${product.barcode}',
                          style: const TextStyle(fontSize: 11, color: black),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: product.tracking == 'lot',
                    child: Row(
                      children: [
                        Text(
                          'Lote: ',
                          style:
                              TextStyle(fontSize: 11, color: primaryColorApp),
                        ),
                        Text(
                          '${product.lotName}',
                          style: const TextStyle(fontSize: 11, color: black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
