import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class LocationDestScannerWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: locationDestIsOk ? Colors.green : Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Card(
          color: isLocationDestOk
              ? locationDestIsOk
                  ? Colors.green[100]
                  : Colors.grey[300]
              : Colors.red[200],
          elevation: 5,
          child: Container(
            width: size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: !context.read<UserBloc>().fabricante.contains("Zebra")
                ? Focus(
                    focusNode: focusNode,
                    onKey: (node, event) {
                      if (event is RawKeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.enter) {
                          onValidateMuelle(controller.text);
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
                    child: Column(
                      children: [
                        dropdownWidget,
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            muelleHint ?? 'Muelle',
                            style: TextStyle(fontSize: 14, color: black),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      dropdownWidget,
                      const SizedBox(height: 5),
                      Container(
                        height: 15,
                        margin: const EdgeInsets.only(bottom: 5),
                        child: TextFormField(
                          showCursor: false,
                          enabled: locationIsOk &&
                              productIsOk &&
                              !quantityIsOk &&
                              !locationDestIsOk,
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: (value) {
                            onValidateMuelle(value);
                          },
                          decoration: InputDecoration(
                            hintText: muelleHint,
                            disabledBorder: InputBorder.none,
                            hintStyle:
                                const TextStyle(fontSize: 14, color: black),
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
