import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/asignacion_observacion.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_pool_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_terminado_card_widget.dart';

class _EntradaTerminada {
  const _EntradaTerminada(this.item, this.asignacion);

  final RecepcionPoolItem item;
  final AsignacionObservacion asignacion;
}

/// Tab 3 — recepciones ya terminadas en esta sesión, por mí o por otros
/// operarios. Reusa el mismo RecepcionMultiusuarioPoolBloc que "Por hacer"
/// (ya cargado al entrar al detalle, ver recepcion_multiusuario_detail_screen.dart):
/// POST /api/receipt/session/{id}/pool trae, por cada producto, el
/// historial completo de asignaciones en `observaciones[]` — acá solo se
/// filtran las que ya quedaron con `state == "done"`, no hace falta un
/// fetch aparte.
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
      FetchRecepcionPoolEvent(sessionId),
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
                  if (state is RecepcionMultiusuarioPoolLoading ||
                      state is RecepcionMultiusuarioPoolDbLoading ||
                      state is RecepcionMultiusuarioPoolInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is RecepcionMultiusuarioPoolError) {
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

                  final items = state is RecepcionPoolLoaded
                      ? state.items
                      : const <RecepcionPoolItem>[];

                  final terminadas =
                      <_EntradaTerminada>[
                        for (final item in items)
                          for (final asignacion in item.observaciones)
                            if (asignacion.isDone)
                              _EntradaTerminada(item, asignacion),
                      ]..sort(
                        (a, b) => (b.asignacion.fechaCompletado ?? '')
                            .compareTo(a.asignacion.fechaCompletado ?? ''),
                      );

                  if (terminadas.isEmpty) {
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
                    itemCount: terminadas.length,
                    itemBuilder: (context, index) {
                      final entrada = terminadas[index];
                      return RecepcionTerminadoCardWidget(
                        item: entrada.item,
                        asignacion: entrada.asignacion,
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
