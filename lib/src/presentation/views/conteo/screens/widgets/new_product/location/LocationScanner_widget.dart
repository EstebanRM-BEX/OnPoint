import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class LocationScannerAll extends StatelessWidget {
  final bool isLocationOk;
  final bool locationIsOk;
  final bool productIsOk;
  final bool quantityIsOk;
  final String? currentLocationName;
  final Function(String) onLocationScanned;
  final Function(String keyLabel)? onKeyScanned;
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
    this.onKeyScanned,
    required this.focusNode,
    required this.controller,
    this.locationDropdown,
  });

  @override
  Widget build(BuildContext context) {
    // Lectura del BLoC una sola vez para determinar el tipo de dispositivo
    final isZebraDevice = context.read<UserBloc>().fabricante.contains("Zebra");

    // Lógica para los colores
    final statusColor = locationIsOk ? green : yellow;
    final cardColor = isLocationOk
        ? locationIsOk
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: isZebraDevice
                ? _buildZebraInput(context)
                : _buildNonZebraInput(context),
          ),
        ),
      ],
    );
  }

  Widget _buildZebraInput(BuildContext context) {
    return Column(
      children: [
        if (locationDropdown != null) locationDropdown!,
        Container(
          height: 15,
          margin: const EdgeInsets.only(bottom: 5),
          child: TextFormField(
            autofocus: true,
            showCursor: false,
            controller: controller,
            enabled: !locationIsOk && !productIsOk && !quantityIsOk,
            focusNode: focusNode,
            onChanged: (value) => onLocationScanned(value),
            decoration: InputDecoration(
              hintText: currentLocationName ?? 'Esperando escaneo',
              disabledBorder: InputBorder.none,
              hintStyle: const TextStyle(fontSize: 14, color: black),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNonZebraInput(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            onLocationScanned(controller.text);
            return KeyEventResult.handled;
          } else {
            if (onKeyScanned != null) {
              onKeyScanned!(event.data.keyLabel);
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: locationDropdown ?? const SizedBox(),
    );
  }
}
