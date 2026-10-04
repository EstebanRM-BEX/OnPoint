import 'package:flutter/material.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

/// Gestiona un único [DialogLoading] por pantalla, evitando que los estados
/// de loading de un bloc apilen diálogos duplicados y que los `Navigator.pop`
/// ciegos cierren rutas equivocadas (bottom sheets, la pantalla misma).
///
/// - [showLoadingDialog] es idempotente: si ya hay un diálogo visible no abre otro.
/// - [hideLoadingDialog] solo cierra el diálogo que este mixin abrió, si no hay
///   diálogo visible no hace nada.
///
/// El diálogo se empuja como una [DialogRoute] cuya referencia se guarda al
/// instante, y se cierra con `Navigator.removeRoute(esa ruta)`. Así el cierre
/// es exacto aunque llegue antes de que el diálogo termine de montarse, y
/// aunque otra ruta (p. ej. el diálogo de "agregar producto") se abra en el
/// mismo frame. Antes se cerraba con `Navigator.of(dialogContext).pop()`, que
/// saca la ruta de ARRIBA de la pila, no la del contexto: si otra ruta se abría
/// justo después del loading, se cerraba esa y el loading quedaba pegado.
mixin LoadingDialogMixin<T extends StatefulWidget> on State<T> {
  DialogRoute<void>? _loadingRoute;
  NavigatorState? _loadingNavigator;

  bool get isLoadingDialogVisible => _loadingRoute != null;

  void showLoadingDialog(String message) {
    if (_loadingRoute != null || !mounted) return;

    // Mismo navegador que usaba showDialog (rootNavigator por defecto).
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (_) => DialogLoading(message: message),
    );

    _loadingRoute = route;
    _loadingNavigator = navigator;
    navigator.push(route).whenComplete(() {
      // Cerrado por nosotros o por otro medio (p. ej. botón atrás).
      if (identical(_loadingRoute, route)) {
        _loadingRoute = null;
        _loadingNavigator = null;
      }
    });
  }

  void hideLoadingDialog() {
    final route = _loadingRoute;
    final navigator = _loadingNavigator;
    if (route == null) return;

    _loadingRoute = null;
    _loadingNavigator = null;

    if (route.isActive && navigator != null && navigator.mounted) {
      navigator.removeRoute(route);
    }
  }
}
