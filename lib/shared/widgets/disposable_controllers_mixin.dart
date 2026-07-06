import 'package:flutter/material.dart';

/// Libera automáticamente los [ChangeNotifier] de la pantalla
/// (TextEditingController, FocusNode, ScrollController, etc.) cuando el
/// State se destruye, evitando que queden vivos tras salir de la pantalla.
///
/// La pantalla declara sus recursos en [disposables]:
///
/// ```dart
/// class _MyScreenState extends State<MyScreen> with DisposableControllersMixin {
///   final _controllerProduct = TextEditingController();
///   final _focusNodeProduct = FocusNode();
///
///   @override
///   List<ChangeNotifier> get disposables => [
///         _controllerProduct,
///         _focusNodeProduct,
///       ];
/// }
/// ```
///
/// Si la pantalla además necesita su propio `dispose()` (remover observers,
/// cancelar timers), debe terminar llamando a `super.dispose()` como siempre;
/// el mixin libera la lista en ese momento.
mixin DisposableControllersMixin<T extends StatefulWidget> on State<T> {
  /// Controllers y nodes que este State posee y deben liberarse al destruirlo.
  List<ChangeNotifier> get disposables;

  @override
  void dispose() {
    for (final disposable in disposables) {
      disposable.dispose();
    }
    super.dispose();
  }
}
