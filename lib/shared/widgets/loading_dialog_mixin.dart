import 'package:flutter/material.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

/// Gestiona un único [DialogLoading] por pantalla, evitando que los estados
/// de loading de un bloc apilen diálogos duplicados y que los `Navigator.pop`
/// ciegos cierren rutas equivocadas (bottom sheets, la pantalla misma).
///
/// - [showLoadingDialog] es idempotente: si ya hay un diálogo visible no abre otro.
/// - [hideLoadingDialog] solo cierra el diálogo que este mixin abrió, usando el
///   contexto propio del diálogo; si no hay diálogo visible, no hace nada.
mixin LoadingDialogMixin<T extends StatefulWidget> on State<T> {
  bool _loadingDialogVisible = false;
  BuildContext? _loadingDialogContext;

  bool get isLoadingDialogVisible => _loadingDialogVisible;

  void showLoadingDialog(String message) {
    if (_loadingDialogVisible || !mounted) return;
    _loadingDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _loadingDialogContext = dialogContext;
        return DialogLoading(message: message);
      },
    ).whenComplete(() {
      _loadingDialogVisible = false;
      _loadingDialogContext = null;
    });
  }

  void hideLoadingDialog() {
    final dialogContext = _loadingDialogContext;
    if (!_loadingDialogVisible || dialogContext == null) return;
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
  }
}
