import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/fetch_recepcion_session_detail_usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_session_card_widget.dart';
import 'package:wms_app/injection_container.dart';

/// Tab 1 — información de la recepción: la misma card que se ve en
/// ListRecepcionMultiusuarioScreen, pero con el detalle refrescado vía
/// POST /api/receipt/picking/{pickingId} (progress_percent, pending_tasks,
/// etc. — puede haber quedado desactualizado si otro operario avanzó la
/// recepción desde que se cargó la lista). Mientras carga o si el fetch
/// falla, muestra la [session] que ya traía la navegación.
class RecepcionMultiusuarioDetailTabDetalle extends StatefulWidget {
  const RecepcionMultiusuarioDetailTabDetalle({
    super.key,
    required this.session,
  });

  final RecepcionSession session;

  @override
  State<RecepcionMultiusuarioDetailTabDetalle> createState() =>
      _RecepcionMultiusuarioDetailTabDetalleState();
}

class _RecepcionMultiusuarioDetailTabDetalleState
    extends State<RecepcionMultiusuarioDetailTabDetalle> {
  late RecepcionSession _session = widget.session;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    final pickingId = widget.session.pickingId;
    if (pickingId == null) return;

    setState(() => _isLoading = true);

    final result = await getIt<FetchRecepcionSessionDetailUseCase>()(
      FetchRecepcionSessionDetailParams(pickingId: pickingId),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Si falla nos quedamos con lo que ya había (la sesión de la lista) en
    // vez de dejar la pantalla vacía — no es una acción que el operario
    // haya pedido explícitamente, no hace falta interrumpirlo con un error.
    result.fold((failure) {}, (session) => setState(() => _session = session));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarDetalle,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColorApp,
                  ),
                ),
              ),
            RecepcionSessionCardWidget(session: _session),
          ],
        ),
      ),
    );
  }
}
