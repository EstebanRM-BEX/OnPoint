import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/presentation/utils/info_rapida_format.dart';

/// Fila "título: valor" con icono, usada en el detalle de paquete.
class IconInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const IconInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColorApp, size: 16),
        const SizedBox(width: 5),
        if (title.isNotEmpty)
          Text(
            '$title ',
            style: const TextStyle(fontSize: 12, color: primaryColorApp),
          ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: black),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Cabecera del detalle de paquete.
class PaqueteDetailCard extends StatelessWidget {
  final PaqueteInfo paquete;

  const PaqueteDetailCard({super.key, required this.paquete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                orDefault(paquete.nombre, 'Sin nombre'),
                style: const TextStyle(
                  color: primaryColorApp,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: black, thickness: 1, height: 5),
            IconInfoRow(
              icon: Icons.qr_code,
              title: 'Código de barras:',
              value: orDefault(paquete.codigoBarras, 'Sin código'),
            ),
            IconInfoRow(
              icon: Icons.add,
              title: 'Total de productos:',
              value: '${paquete.numeroProductos ?? 0}',
            ),
            IconInfoRow(
              icon: Icons.add,
              title: 'Total de unidades:',
              value: formatCantidad(paquete.totalProductos),
            ),
            IconInfoRow(
              icon: Icons.verified,
              title: 'Paquete certificado:',
              value: paquete.isCertificate == true ? 'Sí' : 'No',
            ),
            IconInfoRow(
              icon: Icons.store,
              title: 'Almacen:',
              value: orDefault(paquete.nombreAlmacen, 'Sin almacen'),
            ),
            IconInfoRow(
              icon: Icons.calendar_month,
              title: 'Fecha de empaquetado:',
              value: orDefault(paquete.fechaEmpaquetado, 'Sin fecha'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Producto contenido en un paquete.
class PaqueteProductoCard extends StatelessWidget {
  final ProductoUbicacion producto;

  const PaqueteProductoCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final lote = producto.lote ?? '';
    return Card(
      color: white,
      elevation: 3,
      child: ListTile(
        title: Text(
          orDefault(producto.producto, 'Sin nombre'),
          style: const TextStyle(
            color: primaryColorApp,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          children: [
            IconInfoRow(
              icon: Icons.add,
              title: 'Cantidad:',
              value: formatCantidad(producto.cantidad),
            ),
            IconInfoRow(
              icon: Icons.straighten,
              title: 'Unidad medida:',
              value: orDefault(producto.unidadMedida, 'Sin unidad medida'),
            ),
            IconInfoRow(
              icon: Icons.qr_code,
              title: 'Barcode:',
              value: orDefault(producto.codigoBarras, 'Sin barcode'),
            ),
            if (lote.isNotEmpty)
              IconInfoRow(icon: Icons.inventory_2, title: 'Lote:', value: lote),
            IconInfoRow(
              icon: Icons.person,
              title: 'Contacto:',
              value: orDefault(producto.tercero, 'Sin tercero'),
            ),
            IconInfoRow(
              icon: Icons.list_alt,
              title: '',
              value: orDefault(producto.pedido, 'Sin pedido'),
            ),
            IconInfoRow(
              icon: Icons.receipt,
              title: 'Doc. origin:',
              value: orDefault(producto.origin, 'Sin origen'),
            ),
            IconInfoRow(
              icon: Icons.inventory,
              title: 'Numero de caja:',
              value: orDefault(producto.numeroCaja, 'Sin numero de caja'),
            ),
            IconInfoRow(
              icon: Icons.person,
              title: 'Empaquetado por:',
              value: orDefault(producto.operador, 'Sin operador'),
            ),
          ],
        ),
      ),
    );
  }
}
