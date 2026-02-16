import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class LocationScannerWidget extends StatelessWidget {
  final bool isLocationOk;
  final bool locationIsOk;
  final bool productIsOk;
  final bool quantityIsOk;
  final bool locationDestIsOk;
  final String currentLocationId;
  final Function(String) onValidateLocation;
  final Function(String keyLabel)? onKeyScanned;
  final FocusNode focusNode;
  final TextEditingController controller;
  final Widget locationDropdown;

  const LocationScannerWidget({
    super.key,
    required this.isLocationOk,
    required this.locationIsOk,
    required this.productIsOk,
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: locationIsOk ? Colors.green : Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Card(
          color: isLocationOk
              ? locationIsOk
                  ? Colors.green[100]
                  : Colors.grey[300]
              : Colors.red[200],
          elevation: 5,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: !context.read<UserBloc>().fabricante.contains("Zebra")
                ? Focus(
                    focusNode: focusNode,
                    onKey: (node, event) {
                      if (event is RawKeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.enter) {
                          onValidateLocation(controller.text);
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
                    child: locationDropdown,
                  )
                : Column(
                    children: [
                      locationDropdown,
                      Container(
                        height: 15,
                        margin: const EdgeInsets.only(bottom: 5),
                        child: TextFormField(
                          autofocus: true,
                          showCursor: false,
                          controller: controller,
                          enabled: !locationIsOk &&
                              !productIsOk &&
                              !quantityIsOk &&
                              !locationDestIsOk,
                          focusNode: focusNode,
                          onChanged: (value) {
                            onValidateLocation(value);
                          },
                          decoration: InputDecoration(
                            hintText: currentLocationId,
                            disabledBorder: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 14, color: black),
                            border: InputBorder.none,
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
