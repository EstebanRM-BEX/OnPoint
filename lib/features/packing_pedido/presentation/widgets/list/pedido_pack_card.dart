import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_observacion_expedicion_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_observacion_widget.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/info_linea_pack.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';

/// Tarjeta de un pedido en la lista de packing.
class PedidoPackCard extends StatelessWidget {
  final PedidoPack pedido;
  final VoidCallback onTap;

  const PedidoPackCard({super.key, required this.pedido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = pedido;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Card(
        color: p.isSelected ? primaryColorAppLigth : Colors.white,
        elevation: 5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColorApp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (p.zonaEntrega.isNotEmpty)
                        Text(
                          p.zonaEntrega,
                          style: const TextStyle(fontSize: 12, color: black),
                        ),
                      if (p.manejoPropietario)
                        InfoLineaPack(
                          etiqueta: 'Propietario',
                          valor: p.propietario,
                          vacio: 'Sin propietario',
                        ),
                      InfoLineaPack(
                        etiqueta: 'Operación',
                        valor: p.pickingType,
                      ),
                      if (p.observacion.isNotEmpty)
                        ExpedicionObservacionWidget(
                          observacion: p.observacion,
                          onVerMas: () => showDialog(
                            context: context,
                            builder: (_) => DialogObservacionExpedicionWidget(
                              observacion: p.observacion,
                            ),
                          ),
                        ),
                      InfoLineaPack(
                        etiqueta: 'Prioridad',
                        valor: p.esPrioritario ? 'Alta' : 'Normal',
                        colorValor: p.esPrioritario ? red : black,
                      ),
                      InfoLineaPack(
                        etiqueta: 'Ubicación',
                        valor: p.ubicacionVisible,
                      ),
                      const Divider(color: black, thickness: 1, height: 8),
                      InfoLineaPack(
                        icono: Icons.calendar_month_sharp,
                        valor: p.fechaCreacion == null
                            ? ''
                            : DateFormat('dd/MM/yyyy').format(p.fechaCreacion!),
                        vacio: 'Sin fecha',
                      ),
                      InfoLineaPack(
                        icono: Icons.receipt,
                        etiqueta: 'Doc. Origen',
                        valor: p.referencia,
                        colorValor: primaryColorApp,
                      ),
                      if (p.tieneBackorder)
                        InfoLineaPack(
                          icono: Icons.file_copy,
                          valor: p.backorderName,
                          negrita: true,
                        ),
                      InfoLineaPack(
                        icono: Icons.person,
                        valor: p.proveedor,
                        vacio: 'Sin proveedor',
                      ),
                      InfoLineaPack(
                        icono: Icons.add,
                        etiqueta: 'Cantidad de items',
                        valor: '${p.cantidadProductos}',
                        colorValor: primaryColorApp,
                      ),
                      InfoLineaPack(
                        icono: Icons.add,
                        etiqueta: 'Cantidad de paquetes',
                        valor: '${p.numeroPaquetes}',
                        colorValor: primaryColorApp,
                      ),
                      InfoLineaPack(
                        icono: Icons.person,
                        valor: p.responsable,
                        vacio: 'Sin responsable',
                        trailing: p.iniciado
                            ? GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => DialogInfo(
                                    title: 'Tiempo de inicio',
                                    body:
                                        'Este pedido fue iniciado a las '
                                        '${p.startTimeTransfer}',
                                  ),
                                ),
                                child: Icon(
                                  Icons.timer_sharp,
                                  color: primaryColorApp,
                                  size: 16,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: primaryColorApp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
