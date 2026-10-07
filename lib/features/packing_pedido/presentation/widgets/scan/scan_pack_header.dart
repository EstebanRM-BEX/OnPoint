import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/shared/widgets/onpoint_header_surface.dart';

/// Barra superior del escaneo con el producto en curso.
class ScanPackHeader extends StatelessWidget {
  final ProductoPacking producto;
  final VoidCallback onBack;

  const ScanPackHeader({
    super.key,
    required this.producto,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return OnPointHeaderSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 16, 14),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: white),
              onPressed: onBack,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESCANEAR PRODUCTO',
                    style: TextStyle(
                      color: white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    producto.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (producto.isProductSplit)
              const Tooltip(
                message: 'Producto dividido',
                child: Icon(Icons.call_split, color: white),
              ),
          ],
        ),
      ),
    );
  }
}
