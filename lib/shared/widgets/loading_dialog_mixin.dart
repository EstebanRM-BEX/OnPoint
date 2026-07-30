import 'package:flutter/material.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

/// Gestiona un único [DialogLoading] por pantalla, evitando que los estados
/// de loading de un bloc apilen diálogos duplicados y que los `Navigator.pop`
/// ciegos cierren rutas equivocadas (bottom sheets, la pantalla misma).
///
/// - [showLoadingDialog] es idempotente: si ya hay un diálogo visible no abre otro.
/// - [hideLoadingDialog] solo cierra el diálogo que este mixin abrió, usando el
///   contexto propio del diálogo; si no hay diálogo visible, no hace nada.
///
/// Blinda la carrera show→hide inmediato: si un error de backend (Odoo) llega
/// antes de que el `builder` del diálogo alcance a montarse y capturar su
/// contexto, [hideLoadingDialog] marca un cierre pendiente ([_pendingHide]) que
/// el propio builder resuelve al montar, evitando que el loading quede pegado y
/// que [_loadingDialogVisible] se bloquee para siempre.
mixin LoadingDialogMixin<T extends StatefulWidget> on State<T> {
  bool _loadingDialogVisible = false;
  BuildContext? _loadingDialogContext;
  bool _pendingHide = false;

  bool get isLoadingDialogVisible => _loadingDialogVisible;

  void showLoadingDialog(String message) {
    if (_loadingDialogVisible || !mounted) return;
    _loadingDialogVisible = true;
    _pendingHide = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _loadingDialogContext = dialogContext;
        // Si pidieron cerrar antes de que el diálogo montara, lo cerramos en
        // cuanto termine este frame (sin dejarlo pegado).
        if (_pendingHide) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          });
        }
        return DialogLoading(message: message);
      },
    ).whenComplete(() {
      _loadingDialogVisible = false;
      _loadingDialogContext = null;
      _pendingHide = false;
    });
  }

  void hideLoadingDialog() {
    if (!_loadingDialogVisible) return;
    final dialogContext = _loadingDialogContext;
    if (dialogContext == null) {
      // El builder aún no montó el diálogo; lo cerramos en cuanto lo haga.
      _pendingHide = true;
      return;
    }
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
  }
}
