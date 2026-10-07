import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/inventario/presentation/widgets/session_expired_helper.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/common/packing_operacion.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

/// Traduce el [PackingOperacion] de un bloc en feedback de pantalla:
/// diálogo de carga (uno solo), snackbar de éxito, error con sonido y
/// vibración, y sesión expirada. Las páginas solo reaccionan a lo propio en
/// [onExito].
class PackingOperacionListener<B extends StateStreamable<S>, S>
    extends StatefulWidget {
  final PackingOperacion Function(S state) operacion;
  final void Function(BuildContext context, S state, PackingOperacion op)?
  onExito;

  /// Acciones cuyo error se muestra como snackbar corto (p. ej. escaneos) en
  /// lugar de un diálogo.
  final Set<String> erroresCortos;

  /// Acciones cuyo éxito no muestra snackbar.
  final Set<String> exitosSilenciosos;
  final Widget child;

  const PackingOperacionListener({
    super.key,
    required this.operacion,
    required this.child,
    this.onExito,
    this.erroresCortos = const {'escaneo'},
    this.exitosSilenciosos = const {},
  });

  @override
  State<PackingOperacionListener<B, S>> createState() =>
      _PackingOperacionListenerState<B, S>();
}

class _PackingOperacionListenerState<B extends StateStreamable<S>, S>
    extends State<PackingOperacionListener<B, S>>
    with LoadingDialogMixin {
  void _feedbackError() {
    getIt<IAudioService>().playErrorSound();
    getIt<IVibrationService>().vibrate();
  }

  void _snack(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          duration: Duration(milliseconds: error ? 1500 : 2000),
          backgroundColor: error ? Colors.red[300] : primaryColorApp,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listenWhen: (a, b) => widget.operacion(a).seq != widget.operacion(b).seq,
      listener: (context, state) {
        final op = widget.operacion(state);
        switch (op.tipo) {
          case TipoOperacion.procesando:
            showLoadingDialog(
              op.mensaje.isEmpty ? 'Procesando...' : op.mensaje,
            );
          case TipoOperacion.ninguna:
            hideLoadingDialog();
          case TipoOperacion.exito:
            hideLoadingDialog();
            if (op.mensaje.isNotEmpty &&
                !widget.exitosSilenciosos.contains(op.accion)) {
              _snack(op.mensaje);
            }
            widget.onExito?.call(context, state, op);
          case TipoOperacion.error:
          case TipoOperacion.desincronizado:
            hideLoadingDialog();
            _feedbackError();
            if (widget.erroresCortos.contains(op.accion)) {
              _snack(op.mensaje, error: true);
            } else {
              showScrollableErrorDialog(op.mensaje);
            }
          case TipoOperacion.sesionExpirada:
            hideLoadingDialog();
            SessionExpiredHelper.showDialog();
        }
      },
      child: widget.child,
    );
  }
}
