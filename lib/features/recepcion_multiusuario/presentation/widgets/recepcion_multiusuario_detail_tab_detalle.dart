import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_validacion.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/asignar_validador_recepcion_usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/fetch_recepcion_session_detail_usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/validar_recepcion_multi_usecase.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/dialogs_validar_recepcion_widget.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_session_card_widget.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_validar_button_widget.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

/// Tab 1 — información de la recepción: la misma card que se ve en
/// ListRecepcionMultiusuarioScreen, pero con el detalle refrescado vía
/// POST /api/receipt/picking/{pickingId} (progress_percent, pending_tasks,
/// etc. — puede haber quedado desactualizado si otro operario avanzó la
/// recepción desde que se cargó la lista). Mientras carga o si el fetch
/// falla, muestra la [session] que ya traía la navegación.
///
/// Con el permiso allow_validate_receipt_multi se ve además la acción del
/// validador: asignarse si el documento no tiene validador, o "Validar
/// recepción" (cierra la sesión y valida el picking) si ya es el asignado.
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
    extends State<RecepcionMultiusuarioDetailTabDetalle>
    with LoadingDialogMixin {
  late RecepcionSession _session = widget.session;
  bool _isLoading = false;
  bool _puedeValidar = false;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _cargarPermiso();
    _cargarDetalle();
  }

  Future<void> _cargarPermiso() async {
    final userId = await PrefUtils.getUserId();
    final config = await getIt<ConfiguracionCacheService>().getConfiguration(
      userId,
    );
    if (!mounted) return;
    setState(
      () => _puedeValidar =
          config?.result?.result?.allowValidateReceiptMulti == true,
    );
  }

  /// Devuelve false si el fetch falló (se conserva la sesión anterior).
  Future<bool> _cargarDetalle() async {
    final pickingId = widget.session.pickingId;
    if (pickingId == null) return false;

    setState(() => _isLoading = true);

    final result = await getIt<FetchRecepcionSessionDetailUseCase>()(
      FetchRecepcionSessionDetailParams(pickingId: pickingId),
    );

    if (!mounted) return false;
    setState(() => _isLoading = false);

    // Si falla nos quedamos con lo que ya había (la sesión de la lista) en
    // vez de dejar la pantalla vacía — no es una acción que el operario
    // haya pedido explícitamente, no hace falta interrumpirlo con un error.
    return result.fold((failure) => false, (session) {
      setState(() => _session = session);
      return true;
    });
  }

  bool get _mostrarValidar =>
      _puedeValidar &&
      _session.currentUserCanBeValidator != false &&
      _session.state != 'done' &&
      _session.state != 'cancel';

  Future<void> _onAsignar() async {
    final sessionId = _session.sessionId;
    if (_ocupado || sessionId == null) return;
    setState(() => _ocupado = true);
    try {
      final userId = await PrefUtils.getUserId();
      showLoadingDialog('Asignando validador...');
      final result = await getIt<AsignarValidadorRecepcionUseCase>()(
        AsignarValidadorRecepcionParams(sessionId: sessionId, userId: userId),
      );
      hideLoadingDialog();
      if (!mounted) return;
      result.fold((failure) => _mostrarError(failure.message), (_) {});
      // La cabecera de assign_validator no trae los flags del usuario
      // actual (current_user_is_validator, can_validate_document).
      await _cargarDetalle();
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _onValidar() async {
    final sessionId = _session.sessionId;
    if (_ocupado || sessionId == null) return;
    setState(() => _ocupado = true);
    try {
      // lines_assigned cambia mientras otros operarios confirman o liberan.
      final refrescado = await _cargarDetalle();
      if (!mounted) return;
      if (!refrescado) {
        _mostrarError('No se pudo actualizar la recepción. Intente de nuevo.');
        return;
      }
      if (_session.canValidateDocument != true ||
          (_session.linesAssigned ?? 0) > 0) {
        return; // El botón ya muestra el motivo.
      }

      final completa = (_session.progressPercent ?? 0) >= 100;
      final opcion = await showDialog<OpcionConfirmarRecepcion>(
        context: context,
        builder: (_) =>
            DialogConfirmarRecepcionMultiWidget(recepcionCompleta: completa),
      );
      if (!mounted || opcion == null) return;

      if (opcion == OpcionConfirmarRecepcion.imprimir) {
        // Igual que recepción individual: imprime el picking y no valida.
        ModalPrintersList.show(
          context,
          resIds: [_session.pickingId],
          companyId: _session.warehouseId ?? 1,
        );
        return;
      }

      final crearBackorder = opcion == OpcionConfirmarRecepcion.conBackorder;
      await _enviarValidacion(sessionId, crearBackorder, null);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _enviarValidacion(
    int sessionId,
    bool crearBackorder,
    bool? confirmarCaducados,
  ) async {
    showLoadingDialog('Validando recepción...');
    final result = await getIt<ValidarRecepcionMultiUseCase>()(
      ValidarRecepcionMultiParams(
        sessionId: sessionId,
        crearBackorder: crearBackorder,
        confirmarCaducados: confirmarCaducados,
      ),
    );
    hideLoadingDialog();
    if (!mounted) return;

    await result.fold(
      (failure) async {
        if (failure is ConfirmationRequiredFailure) {
          final recibirVencidos = await showDialog<bool>(
            context: context,
            builder: (_) => DialogLotesVencidosWidget(message: failure.message),
          );
          if (!mounted || recibirVencidos == null) return;
          await _enviarValidacion(sessionId, crearBackorder, recibirVencidos);
          return;
        }
        _mostrarError(failure.message);
        await _cargarDetalle();
      },
      (validacion) async {
        if (!validacion.completada) {
          _mostrarError(
            validacion.message?.isNotEmpty == true
                ? validacion.message!
                : 'La recepción no quedó validada',
          );
          await _cargarDetalle();
          return;
        }
        _mostrarExito(validacion);
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.listRecepcionMultiusuario,
          arguments: [true], // refrescar la lista desde el backend
        );
      },
    );
  }

  /// Errores de asignar/validar: diálogo de errores de la app (el mensaje
  /// de Odoo puede ser largo y un snackbar se pierde).
  void _mostrarError(String message) => showScrollableErrorDialog(message);

  void _mostrarExito(RecepcionValidacion validacion) {
    final picking = validacion.pickingName ?? _session.pickingName ?? '';
    final texto = validacion.tieneBackorder
        ? '$picking validada. Lo pendiente quedó en ${validacion.backorderName}.'
        : '$picking validada.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(texto),
        backgroundColor: green,
      ),
    );
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
            RecepcionSessionCardWidget(
              session: _session,
              mostrarValidador: true,
            ),
            if (_mostrarValidar)
              RecepcionValidarButtonWidget(
                session: _session,
                ocupado: _ocupado,
                onAsignar: _onAsignar,
                onValidar: _onValidar,
              ),
          ],
        ),
      ),
    );
  }
}
