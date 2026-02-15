import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class BarcodeScannerField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String, BuildContext) onBarcodeScanned;
  final Function(String, String, BuildContext) onKeyScanned;
  final String scannedValue5;

  const BarcodeScannerField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onBarcodeScanned,
    required this.onKeyScanned,
    required this.scannedValue5,
  });

  @override
  Widget build(BuildContext context) {
    return context.select((UserBloc bloc) => bloc.fabricante).contains("Zebra")
        ? _buildZebraInput(context)
        : _buildNonZebraInput(context);
  }

  Widget _buildZebraInput(BuildContext context) {
    return Container(
      height: 15,
      margin: const EdgeInsets.only(bottom: 5),
      child: TextFormField(
        autofocus: true,
        showCursor: false,
        controller: controller,
        focusNode: focusNode,
        onChanged: (value) => onBarcodeScanned(value, context),
        decoration: const InputDecoration(
          disabledBorder: InputBorder.none,
          hintStyle: TextStyle(fontSize: 14, color: black),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildNonZebraInput(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            // El `onBarcodeScanned` se llama con el valor final
            // que se está guardado en el BLoC (`scannedValue5`)
            onBarcodeScanned(
              scannedValue5,
              context,
            );
            return KeyEventResult.handled;
          } else {
            // Se llama a `onKeyScanned` para acumular el valor
            onKeyScanned(event.data.keyLabel, 'toDo', context);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(),
    );
  }
}
