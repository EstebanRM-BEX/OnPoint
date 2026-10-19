import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/get_colors_utils.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

/// Resumen del pick actual (misma info que la card de index_list_pick_screen),
/// comprimido por defecto: nombre + zona; al expandir muestra el resto.
class PickDetailsExpandableCard extends StatefulWidget {
  final ResultPick pick;
  final String secuencia;
  final String placa;
  final dynamic porcentajeSeparadas;

  const PickDetailsExpandableCard({
    super.key,
    required this.pick,
    this.secuencia = '',
    this.placa = '',
    this.porcentajeSeparadas,
  });

  @override
  State<PickDetailsExpandableCard> createState() =>
      _PickDetailsExpandableCardState();
}

class _PickDetailsExpandableCardState extends State<PickDetailsExpandableCard> {
  bool _expanded = false;

  ResultPick get pick => widget.pick;

  Widget _label(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: primaryColorApp)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: valueColor ?? black),
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

  String _fecha() {
    final raw = pick.fechaCreacion;
    if (raw == null || raw.isEmpty) return 'Sin fecha';
    final parsed = DateTime.tryParse(raw);
    return parsed != null ? DateFormat('dd/MM/yyyy').format(parsed) : raw;
  }

  @override
  Widget build(BuildContext context) {
    final altaPrioridad = pick.priority != '0';
    final sinProveedor = pick.proveedor == null || pick.proveedor!.isEmpty;
    final sinResponsable =
        pick.responsable == null || pick.responsable!.isEmpty;
    final iniciado =
        pick.startTimeTransfer != null && pick.startTimeTransfer!.isNotEmpty;

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
                            pick.name ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColorApp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (pick.zonaEntrega != null &&
                              pick.zonaEntrega!.isNotEmpty)
                            Text(
                              pick.zonaEntrega!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (widget.porcentajeSeparadas != null)
                            Text(
                              'Unidades separadas: ${widget.porcentajeSeparadas}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: getColorForPercentage(
                                  widget.porcentajeSeparadas,
                                ),
                              ),
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
                  _label('Operación: ', pick.pickingType ?? ''),
                  if (pick.observacion != null && pick.observacion!.isNotEmpty)
                    _label('Observación: ', pick.observacion!),
                  _label(
                    'Propietario: ',
                    pick.propietario ?? 'Sin propietario',
                    valueColor: altaPrioridad ? red : black,
                  ),
                  _label(
                    'Prioridad: ',
                    altaPrioridad ? 'Alta' : 'Normal',
                    valueColor: altaPrioridad ? red : black,
                  ),
                  const Divider(color: black, thickness: 1, height: 5),
                  _icon(
                    Icons.calendar_month_sharp,
                    Text(
                      _fecha(),
                      style: const TextStyle(fontSize: 12, color: black),
                    ),
                  ),
                  _icon(
                    Icons.person,
                    Text(
                      sinProveedor ? 'Sin contacto' : pick.proveedor!,
                      style: TextStyle(
                        fontSize: 12,
                        color: sinProveedor ? red : black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _icon(
                    Icons.receipt,
                    _inline('Doc. Origen: ', pick.origin ?? ''),
                  ),
                  if (pick.backorderId != null && pick.backorderId != 0)
                    _icon(
                      Icons.file_copy,
                      Text(
                        pick.backorderName ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  _icon(
                    Icons.add,
                    _inline(
                      'Cantidad de lineas: ',
                      '${pick.numeroLineas ?? 0}',
                    ),
                  ),
                  _icon(
                    Icons.add,
                    _inline('Cantidad unidades: ', '${pick.numeroItems ?? 0}'),
                  ),
                  _icon(
                    Icons.person,
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sinResponsable
                                ? 'Sin responsable'
                                : pick.responsable!,
                            style: TextStyle(
                              fontSize: 12,
                              color: sinResponsable ? red : black,
                            ),
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
                                    'Este Pick fue iniciado a las ${pick.startTimeTransfer}',
                              ),
                            ),
                            child: Icon(
                              Icons.timer_sharp,
                              color: primaryColorApp,
                              size: 15,
                            ),
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
}
