import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class LocationDestScannerWidget extends StatefulWidget {
  final bool isLocationDestOk;
  final bool locationDestIsOk;
  final bool locationIsOk;
  final bool productIsOk;
  final bool quantityIsOk;
  final Size size;
  final String? muelleHint;
  final Function(String) onValidateMuelle;
  final Function(String)? onKeyScanned;
  final FocusNode focusNode;
  final TextEditingController controller;
  final Widget dropdownWidget;

  const LocationDestScannerWidget({
    super.key,
    required this.isLocationDestOk,
    required this.locationDestIsOk,
    required this.locationIsOk,
    required this.productIsOk,
    required this.quantityIsOk,
    required this.size,
    required this.muelleHint,
    required this.onValidateMuelle,
    this.onKeyScanned,
    required this.focusNode,
    required this.controller,
    required this.dropdownWidget,
  });

  @override
  State<LocationDestScannerWidget> createState() =>
      _LocationDestScannerWidgetState();
}

class _LocationDestScannerWidgetState extends State<LocationDestScannerWidget> {
  Timer? _debounce;
  late String _cachedProductId;

  @override
  void initState() {
    super.initState();
    // Cachear el ID del producto para evitar parpadeo durante el escaneo
    _cachedProductId = widget.muelleHint ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onZebraChanged(String value, BuildContext context) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (value.trim().isNotEmpty) {
        widget.onValidateMuelle(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: widget.locationDestIsOk ? Colors.green : Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Card(
          color: widget.isLocationDestOk
              ? widget.locationDestIsOk
                  ? Colors.green[100]
                  : Colors.grey[300]
              : Colors.red[200],
          elevation: 5,
          child: Container(
            width: widget.size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: [
                widget.dropdownWidget,
                const SizedBox(height: 5),
                Container(
                  height: 15,
                  margin: const EdgeInsets.only(bottom: 5),
                  child: TextFormField(
                    showCursor: false,
                    enabled: widget.locationIsOk &&
                        widget.productIsOk &&
                        !widget.quantityIsOk &&
                        !widget.locationDestIsOk,
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.none,
                    enableInteractiveSelection: false,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: Colors.transparent),
                    onChanged: (value) {
                      // Usa el debounce para evitar múltiples disparos por carácter
                      _onZebraChanged(value, context);
                    },
                    onFieldSubmitted: (value) {
                      // Disparo inmediato en Enter: cancela el debounce pendiente
                      _debounce?.cancel();
                      if (value.trim().isNotEmpty) {
                        widget.onValidateMuelle(value);
                      }
                      // Limpiar el controller después del submit
                      widget.controller.clear();
                    },
                    decoration: InputDecoration(
                      hintText: widget.muelleHint,
                      hintStyle: const TextStyle(fontSize: 14, color: black),
                      disabledBorder: InputBorder.none,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
