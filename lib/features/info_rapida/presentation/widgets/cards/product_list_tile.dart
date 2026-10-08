import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';

/// Fila del catálogo de productos (búsqueda manual).
class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onSelect,
  });

  final ProductoCatalogo product;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final barcode = product.barcode ?? '';
    final code = product.code ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onSelect,
        child: Card(
          elevation: 3,
          color: isSelected ? Colors.green[100] : white,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Nombre', product.name),
                if (product.manejoPropietario)
                  _row('Propietario', product.propietario),
                _row('Barcode', barcode, isError: barcode.isEmpty),
                _row('Code', code, isError: code.isEmpty),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String? value, {bool isError = false}) {
    final displayValue = (value == null || value.isEmpty)
        ? 'Sin ${label.toLowerCase()}'
        : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: black, fontSize: 12)),
          Expanded(
            child: Text(
              displayValue,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isError ? red : primaryColorApp,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
