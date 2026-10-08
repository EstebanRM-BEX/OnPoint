import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/presentation/utils/info_rapida_format.dart';

/// Producto agregado a la transferencia masiva, con botón para quitarlo.
class MassTransferItemCard extends StatelessWidget {
  final ProductoUbicacion producto;
  final VoidCallback onDelete;

  const MassTransferItemCard({
    super.key,
    required this.producto,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Producto:',
                    style: TextStyle(fontSize: 12, color: primaryColorApp),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              Text(
                producto.producto,
                style: const TextStyle(fontSize: 12, color: black),
              ),
              _row('Lote: ', producto.lote, 'Sin lote'),
              _row('Propietario: ', producto.propietario, 'Sin propietario'),
              _row('Caducidad: ', producto.fechaVencimiento, 'Sin caducidad'),
              _row('Barcode: ', producto.codigoBarras, 'Sin barcode'),
              Row(
                children: [
                  _label('Cantidad: '),
                  Text(
                    formatCantidad(producto.cantidadMano),
                    style: const TextStyle(fontSize: 12, color: black),
                  ),
                  const Spacer(),
                  _label('Unidad: '),
                  _value(producto.unidadMedida, 'Sin unidad'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String? value, String vacio) => Row(
    children: [
      _label(label),
      Flexible(child: _value(value, vacio)),
    ],
  );

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontSize: 12, color: primaryColorApp));

  Widget _value(String? value, String vacio) {
    final empty = value == null || value.isEmpty;
    return Text(
      empty ? vacio : value,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, color: empty ? red : black),
    );
  }
}
