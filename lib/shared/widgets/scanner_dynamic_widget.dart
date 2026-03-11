import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class DynamicScannerWidget extends StatefulWidget {
  final bool isLocationOk;
  final bool locationIsOk;
  final bool productIsOk;
  final bool pedidoValidateIsOk;
  final bool isPedidoValidateOk;
  final bool quantityIsOk;
  final bool locationDestIsOk;
  final String currentLocationId;
  final Function(String) onValidateLocation;
  final Function(String keyLabel)? onKeyScanned;
  final FocusNode focusNode;
  final TextEditingController controller;
  final Widget locationDropdown;

  const DynamicScannerWidget({
    super.key,
    required this.isLocationOk,
    required this.locationIsOk,
    required this.productIsOk,
    required this.pedidoValidateIsOk,
    required this.isPedidoValidateOk,
    required this.quantityIsOk,
    required this.locationDestIsOk,
    required this.currentLocationId,
    required this.onValidateLocation,
    this.onKeyScanned,
    required this.focusNode,
    required this.controller,
    required this.locationDropdown,
  });

  @override
  State<DynamicScannerWidget> createState() => _DynamicScannerWidgetState();
}

class _DynamicScannerWidgetState extends State<DynamicScannerWidget> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Cachear el ID del producto para evitar parpadeo durante el escaneo
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
        widget.onValidateLocation(value);
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
              color: widget.pedidoValidateIsOk ? Colors.green : Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Card(
          color: widget.isPedidoValidateOk
              ? widget.pedidoValidateIsOk
                  ? Colors.green[100]
                  : Colors.grey[300]
              : Colors.red[200],
          elevation: 5,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Column(
              children: [
                widget.locationDropdown,
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 5),
                  child: TextFormField(
                    autofocus: true,
                    showCursor: false,
                    controller: widget.controller,
                    enabled: widget.locationIsOk &&
                        widget.productIsOk &&
                        widget.pedidoValidateIsOk &&
                        !widget.quantityIsOk &&
                        !widget.locationDestIsOk,
                    focusNode: widget.focusNode,
                    keyboardType: TextInputType.none,
                    enableInteractiveSelection: false,
                    style: const TextStyle(color: Colors.transparent),
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      _onZebraChanged(value, context);
                    },
                    onFieldSubmitted: (value) {
                      // Disparo inmediato en Enter: cancela el debounce pendiente
                      _debounce?.cancel();
                      if (value.trim().isNotEmpty) {
                        widget.onValidateLocation(value);
                      }
                      // Limpiar el controller después del submit
                      widget.controller.clear();
                    },
                    decoration: InputDecoration(
                      hintMaxLines: 1,
                      disabledBorder: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 1, color: black),
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
