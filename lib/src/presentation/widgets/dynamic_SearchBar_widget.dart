// ignore_for_file: sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';

typedef SearchCallback = void Function(String value);
typedef ClearCallback = void Function();

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
  });

  @override
  _DynamicSearchBarState createState() => _DynamicSearchBarState();
}

class _DynamicSearchBarState extends State<DynamicSearchBar> {
  FocusNode? _internalFocusNode;

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
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
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
