import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Widget unificado de escaneo de código de barras.
///
/// Detecta automáticamente el tipo de dispositivo mediante [UserBloc.fabricante]:
/// - **Zebra**: usa un [TextFormField] invisible con teclado oculto y debounce
///   interno de 300ms para evitar múltiples disparos por carácter.
/// - **Otros**: usa un [Focus] que acumula teclas character a character con
///   [onKeyScanned] y dispara [onBarcodeScanned] al presionar Enter,
class BarcodeScannerField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String, BuildContext) onBarcodeScanned;

  const BarcodeScannerField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onBarcodeScanned,
  });

  @override
  State<BarcodeScannerField> createState() => _BarcodeScannerFieldState();
}

class _BarcodeScannerFieldState extends State<BarcodeScannerField> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onZebraChanged(String value, BuildContext context) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (value.trim().isNotEmpty) {
        widget.onBarcodeScanned(value, context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildInput(context);
  }

  /// Modo scanner: campo invisible con teclado oculto y debounce.
  Widget _buildInput(BuildContext context) {
    return Container(
      height: 15,
      margin: const EdgeInsets.only(bottom: 5),
      child: TextFormField(
        autofocus: true,
        showCursor: false,
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.none,
        enableInteractiveSelection: false,
        textInputAction: TextInputAction.done,
        style: const TextStyle(color: Colors.transparent),
        onChanged: (value) => _onZebraChanged(value, context),
        onFieldSubmitted: (value) {
          // Disparo inmediato al recibir Enter/Submit del escáner
          _debounce?.cancel();
          if (value.trim().isNotEmpty) {
            widget.onBarcodeScanned(value, context);
          }
        },
        decoration: const InputDecoration(
          disabledBorder: InputBorder.none,
          hintStyle: TextStyle(fontSize: 14, color: black),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
