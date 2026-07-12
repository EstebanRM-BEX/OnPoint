import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';

/// Tab "Detalles" de expedition_screen.dart: mismo resumen que
/// ExpedicionCardWidget, a pantalla completa.
class ExpedicionDetailTabDetalles extends StatelessWidget {
  final ExpedicionDetail detail;

  const ExpedicionDetailTabDetalles({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final pedido = detail.pedido;

    Widget infoRow(IconData icon, String text, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: primaryColorApp),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: TextStyle(fontSize: 13, color: color ?? black)),
              ),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pedido.nombre ?? '',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: primaryColorApp, fontSize: 18),
          ),
          const Divider(),
          if (pedido.zonaEntrega != null && pedido.zonaEntrega!.isNotEmpty)
            infoRow(Icons.location_on_outlined, pedido.zonaEntrega!),
          Visibility(
            visible: pedido.manejoPropietario == true,
            child: infoRow(Icons.business_outlined,
                'Propietario: ${pedido.propietario ?? "Sin propietario"}'),
          ),
          infoRow(Icons.local_shipping_outlined,
              'Operación: ${pedido.pickingType ?? ""}'),
          infoRow(Icons.flag_outlined, 'Estado: ${pedido.estado ?? "Sin estado"}'),
          if (pedido.observacion != null && pedido.observacion!.isNotEmpty)
            infoRow(Icons.notes_outlined, 'Observación: ${pedido.observacion}'),
          infoRow(
            Icons.calendar_today,
            pedido.fecha != null
                ? DateFormat('dd/MM/yyyy').format(pedido.fecha!)
                : 'Sin fecha',
          ),
          infoRow(Icons.receipt_long,
              'Doc. Origen: ${pedido.documentoOrigen ?? ""}'),
          infoRow(
            Icons.person,
            pedido.cliente ?? 'Sin cliente',
            color:
                (pedido.cliente == null || pedido.cliente!.isEmpty) ? red : black,
          ),
          infoRow(Icons.add_box_outlined,
              'Cantidad de items: ${pedido.totalCantidades ?? 0}'),
          infoRow(Icons.inventory_2_outlined,
              'Cantidad de paquetes: ${pedido.numeroPaquetes ?? 0}'),
          if (pedido.productoSueltos != null && pedido.productoSueltos! > 0)
            infoRow(Icons.widgets_outlined,
                'Producto sueltos: ${pedido.productoSueltos}'),
          if (pedido.totalPeso != null && pedido.totalPeso! > 0)
            infoRow(Icons.scale_outlined, 'Peso total: ${pedido.totalPeso}'),
          infoRow(
            Icons.badge_outlined,
            pedido.responsable == null || pedido.responsable!.isEmpty
                ? 'Sin responsable'
                : pedido.responsable!,
            color: (pedido.responsable == null || pedido.responsable!.isEmpty)
                ? red
                : black,
          ),
          if (pedido.startTimeTransfer != null &&
              pedido.startTimeTransfer!.isNotEmpty)
            infoRow(Icons.timer_outlined,
                'Iniciado: ${pedido.startTimeTransfer}'),
        ],
      ),
    );
  }
}
