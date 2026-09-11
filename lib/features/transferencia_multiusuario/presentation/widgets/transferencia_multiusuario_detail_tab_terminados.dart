import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_asignacion_observacion.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_pool_item.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/bloc/detail/transferencia_multiusuario_pool_bloc.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_terminado_card_widget.dart';
import 'package:wms_app/shared/widgets/shimmer_list_widget.dart';

class _ProductoTerminado {
  const _ProductoTerminado(this.item, this.observaciones);

  final TransferenciaPoolItem item;

  /// Asignaciones terminadas de este producto, ya deduplicadas.
  final List<TransferenciaAsignacionObservacion> observaciones;

  /// Más reciente primero al ordenar la lista de productos.
  String get ultimaFecha => observaciones
      .map((o) => o.fechaCompletado ?? '')
      .fold('', (max, fecha) => fecha.compareTo(max) > 0 ? fecha : max);
}

/// Tab "Terminados" — transferencias ya terminadas en esta sesión, por mí o
/// por otros operarios. Espejo de RecepcionMultiusuarioDetailTabTerminados:
/// reusa el mismo TransferenciaMultiusuarioPoolBloc que "Por hacer" (ya
/// sembrado al entrar al detalle desde el snapshot, ver
/// transferencia_multiusuario_detail_screen.dart) pero con su propio fetch:
/// POST /api/transfer/session/{id}/pool con verification: true, que es el
/// único modo en el que el backend incluye tareas agotadas junto con su
/// historial de asignaciones en `observaciones[]`. Se agrupa por producto
/// (un card por task_id) y se filtran las asignaciones con `state == "done"`.
class TransferenciaMultiusuarioDetailTabTerminados extends StatelessWidget {
  const TransferenciaMultiusuarioDetailTabTerminados({
    super.key,
    required this.session,
  });

  final TransferenciaSession session;

  void _retry(BuildContext context) {
    final sessionId = session.sessionId;
    if (sessionId == null) return;
    context.read<TransferenciaMultiusuarioPoolBloc>().add(
      FetchTransferenciaPoolEvent(sessionId, verification: true),
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
                TransferenciaMultiusuarioPoolBloc,
                TransferenciaMultiusuarioPoolState
              >(
                builder: (context, state) {
                  // Solo reacciona a loading/error de SU propio fetch
                  // (verification: true) — un refresco de "Por hacer"
                  // (verification: false) no debe mostrar spinner acá. El
                  // seed inicial desde el snapshot
                  // (SeedTransferenciaTerminadosEvent) emite un
                  // TransferenciaPoolLoaded directo, así que ya llega acá
                  // con datos y sin pasar por este loading.
                  if (state is TransferenciaMultiusuarioPoolInitial ||
                      (state is TransferenciaMultiusuarioPoolLoading &&
                          state.verification)) {
                    return const ShimmerListWidget();
                  }

                  if (state is TransferenciaMultiusuarioPoolError &&
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
                      .read<TransferenciaMultiusuarioPoolBloc>()
                      .terminadosItems;

                  // POST /api/transfer/session/{id}/pool a veces repite la
                  // misma asignación (mismo asignacion_id/claim_id) más de
                  // una vez — en el mismo producto o incluso en dos task_id
                  // distintos. Se descarta por id ya visto para no mostrar
                  // la misma transferencia terminada duplicada.
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
                            'Todavía no hay transferencias terminadas',
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
                      return TransferenciaTerminadoCardWidget(
                        item: producto.item,
                        observaciones: producto.observaciones,
                        sessionId: session.sessionId,
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
