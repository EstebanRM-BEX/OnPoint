import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/asignacion_observacion.dart';

/// Detalle de TODAS las asignaciones (`observaciones[]`) de un producto del
/// pool — quién la tomó, cuándo, en qué quedó (terminada/vencida/liberada)
/// y la novedad si tuvo. Es una lista, así que hace scroll (mismo fix de
/// width: double.maxFinite que dialog_barcodes_widget.dart, necesario
/// porque AlertDialog envuelve su content en un IntrinsicWidth).
class RecepcionNovedadesDialogWidget extends StatelessWidget {
  const RecepcionNovedadesDialogWidget({
    super.key,
    required this.productName,
    required this.observaciones,
    this.uom,
  });

  final String productName;
  final List<AsignacionObservacion> observaciones;

  /// Unidad de medida del producto (RecepcionPoolItem.uom) — solo para
  /// mostrarla junto a las cantidades de cada asignación.
  final String? uom;

  String _estadoLabel(String? state) {
    switch (state) {
      case 'done':
        return 'Terminada';
      case 'expired':
        return 'Vencida';
      case 'released':
        return 'Liberada';
      default:
        return state ?? '';
    }
  }

  Color _estadoColor(String? state) {
    switch (state) {
      case 'done':
        return green;
      case 'expired':
        return red;
      case 'released':
        return Colors.orange;
      default:
        return grey;
    }
  }

  /// timeSeconds → "Xm Ys" (o "Sin registrar" si viene en 0/null, como en
  /// las asignaciones vencidas/liberadas que nunca se completaron).
  String _formatTiempo(double? seconds) {
    if (seconds == null || seconds <= 0) return 'Sin registrar';
    final totalSeconds = seconds.round();
    final minutes = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return minutes > 0 ? '${minutes}m ${secs}s' : '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
        child: Text(
          'Novedades\n$productName',
          textAlign: TextAlign.center,
          style: TextStyle(color: primaryColorApp, fontSize: 16),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: observaciones.length,
                itemBuilder: (context, index) {
                  final o = observaciones[index];
                  final tieneNovedad = (o.observacion ?? '').isNotEmpty;
                  final fecha = o.fechaCompletado ?? o.fechaAsignacion ?? '';

                  return Card(
                    elevation: 3,
                    color: white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: black,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  o.operario ?? 'Operario desconocido',
                                  style: TextStyle(
                                    color: primaryColorApp,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _estadoColor(o.state).withOpacity(.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _estadoLabel(o.state),
                                  style: TextStyle(
                                    color: _estadoColor(o.state),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (fecha.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    fecha,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 14,
                                  color: grey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Envió: ${o.qtyRecibida ?? 0}'
                                        '${uom != null ? ' ($uom)' : ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Requeridas: ${o.qtyAsignada ?? 0}'
                                        '${uom != null ? ' ($uom)' : ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tiempo: ${_formatTiempo(o.timeSeconds)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              tieneNovedad ? o.observacion! : 'Sin novedad',
                              style: TextStyle(
                                fontSize: 12,
                                color: tieneNovedad ? Colors.orange : grey,
                                fontStyle: tieneNovedad
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                minimumSize: const Size(double.infinity, 35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Cerrar', style: TextStyle(color: white)),
            ),
          ],
        ),
      ),
    );
  }
}
