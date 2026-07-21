import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Campo invisible de escaneo por keyboard-wedge para PDAs (cualquier marca).
///
/// El disparo principal es el sufijo Enter que envía el escáner
/// ([TextFormField.onFieldSubmitted], inmediato). El [debounce] actúa solo
/// como red de seguridad para escáneres sin sufijo configurado.
///
/// Garantías:
/// - Un mismo buffer nunca dispara [onBarcodeScanned] dos veces, aunque el
///   debounce venza y después llegue el Enter (guard interno).
/// - Escanear el mismo código en escaneos consecutivos SÍ dispara de nuevo
///   (flujo normal de conteo en WMS): cada tecla nueva reinicia el guard.
/// - El teclado nunca se muestra ([TextInputType.none]).
///
/// Comportamientos opt-in (no cambian pantallas existentes):
/// - [clearOnScan]: limpia el buffer tras disparar, evita códigos concatenados.
/// - [refocusOnScan]: recupera el foco tras disparar, evita el refocus manual
///   con `Future.microtask` en cada pantalla.
class BarcodeScannerField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String value, BuildContext context) onBarcodeScanned;

  /// Red de seguridad cuando el escáner no envía sufijo Enter.
  final Duration debounce;

  /// Limpia el buffer automáticamente después de disparar.
  final bool clearOnScan;

  /// Recupera el foco automáticamente después de disparar.
  final bool refocusOnScan;

  /// Si el campo toma el foco al montarse. Desactivar cuando conviva con
  /// otros campos de la pantalla que deban enfocarse primero.
  final bool autofocus;

  const BarcodeScannerField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onBarcodeScanned,
    this.debounce = const Duration(milliseconds: 200),
    this.clearOnScan = false,
    this.refocusOnScan = false,
    this.autofocus = true,
  });

  @override
  State<BarcodeScannerField> createState() => _BarcodeScannerFieldState();
}

class _BarcodeScannerFieldState extends State<BarcodeScannerField> {
  Timer? _debounce;

  /// Último buffer ya entregado a [BarcodeScannerField.onBarcodeScanned].
  /// Evita el doble disparo debounce→Enter sobre el mismo escaneo.
  String _lastProcessed = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    // Tecla nueva = escaneo nuevo en curso: se reinicia el guard para que
    // repetir el mismo código en un escaneo posterior vuelva a disparar.
    _lastProcessed = '';
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () {
      if (mounted) _emit(value);
    });
  }

  void _onSubmitted(String value) {
    // Sufijo Enter del escáner: disparo inmediato, sin esperar el debounce.
    _debounce?.cancel();
    _emit(value);
  }

  void _emit(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    if (value == _lastProcessed) return; // este buffer ya se procesó
    _lastProcessed = value;

    widget.onBarcodeScanned(value, context);

    if (widget.clearOnScan) {
      widget.controller.clear();
    }
    if (widget.refocusOnScan) {
      Future.microtask(() {
        if (mounted) widget.focusNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 15,
      margin: const EdgeInsets.only(bottom: 5),
      child: TextFormField(
        autofocus: widget.autofocus,
        showCursor: false,
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.none,
        enableInteractiveSelection: false,
        textInputAction: TextInputAction.done,
        style: const TextStyle(color: Colors.transparent),
        onChanged: _onChanged,
        onFieldSubmitted: _onSubmitted,
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
