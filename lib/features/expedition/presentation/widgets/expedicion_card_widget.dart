import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';

class ExpedicionCardWidget extends StatelessWidget {
  final ExpedicionPedido expedicion;

  const ExpedicionCardWidget({super.key, required this.expedicion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Card(
        color: white,
        elevation: 3,
        child: ListTile(
          trailing: const Icon(Icons.chevron_right, color: grey),
          title: Text(
            expedicion.nombre ?? '',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: primaryColorApp, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expedicion.zonaEntrega != null &&
                  expedicion.zonaEntrega!.isNotEmpty)
                Text(expedicion.zonaEntrega!,
                    style: const TextStyle(fontSize: 12, color: black)),
              Visibility(
                visible: expedicion.manejoPropietario == true,
                child: Text(
                    'Propietario: ${expedicion.propietario ?? "Sin propietario"}',
                    style: const TextStyle(fontSize: 12, color: primaryColorApp)),
              ),
              Text('Operación: ${expedicion.pickingType ?? ""}',
                  style: const TextStyle(fontSize: 12, color: primaryColorApp)),
          
              if (expedicion.observacion != null &&
                  expedicion.observacion!.isNotEmpty)
                Text('Observación: ${expedicion.observacion}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: primaryColorApp)),
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: primaryColorApp),
                  const SizedBox(width: 4),
                  Text(
                    expedicion.fecha != null
                        ? DateFormat('dd/MM/yyyy').format(expedicion.fecha!)
                        : 'Sin fecha',
                    style: const TextStyle(fontSize: 12, color: primaryColorApp),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.receipt_long, size: 14, color: primaryColorApp),
                  const SizedBox(width: 4),
                  Text('Doc. Origen: ${expedicion.documentoOrigen ?? ""}',
                      style: const TextStyle(fontSize: 12, color: black)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: primaryColorApp),
                  const SizedBox(width: 4),
                  Text(
                    expedicion.cliente ?? 'Sin cliente',
                    style: TextStyle(
                        fontSize: 12,
                        color: (expedicion.cliente == null ||
                                expedicion.cliente!.isEmpty)
                            ? red
                            : black),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.add_box_outlined, size: 14, color: primaryColorApp),
                  const SizedBox(width: 4),
                  Text(
                      'Cantidad de items: ${expedicion.totalCantidades ?? 0}',
                      style: const TextStyle(fontSize: 12, color: black)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 14, color: primaryColorApp),
                  const SizedBox(width: 4),
                  Text(
                      'Cantidad de paquetes: ${expedicion.numeroPaquetes ?? 0}',
                      style: const TextStyle(fontSize: 12, color: black)),
                ],
              ),
              if (expedicion.productoSueltos != null &&
                  expedicion.productoSueltos! > 0)
                Row(
                  children: [
                    const Icon(Icons.widgets_outlined, size: 14, color: primaryColorApp),
                    const SizedBox(width: 4),
                    Text('Producto sueltos: ${expedicion.productoSueltos}',
                        style: const TextStyle(fontSize: 12, color: black)),
                  ],
                ),
              if (expedicion.totalPeso != null && expedicion.totalPeso! > 0)
                Row(
                  children: [
                    const Icon(Icons.scale_outlined, size: 14, color: primaryColorApp),
                    const SizedBox(width: 4),
                    Text('Peso total: ${expedicion.totalPeso}',
                        style: const TextStyle(fontSize: 12, color: black)),
                  ],
                ),
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 14, color: primaryColorApp),
                  const SizedBox(width: 4),
                  Text(
                    expedicion.responsable == "" ? 'Sin responsable' : expedicion.responsable!,
                    style: TextStyle(
                        fontSize: 12,
                        color: (expedicion.responsable == null ||
                                expedicion.responsable!.isEmpty)
                            ? red
                            : black), 
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
