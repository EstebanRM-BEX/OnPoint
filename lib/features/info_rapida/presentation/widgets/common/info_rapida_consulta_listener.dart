import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/utils/widgets/dialog_dispositivo_no_autorizado_widget.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/scan/info_rapida_scan_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/navigation/info_rapida_navigator.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_snackbar.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';

/// Reacciona a las consultas de [InfoRapidaScanBloc] de la página: diálogo de
/// carga, avisos de error (403, sesión, versión, no encontrado, sin red) y
/// navegación al detalle según el tipo de resultado.
///
/// Lo usan todas las páginas que consultan (principal, listas y detalles al
/// tocar una fila), así el manejo es idéntico en todo el módulo.
class InfoRapidaConsultaListener extends StatefulWidget {
  final Widget child;

  /// Permisos a pasar al detalle. Si es null se usan los del estado del bloc
  /// (los carga `InfoRapidaScanIniciado` en la pantalla principal).
  final ConfigInfoRapidaUsuario? config;

  /// Reemplaza la navegación por defecto (p. ej. refrescar el detalle actual
  /// tras una transferencia).
  final ValueChanged<InfoRapida>? onResultado;

  /// Se llama al volver del detalle abierto por la navegación por defecto.
  final VoidCallback? onRetorno;

  const InfoRapidaConsultaListener({
    super.key,
    required this.child,
    this.config,
    this.onResultado,
    this.onRetorno,
  });

  @override
  State<InfoRapidaConsultaListener> createState() =>
      _InfoRapidaConsultaListenerState();
}

class _InfoRapidaConsultaListenerState extends State<InfoRapidaConsultaListener>
    with LoadingDialogMixin {
  void _onState(BuildContext context, InfoRapidaScanState state) {
    switch (state.status) {
      case InfoRapidaScanStatus.loading:
        showLoadingDialog('Buscando información...');
      case InfoRapidaScanStatus.success:
        hideLoadingDialog();
        final info = state.resultado;
        if (info == null) return;
        // Bug 6 ("solo avisar"): el resultado se muestra igual.
        if (info.actualizarVersion) _avisarNuevaVersion();
        if (widget.onResultado != null) {
          widget.onResultado!(info);
          return;
        }
        if (!info.actualizarVersion) {
          InfoRapidaSnackbar.success('Información encontrada');
        }
        InfoRapidaNavigator.abrirResultado(
          context,
          info,
          config: widget.config ?? state.configuracion,
        ).then((_) {
          if (mounted) widget.onRetorno?.call();
        });
      case InfoRapidaScanStatus.failure:
        hideLoadingDialog();
        _mostrarError(context, state);
      case InfoRapidaScanStatus.initial:
        hideLoadingDialog();
    }
  }

  void _mostrarError(BuildContext context, InfoRapidaScanState state) {
    if (state.isDispositivoNoAutorizado) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DialogUnauthorizedDevice(),
      );
      return;
    }
    if (state.isActualizarVersion) {
      _avisarNuevaVersion();
      return;
    }

    final mensaje = state.isNoEncontrado
        ? 'Información no encontrada'
        : (state.mensajeError ?? 'Información no encontrada');
    InfoRapidaSnackbar.error(mensaje, progress: true);
    getIt<IVibrationService>().vibrate();
    getIt<IAudioService>().playErrorSound();
  }

  void _avisarNuevaVersion() => InfoRapidaSnackbar.warning(
        'Hay una nueva versión disponible. Actualiza desde la configuración '
        'de la app, pulsando el nombre de usuario en el Home',
      );

  @override
  Widget build(BuildContext context) {
    return BlocListener<InfoRapidaScanBloc, InfoRapidaScanState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onState,
      child: widget.child,
    );
  }
}
