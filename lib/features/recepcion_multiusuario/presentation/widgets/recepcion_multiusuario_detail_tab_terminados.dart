import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/asignacion_observacion.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_pool_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_terminado_card_widget.dart';
import 'package:wms_app/shared/widgets/shimmer_list_widget.dart';

class _ProductoTerminado {
  const _ProductoTerminado(this.item, this.observaciones);

  final RecepcionPoolItem item;

  /// Asignaciones terminadas de este producto, ya deduplicadas.
  final List<AsignacionObservacion> observaciones;

  /// Más reciente primero al ordenar la lista de productos.
  String get ultimaFecha => observaciones
      .map((o) => o.fechaCompletado ?? '')
      .fold('', (max, fecha) => fecha.compareTo(max) > 0 ? fecha : max);
}

/// Tab 3 — recepciones ya terminadas en esta sesión, por mí o por otros
/// operarios. Reusa el mismo RecepcionMultiusuarioPoolBloc que "Por hacer"
/// (ya cargado al entrar al detalle, ver recepcion_multiusuario_detail_screen.dart)
/// pero con su propio fetch: POST /api/receipt/session/{id}/pool con
/// verification: true, que es el único modo en el que el backend incluye
/// tareas agotadas (qty_available: 0) junto con su historial de
/// asignaciones en `observaciones[]` — sin el flag esas tareas no vienen
/// en la respuesta. Acá se agrupa por producto (un card por task_id) y se
/// filtran las asignaciones que ya quedaron con `state == "done"`.
class RecepcionMultiusuarioDetailTabTerminados extends StatelessWidget {
  const RecepcionMultiusuarioDetailTabTerminados({
    super.key,
    required this.session,
  });

  final RecepcionSession session;

  void _retry(BuildContext context) {
    final sessionId = session.sessionId;
    if (sessionId == null) return;
    context.read<RecepcionMultiusuarioPoolBloc>().add(
      FetchRecepcionPoolEvent(sessionId, verification: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(Icons.refresh, color: primaryColorApp),
            tooltip: 'Actualizar terminados',
            onPressed: () => _retry(context),
          ),
        ),
        Expanded(
          child:
              BlocBuilder<
                RecepcionMultiusuarioPoolBloc,
                RecepcionMultiusuarioPoolState
              >(
                builder: (context, state) {
                  // Solo reacciona a loading/error de SU propio fetch
                  // (verification: true) — un refresco de "Por hacer"
                  // (verification: false) no debe mostrar spinner acá.
                  if (state is RecepcionMultiusuarioPoolInitial ||
                      (state is RecepcionMultiusuarioPoolLoading &&
                          state.verification)) {
                    return const ShimmerListWidget();
                  }

                  if (state is RecepcionMultiusuarioPoolError &&
                      state.verification) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: red,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: grey, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => _retry(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColorApp,
                              ),
                              child: const Text(
                                'Reintentar',
                                style: TextStyle(color: white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final items = context
                      .read<RecepcionMultiusuarioPoolBloc>()
                      .terminadosItems;

                  // POST /api/receipt/session/{id}/pool a veces repite la
                  // misma asignación (mismo asignacion_id/claim_id) más de
                  // una vez — en el mismo producto o incluso en dos task_id
                  // distintos. Se descarta por id ya visto para no mostrar
                  // la misma recepción terminada duplicada.
                  final vistos = <int>{};
                  final productos = <_ProductoTerminado>[];
                  for (final item in items) {
                    final done = item.observaciones
                        .where(
                          (o) =>
                              o.isDone &&
                              vistos.add(
                                o.asignacionId ?? o.claimId ?? o.hashCode,
                              ),
                        )
                        .toList();
                    if (done.isNotEmpty) {
                      productos.add(_ProductoTerminado(item, done));
                    }
                  }
                  productos.sort(
                    (a, b) => b.ultimaFecha.compareTo(a.ultimaFecha),
                  );

                  if (productos.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.done_all, color: grey, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Todavía no hay recepciones terminadas',
                            style: TextStyle(color: grey, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final producto = productos[index];
                      return RecepcionTerminadoCardWidget(
                        item: producto.item,
                        observaciones: producto.observaciones,
                      );
                    },
                  );
                },
              ),
        ),
      ],
    );
  }
}
