import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/fetch_transferencia_session_detail_usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_session_card_widget.dart';
import 'package:wms_app/injection_container.dart';

/// Tab "Detalle" — la misma card que se ve en
/// ListTransferenciaMultiusuarioScreen, pero con el detalle refrescado vía
/// POST /api/transfer/session/{sessionId} (progress_percent, pending_tasks,
/// qty_asignada_total, etc. — puede haber quedado desactualizado si otro
/// operario avanzó la transferencia desde que se cargó la lista). Espejo de
/// RecepcionMultiusuarioDetailTabDetalle: mientras carga o si el fetch
/// falla, muestra la [session] que ya traía la navegación.
class TransferenciaMultiusuarioDetailTabDetalle extends StatefulWidget {
  const TransferenciaMultiusuarioDetailTabDetalle({
    super.key,
    required this.session,
  });

  final TransferenciaSession session;

  @override
  State<TransferenciaMultiusuarioDetailTabDetalle> createState() =>
      _TransferenciaMultiusuarioDetailTabDetalleState();
}

class _TransferenciaMultiusuarioDetailTabDetalleState
    extends State<TransferenciaMultiusuarioDetailTabDetalle> {
  late TransferenciaSession _session = widget.session;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    final sessionId = widget.session.sessionId;
    if (sessionId == null) return;

    setState(() => _isLoading = true);

    final result = await getIt<FetchTransferenciaSessionDetailUseCase>()(
      FetchTransferenciaSessionDetailParams(sessionId: sessionId),
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
            TransferenciaSessionCardWidget(session: _session),
          ],
        ),
      ),
    );
  }
}
