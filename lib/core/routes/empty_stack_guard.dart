import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

/// Red de seguridad: la app nunca debe quedar sin pantalla montada.
///
/// Con `goToScreen` (pushNamedAndRemoveUntil) casi siempre hay UNA sola ruta
/// viva. Un `Navigator.pop` de más (p. ej. el pop ciego del loading al volver
/// de background, cuando el diálogo ya se había cerrado) saca esa última ruta
/// y el Navigator queda vacío: pantalla negra, solo se ven los overlays del
/// `builder` (el "Validando inactividad...").
///
/// Tras cada pop/remove, al siguiente frame, si el stack quedó vacío se monta
/// Home (o `checkout` si no hay sesión, que decide a dónde ir).
class EmptyStackGuard extends NavigatorObserver {
  String? _lastRemoved;
  bool _scheduled = false;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _schedule(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _schedule(route);

  void _schedule(Route<dynamic> route) {
    _lastRemoved = route.settings.name ?? route.runtimeType.toString();
    if (_scheduled) return;
    _scheduled = true;
    // Post-frame: pushNamedAndRemoveUntil empuja y remueve en el mismo flush;
    // se evalúa cuando el Navigator ya terminó de asentar el stack.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      ensureScreen(navigator, reason: 'pop/remove de $_lastRemoved');
    });
  }

  /// Monta Home si [navigator] no tiene ninguna ruta. Seguro de llamar en
  /// cualquier momento (p. ej. al volver de background).
  static Future<void> ensureScreen(
    NavigatorState? navigator, {
    String reason = '',
  }) async {
    if (navigator == null || !navigator.mounted || !_isEmpty(navigator)) {
      return;
    }

    final loggedIn = await PrefUtils.getIsLoggedIn();
    if (!navigator.mounted || !_isEmpty(navigator)) return;

    debugPrint('🧯 Stack de navegación vacío ($reason) → montando pantalla');
    FirebaseCrashlytics.instance.recordError(
      StateError('Stack de navegación vacío: $reason'),
      StackTrace.current,
      reason: 'EmptyStackGuard',
      fatal: false,
    );

    navigator.pushNamed(loggedIn ? AppRoutes.home : AppRoutes.checkout);
  }

  /// `popUntil` evalúa el predicado sobre la ruta de arriba; si devuelve true
  /// no saca nada. Si nunca se llama, no hay rutas.
  static bool _isEmpty(NavigatorState navigator) {
    var empty = true;
    navigator.popUntil((_) {
      empty = false;
      return true;
    });
    return empty;
  }
}
