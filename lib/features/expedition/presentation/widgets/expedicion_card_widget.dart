import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_observacion_expedicion_widget.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';

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
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 6, bottom: 2),
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Observación',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E))),
                            const SizedBox(height: 2),
                            Text(expedicion.observacion!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF334155))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => DialogObservacionExpedicionWidget(
                            observacion: expedicion.observacion!,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryColorApp),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Ver más',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColorApp)),
                              SizedBox(width: 4),
                              Icon(Icons.visibility_outlined,
                                  size: 14, color: primaryColorApp),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  Flexible(
                    child: Text('Doc. Origen: ${expedicion.documentoOrigen ?? ""}',
                        style: const TextStyle(fontSize: 12, color: black)),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: primaryColorApp),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      expedicion.cliente ?? 'Sin cliente',
                      style: TextStyle(
                          fontSize: 12,
                          color: (expedicion.cliente == null ||
                                  expedicion.cliente!.isEmpty)
                              ? red
                              : black),
                    ),
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
              Visibility(
                visible: expedicion.backorderId != null &&
                    expedicion.backorderId != 0,
                child: Row(
                  children: [
                    const Icon(Icons.file_copy, size: 14, color: primaryColorApp),
                    const SizedBox(width: 4),
                    Text(expedicion.backorderName ?? '',
                        style: const TextStyle(
                            fontSize: 12,
                            color: black,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 14, color: primaryColorApp),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      expedicion.responsable == "" ? 'Sin responsable' : expedicion.responsable!,
                      style: TextStyle(
                          fontSize: 12,
                          color: (expedicion.responsable == null ||
                                  expedicion.responsable!.isEmpty)
                              ? red
                              : black),
                    ),
                  ),
                  if (expedicion.startTimeTransfer != null &&
                      expedicion.startTimeTransfer!.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => DialogInfo(
                            title: 'Tiempo de inicio',
                            body:
                                'Este pedido fue iniciado a las ${expedicion.startTimeTransfer}',
                          ),
                        );
                      },
                      child: const Icon(Icons.timer_sharp,
                          color: primaryColorApp, size: 15),
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
