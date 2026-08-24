import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reabre automáticamente el teclado suave si el IME del PDA (Zebra/Urovo/
/// Chainway) lo cierra por sí solo mientras el campo conserva el foco — un
/// cierre que ocurre a nivel de sistema, sin pasar por Flutter, así que
/// ningún FocusNode listener lo detecta. Solo se ve como un cambio en
/// `viewInsets.bottom` (`didChangeMetrics`).
///
/// Distingue ese cierre involuntario del cierre intencional del usuario: si
/// el teclado llevaba abierto más de 600ms antes de cerrarse, se asume que
/// fue el usuario (el PDA lo cierra en <300ms) y no se pelea contra eso.
///
/// Mismo mecanismo que `DynamicSearchBar` con `persistentKeyboard: true`,
/// extraído para poder usarlo en TextFormField sueltos.
///
/// Uso en un State:
/// ```dart
/// class _FooState extends State<Foo> with WidgetsBindingObserver {
///   final _focusNode = FocusNode();
///   late final _kbWatchdog = KeyboardWatchdog(state: this, focusNode: _focusNode);
///
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addObserver(this);
///   }
///
///   @override
///   void didChangeMetrics() => _kbWatchdog.onMetricsChanged();
///
///   @override
///   void dispose() {
///     WidgetsBinding.instance.removeObserver(this);
///     _kbWatchdog.dispose();
///     _focusNode.dispose();
///     super.dispose();
///   }
/// }
/// ```
class KeyboardWatchdog {
  KeyboardWatchdog({required this.state, required this.focusNode}) {
    focusNode.addListener(_onFocusChange);
  }

  final State state;
  final FocusNode focusNode;

  double _lastBottomInset = 0;
  int _reopenAttempts = 0;
  DateTime? _attemptWindowStart;
  DateTime? _keyboardOpenedAt;
  static const _maxReopenAttempts = 3;
  static const _attemptWindow = Duration(seconds: 5);
  static const _userDismissThreshold = Duration(milliseconds: 600);

  double _currentBottomInset() {
    final view = View.of(state.context);
    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  /// Llamar desde `WidgetsBindingObserver.didChangeMetrics()`.
  void onMetricsChanged() {
    if (!state.mounted) return;
    final bottomInset = _currentBottomInset();
    final wasOpen = _lastBottomInset > 0;

    if (!wasOpen && bottomInset > 0) {
      _keyboardOpenedAt = DateTime.now();
    }
    _lastBottomInset = bottomInset;

    // El teclado se cerró pero el campo conserva el foco: fue el IME del
    // PDA, no el usuario (que hubiera perdido el foco al tocar otro lado).
    if (wasOpen && bottomInset == 0 && focusNode.hasFocus) {
      final elapsed = _keyboardOpenedAt != null
          ? DateTime.now().difference(_keyboardOpenedAt!)
          : Duration.zero;
      if (elapsed > _userDismissThreshold) return;
      _attemptReopen();
    }
  }

  void _attemptReopen() {
    final now = DateTime.now();
    if (_attemptWindowStart == null ||
        now.difference(_attemptWindowStart!) > _attemptWindow) {
      _attemptWindowStart = now;
      _reopenAttempts = 0;
    }
    if (_reopenAttempts >= _maxReopenAttempts) return;
    _reopenAttempts++;

    SystemChannels.textInput.invokeMethod('TextInput.show');

    // Si tras 250ms sigue cerrado, reciclamos la conexión IME soltando y
    // recuperando el foco (fuerza una conexión nueva con el sistema).
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!state.mounted || !focusNode.hasFocus) return;
      if (_currentBottomInset() > 0) return; // ya se reabrió
      focusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.mounted) {
          _keyboardOpenedAt = DateTime.now();
          focusNode.requestFocus();
        }
      });
    });
  }

  void _onFocusChange() {
    if (!focusNode.hasFocus) return;
    // Da tiempo al view de quedar "served" por el IME antes de mostrar teclado.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (state.mounted && focusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  /// Llamar desde `State.dispose()`, antes de disponer el FocusNode.
  void dispose() {
    focusNode.removeListener(_onFocusChange);
  }
}
