import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Widget de escaneo de lote/serie reutilizable.
///
/// Usa un [TextFormField] invisible con teclado oculto ([TextInputType.none])
/// y debounce interno de 200ms para evitar múltiples disparos por carácter.
/// Sigue el mismo patrón que [ProductScannerWidget].
class LoteScannerWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

  /// Texto que se muestra como placeholder cuando el campo está inactivo.
  final String hintText;

  /// Callback ejecutado cuando se completa el escaneo del lote.
  final Function(String value) onValidateLote;

  const LoteScannerWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hintText,
    required this.onValidateLote,
  });

  @override
  State<LoteScannerWidget> createState() => _LoteScannerWidgetState();
}

class _LoteScannerWidgetState extends State<LoteScannerWidget> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (value.trim().isNotEmpty) {
        widget.onValidateLote(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Container(
        height: 20,
        margin: const EdgeInsets.only(bottom: 5, top: 5),
        child: TextFormField(
          autofocus: true,
          showCursor: false,
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          keyboardType: TextInputType.none,
          enableInteractiveSelection: false,
          textInputAction: TextInputAction.done,
          style: const TextStyle(color: Colors.transparent),
          onChanged: _onChanged,
          onFieldSubmitted: (value) {
            // Disparo inmediato en Enter: cancela el debounce pendiente
            _debounce?.cancel();
            if (value.trim().isNotEmpty) {
              widget.onValidateLote(value);
            }
            widget.controller.clear();
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintMaxLines: 1,
            disabledBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            border: InputBorder.none,
            hintStyle: const TextStyle(fontSize: 12, color: black),
          ),
        ),
      ),
    );
  }
}
