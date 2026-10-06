import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';

/// Tarjeta de la lista de expediciones (diseño Stitch "Listado de
/// Expediciones"). La navegación la maneja quien la usa vía [onTap].
class ExpedicionCardWidget extends StatelessWidget {
  final ExpedicionPedido expedicion;
  final VoidCallback? onTap;

  const ExpedicionCardWidget({super.key, required this.expedicion, this.onTap});

  static const _mono = 'monospace';
  static const _emerald = Color(0xFF047857);

  /// Fila "icono + label gris + valor en negrita".
  Widget _fila(
    IconData icon, {
    String? label,
    required String value,
    Color? valueColor,
    bool mono = false,
    bool bold = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColorApp),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (label != null)
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(color: ClusterPalette.slate500),
                    ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontFamily: mono ? _mono : null,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                      color: valueColor ?? ClusterPalette.slate800,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  String _iniciales(String nombre) => nombre
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final e = expedicion;
    final sinCliente = e.cliente == null || e.cliente!.isEmpty;
    final sinResponsable = e.responsable == null || e.responsable!.isEmpty;
    final tienePeso = e.totalPeso != null && e.totalPeso! > 0;
    final iniciada =
        e.startTimeTransfer != null && e.startTimeTransfer!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ClusterPalette.slate100),
          boxShadow: ClusterPalette.cardShadow,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                e.nombre ?? '',
                                style: const TextStyle(
                                  fontFamily: _mono,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColorApp,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFA7F3D0)),
                                ),
                                child: Text(
                                  'Operación: ${e.pickingType ?? ""}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _emerald,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (e.zonaEntrega != null &&
                              e.zonaEntrega!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                e.zonaEntrega!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: ClusterPalette.slate500,
                                ),
                              ),
                            ),
                          if (e.manejoPropietario == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                'PROPIETARIO: ${(e.propietario ?? "Sin propietario").toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: ClusterPalette.slate500,
                                ),
                              ),
                            ),
                          if (e.observacion != null &&
                              e.observacion!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                'Observación: ${e.observacion}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ClusterPalette.slate500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.chevron_right,
                          color: ClusterPalette.slate500),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 6),
                  child: Divider(height: 1, color: ClusterPalette.slate100),
                ),
                _fila(
                  Icons.calendar_today_outlined,
                  value: e.fecha != null
                      ? DateFormat('dd/MM/yyyy').format(e.fecha!)
                      : 'Sin fecha',
                  bold: false,
                ),
                _fila(Icons.description_outlined,
                    label: 'Doc. Origen', value: e.documentoOrigen ?? ''),
                _fila(
                  Icons.person_outline,
                  label: 'Cliente',
                  value: e.cliente ?? 'Sin cliente',
                  valueColor: sinCliente ? red : null,
                ),
                _fila(Icons.format_list_bulleted,
                    label: 'Cantidad de items',
                    value: '${e.totalCantidades ?? 0}'),
                _fila(Icons.inventory_2_outlined,
                    label: 'Cantidad de paquetes',
                    value: '${e.numeroPaquetes ?? 0}'),
                if (e.productoSueltos != null && e.productoSueltos! > 0)
                  _fila(Icons.widgets_outlined,
                      label: 'Producto sueltos',
                      value: '${e.productoSueltos}'),
                if (e.backorderId != null && e.backorderId != 0)
                  _fila(Icons.insert_drive_file_outlined,
                      label: 'Despacho rel.',
                      value: e.backorderName ?? '',
                      mono: true),
                if (tienePeso)
                  _fila(Icons.balance_outlined,
                      label: 'Peso total', value: '${e.totalPeso} kg'),
                const Padding(
                  padding: EdgeInsets.only(top: 6, bottom: 8),
                  child: Divider(height: 1, color: ClusterPalette.slate100),
                ),
                Row(
                  children: [
                    if (!sinResponsable) ...[
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: ClusterPalette.brand100,
                        child: Text(
                          _iniciales(e.responsable!),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: primaryColorApp,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        sinResponsable ? 'Sin responsable' : e.responsable!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              sinResponsable ? red : ClusterPalette.slate700,
                        ),
                      ),
                    ),
                    if (iniciada)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => DialogInfo(
                            title: 'Tiempo de inicio',
                            body:
                                'Este pedido fue iniciado a las ${e.startTimeTransfer}',
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ClusterPalette.slate50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: ClusterPalette.slate200),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule,
                                  size: 14, color: primaryColorApp),
                              SizedBox(width: 4),
                              Text('En curso',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: ClusterPalette.slate600)),
                            ],
                          ),
                        ),
                      )
                    else if (!tienePeso)
                      const Text('Sin peso regist.',
                          style: TextStyle(
                              fontSize: 11, color: ClusterPalette.slate400)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
