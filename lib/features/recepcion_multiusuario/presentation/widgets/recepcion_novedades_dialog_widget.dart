import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/asignacion_observacion.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/dialog_deshacer_recepcion_widget.dart';

/// Detalle de TODAS las asignaciones (`observaciones[]`) de un producto del
/// pool — quién la tomó, cuándo, en qué quedó (terminada/vencida/liberada)
/// y la novedad si tuvo. Es una lista, así que hace scroll (mismo fix de
/// width: double.maxFinite que dialog_barcodes_widget.dart, necesario
/// porque AlertDialog envuelve su content en un IntrinsicWidth).
///
/// Cada fila "Terminada" (state: done) tiene su propio ícono de deshacer
/// (usa el claim_id de ESA asignación puntual, no el de la card exterior) —
/// vencidas/liberadas no lo muestran porque nunca se completaron.
///
/// Incluye un filtro para ver solo las asignaciones del usuario actual
/// (compara AsignacionObservacion.operarioId contra PrefUtils.getUserId()).
class RecepcionNovedadesDialogWidget extends StatefulWidget {
  const RecepcionNovedadesDialogWidget({
    super.key,
    required this.productName,
    required this.observaciones,
    required this.sessionId,
    this.uom,
  });

  final String productName;
  final List<AsignacionObservacion> observaciones;

  /// Necesario para refrescar el pool tras un deshacer exitoso (ver
  /// [DialogDeshacerRecepcionWidget]).
  final int? sessionId;

  /// Unidad de medida del producto (RecepcionPoolItem.uom) — solo para
  /// mostrarla junto a las cantidades de cada asignación.
  final String? uom;

  @override
  State<RecepcionNovedadesDialogWidget> createState() =>
      _RecepcionNovedadesDialogWidgetState();
}

class _RecepcionNovedadesDialogWidgetState
    extends State<RecepcionNovedadesDialogWidget> {
  bool _soloMisEnvios = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioActual();
  }

  Future<void> _cargarUsuarioActual() async {
    final userId = await PrefUtils.getUserId();
    if (!mounted) return;
    setState(() => _currentUserId = userId);
  }

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
    final size = MediaQuery.sizeOf(context);

    final observaciones = _soloMisEnvios
        ? widget.observaciones
              .where((o) => o.operarioId == _currentUserId)
              .toList()
        : widget.observaciones;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Center(
        child: Text(
          'Detalles\n${widget.productName}',
          textAlign: TextAlign.center,
          style: TextStyle(color: primaryColorApp, fontSize: 16),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text(
                  'Procesados por mí',
                  style: TextStyle(fontSize: 12),
                ),
                avatar: Icon(
                  Icons.person_outline,
                  size: 16,
                  color: _soloMisEnvios ? white : primaryColorApp,
                ),
                selected: _soloMisEnvios,
                selectedColor: primaryColorApp,
                labelStyle: TextStyle(
                  color: _soloMisEnvios ? white : black,
                  fontSize: 12,
                ),
                onSelected: _currentUserId == null
                    ? null
                    : (value) => setState(() => _soloMisEnvios = value),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: size.height * 0.5,
              width: double.maxFinite,
              child: observaciones.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay envíos tuyos para este producto',
                        style: TextStyle(fontSize: 13, color: grey),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: observaciones.length,
                      itemBuilder: (context, index) {
                        final o = observaciones[index];
                        final tieneNovedad = (o.observacion ?? '').isNotEmpty;
                        final tieneNotaCorreccion =
                            (o.notaCorreccion ?? '').isNotEmpty;
                        final tieneUbicacionDestino =
                            (o.locationDestName ?? '').isNotEmpty;
                        final fecha =
                            o.fechaCompletado ?? o.fechaAsignacion ?? '';

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
                                        color: _estadoColor(
                                          o.state,
                                        ).withValues(alpha: 0.15),
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
                                    if (o.isDone)
                                      IconButton(
                                        tooltip: 'Deshacer',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () async {
                                          final result = await showDialog<bool>(
                                            context: context,
                                            builder: (_) =>
                                                DialogDeshacerRecepcionWidget(
                                                  productName:
                                                      widget.productName,
                                                  claimId: o.claimId,
                                                  sessionId: widget.sessionId,
                                                ),
                                          );
                                          // La lista de observaciones que
                                          // tiene este diálogo quedó
                                          // desactualizada tras el deshacer
                                          // (el pool ya cambió) — se cierra
                                          // para que el operario vuelva a
                                          // abrir "Ver detalles" con datos
                                          // frescos.
                                          if (result == true &&
                                              context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: red,
                                          size: 18,
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
                                              '${widget.uom != null ? ' (${widget.uom})' : ''}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Requeridas: ${o.qtyAsignada ?? 0}'
                                              '${widget.uom != null ? ' (${widget.uom})' : ''}',
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
                                if (tieneUbicacionDestino)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.pin_drop_outlined,
                                          size: 14,
                                          color: grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Ubicación destino: '
                                            '${o.locationDestName}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    tieneNovedad
                                        ? o.observacion!
                                        : 'Sin novedad',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tieneNovedad
                                          ? Colors.orange
                                          : grey,
                                      fontStyle: tieneNovedad
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                    ),
                                  ),
                                ),
                                if (tieneNotaCorreccion)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.edit_note,
                                          size: 14,
                                          color: Colors.blueGrey,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Nota de corrección: '
                                            '${o.notaCorreccion}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ),
                                      ],
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
