import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/get_colors_utils.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

/// Resumen del batch actual (misma info que la card de wms_picking/index.dart),
/// comprimido por defecto: nombre, zona y % separado; al expandir, el resto.
class BatchDetailsExpandableCard extends StatefulWidget {
  final BatchsModel batch;
  final String secuencia;
  final String placa;
  final String porcentajeSeparadas;

  const BatchDetailsExpandableCard({
    super.key,
    required this.batch,
    required this.porcentajeSeparadas,
    this.secuencia = '',
    this.placa = '',
  });

  @override
  State<BatchDetailsExpandableCard> createState() =>
      _BatchDetailsExpandableCardState();
}

class _BatchDetailsExpandableCardState
    extends State<BatchDetailsExpandableCard> {
  bool _expanded = false;

  BatchsModel get batch => widget.batch;

  Widget _label(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: primaryColorApp)),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 12, color: black),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _icon(IconData icon, Widget child) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Icon(icon, color: primaryColorApp, size: 15),
            const SizedBox(width: 5),
            Expanded(child: child),
          ],
        ),
      );

  Widget _inline(String label, String value) => Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: black)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: primaryColorApp),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  String _fecha() {
    final raw = batch.scheduleddate;
    if (raw == null || raw.toString().isEmpty) return 'Sin fecha';
    final parsed = DateTime.tryParse(raw.toString());
    return parsed != null
        ? DateFormat('dd/MM/yyyy').format(parsed)
        : raw.toString();
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Center(
            child: Text(
              'Información',
              style: TextStyle(color: primaryColorApp, fontSize: 20),
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'El porcentaje de unidades separadas se calcula de la siguiente manera:',
              ),
              SizedBox(height: 5),
              Text(
                'Porcentaje de unidades separadas = (Unidades separadas / Unidades totales) * 100',
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar', style: TextStyle(color: white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manejaPropietario =
        batch.manejoPropietario == 1 || batch.manejoPropietario == true;
    final iniciado =
        batch.startTimePick != null && batch.startTimePick.toString().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Card(
        color: white,
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.name ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColorApp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (batch.zonaEntrega != null &&
                              batch.zonaEntrega!.isNotEmpty)
                            Text(
                              batch.zonaEntrega!,
                              style:
                                  const TextStyle(fontSize: 12, color: black),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Row(
                            children: [
                              Text(
                                'Unidades separadas: ${widget.porcentajeSeparadas}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: getColorForPercentage(
                                    double.tryParse(
                                          widget.porcentajeSeparadas,
                                        ) ??
                                        0.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _showHelp,
                                child: Icon(
                                  Icons.help,
                                  color: primaryColorApp,
                                  size: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: primaryColorApp,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 4),
                  if (widget.secuencia.isNotEmpty)
                    _label('Secuencia WMS: ', widget.secuencia),
                  if (widget.placa.isNotEmpty)
                    _label('Placa WMS: ', widget.placa),
                  if (manejaPropietario)
                    _label('Propietario: ',
                        batch.propietario ?? 'Sin propietario'),
                  _label('Tipo de operación: ',
                      batch.pickingTypeId?.toString() ?? ''),
                  const Divider(color: black, thickness: 1, height: 5),
                  _icon(
                    Icons.calendar_month_sharp,
                    Text(_fecha(),
                        style: const TextStyle(fontSize: 12, color: black)),
                  ),
                  _icon(
                    Icons.add,
                    _inline('Cantidad de lineas: ', '${batch.countItems ?? 0}'),
                  ),
                  _icon(
                    Icons.add,
                    _inline('Cantidad unidades: ',
                        '${batch.totalQuantityItems ?? 0}'),
                  ),
                  _icon(
                    Icons.person,
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            batch.userName ?? 'Sin responsable',
                            style: const TextStyle(fontSize: 12, color: black),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (iniciado)
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => DialogInfo(
                                title: 'Tiempo de inicio',
                                body:
                                    'Este batch fue iniciado a las ${batch.startTimePick}',
                              ),
                            ),
                            child: Icon(Icons.timer_sharp,
                                color: primaryColorApp, size: 15),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
