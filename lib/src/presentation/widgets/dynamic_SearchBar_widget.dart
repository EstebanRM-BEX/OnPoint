// ignore_for_file: sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';

typedef SearchCallback = void Function(String value);
typedef ClearCallback = void Function();
typedef KeyboardEventCallback = void Function(String event);

class DynamicSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final SearchCallback onSearchChanged;
  final ClearCallback onSearchCleared;
  final VoidCallback? onTap;
  final String hintText;
  final double width;
  final FocusNode? focusNode;
  final dynamic filterIndex;
  final TextInputAction textInputAction;
  // true  → X cierra el teclado (comportamiento por defecto)
  // false → X mantiene el foco para que el scanner/usuario pueda seguir
  final bool closeKeyboardOnClear;
  // true → watchdog: si el sistema (IME del PDA) cierra el teclado mientras
  // el campo conserva el foco, lo reabre automáticamente. El listener de foco
  // no detecta este caso porque el foco nunca se pierde. Opt-in: también
  // reabre si el usuario cierra el teclado con el botón atrás, así que solo
  // debe activarse en pantallas donde el teclado deba permanecer visible.
  final bool persistentKeyboard;
  // Telemetría opcional del watchdog (keyboard_hidden_while_focused,
  // keyboard_reopen_show, keyboard_reopen_recycle, keyboard_reopen_limit).
  final KeyboardEventCallback? onKeyboardEvent;

  const DynamicSearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.onSearchCleared,
    this.onTap,
    this.hintText = "Buscar...",
    this.filterIndex,
    this.width = double.infinity,
    this.focusNode,
    this.textInputAction = TextInputAction.search,
    this.closeKeyboardOnClear = true,
    this.persistentKeyboard = false,
    this.onKeyboardEvent,
  });

  @override
  _DynamicSearchBarState createState() => _DynamicSearchBarState();
}

class _DynamicSearchBarState extends State<DynamicSearchBar>
    with WidgetsBindingObserver {
  FocusNode? _internalFocusNode;

  // ── Watchdog (persistentKeyboard) ────────────────────────────────────────
  double _lastBottomInset = 0;
  int _reopenAttempts = 0;
  DateTime? _attemptWindowStart;
  static const _maxReopenAttempts = 3;
  static const _attemptWindow = Duration(seconds: 5);

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    // Escucha cambios de foco para forzar teclado en Android 13 + PDAs Chainway/Zebra.
    // El escáner físico puede cerrar el teclado suave; al recuperar foco lo volvemos a abrir.
    _effectiveFocusNode.addListener(_onFocusChange);
    if (widget.persistentKeyboard) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (widget.persistentKeyboard) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  double _currentBottomInset() {
    final view = View.of(context);
    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  @override
  void didChangeMetrics() {
    if (!mounted || !widget.persistentKeyboard) return;
    final bottomInset = _currentBottomInset();
    final wasOpen = _lastBottomInset > 0;
    _lastBottomInset = bottomInset;

    // El teclado se cerró pero el campo conserva el foco: el IME del PDA
    // (Urovo/Zebra/Chainway) lo ocultó sin pasar por Flutter. El listener de
    // foco es ciego a esto — único punto donde se puede detectar.
    if (wasOpen && bottomInset == 0 && _effectiveFocusNode.hasFocus) {
      widget.onKeyboardEvent?.call('keyboard_hidden_while_focused');
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
    if (_reopenAttempts >= _maxReopenAttempts) {
      // Límite alcanzado: el sistema insiste en cerrarlo; no ciclar contra él.
      widget.onKeyboardEvent?.call('keyboard_reopen_limit');
      return;
    }
    _reopenAttempts++;

    // Nivel 1: pedir al IME que se muestre.
    widget.onKeyboardEvent?.call('keyboard_reopen_show');
    SystemChannels.textInput.invokeMethod('TextInput.show');

    // Nivel 2: si tras 250ms sigue cerrado, la conexión IME quedó en mal
    // estado (pasa tras horas de uso en PDAs) — reciclarla soltando y
    // recuperando el foco, lo que fuerza una conexión nueva.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || !_effectiveFocusNode.hasFocus) return;
      if (_currentBottomInset() > 0) return; // ya se reabrió
      widget.onKeyboardEvent?.call('keyboard_reopen_recycle');
      _effectiveFocusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _effectiveFocusNode.requestFocus();
      });
    });
  }

  void _onFocusChange() {
    if (!_effectiveFocusNode.hasFocus) return;
    // Android 13 deprecó showSoftInput(); usar SystemChannels es más confiable.
    // El delay da tiempo al view de quedar "served" por el IME antes de mostrar teclado.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _effectiveFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  void _handleTap() {
    // Forzar teclado inmediatamente al tocar — cubre el caso donde el campo
    // ya tenía foco pero el teclado se cerró (comportamiento Chainway Android 13).
    SystemChannels.textInput.invokeMethod('TextInput.show');
    widget.onTap?.call();
  }

  void _handleClear() {
    widget.controller.clear();
    widget.onSearchCleared();
    if (widget.closeKeyboardOnClear) {
      _effectiveFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      width: widget.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 3,
                child: TextFormField(
                  showCursor: true,
                  textAlignVertical: TextAlignVertical.center,
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onSearchChanged,
                  onTap: _handleTap,
                  onFieldSubmitted: (_) {
                    // Scanner de PDA envía Enter tras el barcode; reabrir teclado
                    Future.delayed(const Duration(milliseconds: 80), () {
                      if (mounted && _effectiveFocusNode.hasFocus) {
                        SystemChannels.textInput.invokeMethod('TextInput.show');
                      }
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: grey),
                    suffixIcon: IconButton(
                      onPressed: _handleClear,
                      icon: const Icon(Icons.close, color: grey),
                    ),
                    disabledBorder: const OutlineInputBorder(),
                    hintText: widget.hintText,
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
