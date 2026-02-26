import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class LocationScannerAll extends StatefulWidget {
  final bool isLocationOk;
  final bool locationIsOk;
  final bool productIsOk;
  final bool quantityIsOk;
  final String? currentLocationName;
  final Function(String) onLocationScanned;
  final FocusNode focusNode;
  final TextEditingController controller;
  final Widget? locationDropdown;

  const LocationScannerAll({
    super.key,
    required this.isLocationOk,
    required this.locationIsOk,
    required this.productIsOk,
    required this.quantityIsOk,
    this.currentLocationName,
    required this.onLocationScanned,
    required this.focusNode,
    required this.controller,
    this.locationDropdown,
  });

  @override
  State<LocationScannerAll> createState() => _LocationScannerAllState();
}

class _LocationScannerAllState extends State<LocationScannerAll> {
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
    _debounce = Timer(const Duration(milliseconds: 200), () {});
  }

  @override
  Widget build(BuildContext context) {
    // Lógica para los colores
    final statusColor = widget.locationIsOk ? green : yellow;
    final cardColor = widget.isLocationOk
        ? widget.locationIsOk
            ? Colors.green[100]
            : Colors.grey[300]
        : Colors.red[200];

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Card(
          color: cardColor,
          elevation: 5,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            child: _buildZebraInput(context),
          ),
        ),
      ],
    );
  }

  Widget _buildZebraInput(BuildContext context) {
    return Column(
      children: [
        if (widget.locationDropdown != null) widget.locationDropdown!,
        Container(
          height: 1,
          margin: const EdgeInsets.only(bottom: 3),
          child: TextFormField(
            autofocus: true,
            showCursor: false,
            controller: widget.controller,
            enabled: !widget.locationIsOk &&
                !widget.productIsOk &&
                !widget.quantityIsOk,
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
                widget.onLocationScanned(value);
              }
              // Limpiar el controller después del submit
              widget.controller.clear();
            },
            decoration: InputDecoration(
              disabledBorder: InputBorder.none,
              hintStyle: const TextStyle(fontSize: 1, color: black),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
